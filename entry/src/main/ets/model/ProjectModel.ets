import { DEFAULT_PROJECT_ID, ReviewCardHistoryItem } from './ReviewCardModel';

export interface ReviewProject {
  id: string;
  name: string;
  createdAt: number;
  updatedAt: number;
  reviewIds: Array<string>;
}

export interface ReviewProjectStats {
  totalCount: number;
  validCount: number;
  unsureCount: number;
  invalidCount: number;
}

export interface ReviewProjectSummary {
  project: ReviewProject;
  items: Array<ReviewCardHistoryItem>;
  recordCount: number;
  stats: ReviewProjectStats;
  latestUpdatedAt: number;
  latestItem?: ReviewCardHistoryItem;
}

export const DEFAULT_PROJECT_NAME: string = '我的摄影复盘';

export function createEmptyProjectStats(): ReviewProjectStats {
  return {
    totalCount: 0,
    validCount: 0,
    unsureCount: 0,
    invalidCount: 0
  };
}

export function createDefaultProjectSummary(): ReviewProjectSummary {
  const now: number = Date.now();
  return {
    project: {
      id: DEFAULT_PROJECT_ID,
      name: DEFAULT_PROJECT_NAME,
      createdAt: now,
      updatedAt: now,
      reviewIds: []
    },
    items: [],
    recordCount: 0,
    stats: createEmptyProjectStats(),
    latestUpdatedAt: 0
  };
}
