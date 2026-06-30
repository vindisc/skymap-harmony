import fs from 'node:fs';

const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const statsPageSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const homeHeroPageSource = fs.readFileSync('entry/src/main/ets/pages/HomeHeroImagePage.ets', 'utf8');
const homeStoragePageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');

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

function forbidIncludes(source, marker, message) {
  assert(!source.includes(marker), `${message}: ${marker}`);
}

[
  "title: '我的'",
  'this.SettingsSection()',
  'this.AboutSection()',
  "title: '设置'",
  "title: '复盘人'",
  "title: '首页图片'",
  "title: '家庭存储'",
  "title: '同步中心'",
  "title: '应用'",
  "Text('版本')",
  'this.VersionInfoCard()',
  'this.DeveloperDiagnosticsCard()'
].forEach((marker) => requireIncludes(myPageSource, marker, 'MyPage missing settings-first marker'));

[
  "subtitle: '复盘身份、存储同步和应用状态。'",
  "description: '影响新建复盘、导出和家庭存储连接。'",
  "subtitle: ''",
  "description: ''",
  'Text(\'\')',
  'Text("")',
  'Blank()',
  'Spacer()',
  'minHeight',
  'top: AppMetrics.sectionGap'
].forEach((marker) => forbidIncludes(myPageSource, marker, 'MyPage must not keep explanatory page or section copy'));

[
  'this.IdentityCard()',
  '@Builder\n  IdentityCard()',
  "Text('当前复盘人')",
  "Text('累计复盘')",
  "Text('成立记录')",
  'ReviewCardHistoryService',
  'ReviewProjectService',
  'ReviewCardHistoryItem',
  'reviewCount',
  'validReviewCount',
  'resolveReviewCountSummary',
  'resolveProfileName',
  'dataLoadFailed'
].forEach((marker) => forbidIncludes(myPageSource, marker, 'MyPage must not duplicate profile/stat card'));

assert(myPageSource.indexOf('this.SettingsSection()') < myPageSource.indexOf('this.AboutSection()'),
  'MyPage should show settings before app section.');
assert(myPageSource.includes('Scroll() {'), 'MyPage must keep scroll ability.');
assert(myPageSource.includes('const MY_PAGE_TITLE_CONTENT_GAP: number = AppMetrics.space10;'), 'MyPage title-to-settings gap must be compact.');
assert(myPageSource.includes('Scroll() {\n        Column() {\n          AppPageHeader({'), 'MyPage title must live in the same scroll content flow as settings.');
assert(myPageSource.includes('.margin({ top: MY_PAGE_TITLE_CONTENT_GAP })'), 'MyPage settings content must sit directly below the title with compact spacing.');
assert(myPageSource.includes('top: AppMetrics.pageTopPadding'), 'MyPage scroll content must keep the normal page top padding.');
assert(myPageSource.includes('bottom: MY_PAGE_BOTTOM_PADDING'), 'MyPage content must keep bottom padding for tab bar.');
assert(myPageSource.includes(".height('100%')"), 'MyPage scroll region must fill the page content height.');
assert(myPageSource.includes('.justifyContent(FlexAlign.Start)'), 'MyPage scroll content must stay pinned to the top.');
assert(myPageSource.includes('router.pushUrl({ url: REVIEWER_PROFILE_PAGE });'), 'Reviewer profile entry navigation must remain.');
assert(myPageSource.includes('router.pushUrl({ url: HOME_HERO_IMAGE_PAGE });'), 'Home hero entry navigation must remain.');
assert(myPageSource.includes('router.pushUrl({ url: HOME_STORAGE_PAGE });'), 'Home storage entry navigation must remain.');
assert(myPageSource.includes('router.pushUrl({ url: SYNC_CENTER_PAGE });'), 'Sync center entry navigation must remain.');
assert(myPageSource.includes('HomeHeroImageService.listImages'), 'Home hero image status must remain visible in MyPage.');
assert(myPageSource.includes('HomeStorageService.resolveEntryStatusLabel'), 'Home storage status mapping must remain visible in MyPage.');

[
  "AppPageHeader({\n          title: '统计'",
  'ReviewCardHistoryService.load(this.getAbilityContext())',
  'ReviewProjectService.buildStatsFeedback(items)',
  'OverviewCard()',
  '.fontSize(AppTypography.statNumber)',
  'this.OverviewMetric(',
  'resolveDistributionProgressWidth',
  'resolveRecentReviewOpacity'
].forEach((marker) => requireIncludes(statsPageSource, marker, 'StatsPage must keep review statistics'));

[
  "label: '首页', activeIcon:",
  "label: '复盘库', activeIcon:",
  "label: '统计', activeIcon:",
  "label: '我的', activeIcon:",
  'MyPage({ refreshToken: this.myRefreshToken + this.reviewLibraryRefreshToken + this.settingsRefreshToken })'
].forEach((marker) => requireIncludes(appShellSource, marker, 'Bottom tab or MyPage refresh wiring changed unexpectedly'));

requireIncludes(homeHeroPageSource, "title: '首页图片'", 'Home hero config page must remain registered and reachable');
requireIncludes(homeStoragePageSource, 'StatusSummary()', 'Home storage page must remain intact');

if (failed) {
  process.exit(1);
}

console.log('my page information architecture verified: no identity stats card, settings entries first, stats stay in StatsPage, tab clearance intact');
