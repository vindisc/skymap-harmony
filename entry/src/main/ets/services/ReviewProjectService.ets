import { ReviewProjectStats, ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import {
  DEFAULT_PROJECT_ID,
  getReviewDocumentKey,
  normalizeReviewJudgement,
  ReviewCardDocument,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';

function ensureProjectId(document: ReviewCardDocument): string {
  return document.projectId && document.projectId.length > 0 ? document.projectId : DEFAULT_PROJECT_ID;
}

function normalizeExcerpt(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

export function getReviewProjectExcerpt(document: ReviewCardDocument): string {
  const coreRelation = normalizeExcerpt(document.content.coreRelation);
  if (coreRelation.length > 0) {
    return `核心关系：${coreRelation}`;
  }

  const currentBlocker = normalizeExcerpt(document.content.currentBlocker);
  if (currentBlocker.length > 0) {
    return currentBlocker;
  }

  const extendedUnderstanding = normalizeExcerpt(document.content.extendedUnderstanding);
  if (extendedUnderstanding.length > 0) {
    return extendedUnderstanding;
  }

  return '还没有提炼核心关系';
}

export class ReviewProjectService {
  static resolvePhotoFileName(document: ReviewCardDocument): string {
    const imageUri: string = typeof document.imageUri === 'string' ? document.imageUri.trim() : '';
    if (imageUri.length === 0) {
      return '';
    }

    const normalizedPath: string = imageUri.replace(/\\/g, '/');
    const fileName: string = normalizedPath.slice(normalizedPath.lastIndexOf('/') + 1);
    return fileName.trim();
  }

  static filterItems(
    items: Array<ReviewCardHistoryItem>,
    rawQuery: string,
    decisionFilter: string
  ): Array<ReviewCardHistoryItem> {
    const query: string = rawQuery.trim().toLocaleLowerCase();
    return items.filter((item: ReviewCardHistoryItem): boolean => {
      const judgement = normalizeReviewJudgement(item.document.content.judgement);
      if (decisionFilter === ReviewJudgementStatus.VALID && judgement !== ReviewJudgementStatus.VALID) {
        return false;
      }
      if (decisionFilter === ReviewJudgementStatus.UNSURE && judgement !== ReviewJudgementStatus.UNSURE) {
        return false;
      }
      if (decisionFilter === ReviewJudgementStatus.INVALID && judgement !== ReviewJudgementStatus.INVALID) {
        return false;
      }

      if (query.length === 0) {
        return true;
      }

      const searchableParts: Array<string> = [
        item.document.content.title,
        item.document.content.coreRelation,
        item.document.content.currentBlocker,
        ReviewProjectService.resolvePhotoFileName(item.document)
      ];
      const searchableText: string = searchableParts
        .map((value: string): string => normalizeExcerpt(value).toLocaleLowerCase())
        .join('\n');
      return searchableText.includes(query);
    });
  }

  static buildGlobalStats(items: Array<ReviewCardHistoryItem>): ReviewProjectStats {
    const stats: ReviewProjectStats = {
      totalCount: items.length,
      validCount: 0,
      unsureCount: 0,
      invalidCount: 0
    };

    items.forEach((item: ReviewCardHistoryItem): void => {
      const judgement = normalizeReviewJudgement(item.document.content.judgement);
      if (judgement === ReviewJudgementStatus.VALID) {
        stats.validCount += 1;
        return;
      }
      if (judgement === ReviewJudgementStatus.INVALID) {
        stats.invalidCount += 1;
        return;
      }
      stats.unsureCount += 1;
    });

    return stats;
  }

  static buildDefaultProjectSummary(items: Array<ReviewCardHistoryItem>): ReviewProjectSummary {
    const summary = createDefaultProjectSummary();
    const projectItems = items.filter((item: ReviewCardHistoryItem): boolean => {
      return ensureProjectId(item.document) === DEFAULT_PROJECT_ID;
    });

    summary.items = projectItems;
    summary.recordCount = projectItems.length;
    summary.stats = ReviewProjectService.buildGlobalStats(projectItems);
    summary.project.reviewIds = projectItems.map((item: ReviewCardHistoryItem): string => {
      return getReviewDocumentKey(item.document);
    });

    if (projectItems.length > 0) {
      summary.latestItem = projectItems[0];
      summary.latestUpdatedAt = projectItems[0].document.updatedAt;
      summary.project.updatedAt = projectItems[0].document.updatedAt;
      summary.project.createdAt = projectItems[projectItems.length - 1].document.createdAt;
    }

    return summary;
  }
}
