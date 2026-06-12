import { normalizeReviewJudgement, ReviewCardHistoryItem, ReviewJudgementStatus } from '../model/ReviewCardModel';

export interface ReviewLibraryFilters {
  query: string;
  judgement: string;
  blocker: string;
  reviewer: string;
}

export interface ReviewLibraryFilterOptions {
  blockers: Array<string>;
  reviewers: Array<string>;
}

function normalizeLibraryText(value: string | undefined): string {
  if (typeof value === 'string') {
    return value.trim();
  }
  return '';
}

function containsText(source: string, query: string): boolean {
  if (query.length === 0) {
    return true;
  }
  return source.toLocaleLowerCase().includes(query.toLocaleLowerCase());
}

function searchableText(item: ReviewCardHistoryItem): string {
  const content = item.document.content;
  return [
    content.title,
    content.visibleFacts,
    content.coreRelation,
    content.extendedUnderstanding,
    content.currentBlocker,
    content.visualFocus,
    content.focusReason,
    content.visualPath
  ].map((value: string | undefined): string => normalizeLibraryText(value)).join('\n');
}

function uniqueSorted(values: Array<string>): Array<string> {
  const seen: Set<string> = new Set<string>();
  values.forEach((value: string): void => {
    const normalized = normalizeLibraryText(value);
    if (normalized.length > 0) {
      seen.add(normalized);
    }
  });
  return Array.from(seen).sort((left: string, right: string): number => left.localeCompare(right));
}

export class ReviewLibraryService {
  static createEmptyFilters(): ReviewLibraryFilters {
    return {
      query: '',
      judgement: '全部判断',
      blocker: '全部卡点',
      reviewer: '全部复盘人'
    };
  }

  static buildFilterOptions(items: Array<ReviewCardHistoryItem>): ReviewLibraryFilterOptions {
    return {
      blockers: uniqueSorted(items.map((item: ReviewCardHistoryItem): string => item.document.content.currentBlocker)),
      reviewers: uniqueSorted(items.map((item: ReviewCardHistoryItem): string => item.reviewerText ? item.reviewerText : ''))
    };
  }

  static filter(items: Array<ReviewCardHistoryItem>, filters: ReviewLibraryFilters): Array<ReviewCardHistoryItem> {
    const query: string = normalizeLibraryText(filters.query);
    const judgementFilter: string = normalizeLibraryText(filters.judgement);
    const blockerFilter: string = normalizeLibraryText(filters.blocker);
    const reviewerFilter: string = normalizeLibraryText(filters.reviewer);

    return items.filter((item: ReviewCardHistoryItem): boolean => {
      if (!containsText(searchableText(item), query)) {
        return false;
      }

      if (judgementFilter.length > 0 && judgementFilter !== '全部判断') {
        const judgement: ReviewJudgementStatus = normalizeReviewJudgement(item.document.content.judgement);
        if (judgement !== judgementFilter) {
          return false;
        }
      }

      if (blockerFilter.length > 0 && blockerFilter !== '全部卡点') {
        if (!containsText(normalizeLibraryText(item.document.content.currentBlocker), blockerFilter)) {
          return false;
        }
      }

      if (reviewerFilter.length > 0 && reviewerFilter !== '全部复盘人') {
        if (normalizeLibraryText(item.reviewerText).toLocaleLowerCase() !== reviewerFilter.toLocaleLowerCase()) {
          return false;
        }
      }

      return true;
    });
  }
}
