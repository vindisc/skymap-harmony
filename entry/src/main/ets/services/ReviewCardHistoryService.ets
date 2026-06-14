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

const PREFERENCES_NAME: string = 'review_card_history';
const HISTORY_KEY: string = 'items';
const BACKUP_IMPORT_COMPLETED_KEY: string = 'backup_import_completed';
const REVIEW_JSON_BACKUP_DIR_NAME: string = 'review_exchange';

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

export class ReviewCardHistoryService {
  private static cachedItems: Array<ReviewCardHistoryItem> = [];

  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return preferences.getPreferences(context, { name: PREFERENCES_NAME });
  }

  private static loadReviewJsonBackupItems(context: common.UIAbilityContext): Array<ReviewCardHistoryItem> {
    const directory: string = `${context.filesDir}/${REVIEW_JSON_BACKUP_DIR_NAME}`;
    let fileNames: Array<string> = [];
    try {
      fileNames = fs.listFileSync(directory);
    } catch (error) {
      return [];
    }

    const backupItems: Array<ReviewCardHistoryItem> = [];
    fileNames.forEach((fileName: string): void => {
      if (!fileName.endsWith('.review.json')) {
        return;
      }

      const filePath: string = `${directory}/${fileName}`;
      try {
        const rawText: string = fs.readTextSync(filePath);
        const payload = JSON.parse(rawText) as ReviewCardExchangeSchemaV1;
        backupItems.push(createHistoryItemFromReviewJsonBackup(payload, fileName, filePath));
      } catch (error) {
      }
    });
    return sortHistoryItems(backupItems);
  }

  private static async loadBackupItemsOnce(
    context: common.UIAbilityContext,
    store: preferences.Preferences
  ): Promise<Array<ReviewCardHistoryItem>> {
    const importedValue = await store.get(BACKUP_IMPORT_COMPLETED_KEY, false);
    if (importedValue === true) {
      return [];
    }

    const backupItems: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.loadReviewJsonBackupItems(context);
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

  static async load(context: common.UIAbilityContext): Promise<Array<ReviewCardHistoryItem>> {
    try {
      const store = await ReviewCardHistoryService.getStore(context);
      const rawValue = await store.get(HISTORY_KEY, '[]');
      const historyItems: Array<ReviewCardHistoryItem> = parseStoredHistory(rawValue);
      const backupItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.loadBackupItemsOnce(context, store);
      const mergedItems: Array<ReviewCardHistoryItem> = mergeHistoryItems(historyItems, backupItems);
      if (backupItems.length > 0) {
        await ReviewCardHistoryService.persist(context, mergedItems);
      }
      return ReviewCardHistoryService.rememberItems(mergedItems);
    } catch (error) {
      return ReviewCardHistoryService.rememberItems(ReviewCardHistoryService.cachedItems);
    }
  }

  static async saveDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<Array<ReviewCardHistoryItem>> {
    const items = await ReviewCardHistoryService.load(context);
    const key = getReviewDocumentKey(document);
    const nextItems: Array<ReviewCardHistoryItem> = [];
    nextItems.push(createHistoryItem(document));

    items.forEach((item: ReviewCardHistoryItem) => {
      if (getReviewDocumentKey(item.document) !== key) {
        nextItems.push(createHistoryItem(item.document, item.exportedPath));
      }
    });

    await ReviewCardHistoryService.persist(context, nextItems);
    return ReviewCardHistoryService.rememberItems(nextItems);
  }

  static async updateDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<Array<ReviewCardHistoryItem>> {
    const items = await ReviewCardHistoryService.load(context);
    const key = getReviewDocumentKey(document);
    const nextItems = items.map((item: ReviewCardHistoryItem): ReviewCardHistoryItem => {
      if (getReviewDocumentKey(item.document) === key) {
        return createHistoryItem(document, item.exportedPath);
      }
      return createHistoryItem(item.document, item.exportedPath);
    });

    if (nextItems.some((item: ReviewCardHistoryItem): boolean => getReviewDocumentKey(item.document) === key)) {
      await ReviewCardHistoryService.persist(context, nextItems);
    }
    return ReviewCardHistoryService.rememberItems(nextItems);
  }

  static async markExported(context: common.UIAbilityContext, document: ReviewCardDocument, exportedPath: string): Promise<Array<ReviewCardHistoryItem>> {
    const items = await ReviewCardHistoryService.load(context);
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
    const items = await ReviewCardHistoryService.load(context);
    const key = getReviewDocumentKey(document);
    const nextItems = items.filter((item: ReviewCardHistoryItem): boolean => {
      return getReviewDocumentKey(item.document) !== key;
    });

    await ReviewCardHistoryService.persist(context, nextItems);
    return ReviewCardHistoryService.rememberItems(nextItems);
  }

  private static async persist(context: common.UIAbilityContext, items: Array<ReviewCardHistoryItem>): Promise<void> {
    const store = await ReviewCardHistoryService.getStore(context);
    const persistedItems: Array<ReviewCardHistoryItem> = ReviewCardHistoryService.rememberItems(items);
    await store.put(HISTORY_KEY, JSON.stringify(persistedItems));
    await store.flush();
  }
}
