import fs from 'node:fs';

const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const reviewerProfileSource = fs.readFileSync('entry/src/main/ets/pages/ReviewerProfilePage.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const syncCenterSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');
const appearanceSource = fs.readFileSync('entry/src/main/ets/pages/AppearanceSettingsPage.ets', 'utf8');
const backupSource = fs.readFileSync('entry/src/main/ets/pages/BackupCenterPage.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function extractStructBody(source, structName) {
  const signature = `export struct ${structName}`;
  const start = source.indexOf(signature);
  if (start < 0) {
    return '';
  }
  const bodyStart = source.indexOf('{', start);
  if (bodyStart < 0) {
    return '';
  }
  let depth = 0;
  for (let index = bodyStart; index < source.length; index += 1) {
    const char = source[index];
    if (char === '{') {
      depth += 1;
    } else if (char === '}') {
      depth -= 1;
      if (depth === 0) {
        return source.slice(bodyStart, index + 1);
      }
    }
  }
  return '';
}

const settingsPageHeaderBody = extractStructBody(appDesignSource, 'SettingsPageHeader');
const settingsScrollContainerBody = extractStructBody(appDesignSource, 'SettingsScrollContainer');

assert(appDesignSource.includes('export struct SettingsPageHeader'), 'Shared settings page header must exist.');
assert(appDesignSource.includes('export struct SettingsSectionHeader'), 'Shared settings section header must exist.');
assert(appDesignSource.includes('export struct SettingsLinkRow'), 'Shared settings link row must exist.');
assert(appDesignSource.includes('export struct SettingsScrollContainer'), 'Shared settings scroll container must exist.');
assert(settingsScrollContainerBody.includes(".constraintSize({ minHeight: '100%' })"), 'SettingsScrollContainer must fill the viewport height.');
assert(settingsScrollContainerBody.includes('.justifyContent(FlexAlign.Start)'), 'SettingsScrollContainer must pin content to the top.');
assert(!appDesignSource.includes("Button('‹')"), 'SettingsPageHeader must not render a back arrow.');
assert(!appDesignSource.includes('showBack'), 'SettingsPageHeader must not expose back-arrow controls.');
assert(settingsPageHeaderBody.includes('.fontSize(AppTypography.sectionTitle)'), 'SettingsPageHeader title must keep compact section title scale for settings subpages.');
assert(!settingsPageHeaderBody.includes('.fontSize(AppTypography.pageTitle)'), 'SettingsPageHeader must not use full page title scale for settings subpages.');
assert(!appDesignSource.includes('.stateEffect(true)\n    .onClick(() => {\n      this.onTap();'), 'SettingsLinkRow must not use unsupported Row stateEffect.');

assert(myPageSource.includes('AppPageHeader({'), 'MyPage root title must use the shared main page header.');
assert(myPageSource.includes("title: '我的'"), 'MyPage must keep the 我的 title.');
assert(!myPageSource.includes("subtitle: '复盘身份、存储同步和应用状态。'"), 'MyPage must not keep the old explanatory subtitle.');
assert(!myPageSource.includes("description: '影响新建复盘、导出和家庭存储连接。'"), 'MyPage settings section must not keep explanatory description.');
assert(!myPageSource.includes("subtitle: ''"), 'MyPage must not pass an empty subtitle prop.');
assert(!myPageSource.includes("description: ''"), 'MyPage must not pass an empty section description prop.');
assert(!myPageSource.includes('Blank()'), 'MyPage must not use Blank as a hidden subtitle placeholder.');
assert(!myPageSource.includes('Spacer()'), 'MyPage must not use Spacer as a hidden subtitle placeholder.');
assert(!myPageSource.includes('SettingsPageHeader({\n          title: \'我的\''), 'MyPage root title must not use compact settings header.');
assert(myPageSource.includes("Column() {\n      AppPageHeader({ title: '我的' })"), 'MyPage title must stay fixed above the scroll content.');
assert(myPageSource.indexOf("title: '我的'") < myPageSource.indexOf('Scroll() {'), 'MyPage fixed title must precede the scroll region.');
assert(myPageSource.includes('Column({ space: AppMetrics.sectionGap }) {\n          this.SettingsSection()'), 'MyPage settings and app sections must keep section spacing.');
assert(myPageSource.includes('const MY_PAGE_TITLE_CONTENT_GAP: number = AppMetrics.space10;'), 'MyPage should define a compact title-to-content gap.');
assert(myPageSource.includes('bottom: MY_PAGE_TITLE_CONTENT_GAP'), 'MyPage fixed title should keep a compact bottom gap.');
assert(!myPageSource.includes('top: AppMetrics.sectionGap'), 'MyPage must not keep the old large title-to-content gap.');
assert(myPageSource.indexOf('this.SettingsSection()') < myPageSource.indexOf('this.AboutSection()'), 'MyPage settings section must appear before app section.');
assert(!myPageSource.includes('this.IdentityCard()'), 'MyPage must not render the old identity card.');
assert(!myPageSource.includes("@Builder\n  IdentityCard()"), 'MyPage must remove the unused identity card builder.');
assert(!myPageSource.includes("Text('当前复盘人')"), 'MyPage must not show 当前复盘人.');
assert(!myPageSource.includes("Text('累计复盘')"), 'MyPage must not show 累计复盘.');
assert(!myPageSource.includes("Text('成立记录')"), 'MyPage must not show 成立记录.');
assert(!myPageSource.includes('ReviewCardHistoryService'), 'MyPage must not load review history for profile stats.');
assert(!myPageSource.includes('ReviewProjectService'), 'MyPage must not calculate review stats.');
assert(!myPageSource.includes('reviewCount'), 'MyPage must not keep reviewCount state.');
assert(!myPageSource.includes('validReviewCount'), 'MyPage must not keep validReviewCount state.');
assert(myPageSource.includes('this.SettingsSection()'), 'MyPage must group settings entries.');
assert(myPageSource.includes('this.AboutSection()'), 'MyPage must group app/developer entries.');
assert(myPageSource.includes("title: '复盘人'"), 'MyPage must expose the reviewer settings entry.');
assert(myPageSource.includes('status: this.resolveReviewerSummary()'), 'MyPage reviewer entry must keep its current status.');
assert(!myPageSource.includes('ReviewerCard()'), 'MyPage must not restore the separate reviewer identity card.');
assert(myPageSource.includes("title: '外观与动效'"), 'MyPage must expose appearance settings entry.');
assert(myPageSource.includes('this.openPage(APPEARANCE_SETTINGS_PAGE'), 'MyPage appearance entry must keep navigation.');
assert(myPageSource.includes("title: '家庭存储'"), 'MyPage must expose home storage entry.');
assert(myPageSource.includes("title: '同步中心'"), 'MyPage must expose sync center entry.');
assert(myPageSource.includes("title: '备份与恢复'"), 'MyPage must expose backup center entry.');
assert(!myPageSource.includes("title: '首页图片'"), 'MyPage must not duplicate secondary appearance settings.');
assert(!myPageSource.includes("title: '备份全部复盘'"), 'MyPage must not duplicate backup actions.');
assert(myPageSource.includes('@Builder\n  DeveloperDiagnosticsCard()'), 'MyPage must keep diagnostics as a weak developer entry.');
assert(myPageSource.includes("Text('开发诊断')"), 'MyPage must keep diagnostics as a weak developer entry.');
assert(myPageSource.includes('运行开发诊断？'), 'Developer diagnostics must require confirmation.');
assert(!myPageSource.includes('this.LinkRow('), 'MyPage should use SettingsLinkRow instead of the old local row.');
assert(myPageSource.includes('bottom: MY_PAGE_BOTTOM_PADDING'), 'MyPage scroll content must keep bottom padding for the tab bar.');
assert(myPageSource.includes('.layoutWeight(1)'), 'MyPage scroll region must fill the remaining page height.');
assert(myPageSource.includes('.justifyContent(FlexAlign.Start)'), 'MyPage scroll content must stay pinned to the top.');

for (const [name, source] of [
  ['ReviewerProfilePage', reviewerProfileSource],
  ['HomeStoragePage', homeStorageSource],
  ['SyncCenterPage', syncCenterSource]
]) {
  assert(source.includes('SettingsPageHeader({'), `${name} must use shared settings header.`);
  assert(!source.includes('showBack: true'), `${name} must not show a back arrow.`);
  assert(!source.includes('router.back()'), `${name} must not wire a custom back arrow.`);
  assert(source.includes('.justifyContent(FlexAlign.Start)'), `${name} must pin content to the top.`);
  assert(!source.includes('.justifyContent(FlexAlign.Center)'), `${name} must not vertically center content.`);
}

for (const [name, source] of [
  ['AppearanceSettingsPage', appearanceSource],
  ['BackupCenterPage', backupSource]
]) {
  assert(source.includes('SettingsPageHeader({'), `${name} must use shared settings header.`);
  assert(source.includes('SettingsScrollContainer({'), `${name} must use the shared top-aligned scroll container.`);
  assert(!source.includes('showBack: true'), `${name} must not show a back arrow.`);
  assert(!source.includes('router.back()'), `${name} must not wire a custom back arrow.`);
  assert(!source.includes('.justifyContent(FlexAlign.Center)'), `${name} must not vertically center content.`);
}

assert(reviewerProfileSource.includes("title: '复盘人'"), 'ReviewerProfilePage must keep its compact settings title.');
assert(!reviewerProfileSource.includes('this.resolvePreviewName()'), 'ReviewerProfilePage must not keep the redundant preview card before editing.');
assert(reviewerProfileSource.includes("primaryLabel: this.isSaving ? '保存中…' : '保存'"), 'ReviewerProfilePage save button must show loading state.');

assert(homeStorageSource.includes('InlineStatusBanner({'), 'HomeStoragePage must show inline banner feedback at form top.');
assert(!homeStorageSource.includes('StatusSummary()'), 'HomeStoragePage must not show the redundant status summary.');
assert(homeStorageSource.includes("'家庭存储地址'"), 'HomeStoragePage must keep connection fields.');
assert(homeStorageSource.includes("primaryLabel: this.isSaving ? '保存中…' : '保存'"), 'HomeStoragePage save action must show loading state.');
assert(homeStorageSource.includes("secondaryLabel: this.isTestingHomeStorage ? '检查中…' : '检查'"), 'HomeStoragePage check action must show loading state.');

assert(syncCenterSource.includes('lastTestMessage'), 'SyncCenterPage must keep visible test feedback.');
assert(syncCenterSource.includes("secondaryLabel: this.isTesting ? '检查中…' : '检查家庭存储'"), 'SyncCenterPage test button must show loading state.');
assert(!syncCenterSource.includes('SettingsLinkRow({'), 'SyncCenterPage must not repeat status above the detail card.');
assert(!homeStorageSource.includes(".height('100%')\n      .justifyContent(FlexAlign.Start)"), 'HomeStoragePage scroll content must not be fixed to viewport height.');

assert(appearanceSource.includes("title: '首页图片'"), 'AppearanceSettingsPage must keep the home hero entry.');
assert(appearanceSource.includes("title: '卡片背景'"), 'AppearanceSettingsPage must keep the widget background entry.');
assert(appearanceSource.includes("title: '显示与动效'"), 'AppearanceSettingsPage must keep the motion settings entry.');
assert(appearanceSource.includes("Text('删除星河效果')"), 'AppearanceSettingsPage must keep the shatter toggle.');
assert(backupSource.includes("title: '备份全部复盘'"), 'BackupCenterPage must keep the export action.');
assert(backupSource.includes("title: '从备份恢复'"), 'BackupCenterPage must keep the restore action.');

if (failed) {
  process.exit(1);
}

console.log('my page rework: unified reviewer row, compact V5 aggregation, routed settings and deep feedback verified');
