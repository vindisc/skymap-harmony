import fs from 'node:fs';

const sources = {
  homeStorage: fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8'),
  homeStorageService: fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8'),
  settingsForm: fs.readFileSync('entry/src/main/ets/components/SettingsForm.ets', 'utf8'),
  smbClient: fs.readFileSync('entry/src/main/ets/services/Smb2Client.ets', 'utf8'),
  exportService: fs.readFileSync('entry/src/main/ets/services/ReviewCardExportService.ets', 'utf8'),
  stats: fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8'),
  reviewer: fs.readFileSync('entry/src/main/ets/pages/ReviewerProfilePage.ets', 'utf8'),
  homeHero: fs.readFileSync('entry/src/main/ets/pages/HomeHeroImagePage.ets', 'utf8')
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

requireIncludes(sources.stats, 'build() {\n    Scroll() {', 'StatsPage');
forbidIncludes(sources.stats, '.layoutWeight(1)\n      .scrollBar(BarState.Off)\n      .edgeEffect(EdgeEffect.Spring)', 'StatsPage fixed lower scroll');

requireIncludes(sources.homeStorage, 'CenterFeedbackOverlay()', 'HomeStoragePage');
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
