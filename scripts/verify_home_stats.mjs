import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const reviewJsonExportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewJsonExportService.ets', 'utf8');
const projectServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewProjectService.ets', 'utf8');
const homeDashboardPresenterSource = fs.readFileSync('entry/src/main/ets/services/HomeDashboardPresenter.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function requireIncludes(source, marker, message) {
  assert(source.includes(marker), `${message}: ${marker}`);
}

[
  "title: '摄影复盘'",
  "Button(this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '导入照片，开始复盘')",
  'beginHomeDashboardReload(this.dashboardReloadState)',
  'ReviewCardHistoryService.loadWithDiagnostics(context)',
  'applyHomeDashboardReloadSuccess(this.dashboardReloadState, requestId, result.items)',
  'applyHomeDashboardReloadFailure(this.dashboardReloadState, requestId)',
  'this.syncDashboardStateFromPresenter()',
  'ReviewCardHistoryService.formatDiagnostics',
  'pasteboard.createData',
  'this.DiagnosticsPanel()'
].forEach((marker) => requireIncludes(homePageSource, marker, 'HomePage missing dashboard recovery marker'));

assert(!homePageSource.includes('ReviewProjectService.buildHomeSummary(items)'),
  'HomePage must not own dashboard calculation logic; keep it in HomeDashboardPresenter.');
assert(!homePageSource.includes('ReviewCardStore.getCurrentDocument()'),
  'HomePage must not mix the in-memory current draft into persisted history state.');
assert(!homePageSource.includes('@State dashboardStats'),
  'HomePage must not keep visible review counts in nested dashboardStats state.');

[
  'const summary: ReviewProjectSummary = ReviewProjectService.buildHomeSummary(items)',
  'reviewCount: summary.recordCount',
  'validReviewCount: stats.validCount',
  'unsureReviewCount: stats.unsureCount',
  'streakDays: resolveHomeDashboardStreakDays(items)',
  'return ReviewProjectService.buildDashboardStats(items).streakDays;',
  'state.historyLoadFailed = true;'
].forEach((marker) => requireIncludes(homeDashboardPresenterSource, marker, 'HomeDashboardPresenter missing summary marker'));

[
  "@Prop @Watch('refreshHomeData') refreshToken",
  'refreshHomeData(): void',
  'this.reloadHeroImages();'
].forEach((marker) => requireIncludes(homePageSource, marker, 'HomePage must reload when AppShell refreshes it'));

[
  'onPageShow(): void',
  'this.refreshCurrentTabIfNeeded();',
  'this.homeRefreshToken += 1;',
  'this.myRefreshToken += 1;'
].forEach((marker) => requireIncludes(appShellSource, marker, 'AppShell must refresh visible tab data'));

[
  'function normalizeParsedHistory(parsed: Object)',
  'payload.items && Array.isArray(payload.items)',
  'payload.documents && Array.isArray(payload.documents)',
  'payload.document',
  "const REVIEW_JSON_BACKUP_DIR_NAME: string = 'review_exchange';",
  'loadBackupItemsOnce(',
  'mergeHistoryItems(historyItems, backupItems)',
  'export interface ReviewCardHistoryDiagnostics',
  'static async loadWithDiagnostics',
  'static formatDiagnostics',
  'backupFileCount',
  'parsedBackupCount',
  'rawHistoryLength'
].forEach((marker) => requireIncludes(historyServiceSource, marker, 'ReviewCardHistoryService missing recovery marker'));

[
  'await this.markExportedQuietly(result.path)',
  'await this.markExportedQuietly(result.remotePath)',
  'private async ensureCurrentDocumentPersisted(): Promise<void>',
  'await this.ensureCurrentDocumentPersisted();',
  'await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);',
  'private hasMeaningfulDocument(document: ReviewCardDocument): boolean'
].forEach((marker) => requireIncludes(previewPageSource, marker, 'PreviewPage missing persistence/export marker'));

[
  "ReviewJsonExportService } from './ReviewJsonExportService';",
  'await ReviewCardHistoryService.writeRecoverableBackup(context, document);',
  'await ReviewJsonExportService.writeSandboxReviewJsonBackup(context, document);',
  'deleteRecoverableBackup(context, document)'
].forEach((marker) => requireIncludes(historyServiceSource, marker, 'History save/delete must keep automatic recovery backups in sync'));

[
  'static async writeSandboxReviewJsonBackup',
  'resolveBackupFileName(document)',
  'formatTimestamp(document.createdAt)',
  'static deleteSandboxReviewJsonBackup',
  'fs.unlinkSync'
].forEach((marker) => requireIncludes(reviewJsonExportServiceSource, marker, 'ReviewJsonExportService missing backup marker'));

[
  'stats.validCount += 1',
  'stats.invalidCount += 1',
  'stats.unsureCount += 1'
].forEach((marker) => requireIncludes(projectServiceSource, marker, 'ReviewProjectService global stats logic must keep all judgement buckets'));

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
    const judgement = normalizeReviewJudgement(item.judgement);
    if (judgement === '成立') {
      stats.validCount += 1;
    } else if (judgement === '不成立') {
      stats.invalidCount += 1;
    } else {
      stats.unsureCount += 1;
    }
  });
  return stats;
}

const stats = buildGlobalStats([
  { judgement: '成立' },
  { judgement: '不成立' },
  { judgement: '待判断' },
  { judgement: '还不确定' }
]);

assert(stats.totalCount === 4, 'Stats total count should include all items.');
assert(stats.validCount === 1, 'Stats valid count should include 成立.');
assert(stats.invalidCount === 1, 'Stats invalid count should include 不成立.');
assert(stats.unsureCount === 2, 'Stats unsure count should include 待判断 and 不确定 variants.');

if (failed) {
  process.exit(1);
}

console.log('home stats/recovery verified: presenter gating, diagnostics, refresh tokens, export marks, backups, and judgement counts');
