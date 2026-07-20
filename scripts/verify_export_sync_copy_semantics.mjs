import fs from 'node:fs';

const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const syncCenterSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const homeStoragePageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const homeStorageServiceSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const reviewModelSource = fs.readFileSync('entry/src/main/ets/model/ReviewCardModel.ets', 'utf8');
const rdbModelSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardRdbModel.ets', 'utf8');
const myPageSettingsStart = myPageSource.indexOf('@Builder\n  SettingsSection()');
const myPageSettingsEnd = myPageSource.indexOf('@Builder\n  AboutSection()');
const myPageOrdinarySource = myPageSettingsStart >= 0 && myPageSettingsEnd > myPageSettingsStart
  ? myPageSource.slice(myPageSettingsStart, myPageSettingsEnd)
  : myPageSource;

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function assertIncludes(source, token, label) {
  assert(source.includes(token), `${label} missing token: ${token}`);
}

function assertNotIncludes(source, token, label) {
  assert(!source.includes(token), `${label} must not include token: ${token}`);
}

assertIncludes(previewSource, "Text('导出当前复盘')", 'Preview export sheet');
assertNotIncludes(previewSource, "Text('导出与同步')", 'Preview export sheet');
assertIncludes(previewSource, 'this.handleExportButtonTap();', 'Preview floating action bar');
assertIncludes(previewSource, 'this.MoreActionButton(this.isActionBusy()', 'Preview floating action bar');
assertIncludes(previewSource, "'导出到相册（原图分辨率 · JPEG）'", 'Preview export sheet');
assertIncludes(previewSource, "'导出到相册（屏幕分辨率 · JPEG）'", 'Preview export sheet');
assertIncludes(previewSource, "'导出复盘包'", 'Preview export sheet');
assertIncludes(previewSource, "'包含复盘数据和导出图，用于家庭存储和 Mac 接力。'", 'Preview export sheet');
assertIncludes(previewSource, "'导出复盘包（含原图）'", 'Preview export sheet');
assertNotIncludes(previewSource, "'复制复盘数据'", 'Preview export sheet');

assertNotIncludes(previewSource, "'上传家庭存储'", 'Preview export sheet');
assertNotIncludes(previewSource, 'uploadReviewJsonToHomeStorage', 'Preview export sheet');
assertNotIncludes(previewSource, "'生成这张复盘卡片图片。'", 'Preview export sheet');
assertNotIncludes(previewSource, "'复制数据'", 'Preview export sheet');
assertNotIncludes(previewSource, 'isUploadingHomeStorage', 'Preview export sheet');
assertNotIncludes(previewSource, "'导出 review.json'", 'Preview export sheet');

assertIncludes(syncCenterSource, "title: '同步中心'", 'SyncCenterPage');
assertIncludes(syncCenterSource, "secondaryLabel: this.isTesting ? '检查中…' : '检查家庭存储'", 'SyncCenterPage');
assertNotIncludes(syncCenterSource, 'SettingsLinkRow({', 'SyncCenterPage');
assertIncludes(syncCenterSource, "this.InfoRow('状态', this.resolveAvailabilityText())", 'SyncCenterPage');
assertNotIncludes(myPageSource, 'value: this.resolveSyncSummary()', 'MyPage');
assertIncludes(myPageSource, "title: '同步中心'", 'MyPage');

const ordinaryCopySources = [
  ['PreviewPage', previewSource],
  ['SyncCenterPage', syncCenterSource],
  ['MyPage', myPageOrdinarySource],
  ['HomeStoragePage', homeStoragePageSource]
];

for (const [label, source] of ordinaryCopySources) {
  assertNotIncludes(source, 'SMB 地址', label);
  assertNotIncludes(source, 'SMB 端口', label);
  assertNotIncludes(source, 'RDB', label);
  assertNotIncludes(source, 'manifest', label);
  assertNotIncludes(source, 'Preferences', label);
  assertNotIncludes(source, 'review_exchange', label);
  assertNotIncludes(source, 'raw JSON', label);
  assertNotIncludes(source, '立即同步', label);
  assertNotIncludes(source, '双向同步', label);
}

assertIncludes(homeStoragePageSource, "'家庭存储地址'", 'HomeStoragePage');
assertIncludes(homeStoragePageSource, "'连接端口'", 'HomeStoragePage');
assertIncludes(homeStorageServiceSource, "return '请先填写家庭存储地址';", 'HomeStorageService');
assertIncludes(homeStorageServiceSource, "return '连接端口需要在 1-65535 之间';", 'HomeStorageService');
assertIncludes(homeStorageServiceSource, 'normalizeHomeStorageErrorMessage', 'HomeStorageService');

assert(!reviewModelSource.includes('bundleId'), 'ReviewCardDocument must not gain bundle fields.');
assert(!reviewModelSource.includes('manifest'), 'ReviewCardDocument must not gain manifest fields.');
assert(!rdbModelSource.includes('bundle'), 'RDB schema must not gain bundle columns.');
assert(!rdbModelSource.includes('manifest'), 'RDB schema must not gain manifest columns.');

if (failed) {
  process.exit(1);
}

console.log('export/sync semantics: four export choices, sync-center scope, and data-model boundaries verified');
