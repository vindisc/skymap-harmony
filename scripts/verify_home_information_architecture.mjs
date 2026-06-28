import fs from 'node:fs';

const sources = {
  homePage: fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8'),
  appShell: fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8'),
  myPage: fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8'),
  libraryPage: fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8'),
  previewPage: fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8'),
  syncCenterPage: fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8'),
  reviewerProfilePage: fs.readFileSync('entry/src/main/ets/pages/ReviewerProfilePage.ets', 'utf8'),
  homeStoragePage: fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8'),
  appRouter: fs.readFileSync('entry/src/main/ets/app/AppRouter.ets', 'utf8'),
  appDesign: fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8'),
  mainPages: fs.readFileSync('entry/src/main/resources/base/profile/main_pages.json', 'utf8')
};

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

function requireIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    fail(`${message}: ${marker}`);
  }
}

function forbidIncludes(source, marker, message) {
  if (source.includes(marker)) {
    fail(`${message}: ${marker}`);
  }
}

[
  'static readonly pageTitle: number = TypographyTokens.PageTitle;',
  'static readonly pageSubtitle: number = TypographyTokens.PageSubtitle;',
  'static readonly sectionTitle: number = TypographyTokens.SectionTitle;',
  'static readonly cardTitle: number = TypographyTokens.CardTitle;',
  'static readonly body: number = TypographyTokens.CardBody;'
].forEach((marker) => requireIncludes(sources.appDesign, marker, 'Design System V1 typography token missing'));

const primaryPageSources = [
  ['HomePage', sources.homePage],
  ['ProjectDetailPage', sources.libraryPage],
  ['MyPage', sources.myPage],
  ['ReviewerProfilePage', sources.reviewerProfilePage],
  ['HomeStoragePage', sources.homeStoragePage],
  ['SyncCenterPage', sources.syncCenterPage]
];

for (const marker of ['static readonly space4:', 'static readonly space12:', 'AppMetrics.space4', 'AppMetrics.space12']) {
  if (sources.appDesign.includes(marker)) {
    fail(`Design system must keep the 8pt spacing scale, found: ${marker}`);
  }
  primaryPageSources.forEach(([pageName, source]) => {
    if (source.includes(marker)) {
      fail(`${pageName} must keep the shared spacing scale, found: ${marker}`);
    }
  });
}

[
  "title: '摄影复盘'",
  "subtitle: '从照片里练习观看与判断'",
  "Text('从一张照片开始，练习判断')",
  "Button(this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '导入照片，开始复盘')",
  '.aspectRatio(HOME_HERO_ASPECT_RATIO)',
  'this.ReviewFlowPanel()',
  'ReviewCardHistoryService.loadWithDiagnostics(context)',
  'pasteboard.createData',
  'HomeHeroImageService.getDisplayImages'
].forEach((marker) => requireIncludes(sources.homePage, marker, 'HomePage missing current information-architecture marker'));

forbidIncludes(sources.homePage, 'ScrollDirection.Vertical', 'HomePage must not make the fixed first screen vertically scrollable');

[
  "label: '首页', activeIcon:",
  "label: '复盘库', activeIcon:",
  "label: '统计', activeIcon:",
  "label: '我的', activeIcon:",
  'Image(this.isCurrentTab(item.key) ? item.activeIcon : item.inactiveIcon)',
  'HomePage({ refreshToken: this.homeRefreshToken + this.reviewLibraryRefreshToken })',
  'MyPage({ refreshToken: this.myRefreshToken + this.reviewLibraryRefreshToken + this.settingsRefreshToken })'
].forEach((marker) => requireIncludes(sources.appShell, marker, 'AppShellPage missing tab or refresh marker'));

for (const marker of ["label: '首'", "label: '库'", "label: '我'", "icon: '●'", "icon: '■'", "icon: '◆'"]) {
  forbidIncludes(sources.appShell, marker, 'AppShellPage must not render debug-style tab text');
}

[
  "title: '我的'",
  'this.IdentityCard()',
  'this.SettingsSection()',
  'this.AboutSection()',
  "title: '首页图片'",
  'HOME_HERO_IMAGE_PAGE',
  'HomeHeroImageService.listImages',
  'router.pushUrl({ url: HOME_HERO_IMAGE_PAGE });',
  "title: '同步中心'",
  "title: '家庭存储'"
].forEach((marker) => requireIncludes(sources.myPage, marker, 'MyPage missing current personal-center marker'));

[
  'this.HeaderRow()',
  'private resolveResultCountText(): string',
  '.height(AppMetrics.filterChipHeight)',
  ".constraintSize({ minWidth: value === 'all' ? 60 : 72 })",
  "title: '复盘库'"
].forEach((marker) => requireIncludes(sources.libraryPage, marker, 'ProjectDetailPage missing compact library marker'));

[
  "this.ActionButton('编辑', false, this.isActionBusy(), () => {",
  "this.ActionButton(this.isExporting ? REVIEW_FLOW_EXPORT_PENDING_TEXT : '导出', true, this.isActionBusy(), () => {",
  '.height(AppMetrics.toolbarButtonHeight)',
  "this.ExportSheetAction(this.isExporting ? REVIEW_FLOW_EXPORT_PENDING_TEXT : '导出图片'",
  "this.ExportSheetAction(this.isExportingReviewBundle ? '导出中…' : '导出复盘包'",
  "this.ExportSheetAction(this.isExportingReviewJson ? REVIEW_FLOW_EXPORT_PENDING_TEXT : '导出 review.json'",
  "this.ExportSheetAction('复制复盘数据'"
].forEach((marker) => requireIncludes(sources.previewPage, marker, 'PreviewPage missing current export action marker'));

[
  "title: '同步中心'",
  "label: this.isTesting ? '检查中…' : '检查家庭存储'",
  "label: this.resolveStatus() === HomeStorageConfigStatus.COMPLETE ? '修改配置' : '配置'"
].forEach((marker) => requireIncludes(sources.syncCenterPage, marker, 'SyncCenterPage missing current sync-center marker'));

[
  "export const HOME_HERO_IMAGE_PAGE: string = 'pages/HomeHeroImagePage';",
  "export const SYNC_CENTER_PAGE: string = 'pages/SyncCenterPage';"
].forEach((marker) => requireIncludes(sources.appRouter, marker, 'AppRouter missing route'));

[
  '"pages/HomeHeroImagePage"',
  '"pages/SyncCenterPage"'
].forEach((marker) => requireIncludes(sources.mainPages, marker, 'main_pages.json missing registration'));

if (failed) {
  process.exit(1);
}

console.log('home information architecture verified: fixed first screen, tab IA, settings entries, export entry, and home hero config');
