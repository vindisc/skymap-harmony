import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import {
  DEFAULT_PROJECT_ID,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardHistoryItem
} from '../model/ReviewCardModel';

function ensureProjectId(document: ReviewCardDocument): string {
  return document.projectId && document.projectId.length > 0 ? document.projectId : DEFAULT_PROJECT_ID;
}

function normalizeExcerpt(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

export function getReviewProjectExcerpt(document: ReviewCardDocument): string {
  const judgement = normalizeExcerpt(document.content.judgement);
  if (judgement.length > 0) {
    return judgement.slice(0, 32);
  }

  const blocker = normalizeExcerpt(document.content.blocker);
  if (blocker.length > 0) {
    return blocker.slice(0, 32);
  }

  const firstLook = normalizeExcerpt(document.content.firstLook);
  if (firstLook.length > 0) {
    return firstLook.slice(0, 32);
  }

  return '还没有写下复盘摘要。';
}

export class ReviewProjectService {
  static buildDefaultProjectSummary(items: Array<ReviewCardHistoryItem>): ReviewProjectSummary {
    const summary = createDefaultProjectSummary();
    const projectItems = items.filter((item: ReviewCardHistoryItem): boolean => {
      return ensureProjectId(item.document) === DEFAULT_PROJECT_ID;
    });

    summary.items = projectItems;
    summary.recordCount = projectItems.length;
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
