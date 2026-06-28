import fs from 'node:fs';

const bundleServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleExportService.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const smbClientSource = fs.readFileSync('entry/src/main/ets/services/Smb2Client.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const exportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardExportService.ets', 'utf8');
const designDocSource = fs.readFileSync('docs/product/REVIEW_BUNDLE_V1_DESIGN.md', 'utf8');
const baselineDocSource = fs.readFileSync('docs/product/HARMONYOS_V0_BASELINE.md', 'utf8');

let failed = false;

function requireIncludes(source, token, label) {
  if (!source.includes(token)) {
    failed = true;
    console.error(`${label} missing token: ${token}`);
  }
}

const requiredBundleTokens = [
  'exportReviewBundleToHomeStorage',
  'bundleVersion: 1',
  "reviewJsonPath: 'review.json'",
  "path: REVIEW_CARD_IMAGE_PATH",
  'originalPhoto: {',
  'included: false',
  'review: {',
  'stringifyReviewCardExchangeSchemaV1(document, reviewerText)',
  'verifyBundle(paths)',
  'Skymap/ReviewBundles/${dateParts.year}/${dateParts.month}/${bundleDirectoryName}',
  "remoteRelativePath: 'manifest.json'",
  "remoteRelativePath: 'review.json'",
  'remoteRelativePath: REVIEW_CARD_IMAGE_PATH',
  'remoteRelativePath: THUMBNAIL_PATH',
  'remoteRelativePath: ASSETS_README_PATH'
];

for (const token of requiredBundleTokens) {
  requireIncludes(bundleServiceSource, token, 'ReviewBundleExportService');
}

const forbiddenBundleTokens = [
  'ReviewCardHistoryService.markExported',
  'ReviewCardRdbService',
  'Preferences',
  'review_exchange/'
];

for (const token of forbiddenBundleTokens) {
  if (bundleServiceSource.includes(token)) {
    failed = true;
    console.error(`ReviewBundleExportService must not own persistence or old exchange sync token: ${token}`);
  }
}

requireIncludes(smbClientSource, 'export interface Smb2UploadBytesOptions', 'Smb2Client');
requireIncludes(smbClientSource, 'async uploadBytes(options: Smb2UploadBytesOptions): Promise<string>', 'Smb2Client');
requireIncludes(smbClientSource, 'await this.writeFile(fileId, options.contentBytes);', 'Smb2Client');
requireIncludes(homeStorageSource, 'export interface HomeStorageUploadFileEntry', 'HomeStorageService');
requireIncludes(homeStorageSource, 'static async uploadFilesToDirectory(', 'HomeStorageService');
requireIncludes(homeStorageSource, 'readLocalFileBytes(localPath)', 'HomeStorageService');
requireIncludes(homeStorageSource, 'await HomeStorageService.markLastUploadedAt(context, Date.now());', 'HomeStorageService');

requireIncludes(exportServiceSource, 'export interface ReviewCardBundleSnapshotResult', 'ReviewCardExportService');
requireIncludes(exportServiceSource, 'static async exportBundleSnapshot(', 'ReviewCardExportService');
requireIncludes(exportServiceSource, "format: BUNDLE_REVIEW_CARD_MIME_TYPE", 'ReviewCardExportService');
requireIncludes(exportServiceSource, "format: BUNDLE_THUMBNAIL_MIME_TYPE", 'ReviewCardExportService');

for (const token of [
  'ReviewBundleExportService.exportReviewBundleToHomeStorage(',
  "this.ExportSheetAction(this.isExportingReviewBundle ? '导出中…' : '导出复盘包'",
  "'包含复盘数据和导出图，用于家庭存储和 Mac 接力。'",
  "@State isExportingReviewBundle: boolean = false;"
]) {
  if (previewPageSource.includes(token)) {
    failed = true;
    console.error(`PreviewPage must hide dormant review bundle entry for Beta: ${token}`);
  }
}

requireIncludes(designDocSource, '阶段 1 已实现', 'REVIEW_BUNDLE_V1_DESIGN.md');
requireIncludes(designDocSource, '阶段 1 先由导出截图重新打包为 JPEG', 'REVIEW_BUNDLE_V1_DESIGN.md');
requireIncludes(designDocSource, 'SMB 写入失败时，本地临时 bundle 会保留', 'REVIEW_BUNDLE_V1_DESIGN.md');
requireIncludes(baselineDocSource, 'review bundle v1 阶段 1 已实现', 'HARMONYOS_V0_BASELINE.md');

if (failed) {
  process.exit(1);
}

console.log('review bundle export: dormant service and docs verified, Beta preview entry hidden');
