import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import {
  cloneReviewCardDocument,
  createDefaultReviewCardDocument,
  DEFAULT_PROJECT_ID,
  getReviewDocumentKey,
  normalizeReviewJudgement,
  ReviewCardDocument,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import {
  ReviewCardExchangeDecision,
  ReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';
import { MigrationResult, ReviewCardMigrationService } from './ReviewCardMigrationService';
import { ReviewCardRdbListResult, ReviewCardRdbService } from './ReviewCardRdbService';
import { ReviewCardRdbReplacementItem } from './ReviewCardRdbService';
import { ReviewCardRdbMapper, ReviewLibraryStats, ReviewListQuery } from './ReviewCardRdbModel';
import { ReviewJsonBackupResult, ReviewJsonExportService } from './ReviewJsonExportService';
import { ReviewLibraryRefreshService } from './ReviewLibraryRefreshService';
import { PendingReviewPhotoStore } from './PendingReviewPhotoStore';
import { upgradeVersionOnPersist } from './VersionUpgrader';

const PREFERENCES_NAME: string = 'review_card_history';
const HISTORY_KEY: string = 'items';
const BACKUP_IMPORT_COMPLETED_KEY: string = 'backup_import_completed';
const RDB_MAIN_INDEX_READY_KEY: string = 'rdb_main_index_ready';
const REVIEW_JSON_BACKUP_DIR_NAME: string = 'review_exchange';

export interface ReviewCardHistoryLoadResult {
  items: Array<ReviewCardHistoryItem>;
  diagnostics: ReviewCardHistoryDiagnostics;
}

export interface ReviewCardHistoryPageResult {
  items: Array<ReviewCardHistoryItem>;
  totalCount: number;
  libraryStats: ReviewLibraryStats;
}

export interface ReviewCardHistoryPageQuery {
  decision?: string;
  keyword?: string;
  limit: number;
  offset: number;
}

export interface ReviewCardHistoryDiagnostics {
  preferencesName: string;
  historyKey: string;
  filesDir: string;
  backupDirectory: string;
  rawHistoryType: string;
  rawHistoryLength: number;
  parsedHistoryCount: number;
  backupImportCompleted: boolean;
  forcedBackupReload: boolean;
  backupDirectoryExists: boolean;
  backupFileCount: number;
  parsedBackupCount: number;
  mergedCount: number;
  persistedMergedHistory: boolean;
  latestTitle: string;
  latestUpdatedAt: number;
  errorMessage: string;
  rdbPrimaryReadAttempted: boolean;
  rdbPrimaryReadUsed: boolean;
  rdbRowCount: number;
  rdbParsedCount: number;
  rdbInvalidRowCount: number;
  rdbMigrationAttempted: boolean;
  rdbMigrationSourceCount: number;
  rdbMigrationInsertedCount: number;
  rdbMigrationSkippedCount: number;
  rdbMigrationFailedCount: number;
  rdbFallbackUsed: boolean;
  rdbErrorMessage: string;
}

interface LegacyHistoryPayload {
  items?: Array<ReviewCardHistoryItem | ReviewCardDocument>;
  documents?: Array<ReviewCardDocument>;
  document?: ReviewCardDocument;
}

interface RecoverableBackupResult {
  success: boolean;
  path: string;
}

function createHistoryItem(document: ReviewCardDocument, exportedPath: string = ''): ReviewCardHistoryItem {
  return {
    document: cloneReviewCardDocument(document),
    exportedPath: exportedPath
  };
}

function normalizeHistoryItem(rawItem: ReviewCardHistoryItem | ReviewCardDocument): ReviewCardHistoryItem | undefined {
  if (!rawItem) {
    return undefined;
  }

  const historyItem = rawItem as ReviewCardHistoryItem;
  if (historyItem.document) {
    return createHistoryItem(historyItem.document, historyItem.exportedPath ? historyItem.exportedPath : '');
  }

  const legacyDocument = rawItem as ReviewCardDocument;
  if (legacyDocument.content) {
    return createHistoryItem(legacyDocument);
  }

  return undefined;
}

function collectHistoryItems(
  rawItems: Array<ReviewCardHistoryItem | ReviewCardDocument>,
  normalizedItems: Array<ReviewCardHistoryItem>
): void {
  rawItems.forEach((item: ReviewCardHistoryItem | ReviewCardDocument): void => {
    const normalizedItem = normalizeHistoryItem(item);
    if (normalizedItem) {
      normalizedItems.push(normalizedItem);
    }
  });
}

function sortHistoryItems(items: Array<ReviewCardHistoryItem>): Array<ReviewCardHistoryItem> {
  return items.sort((left: ReviewCardHistoryItem, right: ReviewCardHistoryItem): number => {
    if (right.document.updatedAt !== left.document.updatedAt) {
      return right.document.updatedAt - left.document.updatedAt;
    }
    return right.document.createdAt - left.document.createdAt;
  });
}

function mergeHistoryItems(
  primaryItems: Array<ReviewCardHistoryItem>,
  extraItems: Array<ReviewCardHistoryItem>
): Array<ReviewCardHistoryItem> {
  const mergedItems: Array<ReviewCardHistoryItem> = [];
  const seenKeys: Set<string> = new Set<string>();
  const appendItem = (item: ReviewCardHistoryItem): void => {
    const key: string = getReviewDocumentKey(item.document);
    if (seenKeys.has(key)) {
      return;
    }
    seenKeys.add(key);
    mergedItems.push(createHistoryItem(item.document, item.exportedPath));
  };

  primaryItems.forEach((item: ReviewCardHistoryItem): void => {
    appendItem(item);
  });
  extraItems.forEach((item: ReviewCardHistoryItem): void => {
    appendItem(item);
  });
  return sortHistoryItems(mergedItems);
}

function normalizeBackupText(value: string | undefined): string {
  return typeof value === 'string' ? value : '';
}

function mapExchangeDecisionToJudgement(decision: string | undefined): ReviewJudgementStatus {
  if (decision === ReviewCardExchangeDecision.WORKS) {
    return ReviewJudgementStatus.VALID;
  }
  if (decision === ReviewCardExchangeDecision.NOT_WORKS) {
    return ReviewJudgementStatus.INVALID;
  }
  return ReviewJudgementStatus.UNSURE;
}

function parseBackupTimestamp(fileName: string): number {
  const timestampMatch: RegExpMatchArray | null =
    fileName.match(/^\d{8}-\d{6}-(\d{10,})-/);
  if (timestampMatch !== null) {
    return Number(timestampMatch[1]);
  }

  const match: RegExpMatchArray | null = fileName.match(/^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})-/);
  if (match === null) {
    return Date.now();
  }
  return new Date(
    Number(match[1]),
    Number(match[2]) - 1,
    Number(match[3]),
    Number(match[4]),
    Number(match[5]),
    Number(match[6])
  ).getTime();
}

function createHistoryItemFromReviewJsonBackup(
  payload: ReviewCardExchangeSchemaV1,
  fileName: string,
  exportedPath: string
): ReviewCardHistoryItem {
  const document: ReviewCardDocument = createDefaultReviewCardDocument();
  const timestamp: number = parseBackupTimestamp(fileName);
  document.projectId = DEFAULT_PROJECT_ID;
  document.imageUri = normalizeBackupText(payload.fileName);
  document.content.title = normalizeBackupText(payload.titleText);
  document.content.visualFocus = normalizeBackupText(payload.firstLookText);
  document.content.focusReason = normalizeBackupText(payload.attentionReasonText);
  document.content.visualPath = normalizeBackupText(payload.eyePathText);
  document.content.visibleFacts = normalizeBackupText(payload.visualFactText);
  document.content.coreRelation = normalizeBackupText(payload.strongestRelationText);
  document.content.judgement = mapExchangeDecisionToJudgement(payload.decision);
  document.content.extendedUnderstanding = normalizeBackupText(payload.extensionReasonText);
  document.content.currentBlocker = normalizeBackupText(payload.blockerText);
  document.createdAt = timestamp;
  document.updatedAt = timestamp;
  return createHistoryItem(document, exportedPath);
}

function normalizeParsedHistory(parsed: Object): Array<ReviewCardHistoryItem> {
  const normalizedItems: Array<ReviewCardHistoryItem> = [];
  if (Array.isArray(parsed)) {
    collectHistoryItems(parsed as Array<ReviewCardHistoryItem | ReviewCardDocument>, normalizedItems);
    return sortHistoryItems(normalizedItems);
  }

  const payload = parsed as LegacyHistoryPayload;
  if (payload.items && Array.isArray(payload.items)) {
    collectHistoryItems(payload.items, normalizedItems);
    return sortHistoryItems(normalizedItems);
  }

  if (payload.documents && Array.isArray(payload.documents)) {
    collectHistoryItems(payload.documents, normalizedItems);
    return sortHistoryItems(normalizedItems);
  }

  if (payload.document) {
    const normalizedItem = normalizeHistoryItem(payload.document);
    if (normalizedItem) {
      normalizedItems.push(normalizedItem);
    }
    return sortHistoryItems(normalizedItems);
  }

  const normalizedItem = normalizeHistoryItem(parsed as ReviewCardHistoryItem | ReviewCardDocument);
  if (normalizedItem) {
    normalizedItems.push(normalizedItem);
  }
  return sortHistoryItems(normalizedItems);
}

function parseStoredHistory(rawValue: preferences.ValueType): Array<ReviewCardHistoryItem> {
  if (typeof rawValue !== 'string') {
    return [];
  }

  try {
    const parsed = JSON.parse(rawValue) as Object;
    return normalizeParsedHistory(parsed);
  } catch (error) {
    return [];
  }
}

function createEmptyDiagnostics(context: common.UIAbilityContext): ReviewCardHistoryDiagnostics {
  const backupDirectory: string = `${context.filesDir}/${REVIEW_JSON_BACKUP_DIR_NAME}`;
  return {
    preferencesName: PREFERENCES_NAME,
    historyKey: HISTORY_KEY,
    filesDir: context.filesDir,
    backupDirectory: backupDirectory,
    rawHistoryType: '',
    rawHistoryLength: 0,
    parsedHistoryCount: 0,
    backupImportCompleted: false,
    forcedBackupReload: false,
    backupDirectoryExists: false,
    backupFileCount: 0,
    parsedBackupCount: 0,
    mergedCount: 0,
    persistedMergedHistory: false,
    latestTitle: '',
    latestUpdatedAt: 0,
    errorMessage: '',
    rdbPrimaryReadAttempted: false,
    rdbPrimaryReadUsed: false,
    rdbRowCount: 0,
    rdbParsedCount: 0,
    rdbInvalidRowCount: 0,
    rdbMigrationAttempted: false,
    rdbMigrationSourceCount: 0,
    rdbMigrationInsertedCount: 0,
    rdbMigrationSkippedCount: 0,
    rdbMigrationFailedCount: 0,
    rdbFallbackUsed: false,
    rdbErrorMessage: ''
  };
}

function updateLatestDiagnostics(
  diagnostics: ReviewCardHistoryDiagnostics,
  items: Array<ReviewCardHistoryItem>
): void {
  diagnostics.mergedCount = items.length;
  if (items.length > 0) {
    diagnostics.latestTitle = items[0].document.content.title;
    diagnostics.latestUpdatedAt = items[0].document.updatedAt;
  }
}

function notifyReviewLibraryChanged(reason: string): void {
  ReviewLibraryRefreshService.notifyReviewLibraryChanged(reason);
}

function createRdbWriteError(operationName: string, error: Error | Object | string | undefined): Error {
  return new Error(`[ReviewCardHistoryService] RDB ${operationName}失败，已停止 Preferences 主索引回退：${error}`);
}

function normalizePageLimit(value: number): number {
  return value > 0 ? Math.floor(value) : 5;
}

function normalizePageOffset(value: number): number {
  return value > 0 ? Math.floor(value) : 0;
}

function createRdbPageQuery(query: ReviewCardHistoryPageQuery): ReviewListQuery {
  const rdbQuery: ReviewListQuery = {
    includeDeleted: false,
    limit: normalizePageLimit(query.limit),
    offset: normalizePageOffset(query.offset)
  };
  if (query.decision && query.decision.length > 0) {
    rdbQuery.decision = query.decision;
  }
  if (query.keyword && query.keyword.trim().length > 0) {
    rdbQuery.keyword = query.keyword.trim();
  }
  return rdbQuery;
}

function normalizeHistoryJudgement(value: string | undefined): ReviewJudgementStatus {
  if (value === 'works') {
    return ReviewJudgementStatus.VALID;
  }
  if (value === 'notWorks') {
    return ReviewJudgementStatus.INVALID;
  }
  if (value === 'uncertain') {
    return ReviewJudgementStatus.UNSURE;
  }
  return normalizeReviewJudgement(value);
}

function filterLegacyPageItems(
  items: Array<ReviewCardHistoryItem>,
  query: ReviewCardHistoryPageQuery
): Array<ReviewCardHistoryItem> {
  const keyword: string = query.keyword ? query.keyword.trim().toLocaleLowerCase() : '';
  const decision: string = query.decision ? query.decision : '';
  return items.filter((item: ReviewCardHistoryItem): boolean => {
    if (decision.length > 0 && normalizeHistoryJudgement(item.document.content.judgement) !== decision) {
      return false;
    }
    if (keyword.length === 0) {
      return true;
    }
    return [
      item.document.content.title,
      item.document.imageUri,
      item.document.content.visualFocus,
      item.document.content.focusReason,
      item.document.content.visualPath,
      item.document.content.visibleFacts,
      item.document.content.coreRelation,
      item.document.content.currentBlocker
    ].join('\n').toLocaleLowerCase().includes(keyword);
  });
}

function buildLegacyLibraryStats(items: Array<ReviewCardHistoryItem>): ReviewLibraryStats {
  const stats: ReviewLibraryStats = ReviewCardRdbMapper.emptyStats();
  stats.total = items.length;
  items.forEach((item: ReviewCardHistoryItem): void => {
    const judgement: ReviewJudgementStatus = normalizeHistoryJudgement(item.document.content.judgement);
    if (judgement === ReviewJudgementStatus.VALID) {
      stats.works += 1;
      return;
    }
    if (judgement === ReviewJudgementStatus.INVALID) {
      stats.notWorks += 1;
      return;
    }
    stats.uncertain += 1;
  });
  return stats;
}

async function applyPendingReviewStats(
  context: common.UIAbilityContext,
  stats: ReviewLibraryStats
): Promise<ReviewLibraryStats> {
  try {
    stats.pendingCount = await PendingReviewPhotoStore.countPending(context);
  } catch (error) {
    stats.pendingCount = 0;
  }
  return stats;
}

export class ReviewCardHistoryService {
  private static cachedItems: Array<ReviewCardHistoryItem> = [];

  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    try {
      return await preferences.getPreferences(context, { name: PREFERENCES_NAME });
    } catch (error) {
      throw new Error(`打开复盘历史索引失败：${error}`);
    }
  }

  private static async getPreference(
    store: preferences.Preferences,
    key: string,
    fallback: preferences.ValueType
  ): Promise<preferences.ValueType> {
    try {
      return await store.get(key, fallback);
    } catch (error) {
      throw new Error(`读取复盘历史索引 ${key} 失败：${error}`);
    }
  }

  private static async persistPreference(
    store: preferences.Preferences,
    key: string,
    value: preferences.ValueType
  ): Promise<void> {
    try {
      await store.put(key, value);
      await store.flush();
    } catch (error) {
      throw new Error(`保存复盘历史索引 ${key} 失败：${error}`);
    }
  }

  private static async isRdbMainIndexReady(context: common.UIAbilityContext): Promise<boolean> {
    const store = await ReviewCardHistoryService.getStore(context);
    const readyValue = await ReviewCardHistoryService.getPreference(store, RDB_MAIN_INDEX_READY_KEY, false);
    return readyValue === true;
  }

  private static async markRdbMainIndexReady(context: common.UIAbilityContext): Promise<void> {
    const store = await ReviewCardHistoryService.getStore(context);
    await ReviewCardHistoryService.persistPreference(store, RDB_MAIN_INDEX_READY_KEY, true);
  }

  private static listReviewJsonBackupFileNames(diagnostics: ReviewCardHistoryDiagnostics): Array<string> {
    try {
      const fileNames: Array<string> = fs.listFileSync(diagnostics.backupDirectory);
      diagnostics.backupDirectoryExists = true;
      diagnostics.backupFileCount = fileNames.length;
      return fileNames;
    } catch (error) {
      diagnostics.backupDirectoryExists = false;
      diagnostics.backupFileCount = 0;
      return [];
    }
  }

  private static loadReviewJsonBackupItemsWithDiagnostics(
    diagnostics: ReviewCardHistoryDiagnostics
  ): Array<ReviewCardHistoryItem> {
    const fileNames: Array<string> = ReviewCardHistoryService.listReviewJsonBackupFileNames(diagnostics);
    const backupItems: Array<ReviewCardHistoryItem> = [];
    fileNames.forEach((fileName: string): void => {
      if (!fileName.endsWith('.review.json') && !fileName.endsWith('.json')) {
        return;
      }

      const filePath: string = `${diagnostics.backupDirectory}/${fileName}`;
      try {
        const rawText: string = fs.readTextSync(filePath);
        const payload = JSON.parse(rawText) as ReviewCardExchangeSchemaV1;
        backupItems.push(createHistoryItemFromReviewJsonBackup(payload, fileName, filePath));
      } catch (error) {
      }
    });
    diagnostics.parsedBackupCount = backupItems.length;
    return sortHistoryItems(backupItems);
  }

  private static async loadBackupItemsOnce(
    store: preferences.Preferences,
    diagnostics: ReviewCardHistoryDiagnostics,
    shouldForceReload: boolean = false
  ): Promise<Array<ReviewCardHistoryItem>> {
    const importedValue = await ReviewCardHistoryService.getPreference(store, BACKUP_IMPORT_COMPLETED_KEY, false);
    diagnostics.backupImportCompleted = importedValue === true;
    diagnostics.forcedBackupReload = shouldForceReload;
    if (importedValue === true && !shouldForceReload) {
      return [];
    }

    const backupItems: Array<ReviewCardHistoryItem> =
      ReviewCardHistoryService.loadReviewJsonBackupItemsWithDiagnostics(diagnostics);
    await ReviewCardHistoryService.persistPreference(store, BACKUP_IMPORT_COMPLETED_KEY, true);
    return backupItems;
  }

  private static async recoverBackupItemsToRdbIfNeeded(
    context: common.UIAbilityContext,
    diagnostics: ReviewCardHistoryDiagnostics
  ): Promise<Array<ReviewCardHistoryItem>> {
    const store = await ReviewCardHistoryService.getStore(context);
    const backupItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.loadBackupItemsOnce(
      store,
      diagnostics,
      true
    );
    if (backupItems.length <= 0) {
      return [];
    }

    await ReviewCardHistoryService.migrateRecoveredBackupItemsToRdb(context, backupItems);
    diagnostics.persistedMergedHistory = true;
    notifyReviewLibraryChanged('review_exchange_recovered_after_empty_rdb');
    return backupItems;
  }

  private static rememberItems(items: Array<ReviewCardHistoryItem>): Array<ReviewCardHistoryItem> {
    ReviewCardHistoryService.cachedItems = sortHistoryItems(
      items.map((item: ReviewCardHistoryItem): ReviewCardHistoryItem => {
        return createHistoryItem(item.document, item.exportedPath);
      })
    );
    return ReviewCardHistoryService.cachedItems.map((item: ReviewCardHistoryItem): ReviewCardHistoryItem => {
      return createHistoryItem(item.document, item.exportedPath);
    });
  }

  private static async loadLegacyWithDiagnostics(
    context: common.UIAbilityContext,
    diagnostics: ReviewCardHistoryDiagnostics
  ): Promise<ReviewCardHistoryLoadResult> {
    const store = await ReviewCardHistoryService.getStore(context);
    const rawValue = await ReviewCardHistoryService.getPreference(store, HISTORY_KEY, '[]');
    diagnostics.rawHistoryType = typeof rawValue;
    diagnostics.rawHistoryLength = typeof rawValue === 'string' ? rawValue.length : 0;
    const historyItems: Array<ReviewCardHistoryItem> = parseStoredHistory(rawValue);
    diagnostics.parsedHistoryCount = historyItems.length;
    const backupItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.loadBackupItemsOnce(
      store,
      diagnostics,
      historyItems.length === 0
    );
    const mergedItems: Array<ReviewCardHistoryItem> = mergeHistoryItems(historyItems, backupItems);
    if (backupItems.length > 0) {
      try {
        await ReviewCardHistoryService.migrateRecoveredBackupItemsToRdb(context, backupItems);
        diagnostics.persistedMergedHistory = true;
      } catch (error) {
        console.warn(`[ReviewCardHistoryService] review_exchange 恢复写入 RDB 失败，保留旧链路回退结果：${error}`);
      }
      notifyReviewLibraryChanged('review_exchange_recovered');
    }
    const items: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.rememberItems(mergedItems);
    updateLatestDiagnostics(diagnostics, items);
    return {
      items: items,
      diagnostics: diagnostics
    };
  }

  private static async migrateRecoveredBackupItemsToRdb(
    context: common.UIAbilityContext,
    backupItems: Array<ReviewCardHistoryItem>
  ): Promise<void> {
    await ReviewCardRdbService.init(context);
    for (let index = 0; index < backupItems.length; index += 1) {
      const item: ReviewCardHistoryItem = backupItems[index];
      await ReviewCardRdbService.upsertReview(context, item, getReviewDocumentKey(item.document));
    }
    await ReviewCardHistoryService.markRdbMainIndexReady(context);
  }

  private static async loadFromRdbWithDiagnostics(
    context: common.UIAbilityContext,
    diagnostics: ReviewCardHistoryDiagnostics
  ): Promise<ReviewCardHistoryLoadResult | undefined> {
    diagnostics.rdbPrimaryReadAttempted = true;
    await ReviewCardRdbService.init(context);
    let rdbResult: ReviewCardRdbListResult = await ReviewCardRdbService.listReviewsWithDiagnostics(context, {
      includeDeleted: false
    });
    diagnostics.rdbRowCount = rdbResult.rowCount;
    diagnostics.rdbParsedCount = rdbResult.items.length;
    diagnostics.rdbInvalidRowCount = rdbResult.invalidRowCount;

    if (rdbResult.items.length > 0) {
      await ReviewCardHistoryService.markRdbMainIndexReady(context);
      diagnostics.rdbPrimaryReadUsed = true;
      const items: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.rememberItems(rdbResult.items);
      updateLatestDiagnostics(diagnostics, items);
      return {
        items: items,
        diagnostics: diagnostics
      };
    }

    if (rdbResult.rowCount > 0 && rdbResult.invalidRowCount > 0) {
      throw new Error(`RDB raw_document_json 解析失败：${rdbResult.invalidRowCount}/${rdbResult.rowCount}`);
    }

    if (await ReviewCardHistoryService.isRdbMainIndexReady(context)) {
      const recoveredBackupItems: Array<ReviewCardHistoryItem> =
        await ReviewCardHistoryService.recoverBackupItemsToRdbIfNeeded(context, diagnostics);
      if (recoveredBackupItems.length > 0) {
        diagnostics.rdbPrimaryReadUsed = true;
        const items: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.rememberItems(recoveredBackupItems);
        updateLatestDiagnostics(diagnostics, items);
        return {
          items: items,
          diagnostics: diagnostics
        };
      }

      diagnostics.rdbPrimaryReadUsed = true;
      const items: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.rememberItems([]);
      updateLatestDiagnostics(diagnostics, items);
      return {
        items: items,
        diagnostics: diagnostics
      };
    }

    diagnostics.rdbMigrationSourceCount = await ReviewCardMigrationService.countPreferenceHistoryItems(context);
    if (diagnostics.rdbMigrationSourceCount === 0) {
      return undefined;
    }

    diagnostics.rdbMigrationAttempted = true;
    const migrationResult: MigrationResult = await ReviewCardMigrationService.migrateFromPreferencesToRdb(context);
    diagnostics.rdbMigrationSourceCount = migrationResult.sourceCount;
    diagnostics.rdbMigrationInsertedCount = migrationResult.insertedCount;
    diagnostics.rdbMigrationSkippedCount = migrationResult.skippedCount;
    diagnostics.rdbMigrationFailedCount = migrationResult.failedCount;
    if (migrationResult.failedCount > 0) {
      throw new Error(`RDB 迁移失败：${migrationResult.errors.join('; ')}`);
    }

    rdbResult = await ReviewCardRdbService.listReviewsWithDiagnostics(context, {
      includeDeleted: false
    });
    diagnostics.rdbRowCount = rdbResult.rowCount;
    diagnostics.rdbParsedCount = rdbResult.items.length;
    diagnostics.rdbInvalidRowCount = rdbResult.invalidRowCount;

    if (rdbResult.items.length > 0) {
      await ReviewCardHistoryService.markRdbMainIndexReady(context);
      diagnostics.rdbPrimaryReadUsed = true;
      const items: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.rememberItems(rdbResult.items);
      updateLatestDiagnostics(diagnostics, items);
      return {
        items: items,
        diagnostics: diagnostics
      };
    }

    if (rdbResult.rowCount > 0 && rdbResult.invalidRowCount > 0) {
      throw new Error(`RDB 迁移后 raw_document_json 解析失败：${rdbResult.invalidRowCount}/${rdbResult.rowCount}`);
    }

    return undefined;
  }

  private static async ensureRdbPageReady(context: common.UIAbilityContext): Promise<void> {
    await ReviewCardRdbService.init(context);
    const rdbTotalCount: number = await ReviewCardRdbService.countReviews(context);
    if (rdbTotalCount > 0 || await ReviewCardHistoryService.isRdbMainIndexReady(context)) {
      return;
    }

    const migrationSourceCount: number = await ReviewCardMigrationService.countPreferenceHistoryItems(context);
    if (migrationSourceCount === 0) {
      return;
    }

    const migrationResult: MigrationResult = await ReviewCardMigrationService.migrateFromPreferencesToRdb(context);
    if (migrationResult.failedCount > 0) {
      throw new Error(`RDB 分页迁移失败：${migrationResult.errors.join('; ')}`);
    }
    await ReviewCardHistoryService.markRdbMainIndexReady(context);
  }

  private static async loadPageFromLegacy(
    context: common.UIAbilityContext,
    query: ReviewCardHistoryPageQuery
  ): Promise<ReviewCardHistoryPageResult> {
    const result: ReviewCardHistoryLoadResult = await ReviewCardHistoryService.loadWithDiagnostics(context);
    const filteredItems: Array<ReviewCardHistoryItem> = filterLegacyPageItems(result.items, query);
    const offset: number = normalizePageOffset(query.offset);
    const limit: number = normalizePageLimit(query.limit);
    return {
      items: filteredItems.slice(offset, offset + limit),
      totalCount: filteredItems.length,
      libraryStats: await applyPendingReviewStats(context, buildLegacyLibraryStats(result.items))
    };
  }

  private static buildSavedItems(
    items: Array<ReviewCardHistoryItem>,
    document: ReviewCardDocument,
    exportedPath: string = ''
  ): Array<ReviewCardHistoryItem> {
    const key = getReviewDocumentKey(document);
    const nextItems: Array<ReviewCardHistoryItem> = [];
    const existingItem: ReviewCardHistoryItem | undefined = items.find((item: ReviewCardHistoryItem): boolean => {
      return getReviewDocumentKey(item.document) === key;
    });
    nextItems.push(createHistoryItem(document, exportedPath.length > 0 ? exportedPath : existingItem ? existingItem.exportedPath : ''));

    items.forEach((item: ReviewCardHistoryItem) => {
      if (getReviewDocumentKey(item.document) !== key) {
        nextItems.push(createHistoryItem(item.document, item.exportedPath));
      }
    });
    return sortHistoryItems(nextItems);
  }

  static async loadWithDiagnostics(context: common.UIAbilityContext): Promise<ReviewCardHistoryLoadResult> {
    const diagnostics: ReviewCardHistoryDiagnostics = createEmptyDiagnostics(context);
    try {
      const rdbResult: ReviewCardHistoryLoadResult | undefined =
        await ReviewCardHistoryService.loadFromRdbWithDiagnostics(context, diagnostics);
      if (rdbResult) {
        return rdbResult;
      }
    } catch (rdbError) {
      diagnostics.rdbErrorMessage = `${rdbError}`;
      console.warn(`[ReviewCardHistoryService] RDB 主读失败，回退旧链路：${diagnostics.rdbErrorMessage}`);
    }

    try {
      diagnostics.rdbFallbackUsed = true;
      return await ReviewCardHistoryService.loadLegacyWithDiagnostics(context, diagnostics);
    } catch (error) {
      diagnostics.errorMessage = `${error}`;
      if (diagnostics.rdbErrorMessage.length > 0) {
        diagnostics.errorMessage = `${diagnostics.errorMessage}; rdb=${diagnostics.rdbErrorMessage}`;
      }
      const items: Array<ReviewCardHistoryItem> =
        ReviewCardHistoryService.rememberItems(ReviewCardHistoryService.cachedItems);
      updateLatestDiagnostics(diagnostics, items);
      return {
        items: items,
        diagnostics: diagnostics
      };
    }
  }

  static async load(context: common.UIAbilityContext): Promise<Array<ReviewCardHistoryItem>> {
    const result: ReviewCardHistoryLoadResult = await ReviewCardHistoryService.loadWithDiagnostics(context);
    return result.items;
  }

  static async loadPage(
    context: common.UIAbilityContext,
    query: ReviewCardHistoryPageQuery
  ): Promise<ReviewCardHistoryPageResult> {
    try {
      await ReviewCardHistoryService.ensureRdbPageReady(context);
      const rdbQuery: ReviewListQuery = createRdbPageQuery(query);
      const pageResult: ReviewCardRdbListResult = await ReviewCardRdbService.listReviewsWithDiagnostics(context, rdbQuery);
      const totalCount: number = await ReviewCardRdbService.countReviews(context, {
        includeDeleted: false,
        decision: rdbQuery.decision,
        keyword: rdbQuery.keyword
      });
      const libraryStats: ReviewLibraryStats = await applyPendingReviewStats(
        context,
        await ReviewCardRdbService.getStats(context)
      );
      if (pageResult.invalidRowCount > 0) {
        throw new Error(`RDB 分页 raw_document_json 解析失败：${pageResult.invalidRowCount}/${pageResult.rowCount}`);
      }
      ReviewCardHistoryService.rememberItems(pageResult.items);
      return {
        items: pageResult.items,
        totalCount: totalCount,
        libraryStats: libraryStats
      };
    } catch (error) {
      console.warn(`[ReviewCardHistoryService] RDB 分页读取失败，回退旧链路：${error}`);
      return ReviewCardHistoryService.loadPageFromLegacy(context, query);
    }
  }

  static formatDiagnostics(diagnostics: ReviewCardHistoryDiagnostics): string {
    return [
      '摄影复盘历史诊断',
      `preferences=${diagnostics.preferencesName}`,
      `historyKey=${diagnostics.historyKey}`,
      `filesDir=${diagnostics.filesDir}`,
      `backupDirectory=${diagnostics.backupDirectory}`,
      `rawHistoryType=${diagnostics.rawHistoryType}`,
      `rawHistoryLength=${diagnostics.rawHistoryLength}`,
      `parsedHistoryCount=${diagnostics.parsedHistoryCount}`,
      `backupImportCompleted=${diagnostics.backupImportCompleted}`,
      `forcedBackupReload=${diagnostics.forcedBackupReload}`,
      `backupDirectoryExists=${diagnostics.backupDirectoryExists}`,
      `backupFileCount=${diagnostics.backupFileCount}`,
      `parsedBackupCount=${diagnostics.parsedBackupCount}`,
      `mergedCount=${diagnostics.mergedCount}`,
      `persistedMergedHistory=${diagnostics.persistedMergedHistory}`,
      `rdbPrimaryReadAttempted=${diagnostics.rdbPrimaryReadAttempted}`,
      `rdbPrimaryReadUsed=${diagnostics.rdbPrimaryReadUsed}`,
      `rdbRowCount=${diagnostics.rdbRowCount}`,
      `rdbParsedCount=${diagnostics.rdbParsedCount}`,
      `rdbInvalidRowCount=${diagnostics.rdbInvalidRowCount}`,
      `rdbMigrationAttempted=${diagnostics.rdbMigrationAttempted}`,
      `rdbMigrationSourceCount=${diagnostics.rdbMigrationSourceCount}`,
      `rdbMigrationInsertedCount=${diagnostics.rdbMigrationInsertedCount}`,
      `rdbMigrationSkippedCount=${diagnostics.rdbMigrationSkippedCount}`,
      `rdbMigrationFailedCount=${diagnostics.rdbMigrationFailedCount}`,
      `rdbFallbackUsed=${diagnostics.rdbFallbackUsed}`,
      `rdbError=${diagnostics.rdbErrorMessage}`,
      `latestTitle=${diagnostics.latestTitle}`,
      `latestUpdatedAt=${diagnostics.latestUpdatedAt}`,
      `error=${diagnostics.errorMessage}`
    ].join('\n');
  }

  static async saveDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<Array<ReviewCardHistoryItem>> {
    const persistedDocument: ReviewCardDocument = upgradeVersionOnPersist(document);
    try {
      const existingItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
      const savedItems: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.buildSavedItems(existingItems, persistedDocument);
      const savedItem: ReviewCardHistoryItem = savedItems[0];
      await ReviewCardRdbService.upsertReview(context, savedItem, getReviewDocumentKey(persistedDocument));
      await ReviewCardHistoryService.markRdbMainIndexReady(context);
      await ReviewCardHistoryService.writeRecoverableBackup(context, persistedDocument);
      notifyReviewLibraryChanged('save_document');
      return ReviewCardHistoryService.load(context);
    } catch (error) {
      const backupResult: RecoverableBackupResult = await ReviewCardHistoryService.writeRecoverableBackup(context, persistedDocument);
      console.error(`[ReviewCardHistoryService] RDB 保存失败，已停止 Preferences 主索引回退，backup=${backupResult.success}, path=${backupResult.path}, error=${error}`);
      throw createRdbWriteError('保存', error as Error | Object | string | undefined);
    }
  }

  static async updateDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<Array<ReviewCardHistoryItem>> {
    const persistedDocument: ReviewCardDocument = upgradeVersionOnPersist(document);
    try {
      const key = getReviewDocumentKey(persistedDocument);
      const existingItem: ReviewCardHistoryItem | undefined = await ReviewCardRdbService.getReview(context, key);
      await ReviewCardRdbService.upsertReview(
        context,
        createHistoryItem(persistedDocument, existingItem ? existingItem.exportedPath : ''),
        key
      );
      await ReviewCardHistoryService.markRdbMainIndexReady(context);
      const latestItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
      await ReviewCardHistoryService.writeRecoverableBackup(context, persistedDocument);
      notifyReviewLibraryChanged('update_document');
      return latestItems;
    } catch (error) {
      const backupResult: RecoverableBackupResult = await ReviewCardHistoryService.writeRecoverableBackup(context, persistedDocument);
      console.error(`[ReviewCardHistoryService] RDB 更新失败，已停止 Preferences 主索引回退，backup=${backupResult.success}, path=${backupResult.path}, error=${error}`);
      throw createRdbWriteError('更新', error as Error | Object | string | undefined);
    }
  }

  static async markExported(context: common.UIAbilityContext, document: ReviewCardDocument, exportedPath: string): Promise<Array<ReviewCardHistoryItem>> {
    try {
      const key = getReviewDocumentKey(document);
      const existingItem: ReviewCardHistoryItem | undefined = await ReviewCardRdbService.getReview(context, key);
      if (existingItem) {
        await ReviewCardRdbService.markExported(context, key, exportedPath);
      } else {
        await ReviewCardRdbService.upsertReview(context, createHistoryItem(document, exportedPath), key);
      }
      await ReviewCardHistoryService.markRdbMainIndexReady(context);
      const latestItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
      notifyReviewLibraryChanged('mark_exported');
      return latestItems;
    } catch (error) {
      console.error(`[ReviewCardHistoryService] RDB 导出标记失败，已停止 Preferences 主索引回退：${error}`);
      throw createRdbWriteError('导出标记', error as Error | Object | string | undefined);
    }
  }

  static async deleteDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<void> {
    try {
      await ReviewCardRdbService.deleteReview(context, getReviewDocumentKey(document));
      await ReviewCardHistoryService.markRdbMainIndexReady(context);
      ReviewCardHistoryService.deleteRecoverableBackup(context, document);
      notifyReviewLibraryChanged('delete_document');
    } catch (error) {
      console.error(`[ReviewCardHistoryService] RDB 删除失败，已停止 Preferences 主索引回退：${error}`);
      throw createRdbWriteError('删除', error as Error | Object | string | undefined);
    }
  }

  static async replaceAllFromBackup(
    context: common.UIAbilityContext,
    replacements: Array<ReviewCardRdbReplacementItem>
  ): Promise<Array<ReviewCardHistoryItem>> {
    await ReviewCardRdbService.replaceAllReviews(context, replacements);
    try {
      await ReviewCardHistoryService.markRdbMainIndexReady(context);
    } catch (error) {
      console.warn(`[ReviewCardHistoryService] 恢复已提交，RDB 主索引标记写入失败：${error}`);
    }
    ReviewCardHistoryService.clearRecoverableBackups(context);

    const restoredItems: Array<ReviewCardHistoryItem> = [];
    for (let index = 0; index < replacements.length; index += 1) {
      const item: ReviewCardHistoryItem = replacements[index].item;
      restoredItems.push(createHistoryItem(item.document, item.exportedPath));
      await ReviewCardHistoryService.writeRecoverableBackup(context, item.document);
    }
    ReviewLibraryRefreshService.notifyReviewLibraryChanged('library_backup_restored');
    return ReviewCardHistoryService.rememberItems(restoredItems);
  }

  // v2 扩展字段说明：本备份遵循 Review JSON Schema v1，不含 frame /
  // templateLevel / exif。若 RDB 损坏后从此备份恢复，用户会失去 v2
  // 模板与 EXIF 状态。此降级已在 schema-alignment §5 显式接受。
  private static async writeRecoverableBackup(
    context: common.UIAbilityContext,
    document: ReviewCardDocument
  ): Promise<RecoverableBackupResult> {
    try {
      const result: ReviewJsonBackupResult = await ReviewJsonExportService.writeSandboxReviewJsonBackup(context, document);
      if (!result.success) {
        console.warn('[ReviewCardHistoryService] review_exchange 备份写入失败');
      }
      return {
        success: result.success,
        path: result.path
      };
    } catch (error) {
      console.warn(`[ReviewCardHistoryService] review_exchange 备份写入异常：${error}`);
      return {
        success: false,
        path: ''
      };
    }
  }

  private static deleteRecoverableBackup(context: common.UIAbilityContext, document: ReviewCardDocument): void {
    try {
      ReviewJsonExportService.deleteSandboxReviewJsonBackup(context, document);
    } catch (error) {
      console.warn(`[ReviewCardHistoryService] review_exchange 备份删除异常：${error}`);
    }
  }

  private static clearRecoverableBackups(context: common.UIAbilityContext): void {
    const directory: string = `${context.filesDir}/${REVIEW_JSON_BACKUP_DIR_NAME}`;
    try {
      const fileNames: Array<string> = fs.listFileSync(directory);
      fileNames.forEach((fileName: string): void => {
        try {
          fs.unlinkSync(`${directory}/${fileName}`);
        } catch (error) {
        }
      });
    } catch (error) {
    }
  }
}
