import fs from 'node:fs';

const sources = {
  homeStorage: fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8'),
  homeStorageService: fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8'),
  settingsForm: fs.readFileSync('entry/src/main/ets/components/SettingsForm.ets', 'utf8'),
  smbClient: fs.readFileSync('entry/src/main/ets/services/Smb2Client.ets', 'utf8'),
  exportService: fs.readFileSync('entry/src/main/ets/services/ReviewCardExportService.ets', 'utf8'),
  stats: fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8'),
  reviewer: fs.readFileSync('entry/src/main/ets/pages/ReviewerProfilePage.ets', 'utf8'),
  homeHero: fs.readFileSync('entry/src/main/ets/pages/HomeHeroImagePage.ets', 'utf8'),
  widgetCardBackground: fs.readFileSync('entry/src/main/ets/pages/WidgetCardBackgroundPage.ets', 'utf8'),
  syncCenter: fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8')
};

let failed = false;

function requireIncludes(source, marker, label) {
  if (!source.includes(marker)) {
    failed = true;
    console.error(`${label} missing marker: ${marker}`);
  }
}

function forbidIncludes(source, marker, label) {
  if (source.includes(marker)) {
    failed = true;
    console.error(`${label} must not include marker: ${marker}`);
  }
}

requireIncludes(sources.smbClient, 'async uploadFile(options: Smb2UploadFileOptions): Promise<string>', 'Smb2Client');
requireIncludes(sources.smbClient, 'private async writeFileFromPath(fileId: Array<number>, localPath: string, byteSize: number): Promise<void>', 'Smb2Client');
requireIncludes(sources.homeStorageService, 'client.uploadFile(createSmbUploadFileOptions(', 'HomeStorageService');
forbidIncludes(sources.homeStorageService, 'readLocalFileBytes(localPath)', 'HomeStorageService');
requireIncludes(sources.exportService, 'await packer.release();', 'ReviewCardExportService');
forbidIncludes(sources.exportService, 'BUNDLE_REVIEW_CARD_MIME_TYPE', 'ReviewCardExportService');
forbidIncludes(sources.exportService, 'image/png', 'ReviewCardExportService');

requireIncludes(sources.stats, 'build() {\n    Scroll() {', 'StatsPage');
requireIncludes(sources.stats, 'const STATS_PAGE_TOP_PADDING: number = AppMetrics.pageTopPadding - AppMetrics.space8;', 'StatsPage fixed top padding');
requireIncludes(sources.stats, 'top: STATS_PAGE_TOP_PADDING', 'StatsPage fixed top padding');
requireIncludes(sources.stats, ".height('100%')\n      .justifyContent(FlexAlign.Start)", 'StatsPage top alignment');
forbidIncludes(sources.stats, '.layoutWeight(1)\n      .scrollBar(BarState.Off)\n      .edgeEffect(EdgeEffect.Spring)', 'StatsPage fixed lower scroll');

requireIncludes(sources.homeStorage, 'CenterFeedbackOverlay()', 'HomeStoragePage');
requireIncludes(sources.homeStorage, 'const SETTINGS_TITLE_FORM_GAP: number = AppMetrics.space8;', 'HomeStoragePage compact title/form gap');
requireIncludes(sources.homeStorage, 'Column({ space: SETTINGS_TITLE_FORM_GAP })', 'HomeStoragePage unified top-aligned scroll content');
requireIncludes(sources.homeStorage, 'const HOME_STORAGE_PAGE_TOP_PADDING: number = 0;', 'HomeStoragePage top-pinned settings content');
requireIncludes(sources.homeStorage, 'const HOME_STORAGE_ROUTE_TOP_COMPENSATION: number = 0 - AppMetrics.space24;', 'HomeStoragePage route top compensation');
requireIncludes(sources.homeStorage, 'top: HOME_STORAGE_PAGE_TOP_PADDING', 'HomeStoragePage top-pinned settings content');
requireIncludes(sources.homeStorage, '.translate({ y: HOME_STORAGE_ROUTE_TOP_COMPENSATION })', 'HomeStoragePage route top compensation');
for (const [name, source] of [
  ['ReviewerProfilePage', sources.reviewer],
  ['HomeHeroImagePage', sources.homeHero],
  ['WidgetCardBackgroundPage', sources.widgetCardBackground],
  ['SyncCenterPage', sources.syncCenter]
]) {
  requireIncludes(source, 'top: AppMetrics.pageTopPadding', `${name} must keep normal settings subpage top padding`);
  forbidIncludes(source, 'settingsSubpageTopCompensation', `${name} must not use home-storage top compensation`);
}
requireIncludes(sources.homeStorage, 'bottom: this.getSettingsBottomPadding()', 'HomeStoragePage bottom action clearance');
requireIncludes(sources.homeStorage, 'Scroll(this.settingsScroller)', 'HomeStoragePage unified scroll');
forbidIncludes(sources.homeStorage, '.layoutWeight(1)', 'HomeStoragePage must not put the form in a remaining-height scroll region');
forbidIncludes(sources.homeStorage, "'家庭存储地址或 IP'", 'HomeStoragePage');
forbidIncludes(sources.homeStorage, 'StatusSummary()', 'HomeStoragePage');
forbidIncludes(sources.homeStorage, "SettingsInput('工作组或域'", 'HomeStoragePage');
forbidIncludes(sources.homeStorage, "SettingsInput('密码或凭据'", 'HomeStoragePage');
requireIncludes(sources.homeStorage, "SettingsInput('密码'", 'HomeStoragePage');
requireIncludes(sources.homeStorageService, "return '请先填写密码';", 'HomeStorageService');

requireIncludes(sources.settingsForm, 'shouldIgnoreToggleEmptyChange', 'SettingsTextInput password toggle guard');
requireIncludes(sources.settingsForm, 'this.shouldIgnoreToggleEmptyChange && value.length === 0 && this.text.length > 0', 'SettingsTextInput password toggle guard');

forbidIncludes(sources.reviewer, 'resolvePreviewName()', 'ReviewerProfilePage');
forbidIncludes(sources.homeHero, "title: '已配置图片'", 'HomeHeroImagePage');
forbidIncludes(sources.homeHero, 'resolveStatusText()', 'HomeHeroImagePage');
forbidIncludes(sources.homeHero, 'SettingsSectionHeader({', 'HomeHeroImagePage');

if (failed) {
  process.exit(1);
}

console.log('release blockers 20260708: export memory, stats empty state, home storage form, reviewer, and home hero cleanup verified');
