import fs from 'node:fs';

const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const settingsPageSource = fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8');
const settingsServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewSettingsService.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function requireIncludes(source, token, label) {
  assert(source.includes(token), `${label} missing token: ${token}`);
}

[
  "EXPORT_DEFAULT_ORIGINAL_RESOLUTION_KEY: string = 'export_default_original_resolution'",
  'loadExportDefaultOriginalResolution',
  'store.get(EXPORT_DEFAULT_ORIGINAL_RESOLUTION_KEY, false)',
  'saveExportDefaultOriginalResolution',
  'persistValue(store, EXPORT_DEFAULT_ORIGINAL_RESOLUTION_KEY, enabled)'
].forEach((token) => requireIncludes(settingsServiceSource, token, 'ReviewSettingsService'));

[
  "Text('默认走原图分辨率导出')",
  'Toggle({ type: ToggleType.Switch, isOn: this.exportDefaultOriginalResolution })',
  'ReviewSettingsService.loadExportDefaultOriginalResolution(context)',
  'ReviewSettingsService.saveExportDefaultOriginalResolution(this.getAbilityContext(), enabled)'
].forEach((token) => requireIncludes(settingsPageSource, token, 'ReviewSettingsPage'));

[
  'private async handleExportButtonTap(): Promise<void>',
  'ReviewSettingsService.loadExportDefaultOriginalResolution(this.getAbilityContext())',
  'await this.exportOriginalResolutionImage();',
  'this.openExportMenu();',
  'ReviewCardExportService.exportOriginalResolution(',
  'context,\n        this.document,\n        reviewerName',
  "'原图导出失败，建议使用屏幕分辨率'",
  "'导出到相册（原图分辨率 · JPEG）'",
  "'导出到相册（屏幕分辨率 · JPEG）'",
  "'导出复盘包'",
  "'导出复盘包（含原图）'"
].forEach((token) => requireIncludes(previewSource, token, 'PreviewPage'));

const menuStart = previewSource.indexOf('ExportMenuContent()');
const menuEnd = previewSource.indexOf('\n  build() {', menuStart);
const menuSource = menuStart >= 0 && menuEnd > menuStart
  ? previewSource.slice(menuStart, menuEnd)
  : '';
const actionCount = (menuSource.match(/this\.ExportSheetAction\(/g) || []).length;
assert(actionCount === 4, `Preview export menu must contain exactly four actions, found ${actionCount}.`);
assert(!menuSource.includes('复制复盘数据'), 'Preview export menu must not keep a fifth copy action.');

if (failed) {
  process.exit(1);
}

console.log('preview export preferences: default-off persistence, direct original export, and four-choice menu verified');
