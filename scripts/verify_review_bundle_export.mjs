import fs from 'node:fs';

const bundleServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleExportService.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const smbClientSource = fs.readFileSync('entry/src/main/ets/services/Smb2Client.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const exportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardExportService.ets', 'utf8');
const contractDocSource = fs.readFileSync('docs/product/REVIEW_BUNDLE_V1_V2_CONTRACT.md', 'utf8');
const currentSpecDocSource = fs.readFileSync('docs/product/CURRENT_PRODUCT_SPEC.md', 'utf8');

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
  'path: THUMBNAIL_PATH',
  'originalPhoto: {',
  'included: false',
  'review: {',
  'stringifyReviewCardExchangeSchemaV1(document, reviewerText)',
  'verifyBundle(paths)',
  'const remoteDirectory: string = bundleDirectoryName;',
  "remoteRelativePath: 'manifest.json'",
  "remoteRelativePath: 'review.json'",
  'remoteRelativePath: THUMBNAIL_PATH'
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
requireIncludes(smbClientSource, 'export interface Smb2UploadFileOptions', 'Smb2Client');
requireIncludes(smbClientSource, 'async uploadFile(options: Smb2UploadFileOptions): Promise<string>', 'Smb2Client');
requireIncludes(smbClientSource, 'private async writeFileFromPath(fileId: Array<number>, localPath: string, byteSize: number): Promise<void>', 'Smb2Client');
requireIncludes(homeStorageSource, 'export interface HomeStorageUploadFileEntry', 'HomeStorageService');
requireIncludes(homeStorageSource, 'static async uploadFilesToDirectory(', 'HomeStorageService');
requireIncludes(homeStorageSource, 'client.uploadFile(createSmbUploadFileOptions(', 'HomeStorageService');
requireIncludes(homeStorageSource, 'await HomeStorageService.markLastUploadedAt(context, Date.now());', 'HomeStorageService');
if (homeStorageSource.includes('readLocalFileBytes(localPath)')) {
  failed = true;
  console.error('HomeStorageService must not read full export files into memory before SMB upload.');
}

requireIncludes(exportServiceSource, 'export interface ReviewCardBundleSnapshotResult', 'ReviewCardExportService');
requireIncludes(exportServiceSource, 'static async exportBundleSnapshot(', 'ReviewCardExportService');
requireIncludes(exportServiceSource, "format: BUNDLE_THUMBNAIL_MIME_TYPE", 'ReviewCardExportService');
requireIncludes(exportServiceSource, 'await packer.release();', 'ReviewCardExportService');
if (exportServiceSource.includes('image/png') || exportServiceSource.includes('BUNDLE_REVIEW_CARD_MIME_TYPE')) {
  failed = true;
  console.error('ReviewCardExportService must not generate PNG for review bundle export.');
}

requireIncludes(previewPageSource, 'ReviewBundleExportService.exportReviewBundleToHomeStorage(', 'PreviewPage');
requireIncludes(previewPageSource, "this.ExportSheetAction(this.exportState === ExportState.BUNDLE ? '导出中…' : '导出复盘包'", 'PreviewPage');
requireIncludes(previewPageSource, "'包含复盘数据和导出图，用于家庭存储和 Mac 接力。'", 'PreviewPage');
requireIncludes(previewPageSource, 'exportState === ExportState.BUNDLE', 'PreviewPage');
requireIncludes(previewPageSource, 'this.isExportSnapshotMode = true;', 'PreviewPage');
requireIncludes(previewPageSource, 'await this.markExportedQuietly(result.remotePath);', 'PreviewPage');

requireIncludes(contractDocSource, 'v1 是成品图复盘包', 'REVIEW_BUNDLE_V1_V2_CONTRACT.md');
requireIncludes(contractDocSource, '当前不包含自动同步、批量导入、双向同步、远端删除、冲突合并', 'REVIEW_BUNDLE_V1_V2_CONTRACT.md');
requireIncludes(contractDocSource, 'v1 / v2 用户文案必须清楚区分', 'REVIEW_BUNDLE_V1_V2_CONTRACT.md');
requireIncludes(currentSpecDocSource, '导出复盘包', 'CURRENT_PRODUCT_SPEC.md');

if (failed) {
  process.exit(1);
}

console.log('review bundle export: service, manifest, SMB upload, preview entry, and docs verified');
