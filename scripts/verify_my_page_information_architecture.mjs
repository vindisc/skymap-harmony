import fs from 'node:fs';

const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const appearanceSource = fs.readFileSync('entry/src/main/ets/pages/AppearanceSettingsPage.ets', 'utf8');
const backupSource = fs.readFileSync('entry/src/main/ets/pages/BackupCenterPage.ets', 'utf8');
const statsPageSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const homeStoragePageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const appRouterSource = fs.readFileSync('entry/src/main/ets/app/AppRouter.ets', 'utf8');
const mainPagesSource = fs.readFileSync('entry/src/main/resources/base/profile/main_pages.json', 'utf8');

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

function countOccurrences(source, marker) {
  return source.split(marker).length - 1;
}

[
  "AppPageHeader({ title: '我的' })",
  "title: '复盘人'",
  'status: this.resolveReviewerSummary()',
  "title: '外观与动效'",
  "title: '家庭存储'",
  "title: '同步中心'",
  "title: '备份与恢复'",
  "Text('关于')",
  'this.DeveloperDiagnosticsCard()'
].forEach((marker) => requireIncludes(myPageSource, marker, 'MyPage 缺少 V4 顶层信息架构'));

const topLevelSettingsRows = countOccurrences(myPageSource, 'this.RippleSettingsLinkRow({');
assert(topLevelSettingsRows <= 5, `MyPage 顶层设置行不得超过 5 条，当前为 ${topLevelSettingsRows}。`);
assert(topLevelSettingsRows === 5, `MyPage 应保留复盘人、外观、家庭存储、同步和备份 5 个入口，当前为 ${topLevelSettingsRows}。`);
const myPageLineCount = myPageSource.trimEnd().split('\n').length;
assert(myPageLineCount <= 500, `MyPage 必须收敛到 500 行以内，当前为 ${myPageLineCount} 行。`);
assert(myPageSource.indexOf("title: '我的'") < myPageSource.indexOf('Scroll() {'),
  'MyPage 固定标题必须位于滚动内容之前。');
assert(myPageSource.indexOf('this.SettingsSection()') < myPageSource.indexOf('this.AboutSection()'),
  'MyPage 应先显示设置入口，再显示关于信息。');
assert(myPageSource.includes('bottom: MY_PAGE_BOTTOM_PADDING'), 'MyPage 必须为底部标签栏预留空间。');
assert(myPageSource.includes('.layoutWeight(1)'), 'MyPage 滚动区必须填充标题下方空间。');
assert(!myPageSource.includes('List()'), 'MyPage 不得恢复会拉大稀疏间距的顶层 List。');
assert(!myPageSource.includes('ReviewerCardContent'), 'MyPage 不得恢复独立复盘人身份卡内容。');
assert(!myPageSource.includes('ReviewerCard()'), 'MyPage 不得恢复独立复盘人身份卡。');
assert(!(myPageSource.includes('backgroundColor(AppColors.primarySoft)') &&
  myPageSource.includes('border({ width: 1, color: AppColors.primary })')),
  'MyPage 不得恢复蓝底蓝框复盘人身份卡样式。');

[
  'HOME_HERO_IMAGE_PAGE',
  'WIDGET_CARD_BACKGROUND_PAGE',
  'HomeHeroImageService.listImages',
  'saveShatterAnimationEnabled',
  "title: '备份全部复盘'",
  "title: '从备份恢复'",
  'ReviewLibraryBackupService.exportToUserFile',
  'ReviewLibraryBackupService.restoreInspectedBackup'
].forEach((marker) => forbidIncludes(myPageSource, marker, 'MyPage 不得重复承载已下沉功能'));

[
  "SettingsPageHeader({ title: '外观与动效' })",
  "title: '首页图片'",
  "title: '卡片背景'",
  "title: '显示与动效'",
  "Text('删除星河效果')",
  'Toggle({ type: ToggleType.Switch, isOn: this.shatterAnimationEnabled })',
  'ReviewSettingsService.saveShatterAnimationEnabled',
  'HOME_HERO_IMAGE_PAGE',
  'WIDGET_CARD_BACKGROUND_PAGE',
  'MOTION_SETTINGS_PAGE',
  'clipRadius: AppMetrics.cardRadius'
].forEach((marker) => requireIncludes(appearanceSource, marker, '外观与动效页缺少迁移功能'));

[
  "SettingsPageHeader({ title: '备份与恢复' })",
  "title: '备份全部复盘'",
  "title: '从备份恢复'",
  'ReviewLibraryBackupService.exportToUserFile',
  'ReviewLibraryBackupService.selectAndInspectBackup',
  'ReviewLibraryBackupService.restoreInspectedBackup',
  'clipRadius: AppMetrics.cardRadius'
].forEach((marker) => requireIncludes(backupSource, marker, '备份与恢复页缺少迁移功能'));

[
  "export const APPEARANCE_SETTINGS_PAGE: string = 'pages/AppearanceSettingsPage';",
  "export const BACKUP_CENTER_PAGE: string = 'pages/BackupCenterPage';"
].forEach((marker) => requireIncludes(appRouterSource, marker, 'AppRouter 缺少 V4 页面路由'));
[
  '"pages/AppearanceSettingsPage"',
  '"pages/BackupCenterPage"'
].forEach((marker) => requireIncludes(mainPagesSource, marker, 'main_pages.json 缺少 V4 页面注册'));

[
  'this.IdentityCard()',
  "Text('当前复盘人')",
  "Text('累计复盘')",
  "Text('成立记录')",
  'ReviewCardHistoryService',
  'ReviewProjectService'
].forEach((marker) => forbidIncludes(myPageSource, marker, 'MyPage 不得恢复身份统计卡'));

[
  "title: '统计'",
  'LearningProgressService.loadWithReviewItems(context)',
  'OverviewCard()'
].forEach((marker) => requireIncludes(statsPageSource, marker, 'StatsPage 必须保留复盘统计'));
requireIncludes(appShellSource,
  'MyPage({ refreshToken: this.myRefreshToken + this.reviewLibraryRefreshToken + this.settingsRefreshToken })',
  '底部标签栏必须保持 MyPage 刷新链路');
requireIncludes(homeStoragePageSource, 'InlineStatusBanner({', '家庭存储页必须保留表单内状态反馈');

if (failed) {
  process.exit(1);
}

console.log('my page information architecture verified: compact V5 settings rows, routed secondary pages and migrated actions');
