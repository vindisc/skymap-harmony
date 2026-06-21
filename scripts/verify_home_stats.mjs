import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const reviewJsonExportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewJsonExportService.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const settingsPageSource = fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8');
const projectServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewProjectService.ets', 'utf8');
const homeDashboardPresenterSource = fs.readFileSync('entry/src/main/ets/services/HomeDashboardPresenter.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

const requiredHomeSections = [
  "title: '摄影复盘'",
  "Text('开始新的复盘')",
  "Text('最近一次')",
  "Text('复盘概览')"
];

for (const marker of requiredHomeSections) {
  assert(homePageSource.includes(marker), `HomePage missing section marker: ${marker}`);
}

if (!homePageSource.includes("label: this.isPickingPhoto ? '打开相册中...' : '开始复盘'")) {
  if (!homePageSource.includes("label: this.isPickingPhoto ? '正在打开相册...' : '开始复盘'")) {
    assert(false, 'HomePage must expose 开始复盘 quick action state.');
  }
}

if (!homePageSource.includes('Text(`${this.reviewCount}`)') ||
  !homePageSource.includes('Text(`${this.validReviewCount}`)') ||
  !homePageSource.includes('Text(`${this.unsureReviewCount}`)')) {
  assert(false, 'HomePage visible stats must bind directly to scalar @State values, matching MyPage refresh behavior.');
}

if (homePageSource.includes('StatItem(') ||
  homePageSource.includes('@Builder\n  StatItem') ||
  homePageSource.includes('StatTile(') ||
  homePageSource.includes('@Builder\n  StatTile')) {
  assert(false, 'HomePage must not pass dynamic stats through a parameterized builder because ArkUI can keep stale values.');
}

if (homePageSource.includes("import { ReviewProjectService } from '../services/ReviewProjectService';") ||
  homePageSource.includes('ReviewProjectService.buildHomeSummary(items)') ||
  homePageSource.includes('private resolveStreakDays(items: Array<ReviewCardHistoryItem>): number')) {
  assert(false, 'HomePage must not own dashboard calculation logic; keep it in HomeDashboardPresenter.');
}

if (!homePageSource.includes('beginHomeDashboardReload(this.dashboardReloadState)') ||
  (!homePageSource.includes('applyHomeDashboardReloadSuccess(this.dashboardReloadState, requestId, items)') &&
    !homePageSource.includes('applyHomeDashboardReloadSuccess(this.dashboardReloadState, requestId, result.items)')) ||
  !homePageSource.includes('applyHomeDashboardReloadFailure(this.dashboardReloadState, requestId)') ||
  !homePageSource.includes('this.syncDashboardStateFromPresenter()')) {
  assert(false, 'HomePage reload flow must delegate stale request gating and data projection to HomeDashboardPresenter.');
}

if (!homePageSource.includes('ReviewCardHistoryService.loadWithDiagnostics(context)') ||
  !homePageSource.includes('ReviewCardHistoryService.formatDiagnostics') ||
  !homePageSource.includes("label: '复制恢复诊断'") ||
  !homePageSource.includes('pasteboard.createData')) {
  assert(false, 'HomePage must expose copyable history recovery diagnostics when visible stats are still empty.');
}

if (!homeDashboardPresenterSource.includes('const summary: ReviewProjectSummary = ReviewProjectService.buildHomeSummary(items)') ||
  !homeDashboardPresenterSource.includes('reviewCount: summary.recordCount') ||
  !homeDashboardPresenterSource.includes('validReviewCount: stats.validCount') ||
  !homeDashboardPresenterSource.includes('unsureReviewCount: stats.unsureCount') ||
  !homeDashboardPresenterSource.includes('streakDays: resolveHomeDashboardStreakDays(items)')) {
  assert(false, 'HomeDashboardPresenter must copy visible state from the same all-history home summary as MyPage.');
}

if (!homeDashboardPresenterSource.includes('return ReviewProjectService.buildDashboardStats(items).streakDays;') ||
  !homeDashboardPresenterSource.includes('return 0;') ||
  !homeDashboardPresenterSource.includes('state.historyLoadFailed = true;')) {
  assert(false, 'HomeDashboardPresenter must isolate streak calculation and failure handling so visible counts are not reset.');
}

const summaryIndex = homeDashboardPresenterSource.indexOf('const summary: ReviewProjectSummary = ReviewProjectService.buildHomeSummary(items)');
const countIndex = homeDashboardPresenterSource.indexOf('reviewCount: summary.recordCount');
const streakIndex = homeDashboardPresenterSource.indexOf('streakDays: resolveHomeDashboardStreakDays(items)');
if (summaryIndex < 0 || countIndex < 0 || streakIndex < 0 || !(summaryIndex < countIndex && countIndex < streakIndex)) {
  assert(false, 'HomeDashboardPresenter must derive counts before calculating streak data.');
}

if (homePageSource.includes('ReviewCardStore.getCurrentDocument()') ||
  homePageSource.includes('hasMeaningfulCurrentDocument')) {
  assert(false, 'HomePage must not mix the in-memory current draft into persisted history stats.');
}

if (homePageSource.includes('const results = await Promise.all([')) {
  assert(false, 'HomePage must apply history stats before loading settings metadata.');
}

if (!myPageSource.includes('ReviewProjectService.buildHomeSummary(historyItems)')) {
  assert(false, 'MyPage identity stats must use the same all-history summary as HomePage.');
}

if (!historyServiceSource.includes('function normalizeParsedHistory(parsed: Object)') ||
  !historyServiceSource.includes('payload.items && Array.isArray(payload.items)') ||
  !historyServiceSource.includes('payload.documents && Array.isArray(payload.documents)') ||
  !historyServiceSource.includes('payload.document')) {
  assert(false, 'ReviewCardHistoryService must tolerate legacy or object-shaped history payloads.');
}

if (!homePageSource.includes("@Prop @Watch('refreshHomeData') refreshToken") ||
  !homePageSource.includes('refreshHomeData(): void') ||
  !appShellSource.includes('onPageShow(): void') ||
  !appShellSource.includes('this.refreshHomeIfNeeded();') ||
  !appShellSource.includes('HomePage({ refreshToken: this.homeRefreshToken })')) {
  assert(false, 'HomePage must reload when AppShell becomes visible again after editor/preview routes.');
}

if (!appShellSource.includes('private selectTab(key: RootTabKey): void') ||
  !appShellSource.includes('this.currentTab = key;\n    this.homeRefreshToken += 1;')) {
  assert(false, 'AppShell must refresh HomePage after any tab switch so stats recover after MyPage reads history.');
}

if (homePageSource.includes('this.dashboardStats.totalCount') ||
  homePageSource.includes('this.dashboardStats.validCount') ||
  homePageSource.includes('this.dashboardStats.unsureCount') ||
  homePageSource.includes('@State dashboardStats')) {
  assert(false, 'HomePage must not keep visible review counts in nested dashboardStats state.');
}

if (homePageSource.includes("this.StatItem(`${this.projectSummary.recordCount}`, '总复盘')") ||
  homePageSource.includes("this.StatItem(`${this.projectSummary.stats.validCount}`, '成立')") ||
  homePageSource.includes("this.StatItem(`${this.projectSummary.stats.unsureCount}`, '待判断')")) {
  assert(false, 'HomePage overview must not bind visible stats to nested projectSummary fields.');
}

if (homePageSource.includes("0天")) {
  assert(false, 'HomePage must not show 0天 for unreliable streak data.');
}

if (homePageSource.indexOf('this.StartReviewPanel()') > homePageSource.indexOf('this.GrowthStatsPanel()')) {
  assert(false, 'HomePage must render 开始新的复盘 before 复盘概览.');
}

if (homePageSource.includes("Text('当前状态')") ||
  homePageSource.includes('家庭存储：') ||
  homePageSource.includes('复盘人：')) {
  assert(false, 'HomePage must not render the old configuration status card.');
}

if (historyServiceSource.includes('MAX_HISTORY_COUNT')) {
  assert(false, 'ReviewCardHistoryService must not truncate older review history.');
}

if (!historyServiceSource.includes("const REVIEW_JSON_BACKUP_DIR_NAME: string = 'review_exchange';") ||
  !historyServiceSource.includes('loadBackupItemsOnce(') ||
  !historyServiceSource.includes('mergeHistoryItems(historyItems, backupItems)')) {
  assert(false, 'ReviewCardHistoryService must import local review.json backups into history once.');
}

if (!historyServiceSource.includes('shouldForceReload: boolean = false') ||
  !historyServiceSource.includes('importedValue === true && !shouldForceReload') ||
  !historyServiceSource.includes('historyItems.length === 0')) {
  assert(false, 'ReviewCardHistoryService must rescan review.json backups when persisted history is empty, even after a previous import marker.');
}

if (!historyServiceSource.includes('export interface ReviewCardHistoryDiagnostics') ||
  !historyServiceSource.includes('static async loadWithDiagnostics') ||
  !historyServiceSource.includes('static formatDiagnostics') ||
  !historyServiceSource.includes('backupFileCount') ||
  !historyServiceSource.includes('parsedBackupCount') ||
  !historyServiceSource.includes('rawHistoryLength')) {
  assert(false, 'ReviewCardHistoryService must provide structured diagnostics for repeated home stats recovery failures.');
}

if (!historyServiceSource.includes("!fileName.endsWith('.review.json') && !fileName.endsWith('.json')")) {
  assert(false, 'ReviewCardHistoryService must recover both *.review.json and legacy *.json review backups.');
}

if (!historyServiceSource.includes('function parseStoredHistory(rawValue: preferences.ValueType): Array<ReviewCardHistoryItem>') ||
  !historyServiceSource.includes('const historyItems: Array<ReviewCardHistoryItem> = parseStoredHistory(rawValue);')) {
  assert(false, 'ReviewCardHistoryService must keep importing backups even when stored history is malformed.');
}

if (!previewPageSource.includes('ReviewCardHistoryService.markExported(context, this.document, result.path)') ||
  !previewPageSource.includes('ReviewCardHistoryService.markExported(context, this.document, result.remotePath)')) {
  assert(false, 'PreviewPage must write successful review.json exports and home-storage uploads into history stats.');
}

if (!historyServiceSource.includes("import { ReviewJsonExportService } from './ReviewJsonExportService';") ||
  !historyServiceSource.includes('await ReviewCardHistoryService.writeRecoverableBackup(context, document);') ||
  !historyServiceSource.includes('await ReviewJsonExportService.writeSandboxReviewJsonBackup(context, document);') ||
  !reviewJsonExportServiceSource.includes('static async writeSandboxReviewJsonBackup') ||
  !reviewJsonExportServiceSource.includes('resolveBackupFileName(document)') ||
  !reviewJsonExportServiceSource.includes('document.createdAt}-${stem}.${REVIEW_JSON_EXTENSION}') ||
  !historyServiceSource.includes('fileName.match(/^\\d{8}-\\d{6}-(\\d{10,})-/)') ||
  !reviewJsonExportServiceSource.includes('formatTimestamp(document.createdAt)')) {
  assert(false, 'Saving history must also write a stable local review.json backup for future home stats recovery.');
}

if (!previewPageSource.includes('private async ensureCurrentDocumentPersisted(): Promise<void>') ||
  !previewPageSource.includes('await this.ensureCurrentDocumentPersisted();') ||
  !previewPageSource.includes('await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);') ||
  !previewPageSource.includes('private hasMeaningfulDocument(document: ReviewCardDocument): boolean')) {
  assert(false, 'PreviewPage must persist a meaningful current review when history is missing.');
}

if (!historyServiceSource.includes('existingItem ? existingItem.exportedPath :') ||
  !historyServiceSource.includes('deleteRecoverableBackup(context, document)') ||
  !reviewJsonExportServiceSource.includes('static deleteSandboxReviewJsonBackup') ||
  !reviewJsonExportServiceSource.includes('fs.unlinkSync')) {
  assert(false, 'History save/delete must preserve export state and keep automatic recovery backups in sync.');
}

if (!settingsPageSource.includes("Text('设置')")) {
  assert(false, 'ReviewSettingsPage title must be 设置.');
}

if (settingsPageSource.includes("Button('返回')") || settingsPageSource.includes('router.back()')) {
  assert(false, 'ReviewSettingsPage must not render or handle an explicit back button.');
}

if (!projectServiceSource.includes('stats.validCount += 1') ||
  !projectServiceSource.includes('stats.invalidCount += 1') ||
  !projectServiceSource.includes('stats.unsureCount += 1')) {
  assert(false, 'ReviewProjectService global stats logic must keep all three judgement buckets.');
}

function normalizeReviewJudgement(value) {
  const trimmedValue = typeof value === 'string' ? value.trim() : '';
  if (trimmedValue === '成立') {
    return '成立';
  }
  if (trimmedValue === '不成立') {
    return '不成立';
  }
  if (trimmedValue === '不确定' || trimmedValue === '待判断') {
    return '不确定';
  }
  if (trimmedValue.includes('不成立')) {
    return '不成立';
  }
  if (trimmedValue.includes('待判断') || trimmedValue.includes('不确定')) {
    return '不确定';
  }
  if (trimmedValue.includes('成立')) {
    return '成立';
  }
  return '不确定';
}

function buildGlobalStats(items) {
  const stats = {
    totalCount: items.length,
    validCount: 0,
    unsureCount: 0,
    invalidCount: 0
  };

  items.forEach((item) => {
    const judgement = normalizeReviewJudgement(item.document.content.judgement);
    if (judgement === '成立') {
      stats.validCount += 1;
      return;
    }
    if (judgement === '不成立') {
      stats.invalidCount += 1;
      return;
    }
    stats.unsureCount += 1;
  });

  return stats;
}

function buildHomeSummary(items) {
  return {
    recordCount: items.length,
    stats: buildGlobalStats(items),
    latestItem: [...items].sort((left, right) => {
      if (right.document.updatedAt !== left.document.updatedAt) {
        return right.document.updatedAt - left.document.updatedAt;
      }
      return right.document.createdAt - left.document.createdAt;
    })[0]
  };
}

function createReviewItem(projectId, judgement, createdAt, updatedAt = createdAt) {
  return {
    document: {
      projectId,
      content: {
        judgement
      },
      createdAt,
      updatedAt
    },
    exportedPath: ''
  };
}

function createHomeDashboardReloadState() {
  return {
    reloadRequestId: 0,
    latestItem: undefined,
    reviewCount: 0,
    validReviewCount: 0,
    unsureReviewCount: 0,
    streakDays: 0,
    historyLoadFailed: false
  };
}

function applyHomeDashboardDataToState(state, items) {
  const summary = buildHomeSummary(items);
  state.latestItem = summary.latestItem;
  state.reviewCount = summary.recordCount;
  state.validReviewCount = summary.stats.validCount;
  state.unsureReviewCount = summary.stats.unsureCount;
  state.streakDays = 0;
}

function applyHomeDashboardReloadSuccess(state, requestId, items) {
  if (requestId !== state.reloadRequestId) {
    return false;
  }
  state.historyLoadFailed = false;
  applyHomeDashboardDataToState(state, items);
  return true;
}

function applyHomeDashboardReloadFailure(state, requestId) {
  if (requestId !== state.reloadRequestId) {
    return false;
  }
  state.historyLoadFailed = true;
  return true;
}

const twelveReviewItems = [
  '成立',
  '成立',
  '成立',
  '不成立',
  '不成立',
  '待判断',
  '不确定',
  '',
  undefined,
  '仍然待判断',
  '判断为成立',
  '判断为不成立'
].map((judgement, index) => {
  return {
    document: {
      projectId: 'default',
      content: {
        judgement
      },
      createdAt: index + 1,
      updatedAt: index + 1
    },
    exportedPath: ''
  };
});

const stats = buildGlobalStats(twelveReviewItems);
if (stats.totalCount !== 12 || stats.validCount !== 4 || stats.unsureCount !== 5 || stats.invalidCount !== 3) {
  assert(false, `Unexpected status split: ${JSON.stringify(stats)}`);
}

const mixedProjectItems = [
  ['default', '成立', 100],
  ['imported-project', '不成立', 300],
  ['legacy-project', '待判断', 200]
].map(([projectId, judgement, updatedAt], index) => {
  return {
    document: {
      projectId,
      content: {
        judgement
      },
      createdAt: index + 1,
      updatedAt
    },
    exportedPath: ''
  };
});

const homeSummary = buildHomeSummary(mixedProjectItems);
if (homeSummary.recordCount !== 3 ||
  homeSummary.stats.validCount !== 1 ||
  homeSummary.stats.unsureCount !== 1 ||
  homeSummary.stats.invalidCount !== 1 ||
  homeSummary.latestItem.document.projectId !== 'imported-project') {
  assert(false, `Home summary must include non-default projects: ${JSON.stringify(homeSummary)}`);
}

const staleReloadState = createHomeDashboardReloadState();
const slowRequestId = 1;
staleReloadState.reloadRequestId = slowRequestId;
const fastRequestId = 2;
staleReloadState.reloadRequestId = fastRequestId;
applyHomeDashboardReloadSuccess(staleReloadState, fastRequestId, [
  createReviewItem('default', '成立', 1, 10),
  createReviewItem('default', '待判断', 2, 20)
]);
applyHomeDashboardReloadSuccess(staleReloadState, slowRequestId, [
  createReviewItem('default', '不成立', 1, 30)
]);
assert(
  staleReloadState.reviewCount === 2 &&
    staleReloadState.validReviewCount === 1 &&
    staleReloadState.unsureReviewCount === 1 &&
    staleReloadState.latestItem.document.updatedAt === 20,
  `Stale home reload must not overwrite newer visible stats: ${JSON.stringify(staleReloadState)}`
);

const failedReloadState = createHomeDashboardReloadState();
failedReloadState.reloadRequestId = 1;
applyHomeDashboardReloadSuccess(failedReloadState, 1, [
  createReviewItem('default', '成立', 1, 10),
  createReviewItem('default', '不成立', 2, 20),
  createReviewItem('default', '待判断', 3, 30)
]);
failedReloadState.reloadRequestId = 2;
applyHomeDashboardReloadFailure(failedReloadState, 2);
assert(
  failedReloadState.historyLoadFailed === true &&
    failedReloadState.reviewCount === 3 &&
    failedReloadState.validReviewCount === 1 &&
    failedReloadState.unsureReviewCount === 1,
  `Failed home reload must keep the last visible stats instead of blanking the dashboard: ${JSON.stringify(failedReloadState)}`
);

function shouldLoadBackupItems(importMarker, historyCount) {
  const shouldForceReload = historyCount === 0;
  return !(importMarker === true && !shouldForceReload);
}

assert(
  shouldLoadBackupItems(true, 0) === true &&
    shouldLoadBackupItems(true, 2) === false &&
    shouldLoadBackupItems(false, 0) === true,
  'Backup import marker must not block recovery when current persisted history is empty.'
);

if (homePageSource.includes('catch (error) {\n      if (requestId === this.reloadRequestId) {\n        this.historyLoadFailed = true;\n        this.reviewCount = 0')) {
  assert(false, 'HomePage load failure must not reset visible review counts to 0.');
}

if (failed) {
  process.exit(1);
}

console.log(`home stats: sections=5, total=${stats.totalCount}, mixedTotal=${homeSummary.recordCount}, valid=${stats.validCount}, unsure=${stats.unsureCount}, invalid=${stats.invalidCount}, staleReloadKept=${staleReloadState.reviewCount}, failureKept=${failedReloadState.reviewCount}`);
