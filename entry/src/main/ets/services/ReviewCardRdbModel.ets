import relationalStore from '@ohos.data.relationalStore';
import {
  cloneReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';

export const REVIEW_LIBRARY_RDB_NAME: string = 'review_library.db';
export const REVIEW_LIBRARY_RDB_TABLE: string = 'reviews';

export const CREATE_REVIEWS_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS reviews (
  id TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  title TEXT,
  decision TEXT,
  image_uri TEXT,
  image_width INTEGER,
  image_height INTEGER,
  exported_path TEXT,
  reviewer_name TEXT,
  focus_text TEXT,
  reason_text TEXT,
  path_text TEXT,
  facts_text TEXT,
  strongest_relation_text TEXT,
  blocker_text TEXT,
  raw_document_json TEXT NOT NULL,
  backup_json_path TEXT,
  is_deleted INTEGER DEFAULT 0
)`;

export const REVIEW_LIBRARY_RDB_INDEX_SQLS: Array<string> = [
  'CREATE INDEX IF NOT EXISTS idx_reviews_updated_at ON reviews(updated_at)',
  'CREATE INDEX IF NOT EXISTS idx_reviews_decision ON reviews(decision)',
  'CREATE INDEX IF NOT EXISTS idx_reviews_is_deleted ON reviews(is_deleted)',
  'CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at)'
];

export interface ReviewCardRdbRow {
  id: string;
  createdAt: number;
  updatedAt: number;
  title: string;
  decision: string;
  imageUri: string;
  imageWidth: number;
  imageHeight: number;
  exportedPath: string;
  reviewerName: string;
  focusText: string;
  reasonText: string;
  pathText: string;
  factsText: string;
  strongestRelationText: string;
  blockerText: string;
  rawDocumentJson: string;
  backupJsonPath: string;
  isDeleted: number;
}

export interface ReviewListQuery {
  decision?: string;
  keyword?: string;
  limit?: number;
  offset?: number;
  includeDeleted?: boolean;
}

export interface ReviewLibraryStats {
  total: number;
  works: number;
  notWorks: number;
  uncertain: number;
}

function normalizeText(value: string | undefined): string {
  return typeof value === 'string' ? value : '';
}

function normalizePositiveNumber(value: number | undefined): number {
  return typeof value === 'number' && value > 0 ? value : 0;
}

function createShortHash(value: string): string {
  let hash: number = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = ((hash << 5) - hash + value.charCodeAt(index)) & 0x7fffffff;
  }
  return hash.toString(36);
}

export class ReviewCardRdbMapper {
  static generateReviewId(now: number = Date.now()): string {
    const randomPart: string = Math.floor(Math.random() * 100000000).toString(36);
    return `review_${now}_${randomPart}`;
  }

  static resolveReviewId(document: ReviewCardDocument, usedIds?: Set<string>, conflictSeed?: string): string {
    const baseId: string = getReviewDocumentKey(document);
    if (!usedIds || !usedIds.has(baseId)) {
      return baseId;
    }

    const hashSource: string = conflictSeed ? conflictSeed : JSON.stringify(cloneReviewCardDocument(document));
    let candidate: string = `${baseId}-${createShortHash(hashSource)}`;
    let index: number = 1;
    while (usedIds.has(candidate)) {
      candidate = `${baseId}-recovered-${index}`;
      index += 1;
    }
    return candidate;
  }

  static toRow(
    item: ReviewCardHistoryItem,
    reviewId?: string,
    backupJsonPath: string = ''
  ): ReviewCardRdbRow {
    const document: ReviewCardDocument = cloneReviewCardDocument(item.document);
    const content = document.content;
    const rawDocumentJson: string = JSON.stringify(document);
    return {
      id: reviewId && reviewId.length > 0 ? reviewId : ReviewCardRdbMapper.resolveReviewId(document),
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
      title: normalizeText(content.title),
      decision: normalizeText(content.judgement),
      imageUri: normalizeText(document.imageUri),
      imageWidth: normalizePositiveNumber(document.imageWidth),
      imageHeight: normalizePositiveNumber(document.imageHeight),
      exportedPath: normalizeText(item.exportedPath),
      reviewerName: '',
      focusText: normalizeText(content.visualFocus),
      reasonText: normalizeText(content.focusReason),
      pathText: normalizeText(content.visualPath),
      factsText: normalizeText(content.visibleFacts),
      strongestRelationText: normalizeText(content.coreRelation),
      blockerText: normalizeText(content.currentBlocker),
      rawDocumentJson: rawDocumentJson,
      backupJsonPath: backupJsonPath,
      isDeleted: 0
    };
  }

  static toValuesBucket(row: ReviewCardRdbRow): relationalStore.ValuesBucket {
    return {
      id: row.id,
      created_at: row.createdAt,
      updated_at: row.updatedAt,
      title: row.title,
      decision: row.decision,
      image_uri: row.imageUri,
      image_width: row.imageWidth,
      image_height: row.imageHeight,
      exported_path: row.exportedPath,
      reviewer_name: row.reviewerName,
      focus_text: row.focusText,
      reason_text: row.reasonText,
      path_text: row.pathText,
      facts_text: row.factsText,
      strongest_relation_text: row.strongestRelationText,
      blocker_text: row.blockerText,
      raw_document_json: row.rawDocumentJson,
      backup_json_path: row.backupJsonPath,
      is_deleted: row.isDeleted
    };
  }

  static toHistoryItem(row: ReviewCardRdbRow): ReviewCardHistoryItem | undefined {
    try {
      const rawDocument = JSON.parse(row.rawDocumentJson) as ReviewCardDocument;
      return {
        document: cloneReviewCardDocument(rawDocument),
        exportedPath: row.exportedPath
      };
    } catch (error) {
      return undefined;
    }
  }

  static emptyStats(): ReviewLibraryStats {
    return {
      total: 0,
      works: 0,
      notWorks: 0,
      uncertain: 0
    };
  }

  static mapDecisionToStatsKey(decision: string): string {
    if (decision === ReviewJudgementStatus.VALID) {
      return 'works';
    }
    if (decision === ReviewJudgementStatus.INVALID) {
      return 'notWorks';
    }
    return 'uncertain';
  }
}
