import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import {
  cloneReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardHistoryItem
} from '../model/ReviewCardModel';

const PREFERENCES_NAME: string = 'review_card_history';
const HISTORY_KEY: string = 'items';

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

export class ReviewCardHistoryService {
  private static cachedItems: Array<ReviewCardHistoryItem> = [];

  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return preferences.getPreferences(context, { name: PREFERENCES_NAME });
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
      if (typeof rawValue !== 'string') {
        return ReviewCardHistoryService.rememberItems([]);
      }

      const parsed = JSON.parse(rawValue) as Object;
      return ReviewCardHistoryService.rememberItems(normalizeParsedHistory(parsed));
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
