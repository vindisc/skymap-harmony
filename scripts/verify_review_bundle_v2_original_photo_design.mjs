import fs from 'node:fs';

const v2Doc = fs.readFileSync('docs/product/REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md', 'utf8');
const v1Doc = fs.readFileSync('docs/product/REVIEW_BUNDLE_V1_DESIGN.md', 'utf8');
const bundleServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleExportService.ets', 'utf8');
const originalPhotoExportSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleOriginalPhotoExportService.ets', 'utf8');
const exchangeSchemaSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardExchangeSchema.ets', 'utf8');
const rdbModelSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardRdbModel.ets', 'utf8');

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

for (const token of [
  'v2 是新增的“原图复盘包”',
  'v2 不替代 v1',
  '不修改 Review JSON v1 字段',
  '"bundleVersion": 2',
  '"bundleType": "original-photo-review"',
  '"exportedImages": []',
  '"included": true',
  '"path": "assets/original/original.jpg"',
  'originalPhoto.path',
  'assets/original/original.*',
  '导出复盘包（含原图）',
  'original_read_failed',
  'original_copy_failed',
  'original_upload_failed',
  'bundle_v2_upload_failed',
  '`readonlyExportReview`',
  '`originalPhotoReview`',
  '因为 `exportedImages = []` 直接判定非法',
  'Mac 端当前已支持 v2 导入和可编辑恢复入口',
  'HarmonyOS 增加 v2 设计和导出验证脚本',
  'Mac v2 原图复盘包可打开为复盘卡',
  'RDB 表结构变更',
  'Review JSON 字段变更',
  '废弃 v1'
]) {
  assertIncludes(v2Doc, token, 'REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md');
}

for (const token of [
  '`bundleId`',
  '`bundleType`',
  '`originalPhoto`',
  '`localPath`',
  '`remotePath`',
  '`thumbnailPath`',
  '`exportedImages`'
]) {
  assertIncludes(v2Doc, token, 'Review JSON 禁止字段');
}

assertIncludes(v1Doc, '"bundleVersion": 1', 'REVIEW_BUNDLE_V1_DESIGN.md');
assertIncludes(v1Doc, '原图默认不进入 bundle v1', 'REVIEW_BUNDLE_V1_DESIGN.md');
assertIncludes(bundleServiceSource, 'bundleVersion: 1', 'ReviewBundleExportService v1 remains');
assertIncludes(bundleServiceSource, 'included: false', 'ReviewBundleExportService v1 remains');
assertIncludes(bundleServiceSource, 'remoteRelativePath: REVIEW_CARD_IMAGE_PATH', 'ReviewBundleExportService v1 exported image remains');
assertIncludes(originalPhotoExportSource, 'bundleVersion: 2', 'ReviewBundleOriginalPhotoExportService v2 export');
assertIncludes(originalPhotoExportSource, "const BUNDLE_TYPE: string = 'original-photo-review'", 'ReviewBundleOriginalPhotoExportService v2 export');
assertIncludes(originalPhotoExportSource, 'exportedImages: []', 'ReviewBundleOriginalPhotoExportService v2 export');
assertIncludes(originalPhotoExportSource, 'verifyReviewJsonNotPolluted(paths.reviewJson)', 'ReviewBundleOriginalPhotoExportService v2 export');
assert(!exchangeSchemaSource.includes('bundleId'), 'Review JSON schema must not gain bundleId.');
assert(!exchangeSchemaSource.includes('bundleType'), 'Review JSON schema must not gain bundleType.');
assert(!exchangeSchemaSource.includes('originalPhoto'), 'Review JSON schema must not gain originalPhoto.');
assert(!rdbModelSource.includes('bundleType'), 'HarmonyOS RDB schema must not gain bundleType.');
assert(!rdbModelSource.includes('originalPhotoReview'), 'HarmonyOS RDB schema must not gain originalPhotoReview.');

if (failed) {
  process.exit(1);
}

console.log('review bundle v2 original photo design: docs, v1 boundary, Review JSON freeze, and no half export verified');
