import { DEFAULT_PROJECT_ID, ReviewCardHistoryItem } from './ReviewCardModel';

export interface ReviewProject {
  id: string;
  name: string;
  createdAt: number;
  updatedAt: number;
  reviewIds: Array<string>;
}

export interface ReviewProjectSummary {
  project: ReviewProject;
  items: Array<ReviewCardHistoryItem>;
  recordCount: number;
  latestUpdatedAt: number;
  latestItem?: ReviewCardHistoryItem;
}

export const DEFAULT_PROJECT_NAME: string = '我的摄影复盘';

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
    latestUpdatedAt: 0
  };
}
