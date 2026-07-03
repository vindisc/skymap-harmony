import common from '@ohos.app.ability.common';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { PendingReviewPhotoStats, PendingReviewPhotoStore } from './PendingReviewPhotoStore';
import { ReviewCardHistoryService } from './ReviewCardHistoryService';

export interface LearningProgressSnapshot {
  pendingCount: number;
  totalImportedCount: number;
  completedCount: number;
  completionRateText: string;
}

export interface LearningProgressLoadResult {
  snapshot: LearningProgressSnapshot;
  reviewItems: Array<ReviewCardHistoryItem>;
}

export function createEmptyLearningProgressSnapshot(): LearningProgressSnapshot {
  return {
    pendingCount: 0,
    totalImportedCount: 0,
    completedCount: 0,
    completionRateText: '--'
  };
}

export class LearningProgressService {
  static buildSnapshot(pendingCount: number, completedCount: number): LearningProgressSnapshot {
    const safePendingCount: number = Math.max(0, pendingCount);
    const safeCompletedCount: number = Math.max(0, completedCount);
    const totalImportedCount: number = safePendingCount + safeCompletedCount;
    return {
      pendingCount: safePendingCount,
      totalImportedCount: totalImportedCount,
      completedCount: safeCompletedCount,
      completionRateText: totalImportedCount <= 0
        ? '--'
        : `${Math.floor(safeCompletedCount * 100 / totalImportedCount)}%`
    };
  }

  static async load(context: common.UIAbilityContext): Promise<LearningProgressSnapshot> {
    const result: LearningProgressLoadResult = await LearningProgressService.loadWithReviewItems(context);
    return result.snapshot;
  }

  static async loadWithReviewItems(context: common.UIAbilityContext): Promise<LearningProgressLoadResult> {
    const pendingStats: PendingReviewPhotoStats = await PendingReviewPhotoStore.getStats(context);
    const reviewItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
    return {
      snapshot: LearningProgressService.buildSnapshot(pendingStats.pendingCount, reviewItems.length),
      reviewItems: reviewItems
    };
  }
}
