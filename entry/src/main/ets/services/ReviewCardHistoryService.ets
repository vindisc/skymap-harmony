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
const MAX_HISTORY_COUNT: number = 200;

function createHistoryItem(document: ReviewCardDocument, exportedPath: string = ''): ReviewCardHistoryItem {
  return {
    document: cloneReviewCardDocument(document),
    exportedPath: exportedPath
  };
}

function normalizeHistoryItem(rawItem: ReviewCardHistoryItem | ReviewCardDocument): ReviewCardHistoryItem | undefined {
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

export class ReviewCardHistoryService {
  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return preferences.getPreferences(context, { name: PREFERENCES_NAME });
  }

  static async load(context: common.UIAbilityContext): Promise<Array<ReviewCardHistoryItem>> {
    try {
      const store = await ReviewCardHistoryService.getStore(context);
      const rawValue = await store.get(HISTORY_KEY, '[]');
      if (typeof rawValue !== 'string') {
        return [];
      }

      const parsed = JSON.parse(rawValue) as Array<ReviewCardHistoryItem | ReviewCardDocument>;
      const normalizedItems: Array<ReviewCardHistoryItem> = [];
      parsed.forEach((item: ReviewCardHistoryItem | ReviewCardDocument): void => {
        const normalizedItem = normalizeHistoryItem(item);
        if (normalizedItem) {
          normalizedItems.push(normalizedItem);
        }
      });
      normalizedItems.sort((left: ReviewCardHistoryItem, right: ReviewCardHistoryItem): number => {
        if (right.document.updatedAt !== left.document.updatedAt) {
          return right.document.updatedAt - left.document.updatedAt;
        }
        return right.document.createdAt - left.document.createdAt;
      });
      return normalizedItems;
    } catch (error) {
      return [];
    }
  }

  static async saveDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<Array<ReviewCardHistoryItem>> {
    const items = await ReviewCardHistoryService.load(context);
    const key = getReviewDocumentKey(document);
    const nextItems: Array<ReviewCardHistoryItem> = [];
    nextItems.push(createHistoryItem(document));

    items.forEach((item: ReviewCardHistoryItem) => {
      if (getReviewDocumentKey(item.document) !== key && nextItems.length < MAX_HISTORY_COUNT) {
        nextItems.push(createHistoryItem(item.document, item.exportedPath));
      }
    });

    await ReviewCardHistoryService.persist(context, nextItems);
    return nextItems;
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
    return nextItems;
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

    const persistedItems: Array<ReviewCardHistoryItem> = nextItems.slice(0, MAX_HISTORY_COUNT);
    await ReviewCardHistoryService.persist(context, persistedItems);
    return persistedItems;
  }

  static async deleteDocument(context: common.UIAbilityContext, document: ReviewCardDocument): Promise<Array<ReviewCardHistoryItem>> {
    const items = await ReviewCardHistoryService.load(context);
    const key = getReviewDocumentKey(document);
    const nextItems = items.filter((item: ReviewCardHistoryItem): boolean => {
      return getReviewDocumentKey(item.document) !== key;
    });

    await ReviewCardHistoryService.persist(context, nextItems);
    return nextItems;
  }

  private static async persist(context: common.UIAbilityContext, items: Array<ReviewCardHistoryItem>): Promise<void> {
    const store = await ReviewCardHistoryService.getStore(context);
    await store.put(HISTORY_KEY, JSON.stringify(items));
    await store.flush();
  }
}
