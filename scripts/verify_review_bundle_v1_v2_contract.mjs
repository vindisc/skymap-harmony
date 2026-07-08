import fs from 'node:fs';

const v1Service = fs.readFileSync('entry/src/main/ets/services/ReviewBundleExportService.ets', 'utf8');
const v2Service = fs.readFileSync('entry/src/main/ets/services/ReviewBundleOriginalPhotoExportService.ets', 'utf8');
const previewPage = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const exchangeSchema = fs.readFileSync('entry/src/main/ets/services/ReviewCardExchangeSchema.ets', 'utf8');
const feedback = fs.readFileSync('entry/src/main/ets/services/ReviewFlowFeedback.ets', 'utf8');
const contractDoc = fs.readFileSync('docs/product/REVIEW_BUNDLE_V1_V2_CONTRACT.md', 'utf8');
const checklistPath = 'docs/product/REVIEW_BUNDLE_V1_V2_E2E_CHECKLIST.md';
const checklistDoc = fs.existsSync(checklistPath) ? fs.readFileSync(checklistPath, 'utf8') : '';

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function includes(source, token, label) {
  assert(source.includes(token), `${label} missing token: ${token}`);
}

function excludes(source, token, label) {
  assert(!source.includes(token), `${label} must not include token: ${token}`);
}

for (const token of [
  'exportReviewBundleToHomeStorage',
  'bundleVersion: 1',
  'path: THUMBNAIL_PATH',
  'exportedImages: exportedImages',
  'originalPhoto: {',
  'included: false',
  'assertFileExists(paths.thumbnail',
  'manifest.originalPhoto.included !== false',
  'remoteRelativePath: THUMBNAIL_PATH'
]) {
  includes(v1Service, token, 'v1 ReviewBundleExportService');
}

for (const token of [
  'exportOriginalPhotoReviewBundleToHomeStorage',
  'bundleVersion: 2',
  'bundleType: BUNDLE_TYPE',
  "const BUNDLE_TYPE: string = 'original-photo-review'",
  'exportedImages: []',
  'included: true',
  'const originalFileName: string = `original.${extension}`',
  'const originalRelativePath: string = originalFileName',
  'copyOriginalPhoto(document.imageUri, paths.originalPhoto)',
  'assertFileExists(paths.originalPhoto, originalRelativePath)',
  'manifest.originalPhoto.included !== true',
  'manifest.originalPhoto.path !== originalRelativePath',
  'manifest.originalPhoto.fileSize <= 0',
  'verifyReviewJsonNotPolluted(paths.reviewJson)',
  '{ localPath: paths.originalPhoto, remoteRelativePath: originalRelativePath }'
]) {
  includes(v2Service, token, 'v2 ReviewBundleOriginalPhotoExportService');
}

for (const token of [
  "'导出复盘包'",
  "'包含复盘数据和导出图，用于家庭存储和 Mac 接力。'",
  "'导出复盘包（含原图）'",
  "'包含原始照片和复盘数据，适合在 Mac 端继续处理。'"
]) {
  includes(previewPage, token, 'PreviewPage v1/v2 export copy');
}

for (const token of [
  '原始照片无法读取，请重新导入。',
  '原始照片保存失败，请重试。',
  '无法连接家庭存储。请连接家庭 Wi-Fi 或 VPN 后重试。'
]) {
  includes(feedback, token, 'ReviewFlowFeedback');
}

for (const token of [
  'bundleId',
  'bundleType',
  'originalPhoto',
  'thumbnailPath',
  'exportedImages',
  'remotePath',
  'localPath'
]) {
  excludes(exchangeSchema, token, 'ReviewCardExchangeSchema Review JSON fields');
}

for (const token of [
  'v1 是成品图复盘包',
  'v2 是原图复盘包',
  'Review JSON 字段继续冻结',
  '`exportedImages` 必须存在，允许为空数组 `[]`',
  'Mac 不自动写回原 bundle',
  '当前不包含自动同步、批量导入、双向同步、远端删除、冲突合并、云数据库或写回原 bundle'
]) {
  includes(contractDoc, token, 'REVIEW_BUNDLE_V1_V2_CONTRACT.md');
}

if (checklistDoc.length > 0) {
  for (const token of [
    'HarmonyOS v1 导出',
    'Mac v1 导入',
    'HarmonyOS v2 导出',
    'Mac v2 导入',
    'Mac v2 打开为复盘卡',
    'v2 不因为缺少 v1 成品图被当作 v1 失败'
  ]) {
    includes(checklistDoc, token, 'REVIEW_BUNDLE_V1_V2_E2E_CHECKLIST.md');
  }
}

excludes(v2Service, 'REVIEW_CARD_IMAGE_PATH', 'v2 service boundary');
excludes(v2Service, 'review-card.png', 'v2 upload list');

if (failed) {
  process.exit(1);
}

console.log('review bundle v1/v2 contract verified: v1 export, v2 original-photo export, Review JSON boundary, user copy, and docs');
