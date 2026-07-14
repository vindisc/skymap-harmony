import fs from 'node:fs';

const sources = new Map([
  ['entry/src/main/ets/services/MotionCeremonyEventService.ets', [
    'REVIEW_QUEUE_CLEARED',
    'STREAK_RECORD',
    'SMB_FIRST_CONNECT',
    'static emit(kind: MotionCeremonyEventKind): boolean'
  ]],
  ['entry/src/main/ets/services/LearningProgressService.ets', [
    'notifyPendingReviewCompleted',
    'PendingReviewPhotoStore.getStats(context)',
    'MotionCeremonyEventKind.REVIEW_QUEUE_CLEARED',
    'detectAndNotifyStreakRecord',
    'MotionCeremonyEventKind.STREAK_RECORD'
  ]],
  ['entry/src/main/ets/services/ReviewSettingsService.ets', [
    "REVIEW_STREAK_RECORD_KEY: string = 'review_streak_record'",
    'updateReviewStreakRecord',
    'normalizedStreakDays <= previousRecord'
  ]],
  ['entry/src/main/ets/services/HomeStorageService.ets', [
    "SMB_FIRST_CONNECTION_CEREMONY_SHOWN_KEY: string = 'smb_first_connection_ceremony_shown'",
    'notifyFirstSuccessfulConnection',
    'MotionCeremonyEventKind.SMB_FIRST_CONNECT'
  ]],
  ['entry/src/main/ets/pages/HomePage.ets', [
    'MotionCeremonyEventService.subscribe(this.ceremonyEventListener)',
    'MotionCeremonyEventService.unsubscribe(this.ceremonyEventListener)',
    'MotionCeremonyEventKind.REVIEW_QUEUE_CLEARED',
    "kind: 'review-done'"
  ]],
  ['entry/src/main/ets/pages/StatsPage.ets', [
    'LearningProgressService.detectAndNotifyStreakRecord',
    'MotionCeremonyEventKind.STREAK_RECORD',
    "kind: 'streak-record'"
  ]],
  ['entry/src/main/ets/pages/HomeStoragePage.ets', [
    'HomeStorageService.testConnection(',
    'MotionCeremonyEventKind.SMB_FIRST_CONNECT',
    "kind: 'smb-first-connect'"
  ]],
  ['entry/src/main/ets/pages/EditorPage.ets', [
    'PendingReviewCompletionMotionResult',
    'pendingReviewCompleted',
    '!ceremonyHandledBySubscriber'
  ]]
]);

for (const [path, markers] of sources.entries()) {
  const source = fs.readFileSync(path, 'utf8');
  for (const marker of markers) {
    if (!source.includes(marker)) {
      throw new Error(`${path} 缺少仪式动效挂点: ${marker}`);
    }
  }
}

console.log('motion ceremony hooks verified: pending zero, streak record and first SMB connection');
