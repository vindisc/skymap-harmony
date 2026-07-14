import common from '@ohos.app.ability.common';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { PendingReviewPhotoStats, PendingReviewPhotoStore } from './PendingReviewPhotoStore';
import { ReviewCardHistoryService } from './ReviewCardHistoryService';
import {
  MotionCeremonyEventKind,
  MotionCeremonyEventService
} from './MotionCeremonyEventService';
import { ReviewSettingsService } from './ReviewSettingsService';

export interface LearningProgressSnapshot {
  pendingCount: number;
  totalImportedCount: number;
  completedCount: number;
  completionRateText: string;
  reviewStreakDays: number;
}

export interface LearningProgressLoadResult {
  snapshot: LearningProgressSnapshot;
  reviewItems: Array<ReviewCardHistoryItem>;
}

export interface PendingReviewCompletionMotionResult {
  pendingBecameEmpty: boolean;
  ceremonyScheduled: boolean;
}

export function createEmptyLearningProgressSnapshot(): LearningProgressSnapshot {
  return {
    pendingCount: 0,
    totalImportedCount: 0,
    completedCount: 0,
    completionRateText: '--',
    reviewStreakDays: 3
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

function buildReviewStreakDays(reviewItems: Array<ReviewCardHistoryItem>): number {
  const uniqueDaySet: Set<string> = new Set<string>();
  reviewItems.forEach((item: ReviewCardHistoryItem): void => {
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

  return streakDays;
}

export class LearningProgressService {
  static buildSnapshot(
    pendingCount: number,
    completedCount: number,
    reviewStreakDays: number = 0
  ): LearningProgressSnapshot {
    const safePendingCount: number = Math.max(0, pendingCount);
    const safeCompletedCount: number = Math.max(0, completedCount);
    const totalImportedCount: number = safePendingCount + safeCompletedCount;
    return {
      pendingCount: safePendingCount,
      totalImportedCount: totalImportedCount,
      completedCount: safeCompletedCount,
      completionRateText: totalImportedCount <= 0
        ? '--'
        : `${Math.floor(safeCompletedCount * 100 / totalImportedCount)}%`,
      reviewStreakDays: Math.max(0, reviewStreakDays)
    };
  }

  static async load(context: common.UIAbilityContext): Promise<LearningProgressSnapshot> {
    const result: LearningProgressLoadResult = await LearningProgressService.loadWithReviewItems(context);
    return result.snapshot;
  }

  static async notifyPendingReviewCompleted(
    context: common.UIAbilityContext
  ): Promise<PendingReviewCompletionMotionResult> {
    const pendingStats: PendingReviewPhotoStats = await PendingReviewPhotoStore.getStats(context);
    if (pendingStats.pendingCount > 0) {
      return {
        pendingBecameEmpty: false,
        ceremonyScheduled: false
      };
    }
    MotionCeremonyEventService.enqueue(MotionCeremonyEventKind.REVIEW_QUEUE_CLEARED);
    return {
      pendingBecameEmpty: true,
      ceremonyScheduled: true
    };
  }

  static async detectAndNotifyStreakRecord(
    context: common.UIAbilityContext,
    streakDays: number
  ): Promise<boolean> {
    const recordBroken: boolean = await ReviewSettingsService.updateReviewStreakRecord(context, streakDays);
    if (recordBroken) {
      MotionCeremonyEventService.emit(MotionCeremonyEventKind.STREAK_RECORD);
    }
    return recordBroken;
  }

  static async loadWithReviewItems(context: common.UIAbilityContext): Promise<LearningProgressLoadResult> {
    const pendingStats: PendingReviewPhotoStats = await PendingReviewPhotoStore.getStats(context);
    const reviewItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
    return {
      snapshot: LearningProgressService.buildSnapshot(
        pendingStats.pendingCount,
        reviewItems.length,
        buildReviewStreakDays(reviewItems)
      ),
      reviewItems: reviewItems
    };
  }
}
