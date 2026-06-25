import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import {
  cloneReviewCardDocument,
  createDefaultReviewCardDocument,
  DEFAULT_PROJECT_ID,
  getReviewDocumentKey,
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
import { ReviewJsonExportService } from './ReviewJsonExportService';

const PREFERENCES_NAME: string = 'review_card_history';
const HISTORY_KEY: string = 'items';
const BACKUP_IMPORT_COMPLETED_KEY: string = 'backup_import_completed';
const REVIEW_JSON_BACKUP_DIR_NAME: string = 'review_exchange';

export interface ReviewCardHistoryLoadResult {
  items: Array<ReviewCardHistoryItem>;
  diagnostics: ReviewCardHistoryDiagnostics;
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

export class ReviewCardHistoryService {
  private static cachedItems: Array<ReviewCardHistoryItem> = [];

  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return preferences.getPreferences(context, { name: PREFERENCES_NAME });
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
    const importedValue = await store.get(BACKUP_IMPORT_COMPLETED_KEY, false);
    diagnostics.backupImportCompleted = importedValue === true;
    diagnostics.forcedBackupReload = shouldForceReload;
    if (importedValue === true && !shouldForceReload) {
      return [];
    }

    const backupItems: Array<ReviewCardHistoryItem> =
      ReviewCardHistoryService.loadReviewJsonBackupItemsWithDiagnostics(diagnostics);
    await store.put(BACKUP_IMPORT_COMPLETED_KEY, true);
    await store.flush();
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
    const rawValue = await store.get(HISTORY_KEY, '[]');
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
      await ReviewCardHistoryService.persist(context, mergedItems);
      diagnostics.persistedMergedHistory = true;
    }
    const items: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.rememberItems(mergedItems);
    updateLatestDiagnostics(diagnostics, items);
    return {
      items: items,
      diagnostics: diagnostics
    };
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

  private static async loadLegacyItemsForWrite(context: common.UIAbilityContext): Promise<Array<ReviewCardHistoryItem>> {
    try {
      const result: ReviewCardHistoryLoadResult = await ReviewCardHistoryService.loadLegacyWithDiagnostics(
        context,
        createEmptyDiagnostics(context)
      );
      return result.items;
    } catch (error) {
      return ReviewCardHistoryService.rememberItems(ReviewCardHistoryService.cachedItems);
    }
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
    const items = await ReviewCardHistoryService.loadLegacyItemsForWrite(context);
    const key = getReviewDocumentKey(document);
    const nextItems: Array<ReviewCardHistoryItem> = [];
    const existingItem: ReviewCardHistoryItem | undefined = items.find((item: ReviewCardHistoryItem): boolean => {
      return getReviewDocumentKey(item.document) === key;
    });
    nextItems.push(createHistoryItem(document, existingItem ? existingItem.exportedPath : ''));

    items.forEach((item: ReviewCardHistoryItem) => {
      if (getReviewDocumentKey(item.document) !== key) {
        nextItems.push(createHistoryItem(item.document, item.exportedPath));
      }
    });

    await ReviewCardHistoryService.persist(context, nextItems);
    await ReviewCardHistoryService.writeRecoverableBackup(context, document);
    return ReviewCardHistoryService.rememberItems(nextItems);
  }

  static async updateDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<Array<ReviewCardHistoryItem>> {
    const items = await ReviewCardHistoryService.loadLegacyItemsForWrite(context);
    const key = getReviewDocumentKey(document);
    const nextItems = items.map((item: ReviewCardHistoryItem): ReviewCardHistoryItem => {
      if (getReviewDocumentKey(item.document) === key) {
        return createHistoryItem(document, item.exportedPath);
      }
      return createHistoryItem(item.document, item.exportedPath);
    });

    if (nextItems.some((item: ReviewCardHistoryItem): boolean => getReviewDocumentKey(item.document) === key)) {
      await ReviewCardHistoryService.persist(context, nextItems);
      await ReviewCardHistoryService.writeRecoverableBackup(context, document);
    }
    return ReviewCardHistoryService.rememberItems(nextItems);
  }

  static async markExported(context: common.UIAbilityContext, document: ReviewCardDocument, exportedPath: string): Promise<Array<ReviewCardHistoryItem>> {
    const items = await ReviewCardHistoryService.loadLegacyItemsForWrite(context);
    const key = getReviewDocumentKey(document);
    const nextItems = items.map((item: ReviewCardHistoryItem): ReviewCardHistoryItem => {
      if (getReviewDocumentKey(item.document) === key) {
        return createHistoryItem(document, exportedPath);
      }
      return createHistoryItem(item.document, item.exportedPath);
    });

    if (!nextItems.some((item: ReviewCardHistoryItem): boolean => getReviewDocumentKey(item.document) === key)) {
      nextItems.unshift(createHistoryItem(document, exportedPath));
    }

    await ReviewCardHistoryService.persist(context, nextItems);
    return ReviewCardHistoryService.rememberItems(nextItems);
  }

  static async deleteDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<Array<ReviewCardHistoryItem>> {
    const items = await ReviewCardHistoryService.loadLegacyItemsForWrite(context);
    const key = getReviewDocumentKey(document);
    const nextItems = items.filter((item: ReviewCardHistoryItem): boolean => {
      return getReviewDocumentKey(item.document) !== key;
    });

    await ReviewCardHistoryService.persist(context, nextItems);
    ReviewCardHistoryService.deleteRecoverableBackup(context, document);
    return ReviewCardHistoryService.rememberItems(nextItems);
  }

  private static async persist(context: common.UIAbilityContext, items: Array<ReviewCardHistoryItem>): Promise<void> {
    const store = await ReviewCardHistoryService.getStore(context);
    const persistedItems: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.rememberItems(items);
    await store.put(HISTORY_KEY, JSON.stringify(persistedItems));
    await store.flush();
  }

  private static async writeRecoverableBackup(
    context: common.UIAbilityContext,
    document: ReviewCardDocument
  ): Promise<void> {
    try {
      await ReviewJsonExportService.writeSandboxReviewJsonBackup(context, document);
    } catch (error) {
    }
  }

  private static deleteRecoverableBackup(context: common.UIAbilityContext, document: ReviewCardDocument): void {
    try {
      ReviewJsonExportService.deleteSandboxReviewJsonBackup(context, document);
    } catch (error) {
    }
  }
}
