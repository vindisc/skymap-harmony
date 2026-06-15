import { ReviewProjectStats, ReviewProjectSummary } from '../model/ProjectModel';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewProjectService } from './ReviewProjectService';

export interface HomeDashboardState {
  latestItem?: ReviewCardHistoryItem;
  reviewCount: number;
  validReviewCount: number;
  unsureReviewCount: number;
  streakDays: number;
  historyLoadFailed: boolean;
}

export interface HomeDashboardReloadState extends HomeDashboardState {
  reloadRequestId: number;
}

export function createHomeDashboardState(): HomeDashboardState {
  return {
    latestItem: undefined,
    reviewCount: 0,
    validReviewCount: 0,
    unsureReviewCount: 0,
    streakDays: 0,
    historyLoadFailed: false
  };
}

export function createHomeDashboardReloadState(): HomeDashboardReloadState {
  return {
    latestItem: undefined,
    reviewCount: 0,
    validReviewCount: 0,
    unsureReviewCount: 0,
    streakDays: 0,
    historyLoadFailed: false,
    reloadRequestId: 0
  };
}

export function beginHomeDashboardReload(state: HomeDashboardReloadState): number {
  state.reloadRequestId += 1;
  return state.reloadRequestId;
}

export function isCurrentHomeDashboardReload(state: HomeDashboardReloadState, requestId: number): boolean {
  return requestId === state.reloadRequestId;
}

export function resolveHomeDashboardStreakDays(items: Array<ReviewCardHistoryItem>): number {
  try {
    return ReviewProjectService.buildDashboardStats(items).streakDays;
  } catch (error) {
    return 0;
  }
}

export function buildHomeDashboardState(items: Array<ReviewCardHistoryItem>): HomeDashboardState {
  const summary: ReviewProjectSummary = ReviewProjectService.buildHomeSummary(items);
  const stats: ReviewProjectStats = summary.stats;
  return {
    latestItem: summary.latestItem,
    reviewCount: summary.recordCount,
    validReviewCount: stats.validCount,
    unsureReviewCount: stats.unsureCount,
    streakDays: resolveHomeDashboardStreakDays(items),
    historyLoadFailed: false
  };
}

export function applyHomeDashboardReloadSuccess(
  state: HomeDashboardReloadState,
  requestId: number,
  items: Array<ReviewCardHistoryItem>
): boolean {
  if (!isCurrentHomeDashboardReload(state, requestId)) {
    return false;
  }

  const nextState: HomeDashboardState = buildHomeDashboardState(items);
  state.latestItem = nextState.latestItem;
  state.reviewCount = nextState.reviewCount;
  state.validReviewCount = nextState.validReviewCount;
  state.unsureReviewCount = nextState.unsureReviewCount;
  state.streakDays = nextState.streakDays;
  state.historyLoadFailed = false;
  return true;
}

export function applyHomeDashboardReloadFailure(
  state: HomeDashboardReloadState,
  requestId: number
): boolean {
  if (!isCurrentHomeDashboardReload(state, requestId)) {
    return false;
  }

  state.historyLoadFailed = true;
  return true;
}
