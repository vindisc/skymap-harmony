import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import {
  cloneReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardHistoryItem
} from '../model/ReviewCardModel';
import { ReviewCardRdbService } from './ReviewCardRdbService';
import { ReviewCardRdbRow } from './ReviewCardRdbModel';
import { ReviewLibraryRefreshService } from './ReviewLibraryRefreshService';

const PREFERENCES_NAME: string = 'review_card_history';
const HISTORY_KEY: string = 'items';

export interface MigrationResult {
  sourceCount: number;
  insertedCount: number;
  skippedCount: number;
  failedCount: number;
  errors: Array<string>;
}

export interface MigrationVerifyResult {
  preferencesCount: number;
  rdbCount: number;
  missingIds: Array<string>;
  rawJsonInvalidCount: number;
  success: boolean;
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
    const normalizedItem: ReviewCardHistoryItem | undefined = normalizeHistoryItem(item);
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
    const normalizedItem: ReviewCardHistoryItem | undefined = normalizeHistoryItem(payload.document);
    if (normalizedItem) {
      normalizedItems.push(normalizedItem);
    }
    return sortHistoryItems(normalizedItems);
  }

  const normalizedItem: ReviewCardHistoryItem | undefined =
    normalizeHistoryItem(parsed as ReviewCardHistoryItem | ReviewCardDocument);
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

export class ReviewCardMigrationService {
  static async countPreferenceHistoryItems(context: common.UIAbilityContext): Promise<number> {
    const store: preferences.Preferences = await preferences.getPreferences(context, { name: PREFERENCES_NAME });
    const rawValue: preferences.ValueType = await store.get(HISTORY_KEY, '[]');
    return parseStoredHistory(rawValue).length;
  }

  static async migrateFromPreferencesToRdb(context: common.UIAbilityContext): Promise<MigrationResult> {
    await ReviewCardRdbService.init(context);
    const sourceItems: Array<ReviewCardHistoryItem> = await ReviewCardMigrationService.loadMigrationSource(context);
    const result: MigrationResult = {
      sourceCount: sourceItems.length,
      insertedCount: 0,
      skippedCount: 0,
      failedCount: 0,
      errors: []
    };

    const usedIds: Set<string> = new Set<string>();
    for (let index = 0; index < sourceItems.length; index += 1) {
      const item: ReviewCardHistoryItem = sourceItems[index];
      const rawDocumentJson: string = JSON.stringify(cloneReviewCardDocument(item.document));
      const reviewId: string = ReviewCardRdbService.resolveReviewId(item.document, usedIds, `${rawDocumentJson}-${index}`);
      usedIds.add(reviewId);
      try {
        const existingItem: ReviewCardHistoryItem | undefined = await ReviewCardRdbService.getReview(context, reviewId);
        if (existingItem) {
          result.skippedCount += 1;
          continue;
        }
        await ReviewCardRdbService.upsertReview(context, item, reviewId);
        result.insertedCount += 1;
      } catch (error) {
        result.failedCount += 1;
        result.errors.push(`${getReviewDocumentKey(item.document)}: ${error}`);
      }
    }

    if (result.insertedCount > 0) {
      ReviewLibraryRefreshService.notifyReviewLibraryChanged('preferences_migrated_to_rdb');
    }

    return result;
  }

  static async verifyRdbMigration(context: common.UIAbilityContext): Promise<MigrationVerifyResult> {
    const sourceItems: Array<ReviewCardHistoryItem> = await ReviewCardMigrationService.loadMigrationSource(context);
    const rdbItems: Array<ReviewCardHistoryItem> = await ReviewCardRdbService.listReviews(context, { includeDeleted: false });
    const rdbRows: Array<ReviewCardRdbRow> = await ReviewCardRdbService.listReviewRows(context, { includeDeleted: false });
    const rdbIds: Set<string> = new Set<string>();
    rdbItems.forEach((item: ReviewCardHistoryItem): void => {
      rdbIds.add(getReviewDocumentKey(item.document));
    });

    const missingIds: Array<string> = [];
    sourceItems.forEach((item: ReviewCardHistoryItem): void => {
      const id: string = getReviewDocumentKey(item.document);
      if (!rdbIds.has(id)) {
        missingIds.push(id);
      }
    });

    let rawJsonInvalidCount: number = 0;
    rdbRows.forEach((row: ReviewCardRdbRow): void => {
      try {
        JSON.parse(row.rawDocumentJson);
      } catch (error) {
        rawJsonInvalidCount += 1;
      }
    });

    return {
      preferencesCount: sourceItems.length,
      rdbCount: rdbItems.length,
      missingIds: missingIds,
      rawJsonInvalidCount: rawJsonInvalidCount,
      success: missingIds.length === 0 && rawJsonInvalidCount === 0 && rdbItems.length >= sourceItems.length
    };
  }

  private static async loadMigrationSource(context: common.UIAbilityContext): Promise<Array<ReviewCardHistoryItem>> {
    const store: preferences.Preferences = await preferences.getPreferences(context, { name: PREFERENCES_NAME });
    const rawValue: preferences.ValueType = await store.get(HISTORY_KEY, '[]');
    return parseStoredHistory(rawValue);
  }
}
