import fs from 'node:fs';

const v2ServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleOriginalPhotoExportService.ets', 'utf8');
const v1ServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleExportService.ets', 'utf8');
const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const feedbackSource = fs.readFileSync('entry/src/main/ets/services/ReviewFlowFeedback.ets', 'utf8');
const exchangeSchemaSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardExchangeSchema.ets', 'utf8');
const rdbModelSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardRdbModel.ets', 'utf8');
const smbClientSource = fs.readFileSync('entry/src/main/ets/services/Smb2Client.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');

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

for (const token of [
  'export class ReviewBundleOriginalPhotoExportService',
  'exportOriginalPhotoReviewBundleToHomeStorage',
  'bundleVersion: 2',
  'bundleType: BUNDLE_TYPE',
  "const BUNDLE_TYPE: string = 'original-photo-review'",
  'exportedImages: []',
  'included: true',
  "const ORIGINAL_PHOTO_ROOT: string = 'assets/original'",
  'const originalFileName: string = `original.${extension}`',
  'const originalRelativePath: string = `${ORIGINAL_PHOTO_ROOT}/${originalFileName}`',
  'copyOriginalPhoto(document.imageUri, paths.originalPhoto)',
  'fs.openSync(sourceUri, fs.OpenMode.READ_ONLY)',
  'fs.copyFileSync(sourceFile.fd, targetFile.fd)',
  'manifest.originalPhoto.fileSize <= 0',
  'verifyReviewJsonNotPolluted(paths.reviewJson)',
  'remoteRelativePath: originalRelativePath',
  'HomeStorageService.uploadFilesToDirectory(',
  'bundle_v2_export_start',
  'document_file_name=',
  'original_source_uri=',
  'image_uri=',
  'uri_scheme=',
  'uri_digest=',
  'uri_length=',
  'original_copy_start',
  'read_method=fs.openSync_read_only',
  'original_read_failed',
  'original_copy_success',
  'original_copy_failed',
  'raw_message=',
  'raw_stack=',
  'manifest_v2_write_success',
  'local_bundle_v2_validation_start',
  'local_bundle_v2_validation_failed',
  'local_bundle_v2_validation_success',
  'home_storage_reachability_result',
  'remote_target_directory',
  'bundle_v2_upload_start',
  'original_upload_start',
  'original_upload_success',
  'original_upload_failed',
  'bundle_v2_upload_failed',
  'bundle_v2_export_success',
  'bundle_v2_export_failed'
]) {
  assertIncludes(v2ServiceSource, token, 'ReviewBundleOriginalPhotoExportService');
}

for (const token of [
  "ORIGINAL_READ_FAILED = 'originalReadFailed'",
  "ORIGINAL_COPY_FAILED = 'originalCopyFailed'",
  "LOCAL_BUNDLE_VALIDATION_FAILED = 'localBundleValidationFailed'",
  'original_upload_start',
  'original_upload_success',
  'original_upload_failed'
]) {
  assertIncludes(homeStorageSource, token, 'HomeStorageService');
}

for (const token of [
  'assertFileExists(paths.manifest,',
  'assertFileExists(paths.reviewJson,',
  'assertFileExists(paths.originalPhoto, originalRelativePath)',
  'manifest.bundleVersion !== 2',
  'manifest.bundleType !== BUNDLE_TYPE',
  'manifest.originalPhoto.included !== true',
  'manifest.originalPhoto.path !== originalRelativePath',
  '!Array.isArray(manifest.exportedImages)'
]) {
  assertIncludes(v2ServiceSource, token, 'v2 local bundle validation');
}

for (const token of [
  "{ localPath: paths.manifest, remoteRelativePath: 'manifest.json' }",
  "{ localPath: paths.reviewJson, remoteRelativePath: 'review.json' }",
  '{ localPath: paths.originalPhoto, remoteRelativePath: originalRelativePath }',
  "{ localPath: paths.assetsReadme, remoteRelativePath: ASSETS_README_PATH }"
]) {
  assertIncludes(v2ServiceSource, token, 'v2 upload file list');
}

assertNotIncludes(v2ServiceSource, 'ReviewCardExportService', 'v2 service');
assertNotIncludes(v2ServiceSource, 'REVIEW_CARD_IMAGE_PATH', 'v2 service');
assertNotIncludes(v2ServiceSource, "thumbnailPath: 'thumbnails/thumb.jpg'", 'v2 manifest must not declare missing thumbnail');
assertNotIncludes(v2ServiceSource, 'thumbnailPath: THUMBNAIL_PATH', 'v2 manifest must not declare missing thumbnail');
assertNotIncludes(v2ServiceSource, "remoteRelativePath: 'exports/review-card.png'", 'v2 upload list');

const sourceCheckIndex = v2ServiceSource.indexOf('if (!hasOriginalSource)');
const copyStartIndex = v2ServiceSource.indexOf('original_copy_start');
const validationStartIndex = v2ServiceSource.indexOf('local_bundle_v2_validation_start');
const availabilityIndex = v2ServiceSource.indexOf('HomeStorageService.checkAvailability(context)');
const uploadStartIndex = v2ServiceSource.indexOf('bundle_v2_upload_start');
assert(sourceCheckIndex >= 0 && sourceCheckIndex < availabilityIndex, 'v2 must reject missing imageUri before home storage reachability.');
assert(copyStartIndex >= 0 && copyStartIndex < availabilityIndex, 'v2 must copy original before home storage reachability.');
assert(validationStartIndex >= 0 && validationStartIndex < availabilityIndex, 'v2 must validate local bundle before home storage reachability.');
assert(availabilityIndex >= 0 && availabilityIndex < uploadStartIndex, 'v2 must check reachability before upload.');

assertIncludes(previewSource, 'ReviewBundleOriginalPhotoExportService', 'PreviewPage');
assertIncludes(previewSource, '@State isExportingOriginalPhotoBundle: boolean = false;', 'PreviewPage');
assertIncludes(previewSource, 'exportOriginalPhotoReviewBundleToHomeStorage()', 'PreviewPage');
assertIncludes(previewSource, "'导出复盘包（含原图）'", 'PreviewPage');
assertIncludes(previewSource, "'包含原始照片和复盘数据，适合在 Mac 端继续处理。'", 'PreviewPage');
assertIncludes(previewSource, "'导出复盘包'", 'PreviewPage');
assertIncludes(previewSource, "'包含复盘数据和导出图，用于家庭存储和 Mac 接力。'", 'PreviewPage');
assertIncludes(previewSource, "'导出 review.json'", 'PreviewPage');
assertIncludes(previewSource, "'复制复盘数据'", 'PreviewPage');

for (const token of [
  "REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_PENDING_TEXT: string = '正在导出含原图复盘包…'",
  "REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT: string = '含原图复盘包已导出到家庭存储'",
  "REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT: string = '含原图复盘包导出失败，请重试。'",
  "REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_READ_FAILED_TEXT: string = '原始照片无法读取，请重新选择照片。'",
  "REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_COPY_FAILED_TEXT: string = '原始照片保存失败，请重试。'",
  "REVIEW_FLOW_BUNDLE_EXPORT_AUTH_FAILED_TEXT: string = '家庭存储账号或密码不正确，请检查设置'",
  "REVIEW_FLOW_BUNDLE_EXPORT_UNREACHABLE_TEXT: string = '无法连接家庭存储。请连接家庭 Wi-Fi 或 VPN 后重试。'"
]) {
  assertIncludes(feedbackSource, token, 'ReviewFlowFeedback');
}

const previewUserCopyStart = previewSource.indexOf('@Builder\n  ExportMenuSheet()');
const previewUserCopyEnd = previewSource.indexOf('  build() {');
const previewUserCopy = previewUserCopyStart >= 0 && previewUserCopyEnd > previewUserCopyStart
  ? previewSource.slice(previewUserCopyStart, previewUserCopyEnd)
  : previewSource;
const feedbackUserCopy = [
  "正在导出含原图复盘包…",
  "含原图复盘包已导出到家庭存储",
  "含原图复盘包导出失败，请重试。",
  "原始照片无法读取，请重新选择照片。",
  "原始照片保存失败，请重试。",
  "请先配置家庭存储",
  "无法连接家庭存储。请连接家庭 Wi-Fi 或 VPN 后重试。",
  "家庭存储账号或密码不正确，请检查设置。"
].join('\n');

for (const forbidden of ['SMB', 'manifest', 'RDB', 'Preferences', 'URI', 'raw JSON', 'bundleVersion']) {
  assertNotIncludes(previewUserCopy, forbidden, 'PreviewPage ordinary v2 export copy');
  assertNotIncludes(feedbackUserCopy, forbidden, 'ReviewFlowFeedback ordinary v2 export copy');
}

assertIncludes(v1ServiceSource, 'exportReviewBundleToHomeStorage', 'ReviewBundleExportService v1 remains');
assertIncludes(v1ServiceSource, 'bundleVersion: 1', 'ReviewBundleExportService v1 remains');
assertIncludes(v1ServiceSource, 'included: false', 'ReviewBundleExportService v1 remains');
assertIncludes(v1ServiceSource, 'remoteRelativePath: REVIEW_CARD_IMAGE_PATH', 'ReviewBundleExportService v1 remains');
assertIncludes(smbClientSource, 'SMB2_WRITE_CHUNK_SIZE', 'Smb2Client chunked upload');
assertIncludes(smbClientSource, 'private async writeFileChunk(', 'Smb2Client chunked upload');
assert(!exchangeSchemaSource.includes('bundleId'), 'Review JSON schema must not gain bundleId.');
assert(!exchangeSchemaSource.includes('bundleType'), 'Review JSON schema must not gain bundleType.');
assert(!exchangeSchemaSource.includes('originalPhoto'), 'Review JSON schema must not gain originalPhoto.');
assert(!rdbModelSource.includes('bundleType'), 'RDB schema must not gain bundleType.');
assert(!rdbModelSource.includes('originalPhotoReview'), 'RDB schema must not gain originalPhotoReview.');

if (failed) {
  process.exit(1);
}

console.log('review bundle v2 original photo export: entry, service, manifest, original copy, validation, upload, copy, and v1 boundary verified');
