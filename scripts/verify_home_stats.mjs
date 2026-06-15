import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const settingsPageSource = fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8');
const projectServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewProjectService.ets', 'utf8');

let failed = false;

const requiredHomeSections = [
  "title: '摄影复盘'",
  "Text('开始新的复盘')",
  "Text('最近一次')",
  "Text('复盘概览')"
];

for (const marker of requiredHomeSections) {
  if (!homePageSource.includes(marker)) {
    failed = true;
    console.error(`HomePage missing section marker: ${marker}`);
  }
}

if (!homePageSource.includes("label: this.isPickingPhoto ? '打开相册中...' : '开始复盘'")) {
  if (!homePageSource.includes("label: this.isPickingPhoto ? '正在打开相册...' : '开始复盘'")) {
    failed = true;
    console.error('HomePage must expose 开始复盘 quick action state.');
  }
}

if (!homePageSource.includes("this.StatItem(`${this.reviewCount}`, '总复盘')") ||
  !homePageSource.includes("this.StatItem(`${this.validReviewCount}`, '成立')") ||
  !homePageSource.includes("this.StatItem(`${this.unsureReviewCount}`, '待判断')")) {
  failed = true;
  console.error('HomePage visible stats must read from scalar @State values, matching MyPage refresh behavior.');
}

if (!homePageSource.includes('const summary: ReviewProjectSummary = ReviewProjectService.buildHomeSummary(items)') ||
  !homePageSource.includes('this.reviewCount = summary.recordCount') ||
  !homePageSource.includes('this.validReviewCount = summary.stats.validCount') ||
  !homePageSource.includes('this.unsureReviewCount = summary.stats.unsureCount')) {
  failed = true;
  console.error('HomePage scalar stats must be copied from the same all-history home summary as MyPage.');
}

if (homePageSource.includes('const results = await Promise.all([')) {
  failed = true;
  console.error('HomePage must apply history stats before loading settings metadata.');
}

if (!myPageSource.includes('ReviewProjectService.buildHomeSummary(historyItems)')) {
  failed = true;
  console.error('MyPage identity stats must use the same all-history summary as HomePage.');
}

if (!historyServiceSource.includes('function normalizeParsedHistory(parsed: Object)') ||
  !historyServiceSource.includes('payload.items && Array.isArray(payload.items)') ||
  !historyServiceSource.includes('payload.documents && Array.isArray(payload.documents)') ||
  !historyServiceSource.includes('payload.document')) {
  failed = true;
  console.error('ReviewCardHistoryService must tolerate legacy or object-shaped history payloads.');
}

if (!homePageSource.includes("@Prop @Watch('refreshHomeData') refreshToken") ||
  !homePageSource.includes('refreshHomeData(): void') ||
  !appShellSource.includes('onPageShow(): void') ||
  !appShellSource.includes('this.refreshHomeIfNeeded();') ||
  !appShellSource.includes('HomePage({ refreshToken: this.homeRefreshToken })')) {
  failed = true;
  console.error('HomePage must reload when AppShell becomes visible again after editor/preview routes.');
}

if (homePageSource.includes('this.dashboardStats.totalCount') ||
  homePageSource.includes('this.dashboardStats.validCount') ||
  homePageSource.includes('this.dashboardStats.unsureCount') ||
  homePageSource.includes('@State dashboardStats')) {
  failed = true;
  console.error('HomePage must not keep visible review counts in nested dashboardStats state.');
}

if (homePageSource.includes("this.StatItem(`${this.projectSummary.recordCount}`, '总复盘')") ||
  homePageSource.includes("this.StatItem(`${this.projectSummary.stats.validCount}`, '成立')") ||
  homePageSource.includes("this.StatItem(`${this.projectSummary.stats.unsureCount}`, '待判断')")) {
  failed = true;
  console.error('HomePage overview must not bind visible stats to nested projectSummary fields.');
}

if (homePageSource.includes("0天")) {
  failed = true;
  console.error('HomePage must not show 0天 for unreliable streak data.');
}

if (homePageSource.indexOf('this.StartReviewPanel()') > homePageSource.indexOf('this.GrowthStatsPanel()')) {
  failed = true;
  console.error('HomePage must render 开始新的复盘 before 复盘概览.');
}

if (homePageSource.includes("Text('当前状态')") ||
  homePageSource.includes('家庭存储：') ||
  homePageSource.includes('复盘人：')) {
  failed = true;
  console.error('HomePage must not render the old configuration status card.');
}

if (historyServiceSource.includes('MAX_HISTORY_COUNT')) {
  failed = true;
  console.error('ReviewCardHistoryService must not truncate older review history.');
}

if (!historyServiceSource.includes("const REVIEW_JSON_BACKUP_DIR_NAME: string = 'review_exchange';") ||
  !historyServiceSource.includes('loadBackupItemsOnce(context, store)') ||
  !historyServiceSource.includes('mergeHistoryItems(historyItems, backupItems)')) {
  failed = true;
  console.error('ReviewCardHistoryService must import local review.json backups into history once.');
}

if (!historyServiceSource.includes('function parseStoredHistory(rawValue: preferences.ValueType): Array<ReviewCardHistoryItem>') ||
  !historyServiceSource.includes('const historyItems: Array<ReviewCardHistoryItem> = parseStoredHistory(rawValue);')) {
  failed = true;
  console.error('ReviewCardHistoryService must keep importing backups even when stored history is malformed.');
}

if (!previewPageSource.includes('ReviewCardHistoryService.markExported(context, this.document, result.path)') ||
  !previewPageSource.includes('ReviewCardHistoryService.markExported(context, this.document, result.remotePath)')) {
  failed = true;
  console.error('PreviewPage must write successful review.json exports and home-storage uploads into history stats.');
}

if (!settingsPageSource.includes("Text('设置')")) {
  failed = true;
  console.error('ReviewSettingsPage title must be 设置.');
}

if (settingsPageSource.includes("Button('返回')") || settingsPageSource.includes('router.back()')) {
  failed = true;
  console.error('ReviewSettingsPage must not render or handle an explicit back button.');
}

if (!projectServiceSource.includes('stats.validCount += 1') ||
  !projectServiceSource.includes('stats.invalidCount += 1') ||
  !projectServiceSource.includes('stats.unsureCount += 1')) {
  failed = true;
  console.error('ReviewProjectService global stats logic must keep all three judgement buckets.');
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
  failed = true;
  console.error(`Unexpected status split: ${JSON.stringify(stats)}`);
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
  failed = true;
  console.error(`Home summary must include non-default projects: ${JSON.stringify(homeSummary)}`);
}

if (failed) {
  process.exit(1);
}

console.log(`home stats: sections=5, total=${stats.totalCount}, mixedTotal=${homeSummary.recordCount}, valid=${stats.validCount}, unsure=${stats.unsureCount}, invalid=${stats.invalidCount}`);
