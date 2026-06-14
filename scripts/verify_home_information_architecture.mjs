import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const libraryPageSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const syncCenterPageSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');
const reviewerProfilePageSource = fs.readFileSync('entry/src/main/ets/pages/ReviewerProfilePage.ets', 'utf8');
const homeStoragePageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const appRouterSource = fs.readFileSync('entry/src/main/ets/app/AppRouter.ets', 'utf8');
const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const mainPagesSource = fs.readFileSync('entry/src/main/resources/base/profile/main_pages.json', 'utf8');

let failed = false;

const requiredTypographyTokens = [
  'static readonly pageTitle: number = TypographyTokens.PageTitle;',
  'static readonly pageSubtitle: number = TypographyTokens.PageSubtitle;',
  'static readonly sectionTitle: number = TypographyTokens.SectionTitle;',
  'static readonly cardTitle: number = TypographyTokens.CardTitle;',
  'static readonly body: number = TypographyTokens.CardBody;'
];

for (const marker of requiredTypographyTokens) {
  if (!appDesignSource.includes(marker)) {
    failed = true;
    console.error(`Design System V1 typography token missing: ${marker}`);
  }
}

const forbiddenLegacySpacingTokens = [
  'static readonly space4:',
  'static readonly space12:',
  'AppMetrics.space4',
  'AppMetrics.space12'
];

for (const marker of forbiddenLegacySpacingTokens) {
  if (appDesignSource.includes(marker) ||
    homePageSource.includes(marker) ||
    libraryPageSource.includes(marker) ||
    myPageSource.includes(marker) ||
    reviewerProfilePageSource.includes(marker) ||
    homeStoragePageSource.includes(marker) ||
    syncCenterPageSource.includes(marker)) {
    failed = true;
    console.error(`Primary pages must use the 8pt Design System V1 spacing scale, found: ${marker}`);
  }
}

const requiredHomeSections = [
  "title: '摄影复盘'",
  "Text('开始新的复盘')",
  "Text('最近一次')",
  "Text('复盘概览')",
  "Text('当前状态')"
];

for (const marker of requiredHomeSections) {
  if (!homePageSource.includes(marker)) {
    failed = true;
    console.error(`HomePage missing fixed section: ${marker}`);
  }
}

if (homePageSource.indexOf('this.StartReviewPanel()') > homePageSource.indexOf('this.GrowthStatsPanel()')) {
  failed = true;
  console.error('HomePage must render start action before stats overview.');
}

const forbiddenTabText = [
  "label: '首'",
  "label: '库'",
  "label: '我'",
  "symbol: '首'",
  "symbol: '库'",
  "symbol: '我'",
  "icon: '●'",
  "icon: '■'",
  "icon: '◆'"
];

for (const marker of forbiddenTabText) {
  if (appShellSource.includes(marker)) {
    failed = true;
    console.error(`AppShellPage must not render debug-style tab text: ${marker}`);
  }
}

const requiredTabIcons = [
  "label: '首页', activeIcon:",
  "label: '复盘库', activeIcon:",
  "label: '我的', activeIcon:",
  'Image(this.isCurrentTab(item.key) ? item.activeIcon : item.inactiveIcon)'
];

for (const marker of requiredTabIcons) {
  if (!appShellSource.includes(marker)) {
    failed = true;
    console.error(`AppShellPage missing tab icon marker: ${marker}`);
  }
}

if (!myPageSource.includes('top: AppMetrics.pageTopPadding') ||
  !libraryPageSource.includes('top: AppMetrics.pageTopPadding') ||
  !homePageSource.includes('top: AppMetrics.pageTopPadding')) {
  failed = true;
  console.error('Home, library, and my pages must use the shared Design System top padding.');
}

if (!myPageSource.includes("title: '我的'") ||
  !myPageSource.includes("subtitle: '管理复盘人、家庭存储和版本信息'") ||
  !myPageSource.includes('this.IdentityCard()') ||
  !myPageSource.includes("this.LinkRow('复盘人'") ||
  !myPageSource.includes("'家庭存储',") ||
  !myPageSource.includes("this.LinkRow('关于'")) {
  failed = true;
  console.error('MyPage must keep the personal-center structure.');
}

const topAlignedPageSources = [
  ['HomePage', homePageSource],
  ['ProjectDetailPage', libraryPageSource],
  ['MyPage', myPageSource],
  ['ReviewerProfilePage', reviewerProfilePageSource],
  ['HomeStoragePage', homeStoragePageSource],
  ['SyncCenterPage', syncCenterPageSource]
];

for (const [pageName, source] of topAlignedPageSources) {
  if (source.includes('.justifyContent(FlexAlign.Center)')) {
    failed = true;
    console.error(`${pageName} must not vertically center first-level page content.`);
  }
}

if (!previewPageSource.includes("this.ActionButton('编辑', false, this.isActionBusy(), () => {")) {
  failed = true;
  console.error('PreviewPage must keep 编辑 as a top-level action.');
}

if (!previewPageSource.includes("this.ActionButton(this.isExporting ? '导出中' : '导出', true, this.isActionBusy(), () => {")) {
  failed = true;
  console.error('PreviewPage must keep 导出 as the single top-level export action.');
}

const disallowedTopLevelActions = [
  "this.ActionButton('导出 review.json'",
  "this.ActionButton('复制复盘数据'",
  "this.ActionButton(this.isUploadingHomeStorage ? '上传中' : '上传到家庭存储'"
];

for (const marker of disallowedTopLevelActions) {
  if (previewPageSource.includes(marker)) {
    failed = true;
    console.error(`PreviewPage still exposes deprecated top-level action: ${marker}`);
  }
}

const requiredExportSheetActions = [
  "this.ExportSheetAction('导出 review.json'",
  "this.ExportSheetAction(this.isUploadingHomeStorage ? '上传到家庭存储中...' : '上传到家庭存储'",
  "this.ExportSheetAction(this.isExporting ? '导出复盘图片中...' : '导出复盘图片'",
  "this.ExportSheetAction('复制复盘数据'"
];

for (const marker of requiredExportSheetActions) {
  if (!previewPageSource.includes(marker)) {
    failed = true;
    console.error(`PreviewPage export sheet missing action: ${marker}`);
  }
}

for (let index = 1; index < requiredExportSheetActions.length; index += 1) {
  const previousMarker = requiredExportSheetActions[index - 1];
  const currentMarker = requiredExportSheetActions[index];
  if (previewPageSource.indexOf(previousMarker) > previewPageSource.indexOf(currentMarker)) {
    failed = true;
    console.error('PreviewPage export sheet actions must be ordered by expected use frequency.');
  }
}

if (!syncCenterPageSource.includes("title: '同步中心'")) {
  failed = true;
  console.error('SyncCenterPage title is missing.');
}

if (!syncCenterPageSource.includes("Button(this.isTesting ? '测试中...' : '测试连接')")) {
  failed = true;
  console.error('SyncCenterPage must provide 测试连接.');
}

if (!syncCenterPageSource.includes("label: '进入配置'")) {
  failed = true;
  console.error('SyncCenterPage must provide 进入配置.');
}

if (!appRouterSource.includes("export const SYNC_CENTER_PAGE: string = 'pages/SyncCenterPage';")) {
  failed = true;
  console.error('AppRouter missing SyncCenterPage route.');
}

if (!mainPagesSource.includes('"pages/SyncCenterPage"')) {
  failed = true;
  console.error('main_pages.json missing SyncCenterPage registration.');
}

if (failed) {
  process.exit(1);
}

console.log('home information architecture verified: fixed tabs, home sections, sync center, export entry consolidated');
