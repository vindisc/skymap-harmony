import fs from 'node:fs';

const v2ServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleOriginalPhotoExportService.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const feedbackSource = fs.readFileSync('entry/src/main/ets/services/ReviewFlowFeedback.ets', 'utf8');

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
  'bundle_v2_export_start',
  'review_id=',
  'bundleId=',
  'document_file_name=',
  'image_uri=',
  'uri_scheme=',
  'uri_digest=',
  'uri_length=',
  'original_copy_start',
  'read_method=fs.openSync_read_only',
  'original_read_failed',
  'raw_message=',
  'raw_stack=',
  'original_copy_success',
  'localPath=',
  'fileSize=',
  'ext=',
  'mimeType=',
  'original_copy_failed',
  'manifest_v2_write_success',
  'local_bundle_v2_validation_start',
  'local_bundle_v2_validation_failed',
  'local_bundle_v2_validation_success',
  'home_storage_reachability_result',
  'remote_target_directory',
  'original_upload_start',
  'original_upload_success',
  'original_upload_failed',
  'bundle_v2_export_failed'
]) {
  assertIncludes(v2ServiceSource, token, 'v2 export diagnostics');
}

for (const token of [
  "ORIGINAL_READ_FAILED = 'originalReadFailed'",
  "ORIGINAL_COPY_FAILED = 'originalCopyFailed'",
  "LOCAL_BUNDLE_VALIDATION_FAILED = 'localBundleValidationFailed'",
  'entry.remoteRelativePath.indexOf(\'assets/original/\') === 0',
  'original_upload_start',
  'original_upload_success',
  'original_upload_failed'
]) {
  assertIncludes(homeStorageSource, token, 'home storage diagnostics');
}

const missingSourceIndex = v2ServiceSource.indexOf('if (!hasOriginalSource)');
const rootDirectoryIndex = v2ServiceSource.indexOf('ensureDirectory(paths.root)');
const assetsDirectoryIndex = v2ServiceSource.indexOf('ensureDirectory(`${paths.root}/assets`)');
const ensureDirectoryIndex = v2ServiceSource.indexOf('ensureDirectory(paths.originalDirectory)');
const reviewJsonWriteIndex = v2ServiceSource.indexOf('writeTextFile(paths.reviewJson');
const copyStartIndex = v2ServiceSource.indexOf('original_copy_start');
const validationStartIndex = v2ServiceSource.indexOf('local_bundle_v2_validation_start');
const reachabilityIndex = v2ServiceSource.indexOf('HomeStorageService.checkAvailability(context)');
const uploadIndex = v2ServiceSource.indexOf('HomeStorageService.uploadFilesToDirectory(');

assert(missingSourceIndex >= 0 && missingSourceIndex < ensureDirectoryIndex, 'missing imageUri must stop before local bundle files are created.');
assert(rootDirectoryIndex >= 0 && rootDirectoryIndex < assetsDirectoryIndex, 'v2 must create bundle root before assets directory.');
assert(assetsDirectoryIndex >= 0 && assetsDirectoryIndex < ensureDirectoryIndex, 'v2 must create assets directory before assets/original.');
assert(copyStartIndex >= 0 && copyStartIndex < reviewJsonWriteIndex, 'original photo must be copied before review.json/manifest writes.');
assert(validationStartIndex >= 0 && validationStartIndex < reachabilityIndex, 'local bundle validation must run before home storage reachability.');
assert(reachabilityIndex >= 0 && reachabilityIndex < uploadIndex, 'home storage reachability must run before upload.');

const previewUserCopyStart = previewSource.indexOf('@Builder\n  ExportMenuSheet()');
const previewUserCopyEnd = previewSource.indexOf('  build() {');
const previewUserCopy = previewUserCopyStart >= 0 && previewUserCopyEnd > previewUserCopyStart
  ? previewSource.slice(previewUserCopyStart, previewUserCopyEnd)
  : previewSource;
const feedbackUserCopy = [
  '正在导出含原图复盘包…',
  '含原图复盘包已导出到家庭存储',
  '含原图复盘包导出失败，请重试。',
  '原始照片无法读取，请重新选择照片。',
  '原始照片保存失败，请重试。',
  '请先配置家庭存储',
  '无法连接家庭存储。请连接家庭 Wi-Fi 或 VPN 后重试。',
  '家庭存储账号或密码不正确，请检查设置。'
].join('\n');

for (const forbidden of ['SMB', 'manifest', 'RDB', 'Preferences', 'URI', 'raw JSON', 'bundleVersion']) {
  assertNotIncludes(previewUserCopy, forbidden, 'PreviewPage ordinary v2 export copy');
  assertNotIncludes(feedbackUserCopy, forbidden, 'ReviewFlowFeedback ordinary v2 export copy');
}

if (failed) {
  process.exit(1);
}

console.log('review bundle v2 original photo diagnostics: failure layers, log tokens, execution order, and user-copy boundary verified');
