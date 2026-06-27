import fs from 'node:fs';

const bundleServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleExportService.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const smbClientSource = fs.readFileSync('entry/src/main/ets/services/Smb2Client.ets', 'utf8');
const exportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardExportService.ets', 'utf8');
const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const feedbackSource = fs.readFileSync('entry/src/main/ets/services/ReviewFlowFeedback.ets', 'utf8');
const modelSource = fs.readFileSync('entry/src/main/ets/model/ReviewCardModel.ets', 'utf8');
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

function assertNotIncludes(source, token, label) {
  assert(!source.includes(token), `${label} must not include token: ${token}`);
}

for (const token of [
  '[ReviewBundleExport] start reviewId=',
  'local_directories_ready',
  'review_json_written',
  'review_card_written',
  'thumbnail_written',
  'assets_readme_written',
  'manifest_written',
  'local_bundle_verified',
  'upload_finished',
  'stack=${stack}'
]) {
  assertIncludes(bundleServiceSource, token, 'ReviewBundleExportService diagnostics');
}

for (const token of [
  'bundle_upload_config status=',
  'bundle_upload_config_invalid',
  'bundle_upload_start targetDirectory=',
  'bundle_upload_file index=',
  'bundle_upload_failed index=',
  'bundle_upload_success targetDirectory=',
  'file_upload_start local=',
  'file_upload_success remote=',
  'file_upload_failed local='
]) {
  assertIncludes(homeStorageSource, token, 'HomeStorageService diagnostics');
}

for (const token of [
  'SMB2_WRITE_CHUNK_SIZE',
  'private async writeFileChunk(',
  'writeUInt64LEFromNumber(body, 8, offset);',
  'write_chunk_start chunk=',
  'write_chunk_success chunk=',
  'write_chunk_failed chunk=',
  'mkdir_start level=',
  'mkdir_success level=',
  'mkdir_failed level=',
  'upload_bytes_failed file='
]) {
  assertIncludes(smbClientSource, token, 'Smb2Client diagnostics and chunking');
}

assertIncludes(exportServiceSource, 'assertImageBytes', 'ReviewCardExportService');
assertIncludes(exportServiceSource, 'thumbnail_jpeg_failed fallback=review-card', 'ReviewCardExportService');
assertIncludes(exportServiceSource, 'writeImageToSandbox(thumbnailPath, reviewCardData);', 'ReviewCardExportService');

for (const relativePath of [
  "remoteRelativePath: 'manifest.json'",
  "remoteRelativePath: 'review.json'",
  'remoteRelativePath: REVIEW_CARD_IMAGE_PATH',
  'remoteRelativePath: THUMBNAIL_PATH',
  'remoteRelativePath: ASSETS_README_PATH'
]) {
  assertIncludes(bundleServiceSource, relativePath, 'Review bundle upload file list');
}

assertIncludes(previewSource, 'REVIEW_FLOW_BUNDLE_EXPORT_SUCCESS_TEXT', 'PreviewPage user feedback');
assertIncludes(previewSource, 'REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT', 'PreviewPage user feedback');
assertIncludes(previewSource, 'REVIEW_FLOW_BUNDLE_EXPORT_CONFIG_REQUIRED_TEXT', 'PreviewPage user feedback');
assertIncludes(previewSource, "result.message.indexOf('请先填写') >= 0", 'PreviewPage config failure mapping');
assertIncludes(feedbackSource, "REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT: string = '复盘包导出失败，请重试'", 'ReviewFlowFeedback');
assertIncludes(feedbackSource, "REVIEW_FLOW_BUNDLE_EXPORT_CONFIG_REQUIRED_TEXT: string = '请先配置家庭存储'", 'ReviewFlowFeedback');

const previewUserCopyStart = previewSource.indexOf('private async exportReviewBundleToHomeStorage()');
const previewUserCopyEnd = previewSource.indexOf('private async waitForExportLayout()');
const previewBundleExportSource = previewUserCopyStart >= 0 && previewUserCopyEnd > previewUserCopyStart
  ? previewSource.slice(previewUserCopyStart, previewUserCopyEnd)
  : previewSource;

const bundleFeedbackCopy = [
  "REVIEW_FLOW_BUNDLE_EXPORT_SUCCESS_TEXT: string = '复盘包已导出到家庭存储'",
  "REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT: string = '复盘包导出失败，请重试'",
  "REVIEW_FLOW_BUNDLE_EXPORT_CONFIG_REQUIRED_TEXT: string = '请先配置家庭存储'"
].join('\n');

for (const forbidden of ['SMB', 'manifest', 'RDB', 'raw JSON']) {
  assertNotIncludes(bundleFeedbackCopy, forbidden, 'ReviewFlowFeedback bundle user copy');
  assertNotIncludes(previewBundleExportSource.replace(/console\.[^\n]+/g, ''), forbidden, 'PreviewPage ordinary bundle export copy');
}

assert(!modelSource.includes('bundleId'), 'ReviewCardDocument must not gain bundle fields.');
assert(!modelSource.includes('manifest'), 'ReviewCardDocument must not gain manifest fields.');
assert(!rdbModelSource.includes('bundle'), 'RDB schema must not gain bundle columns.');
assert(!rdbModelSource.includes('manifest'), 'RDB schema must not gain manifest columns.');

if (failed) {
  process.exit(1);
}

console.log('review bundle export diagnostics: logs, chunked SMB write, fallback thumbnail, upload list, and safe user copy verified');
