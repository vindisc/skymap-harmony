import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
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
  static buildDefaultProjectSummary(items: Array<ReviewCardHistoryItem>): ReviewProjectSummary {
    const summary = createDefaultProjectSummary();
    const projectItems = items.filter((item: ReviewCardHistoryItem): boolean => {
      return ensureProjectId(item.document) === DEFAULT_PROJECT_ID;
    });

    summary.items = projectItems;
    summary.recordCount = projectItems.length;
    summary.stats.totalCount = projectItems.length;
    summary.project.reviewIds = projectItems.map((item: ReviewCardHistoryItem): string => {
      return getReviewDocumentKey(item.document);
    });

    projectItems.forEach((item: ReviewCardHistoryItem): void => {
      const judgement = normalizeReviewJudgement(item.document.content.judgement);
      if (judgement === ReviewJudgementStatus.VALID) {
        summary.stats.validCount += 1;
        return;
      }
      if (judgement === ReviewJudgementStatus.INVALID) {
        summary.stats.invalidCount += 1;
        return;
      }
      summary.stats.unsureCount += 1;
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
