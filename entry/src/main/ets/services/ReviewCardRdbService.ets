import common from '@ohos.app.ability.common';
import relationalStore from '@ohos.data.relationalStore';
import {
  CREATE_REVIEWS_TABLE_SQL,
  REVIEW_LIBRARY_RDB_INDEX_SQLS,
  REVIEW_LIBRARY_RDB_NAME,
  REVIEW_LIBRARY_RDB_TABLE,
  ReviewCardRdbMapper,
  ReviewCardRdbRow,
  ReviewLibraryStats,
  ReviewListQuery
} from './ReviewCardRdbModel';
import { ReviewCardDocument, ReviewCardHistoryItem, ReviewJudgementStatus } from '../model/ReviewCardModel';

const REVIEW_LIBRARY_RDB_CONFIG: relationalStore.StoreConfig = {
  name: REVIEW_LIBRARY_RDB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

interface ReviewRdbWhereClause {
  sql: string;
  args: Array<relationalStore.ValueType>;
}

export interface ReviewCardRdbListResult {
  items: Array<ReviewCardHistoryItem>;
  rowCount: number;
  invalidRowCount: number;
}

function normalizeLimit(value: number | undefined): number {
  if (typeof value === 'number' && value > 0) {
    return Math.floor(value);
  }
  return 0;
}

function normalizeOffset(value: number | undefined): number {
  if (typeof value === 'number' && value > 0) {
    return Math.floor(value);
  }
  return 0;
}

function toLikeKeyword(value: string | undefined): string {
  if (typeof value !== 'string') {
    return '';
  }
  const keyword: string = value.trim();
  return keyword.length > 0 ? `%${keyword}%` : '';
}

function getValue(resultSet: relationalStore.ResultSet, columnName: string): relationalStore.ValueType {
  return resultSet.getValue(resultSet.getColumnIndex(columnName));
}

function getStringValue(resultSet: relationalStore.ResultSet, columnName: string): string {
  const value: relationalStore.ValueType = getValue(resultSet, columnName);
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return `${value}`;
  }
  return '';
}

function getNumberValue(resultSet: relationalStore.ResultSet, columnName: string): number {
  const value: relationalStore.ValueType = getValue(resultSet, columnName);
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsedValue: number = Number(value);
    return Number.isFinite(parsedValue) ? parsedValue : 0;
  }
  return 0;
}

function rowFromResultSet(resultSet: relationalStore.ResultSet): ReviewCardRdbRow {
  return {
    id: getStringValue(resultSet, 'id'),
    createdAt: getNumberValue(resultSet, 'created_at'),
    updatedAt: getNumberValue(resultSet, 'updated_at'),
    title: getStringValue(resultSet, 'title'),
    decision: getStringValue(resultSet, 'decision'),
    imageUri: getStringValue(resultSet, 'image_uri'),
    imageWidth: getNumberValue(resultSet, 'image_width'),
    imageHeight: getNumberValue(resultSet, 'image_height'),
    exportedPath: getStringValue(resultSet, 'exported_path'),
    reviewerName: getStringValue(resultSet, 'reviewer_name'),
    focusText: getStringValue(resultSet, 'focus_text'),
    reasonText: getStringValue(resultSet, 'reason_text'),
    pathText: getStringValue(resultSet, 'path_text'),
    factsText: getStringValue(resultSet, 'facts_text'),
    strongestRelationText: getStringValue(resultSet, 'strongest_relation_text'),
    blockerText: getStringValue(resultSet, 'blocker_text'),
    rawDocumentJson: getStringValue(resultSet, 'raw_document_json'),
    backupJsonPath: getStringValue(resultSet, 'backup_json_path'),
    isDeleted: getNumberValue(resultSet, 'is_deleted')
  };
}

function buildWhereClause(query?: ReviewListQuery): ReviewRdbWhereClause {
  const whereParts: Array<string> = [];
  const args: Array<relationalStore.ValueType> = [];

  if (!query || query.includeDeleted !== true) {
    whereParts.push('is_deleted = ?');
    args.push(0);
  }

  if (query && typeof query.decision === 'string' && query.decision.length > 0) {
    whereParts.push('decision = ?');
    args.push(query.decision);
  }

  const likeKeyword: string = query ? toLikeKeyword(query.keyword) : '';
  if (likeKeyword.length > 0) {
    whereParts.push(
      '(title LIKE ? OR focus_text LIKE ? OR reason_text LIKE ? OR path_text LIKE ? OR facts_text LIKE ? OR strongest_relation_text LIKE ? OR blocker_text LIKE ?)'
    );
    for (let index = 0; index < 7; index += 1) {
      args.push(likeKeyword);
    }
  }

  return {
    sql: whereParts.length > 0 ? ` WHERE ${whereParts.join(' AND ')}` : '',
    args: args
  };
}

export class ReviewCardRdbService {
  private static storePromise: Promise<relationalStore.RdbStore> | undefined = undefined;

  static async init(context: common.UIAbilityContext): Promise<void> {
    const store: relationalStore.RdbStore = await ReviewCardRdbService.getStore(context);
    await store.executeSql(CREATE_REVIEWS_TABLE_SQL);
    for (let index = 0; index < REVIEW_LIBRARY_RDB_INDEX_SQLS.length; index += 1) {
      await store.executeSql(REVIEW_LIBRARY_RDB_INDEX_SQLS[index]);
    }
  }

  static generateReviewId(): string {
    return ReviewCardRdbMapper.generateReviewId();
  }

  static resolveReviewId(document: ReviewCardDocument, usedIds?: Set<string>, conflictSeed?: string): string {
    return ReviewCardRdbMapper.resolveReviewId(document, usedIds, conflictSeed);
  }

  static async upsertReview(context: common.UIAbilityContext, item: ReviewCardHistoryItem, reviewId?: string): Promise<void> {
    const store: relationalStore.RdbStore = await ReviewCardRdbService.getInitializedStore(context);
    const row: ReviewCardRdbRow = ReviewCardRdbMapper.toRow(item, reviewId);
    await store.insert(
      REVIEW_LIBRARY_RDB_TABLE,
      ReviewCardRdbMapper.toValuesBucket(row),
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    );
  }

  static async getReview(context: common.UIAbilityContext, id: string): Promise<ReviewCardHistoryItem | undefined> {
    const store: relationalStore.RdbStore = await ReviewCardRdbService.getInitializedStore(context);
    const resultSet: relationalStore.ResultSet = await store.querySql(
      `SELECT * FROM ${REVIEW_LIBRARY_RDB_TABLE} WHERE id = ? AND is_deleted = 0 LIMIT 1`,
      [id]
    );
    try {
      if (!resultSet.goToFirstRow()) {
        return undefined;
      }
      return ReviewCardRdbMapper.toHistoryItem(rowFromResultSet(resultSet));
    } finally {
      resultSet.close();
    }
  }

  static async listReviews(context: common.UIAbilityContext, query?: ReviewListQuery): Promise<Array<ReviewCardHistoryItem>> {
    const result: ReviewCardRdbListResult = await ReviewCardRdbService.listReviewsWithDiagnostics(context, query);
    return result.items;
  }

  static async listReviewsWithDiagnostics(
    context: common.UIAbilityContext,
    query?: ReviewListQuery
  ): Promise<ReviewCardRdbListResult> {
    const rows: Array<ReviewCardRdbRow> = await ReviewCardRdbService.listReviewRows(context, query);
    const items: Array<ReviewCardHistoryItem> = [];
    let invalidRowCount: number = 0;
    rows.forEach((row: ReviewCardRdbRow): void => {
      const item: ReviewCardHistoryItem | undefined = ReviewCardRdbMapper.toHistoryItem(row);
      if (item) {
        items.push(item);
      } else {
        invalidRowCount += 1;
      }
    });
    return {
      items: items,
      rowCount: rows.length,
      invalidRowCount: invalidRowCount
    };
  }

  static async listReviewRows(context: common.UIAbilityContext, query?: ReviewListQuery): Promise<Array<ReviewCardRdbRow>> {
    const store: relationalStore.RdbStore = await ReviewCardRdbService.getInitializedStore(context);
    const whereClause = buildWhereClause(query);
    const limit: number = query ? normalizeLimit(query.limit) : 0;
    const offset: number = query ? normalizeOffset(query.offset) : 0;
    let sql: string = `SELECT * FROM ${REVIEW_LIBRARY_RDB_TABLE}${whereClause.sql} ORDER BY updated_at DESC, created_at DESC`;
    const args: Array<relationalStore.ValueType> = whereClause.args;
    if (limit > 0) {
      sql = `${sql} LIMIT ?`;
      args.push(limit);
      if (offset > 0) {
        sql = `${sql} OFFSET ?`;
        args.push(offset);
      }
    } else if (offset > 0) {
      sql = `${sql} LIMIT -1 OFFSET ?`;
      args.push(offset);
    }

    const resultSet: relationalStore.ResultSet = await store.querySql(sql, args);
    const rows: Array<ReviewCardRdbRow> = [];
    try {
      while (resultSet.goToNextRow()) {
        rows.push(rowFromResultSet(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return rows;
  }

  static async countReviews(context: common.UIAbilityContext, query?: ReviewListQuery): Promise<number> {
    const store: relationalStore.RdbStore = await ReviewCardRdbService.getInitializedStore(context);
    const whereClause = buildWhereClause(query);
    const resultSet: relationalStore.ResultSet = await store.querySql(
      `SELECT COUNT(1) AS total FROM ${REVIEW_LIBRARY_RDB_TABLE}${whereClause.sql}`,
      whereClause.args
    );
    try {
      if (!resultSet.goToFirstRow()) {
        return 0;
      }
      return getNumberValue(resultSet, 'total');
    } finally {
      resultSet.close();
    }
  }

  static async deleteReview(context: common.UIAbilityContext, id: string): Promise<void> {
    const store: relationalStore.RdbStore = await ReviewCardRdbService.getInitializedStore(context);
    await store.executeSql(`DELETE FROM ${REVIEW_LIBRARY_RDB_TABLE} WHERE id = ?`, [id]);
  }

  static async markExported(context: common.UIAbilityContext, id: string, exportedPath: string): Promise<void> {
    const store: relationalStore.RdbStore = await ReviewCardRdbService.getInitializedStore(context);
    await store.executeSql(
      `UPDATE ${REVIEW_LIBRARY_RDB_TABLE} SET exported_path = ?, updated_at = updated_at WHERE id = ?`,
      [exportedPath, id]
    );
  }

  static async getStats(context: common.UIAbilityContext): Promise<ReviewLibraryStats> {
    const stats: ReviewLibraryStats = ReviewCardRdbMapper.emptyStats();
    stats.total = await ReviewCardRdbService.countReviews(context);
    stats.works = await ReviewCardRdbService.countReviews(context, { decision: ReviewJudgementStatus.VALID });
    stats.notWorks = await ReviewCardRdbService.countReviews(context, { decision: ReviewJudgementStatus.INVALID });
    stats.uncertain = await ReviewCardRdbService.countReviews(context, { decision: ReviewJudgementStatus.UNSURE });
    return stats;
  }

  static async clearAll(context: common.UIAbilityContext): Promise<void> {
    const store: relationalStore.RdbStore = await ReviewCardRdbService.getInitializedStore(context);
    await store.executeSql(`DELETE FROM ${REVIEW_LIBRARY_RDB_TABLE}`);
  }

  private static async getInitializedStore(context: common.UIAbilityContext): Promise<relationalStore.RdbStore> {
    await ReviewCardRdbService.init(context);
    return ReviewCardRdbService.getStore(context);
  }

  private static async getStore(context: common.UIAbilityContext): Promise<relationalStore.RdbStore> {
    if (!ReviewCardRdbService.storePromise) {
      ReviewCardRdbService.storePromise = relationalStore.getRdbStore(context, REVIEW_LIBRARY_RDB_CONFIG);
    }
    return ReviewCardRdbService.storePromise;
  }
}
