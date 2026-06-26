import fs from 'node:fs';

const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const reviewerProfileSource = fs.readFileSync('entry/src/main/ets/pages/ReviewerProfilePage.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const syncCenterSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');

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

assert(appDesignSource.includes('export struct SettingsPageHeader'), 'Shared settings page header must exist.');
assert(appDesignSource.includes('export struct SettingsSectionHeader'), 'Shared settings section header must exist.');
assert(appDesignSource.includes('export struct SettingsLinkRow'), 'Shared settings link row must exist.');
assert(!appDesignSource.includes("Button('‹')"), 'SettingsPageHeader must not render a back arrow.');
assert(!appDesignSource.includes('showBack'), 'SettingsPageHeader must not expose back-arrow controls.');
assert(settingsPageHeaderBody.includes('.fontSize(AppTypography.sectionTitle)'), 'SettingsPageHeader title must keep compact section title scale for settings subpages.');
assert(!settingsPageHeaderBody.includes('.fontSize(AppTypography.pageTitle)'), 'SettingsPageHeader must not use full page title scale for settings subpages.');
assert(!appDesignSource.includes('.stateEffect(true)\n    .onClick(() => {\n      this.onTap();'), 'SettingsLinkRow must not use unsupported Row stateEffect.');

assert(myPageSource.includes('AppPageHeader({'), 'MyPage root title must use the shared main page header.');
assert(myPageSource.includes("title: '我的'"), 'MyPage must keep the 我的 title.');
assert(!myPageSource.includes('SettingsPageHeader({\n          title: \'我的\''), 'MyPage root title must not use compact settings header.');
assert(myPageSource.includes('Scroll() {\n        Column({ space: AppMetrics.sectionGap }) {'), 'MyPage content must scroll below a fixed title header.');
assert(myPageSource.includes('top: AppMetrics.sectionGap'), 'MyPage scroll content should start below the fixed title with section spacing.');
assert(myPageSource.includes('this.IdentityCard()'), 'MyPage must keep a concise identity card.');
assert(myPageSource.includes('this.SettingsSection()'), 'MyPage must group settings entries.');
assert(myPageSource.includes('this.AboutSection()'), 'MyPage must group app/developer entries.');
assert(myPageSource.includes("title: '复盘人'"), 'MyPage must expose reviewer profile entry.');
assert(myPageSource.includes("title: '家庭存储'"), 'MyPage must expose home storage entry.');
assert(myPageSource.includes("title: '同步中心'"), 'MyPage must expose sync center entry.');
assert(myPageSource.includes("title: '开发诊断'"), 'MyPage must keep diagnostics as a weak developer entry.');
assert(myPageSource.includes('运行开发诊断？'), 'Developer diagnostics must require confirmation.');
assert(!myPageSource.includes('this.LinkRow('), 'MyPage should use SettingsLinkRow instead of the old local row.');

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

assert(reviewerProfileSource.includes('当前状态'), 'ReviewerProfilePage must show current state before editing.');
assert(reviewerProfileSource.includes('复盘人只影响应用内展示和导出的复盘数据。'), 'ReviewerProfilePage must explain setting scope.');
assert(reviewerProfileSource.includes("label: this.isSaving ? '保存中…' : '保存'"), 'ReviewerProfilePage save button must show loading state.');

assert(homeStorageSource.includes('StatusSummary()'), 'HomeStoragePage must show a status summary.');
assert(homeStorageSource.includes('连接信息'), 'HomeStoragePage must group connection fields.');
assert(homeStorageSource.includes("primaryLabel: this.isSaving ? '保存中…' : '保存'"), 'HomeStoragePage save action must show loading state.');
assert(homeStorageSource.includes("secondaryLabel: this.isTestingHomeStorage ? '测试中…' : '测试'"), 'HomeStoragePage test action must show loading state.');

assert(syncCenterSource.includes('lastTestMessage'), 'SyncCenterPage must keep visible test feedback.');
assert(syncCenterSource.includes("label: this.isTesting ? '测试中…' : '测试连接'"), 'SyncCenterPage test button must show loading state.');
assert(syncCenterSource.includes('SettingsLinkRow({'), 'SyncCenterPage must show a compact status row.');
assert(!homeStorageSource.includes(".height('100%')\n      .justifyContent(FlexAlign.Start)"), 'HomeStoragePage scroll content must not be fixed to viewport height.');

if (failed) {
  process.exit(1);
}

console.log('my page rework: fixed main title, grouped entries, no back arrows, top alignment, and deep feedback verified');
