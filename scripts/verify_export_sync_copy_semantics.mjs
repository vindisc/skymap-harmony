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
assertIncludes(previewSource, "this.ExportSheetSectionTitle('常用')", 'Preview export sheet');
assertIncludes(previewSource, "this.ExportSheetSectionTitle('高级')", 'Preview export sheet');
assertIncludes(previewSource, "'导出图片'", 'Preview export sheet');
assertIncludes(previewSource, "'生成这张复盘卡片图片。'", 'Preview export sheet');
assertIncludes(previewSource, "'导出 review.json'", 'Preview export sheet');
assertIncludes(previewSource, "'只导出复盘数据文件，不包含图片。'", 'Preview export sheet');
assertIncludes(previewSource, "'复制复盘数据'", 'Preview export sheet');
assertIncludes(previewSource, "'复制当前复盘的文本数据。'", 'Preview export sheet');

assertNotIncludes(previewSource, "'上传家庭存储'", 'Preview export sheet');
assertNotIncludes(previewSource, "'导出复盘包'", 'Preview export sheet');
assertNotIncludes(previewSource, "'导出复盘包（含原图）'", 'Preview export sheet');
assertNotIncludes(previewSource, 'uploadReviewJsonToHomeStorage', 'Preview export sheet');
assertNotIncludes(previewSource, "'复制数据'", 'Preview export sheet');
assertNotIncludes(previewSource, 'isUploadingHomeStorage', 'Preview export sheet');

assertIncludes(syncCenterSource, "title: '同步中心'", 'SyncCenterPage');
assertIncludes(syncCenterSource, '家庭存储仍是 Beta 后实验能力。当前 Beta 请使用导出 review.json 完成手动交换。', 'SyncCenterPage');
assertIncludes(syncCenterSource, '当前家庭存储需要在同一网络或 VPN 下使用。', 'SyncCenterPage');
assertIncludes(syncCenterSource, "label: this.isTesting ? '检查中…' : '检查家庭存储'", 'SyncCenterPage');
assertNotIncludes(myPageSource, "title: '同步中心'", 'MyPage');
assertNotIncludes(myPageSource, "title: '家庭存储'", 'MyPage');

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

assertIncludes(homeStoragePageSource, "'家庭存储地址或 IP'", 'HomeStoragePage');
assertIncludes(homeStoragePageSource, "'连接端口'", 'HomeStoragePage');
assertIncludes(homeStorageServiceSource, "return '请先填写家庭存储地址或 IP';", 'HomeStorageService');
assertIncludes(homeStorageServiceSource, "return '连接端口需要在 1-65535 之间';", 'HomeStorageService');
assertIncludes(homeStorageServiceSource, 'normalizeHomeStorageErrorMessage', 'HomeStorageService');

assert(!reviewModelSource.includes('bundleId'), 'ReviewCardDocument must not gain bundle fields.');
assert(!reviewModelSource.includes('manifest'), 'ReviewCardDocument must not gain manifest fields.');
assert(!rdbModelSource.includes('bundle'), 'RDB schema must not gain bundle columns.');
assert(!rdbModelSource.includes('manifest'), 'RDB schema must not gain manifest columns.');

if (failed) {
  process.exit(1);
}

console.log('export/sync/copy semantics: labels, descriptions, sync-center scope, and data-model boundaries verified');
