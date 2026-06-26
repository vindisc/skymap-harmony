import { ReviewProjectStats, ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import {
  DEFAULT_REVIEW_TITLE,
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

function normalizeExcerpt(value: string | undefined): string {
  if (typeof value !== 'string') {
    return '';
  }
  return value.replace(/\s+/g, ' ').trim();
}

function normalizeProjectJudgement(value: string | undefined): ReviewJudgementStatus {
  const trimmedValue: string = normalizeExcerpt(value);
  if (trimmedValue === 'works') {
    return ReviewJudgementStatus.VALID;
  }
  if (trimmedValue === 'notWorks') {
    return ReviewJudgementStatus.INVALID;
  }
  if (trimmedValue === 'uncertain') {
    return ReviewJudgementStatus.UNSURE;
  }
  return normalizeReviewJudgement(trimmedValue);
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

export interface ReviewDashboardStats {
  streakDays: number;
}

export interface ReviewStatsDecisionCounts {
  totalCount: number;
  worksCount: number;
  uncertainCount: number;
  notWorksCount: number;
}

export interface ReviewStatsDistributionItem {
  key: string;
  label: string;
  count: number;
  rate: number;
}

export interface ReviewStatsBlockerItem {
  key: string;
  order: number;
  text: string;
}

export interface ReviewStatsRecentReviewItem {
  key: string;
  title: string;
  decision: string;
  updatedAt: number;
}

export interface ReviewStatsFeedback {
  totalCount: number;
  worksCount: number;
  uncertainCount: number;
  notWorksCount: number;
  worksRate: number;
  latestReviewTime: number;
  recent30DaysCount: number;
  recent30DaysWorksCount: number;
  recent30DaysUncertainCount: number;
  recent30DaysNotWorksCount: number;
  decisionDistribution: Array<ReviewStatsDistributionItem>;
  recentBlockers: Array<ReviewStatsBlockerItem>;
  recentReviews: Array<ReviewStatsRecentReviewItem>;
}

const REVIEW_STATS_RECENT_WINDOW_DAYS: number = 30;
const REVIEW_STATS_DAY_TIME: number = 24 * 60 * 60 * 1000;
const REVIEW_STATS_PLACEHOLDER_TEXTS: Array<string> = [
  DEFAULT_REVIEW_TITLE,
  '待填写',
  '暂无记录',
  '未命名复盘',
  '照片预览',
  '第一眼先看到哪里',
  '为什么它会先被看到',
  '视线接着从哪里走到哪里',
  '画面里有哪些可见事实',
  '最重要的 A ↔ B 关系是什么',
  '这张照片为什么成立或不成立',
  '当前最大问题是什么',
  '当前卡点'
];
const REVIEW_STATS_GUIDANCE_TOKENS: Array<string> = [
  '第一眼先看到哪里',
  '为什么它会先被看到',
  '视线接着从哪里走到哪里',
  '画面里有哪些可见事实',
  '最重要的 A ↔ B 关系是什么',
  '这张照片为什么成立或不成立',
  '当前最大问题是什么',
  '第一眼落点',
  '落点原因',
  '视线路径',
  '画面事实',
  '核心关系',
  '延伸理解',
  '当前卡点'
];

function createEmptyStatsDecisionCounts(): ReviewStatsDecisionCounts {
  return {
    totalCount: 0,
    worksCount: 0,
    uncertainCount: 0,
    notWorksCount: 0
  };
}

function resolveReviewUpdatedTime(document: ReviewCardDocument): number {
  if (document.updatedAt > 0) {
    return document.updatedAt;
  }
  return document.createdAt > 0 ? document.createdAt : 0;
}

function stripStatsDisplayNoise(value: string): string {
  return value
    .replace(/https?:\/\/[^\s，。；、]+/g, ' ')
    .replace(/\d{12,}/g, ' ')
    .replace(/[＿_—-]{6,}/g, ' ');
}

function normalizePlaceholderComparison(value: string): string {
  return value.replace(/[？?。.!！:：\s]/g, '');
}

function isStatsPlaceholderText(value: string): boolean {
  const normalizedValue: string = normalizeExcerpt(stripStatsDisplayNoise(value));
  if (normalizedValue.length === 0) {
    return true;
  }

  const comparisonValue: string = normalizePlaceholderComparison(normalizedValue);
  for (let index = 0; index < REVIEW_STATS_PLACEHOLDER_TEXTS.length; index += 1) {
    const placeholder: string = normalizePlaceholderComparison(REVIEW_STATS_PLACEHOLDER_TEXTS[index]);
    if (comparisonValue === placeholder) {
      return true;
    }
  }

  let matchedCount: number = 0;
  REVIEW_STATS_GUIDANCE_TOKENS.forEach((token: string): void => {
    if (normalizedValue.includes(token)) {
      matchedCount += 1;
    }
  });
  return matchedCount >= 2;
}

function cleanStatsDisplayText(value: string | undefined): string {
  const normalizedValue: string = normalizeExcerpt(stripStatsDisplayNoise(typeof value === 'string' ? value : ''));
  if (isStatsPlaceholderText(normalizedValue)) {
    return '';
  }
  return normalizedValue;
}

function buildStatsDecisionCounts(items: Array<ReviewCardHistoryItem>): ReviewStatsDecisionCounts {
  const counts: ReviewStatsDecisionCounts = createEmptyStatsDecisionCounts();
  counts.totalCount = items.length;
  items.forEach((item: ReviewCardHistoryItem): void => {
    const judgement: ReviewJudgementStatus = normalizeProjectJudgement(item.document.content.judgement);
    if (judgement === ReviewJudgementStatus.VALID) {
      counts.worksCount += 1;
      return;
    }
    if (judgement === ReviewJudgementStatus.INVALID) {
      counts.notWorksCount += 1;
      return;
    }
    counts.uncertainCount += 1;
  });
  return counts;
}

function resolveStatsRate(count: number, total: number): number {
  if (total <= 0) {
    return 0;
  }
  return Math.floor(count * 100 / total);
}

function buildStatsDistribution(counts: ReviewStatsDecisionCounts): Array<ReviewStatsDistributionItem> {
  return [
    {
      key: 'works',
      label: '成立',
      count: counts.worksCount,
      rate: resolveStatsRate(counts.worksCount, counts.totalCount)
    },
    {
      key: 'uncertain',
      label: '待判断',
      count: counts.uncertainCount,
      rate: resolveStatsRate(counts.uncertainCount, counts.totalCount)
    },
    {
      key: 'notWorks',
      label: '不成立',
      count: counts.notWorksCount,
      rate: resolveStatsRate(counts.notWorksCount, counts.totalCount)
    }
  ];
}

function getJudgementStatsLabel(value: string | undefined): string {
  const judgement: ReviewJudgementStatus = normalizeProjectJudgement(value);
  if (judgement === ReviewJudgementStatus.VALID) {
    return '成立';
  }
  if (judgement === ReviewJudgementStatus.INVALID) {
    return '不成立';
  }
  return '待判断';
}

function resolveStatsReviewTitle(document: ReviewCardDocument): string {
  const title: string = cleanStatsDisplayText(document.content.title);
  if (title.length > 0) {
    return title;
  }

  const fileName: string = ReviewProjectService.resolvePhotoFileName(document);
  if (fileName.length > 0) {
    return fileName;
  }

  return '未命名复盘';
}

export function createEmptyReviewStatsFeedback(): ReviewStatsFeedback {
  const counts: ReviewStatsDecisionCounts = createEmptyStatsDecisionCounts();
  return {
    totalCount: 0,
    worksCount: 0,
    uncertainCount: 0,
    notWorksCount: 0,
    worksRate: 0,
    latestReviewTime: 0,
    recent30DaysCount: 0,
    recent30DaysWorksCount: 0,
    recent30DaysUncertainCount: 0,
    recent30DaysNotWorksCount: 0,
    decisionDistribution: buildStatsDistribution(counts),
    recentBlockers: [],
    recentReviews: []
  };
}

function normalizeReviewDayKey(timestamp: number): string {
  const date: Date = new Date(timestamp);
  const year: number = date.getFullYear();
  const month: string = `${date.getMonth() + 1}`.padStart(2, '0');
  const day: string = `${date.getDate()}`.padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function parseReviewDayKey(dayKey: string): number {
  const parts: Array<string> = dayKey.split('-');
  if (parts.length !== 3) {
    return 0;
  }
  return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])).getTime();
}

function sortHistoryItems(items: Array<ReviewCardHistoryItem>): Array<ReviewCardHistoryItem> {
  return [...items].sort((left: ReviewCardHistoryItem, right: ReviewCardHistoryItem): number => {
    const rightUpdatedAt: number = resolveReviewUpdatedTime(right.document);
    const leftUpdatedAt: number = resolveReviewUpdatedTime(left.document);
    if (rightUpdatedAt !== leftUpdatedAt) {
      return rightUpdatedAt - leftUpdatedAt;
    }
    return right.document.createdAt - left.document.createdAt;
  });
}

function buildSummaryFromItems(items: Array<ReviewCardHistoryItem>): ReviewProjectSummary {
  const summary = createDefaultProjectSummary();
  const sortedItems: Array<ReviewCardHistoryItem> = sortHistoryItems(items);

  summary.items = sortedItems;
  summary.recordCount = sortedItems.length;
  summary.stats = ReviewProjectService.buildGlobalStats(sortedItems);
  summary.project.reviewIds = sortedItems.map((item: ReviewCardHistoryItem): string => {
    return getReviewDocumentKey(item.document);
  });

  if (sortedItems.length > 0) {
    summary.latestItem = sortedItems[0];
    summary.latestUpdatedAt = resolveReviewUpdatedTime(sortedItems[0].document);
    summary.project.updatedAt = resolveReviewUpdatedTime(sortedItems[0].document);
    summary.project.createdAt = sortedItems[sortedItems.length - 1].document.createdAt;
  }

  return summary;
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
      const judgement = normalizeProjectJudgement(item.document.content.judgement);
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
      const judgement = normalizeProjectJudgement(item.document.content.judgement);
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

  static buildStatsFeedback(
    items: Array<ReviewCardHistoryItem>,
    now: number = Date.now()
  ): ReviewStatsFeedback {
    const sortedItems: Array<ReviewCardHistoryItem> = sortHistoryItems(items);
    const totalCounts: ReviewStatsDecisionCounts = buildStatsDecisionCounts(sortedItems);
    const recentSince: number = now - REVIEW_STATS_RECENT_WINDOW_DAYS * REVIEW_STATS_DAY_TIME;
    const recent30DaysItems: Array<ReviewCardHistoryItem> = sortedItems.filter((item: ReviewCardHistoryItem): boolean => {
      return resolveReviewUpdatedTime(item.document) >= recentSince;
    });
    const recentCounts: ReviewStatsDecisionCounts = buildStatsDecisionCounts(recent30DaysItems);
    const blockers: Array<ReviewStatsBlockerItem> = [];
    const recentReviews: Array<ReviewStatsRecentReviewItem> = [];

    sortedItems.forEach((item: ReviewCardHistoryItem): void => {
      const key: string = getReviewDocumentKey(item.document);
      if (blockers.length < 3) {
        const blockerText: string = cleanStatsDisplayText(item.document.content.currentBlocker);
        if (blockerText.length > 0) {
          blockers.push({
            key: `${key}-blocker-${blockers.length + 1}`,
            order: blockers.length + 1,
            text: blockerText
          });
        }
      }

      if (recentReviews.length < 3) {
        recentReviews.push({
          key: key,
          title: resolveStatsReviewTitle(item.document),
          decision: getJudgementStatsLabel(item.document.content.judgement),
          updatedAt: resolveReviewUpdatedTime(item.document)
        });
      }
    });

    return {
      totalCount: totalCounts.totalCount,
      worksCount: totalCounts.worksCount,
      uncertainCount: totalCounts.uncertainCount,
      notWorksCount: totalCounts.notWorksCount,
      worksRate: resolveStatsRate(totalCounts.worksCount, totalCounts.totalCount),
      latestReviewTime: sortedItems.length > 0 ? resolveReviewUpdatedTime(sortedItems[0].document) : 0,
      recent30DaysCount: recentCounts.totalCount,
      recent30DaysWorksCount: recentCounts.worksCount,
      recent30DaysUncertainCount: recentCounts.uncertainCount,
      recent30DaysNotWorksCount: recentCounts.notWorksCount,
      decisionDistribution: buildStatsDistribution(totalCounts),
      recentBlockers: blockers,
      recentReviews: recentReviews
    };
  }

  static buildDefaultProjectSummary(items: Array<ReviewCardHistoryItem>): ReviewProjectSummary {
    const projectItems = items.filter((item: ReviewCardHistoryItem): boolean => {
      return ensureProjectId(item.document) === DEFAULT_PROJECT_ID;
    });

    return buildSummaryFromItems(projectItems);
  }

  static buildHomeSummary(items: Array<ReviewCardHistoryItem>): ReviewProjectSummary {
    return buildSummaryFromItems(items);
  }

  static buildDashboardStats(items: Array<ReviewCardHistoryItem>): ReviewDashboardStats {
    const summary: ReviewProjectSummary = ReviewProjectService.buildHomeSummary(items);
    const uniqueDaySet: Set<string> = new Set<string>();
    summary.items.forEach((item: ReviewCardHistoryItem): void => {
      uniqueDaySet.add(normalizeReviewDayKey(item.document.createdAt));
    });

    const sortedDays: Array<number> = Array.from(uniqueDaySet)
      .map((dayKey: string): number => parseReviewDayKey(dayKey))
      .filter((value: number): boolean => value > 0)
      .sort((left: number, right: number): number => right - left);

    let streakDays: number = 0;
    let previousDayTime: number = 0;
    sortedDays.forEach((dayTime: number, index: number): void => {
      if (index === 0) {
        streakDays = 1;
        previousDayTime = dayTime;
        return;
      }

      const dayDiff: number = Math.round((previousDayTime - dayTime) / 86400000);
      if (dayDiff === 1) {
        streakDays += 1;
        previousDayTime = dayTime;
      }
    });

    return {
      streakDays: streakDays
    };
  }
}
