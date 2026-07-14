import fs from 'node:fs';

const sources = new Map([
  ['entry/src/main/ets/services/MotionCeremonyEventService.ets', [
    'REVIEW_QUEUE_CLEARED',
    'STREAK_RECORD',
    'SMB_FIRST_CONNECT',
    'pendingKinds',
    'interface MotionCeremonyPendingEvent',
    'enqueuedAt: number;',
    'MOTION_CEREMONY_PENDING_TTL_MS: number = 60_000',
    'now - pendingEvent.enqueuedAt <= MOTION_CEREMONY_PENDING_TTL_MS',
    'static enqueue(kind: MotionCeremonyEventKind): void',
    'static consumePending(listener: MotionCeremonyEventListener): void',
    'if (!handled)',
    'static emit(kind: MotionCeremonyEventKind): boolean',
    'listener 已订阅，已跳过重复注册',
    'emit(kind)：发一次事件',
    'enqueue(kind)：直接入队',
    'consumePending(listener)：subscribe 内部会自动调用'
  ]],
  ['entry/src/main/ets/services/LearningProgressService.ets', [
    'notifyPendingReviewCompleted',
    'PendingReviewPhotoStore.getStats(context)',
    'MotionCeremonyEventService.enqueue(MotionCeremonyEventKind.REVIEW_QUEUE_CLEARED)',
    'MotionCeremonyEventKind.REVIEW_QUEUE_CLEARED',
    'detectAndNotifyStreakRecord',
    'MotionCeremonyEventKind.STREAK_RECORD'
  ]],
  ['entry/src/main/ets/services/ReviewSettingsService.ets', [
    "REVIEW_STREAK_RECORD_KEY: string = 'review_streak_record'",
    'updateReviewStreakRecord',
    'normalizedStreakDays < 2',
    'normalizedStreakDays <= previousRecord'
  ]],
  ['entry/src/main/ets/services/HomeStorageService.ets', [
    "SMB_FIRST_CONNECTION_CEREMONY_SHOWN_KEY: string = 'smb_first_connection_ceremony_shown'",
    'notifyFirstSuccessfulConnection',
    'MotionCeremonyEventKind.SMB_FIRST_CONNECT'
  ]],
  ['entry/src/main/ets/pages/HomePage.ets', [
    'this.ensureCeremonySubscription()',
    'MotionCeremonyEventService.consumePending(this.ceremonyEventListener)',
    'if (MotionQualityContext.shouldPlayCeremony())',
    'MotionCeremonyEventService.unsubscribe(this.ceremonyEventListener)',
    'MotionCeremonyEventKind.REVIEW_QUEUE_CLEARED',
    "kind: 'review-done'"
  ]],
  ['entry/src/main/ets/pages/StatsPage.ets', [
    'LearningProgressService.detectAndNotifyStreakRecord',
    'MotionCeremonyEventKind.STREAK_RECORD',
    'if (MotionQualityContext.shouldPlayCeremony())',
    "kind: 'streak-record'"
  ]],
  ['entry/src/main/ets/pages/HomeStoragePage.ets', [
    'HomeStorageService.testConnection(',
    'MotionCeremonyEventKind.SMB_FIRST_CONNECT',
    'if (MotionQualityContext.shouldPlayCeremony())',
    "kind: 'smb-first-connect'"
  ]],
  ['entry/src/main/ets/pages/EditorPage.ets', [
    'pendingReviewCompleted',
    'LearningProgressService.notifyPendingReviewCompleted',
    'this.openPreview()'
  ]],
  ['entry/src/main/ets/pages/SyncCenterPage.ets', [
    'HomeStorageService.testConnection(',
    'this.getAbilityContext()'
  ]]
]);

const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const editorSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');
if (homeStorageSource.includes('context?: common.UIAbilityContext') ||
  !homeStorageSource.includes('HomeStorageService.testConnection(settings, context)')) {
  throw new Error('HomeStorageService.testConnection 必须要求 context，内部可用性检查也必须传入。');
}
if (editorSource.includes("import { CeremonyBurst }") || editorSource.includes('@State ceremonyVisible') ||
  editorSource.includes('keepSavingLockedForCeremony')) {
  throw new Error('EditorPage 不得保留已迁移到 HomePage 的仪式死代码。');
}

for (const [path, markers] of sources.entries()) {
  const source = fs.readFileSync(path, 'utf8');
  for (const marker of markers) {
    if (!source.includes(marker)) {
      throw new Error(`${path} 缺少仪式动效挂点: ${marker}`);
    }
  }
}

console.log('motion ceremony hooks verified: pending zero, streak record and first SMB connection');
