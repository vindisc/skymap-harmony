import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import { hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import {
  createReviewCardExchangeSchemaV1,
  mapReviewJudgementToExchangeDecision,
  stringifyReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';
import {
  HomeStorageErrorType,
  HomeStorageOperationResult,
  HomeStorageService,
  HomeStorageUploadFileEntry
} from './HomeStorageService';

export interface ReviewBundleOriginalPhotoExportResult {
  success: boolean;
  localBundlePath: string;
  remotePath: string;
  bundleId: string;
  bundleDirectoryName: string;
  message: string;
  errorType: HomeStorageErrorType;
}

interface ReviewBundleOriginalPhotoPaths {
  root: string;
  manifest: string;
  reviewJson: string;
  originalPhoto: string;
}

interface OriginalPhotoCopyResult {
  success: boolean;
  errorType: HomeStorageErrorType;
  message: string;
  rawMessage: string;
  rawStack: string;
}

interface ReviewBundleDateParts {
  year: string;
  month: string;
  day: string;
  hour: string;
  minute: string;
  second: string;
  isoText: string;
}

interface ReviewBundleOriginalPhotoManifest {
  included: boolean;
  path: string;
  fileName: string;
  mimeType: string;
  pixelWidth: number;
  pixelHeight: number;
  fileSize: number;
}

interface ReviewBundleReviewSummaryManifest {
  decision: string;
  titleText: string;
  reviewTimeText: string;
  reviewerText: string;
}

interface ReviewBundleManifestV2 {
  bundleVersion: number;
  bundleType: string;
  bundleId: string;
  createdAt: string;
  updatedAt: string;
  sourceApp: string;
  sourceAppVersion: string;
  platform: string;
  reviewJsonPath: string;
  exportedImages: Array<Object>;
  thumbnailPath?: string;
  originalPhoto: ReviewBundleOriginalPhotoManifest;
  review: ReviewBundleReviewSummaryManifest;
}

const LOCAL_BUNDLE_DIR_NAME: string = 'review_bundles';
const SOURCE_APP: string = 'skymap-photoreview';
const SOURCE_APP_VERSION: string = '0.1.0';
const PLATFORM: string = 'HarmonyOS';
const BUNDLE_TYPE: string = 'original-photo-review';
const ORIGINAL_READ_FAILED_TEXT: string = '原始照片无法读取，请重新导入。';
const ORIGINAL_COPY_FAILED_TEXT: string = '原始照片保存失败，请重试。';
const ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT: string = '含原图复盘包导出失败，请重试。';
const ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT: string = '含原图复盘包已导出到家庭存储';

function pad2(value: number): string {
  return `${value}`.padStart(2, '0');
}

function resolveDateParts(timestamp: number): ReviewBundleDateParts {
  const date = new Date(timestamp > 0 ? timestamp : Date.now());
  return {
    year: `${date.getFullYear()}`,
    month: pad2(date.getMonth() + 1),
    day: pad2(date.getDate()),
    hour: pad2(date.getHours()),
    minute: pad2(date.getMinutes()),
    second: pad2(date.getSeconds()),
    isoText: date.toISOString()
  };
}

function safeHash(value: string): string {
  let hash: number = 2166136261;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, '0').slice(0, 8);
}

function resolveUriScheme(value: string): string {
  const separatorIndex: number = value.indexOf('://');
  if (separatorIndex > 0) {
    return value.slice(0, separatorIndex).toLowerCase();
  }
  if (value.indexOf('/') === 0) {
    return 'path';
  }
  return value.length > 0 ? 'unknown' : 'empty';
}

function safeUriDigest(value: string): string {
  return safeHash(value);
}

function sanitizeBundleName(value: string): string {
  const sanitized: string = value
    .replace(/[^0-9A-Za-z_-]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '');
  return sanitized.length > 0 ? sanitized : `review_${Date.now()}`;
}

function encodeUtf8(value: string): ArrayBuffer {
  const encoded: string = encodeURIComponent(value);
  const bytes: Array<number> = [];
  let index: number = 0;
  while (index < encoded.length) {
    const current: string = encoded[index];
    if (current === '%' && index + 2 < encoded.length) {
      bytes.push(parseInt(encoded.slice(index + 1, index + 3), 16));
      index += 3;
      continue;
    }
    bytes.push(current.charCodeAt(0));
    index += 1;
  }
  return new Uint8Array(bytes).buffer;
}

function ensureDirectory(path: string): void {
  try {
    fs.mkdirSync(path, true);
  } catch (error) {
    const message: string = describeUnknownError(error);
    if (message.indexOf('File exists') < 0) {
      throw new Error(message);
    }
  }
}

function writeTextFile(path: string, value: string): void {
  const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, encodeUtf8(value));
  } finally {
    fs.closeSync(file);
  }
}

function fileSize(path: string): number {
  try {
    return fs.statSync(path).size;
  } catch (error) {
    return -1;
  }
}

function describeUnknownError(error: Error | Object): string {
  if (error instanceof Error) {
    return error.message;
  }
  return `${error}`;
}

function describeUnknownStack(error: Error | Object): string {
  if (error instanceof Error && typeof error.stack === 'string') {
    return error.stack;
  }
  return '';
}

function assertFileExists(path: string, label: string): void {
  try {
    const stat = fs.statSync(path);
    if (stat.size <= 0) {
      throw new Error(`${label} 为空`);
    }
  } catch (error) {
    throw new Error(`${label} 缺失`);
  }
}

function removeQueryAndFragment(uri: string): string {
  return uri.split('?')[0].split('#')[0];
}

function resolveSourceFileName(document: ReviewCardDocument): string {
  const reviewSummary = createReviewCardExchangeSchemaV1(document, '');
  if (reviewSummary.fileName.trim().length > 0) {
    return reviewSummary.fileName.trim();
  }

  const cleanUri: string = removeQueryAndFragment(document.imageUri);
  const parts: Array<string> = cleanUri.split('/');
  const rawFileName: string = parts.length > 0 ? parts[parts.length - 1] : '';
  if (rawFileName.length === 0) {
    return '';
  }

  try {
    return decodeURIComponent(rawFileName);
  } catch (error) {
    return rawFileName;
  }
}

function resolveSafeOriginalExtension(document: ReviewCardDocument): string {
  const candidates: Array<string> = [
    resolveSourceFileName(document),
    removeQueryAndFragment(document.imageUri)
  ];
  for (const candidate of candidates) {
    const normalized: string = candidate.toLowerCase();
    const slashIndex: number = normalized.lastIndexOf('/');
    const dotIndex: number = normalized.lastIndexOf('.');
    if (dotIndex > slashIndex && dotIndex >= 0) {
      const extension: string = normalized.slice(dotIndex + 1).replace(/[^a-z0-9]/g, '');
      if (extension === 'jpg' || extension === 'jpeg') {
        return 'jpg';
      }
      if (extension === 'png' || extension === 'webp' || extension === 'heic' || extension === 'heif') {
        return extension;
      }
    }
  }
  return 'jpg';
}

function resolveMimeType(extension: string): string {
  if (extension === 'jpg' || extension === 'jpeg') {
    return 'image/jpeg';
  }
  if (extension === 'png') {
    return 'image/png';
  }
  if (extension === 'webp') {
    return 'image/webp';
  }
  if (extension === 'heic') {
    return 'image/heic';
  }
  if (extension === 'heif') {
    return 'image/heif';
  }
  return 'application/octet-stream';
}

function buildLocalPaths(
  context: common.UIAbilityContext,
  bundleDirectoryName: string,
  originalFileName: string
): ReviewBundleOriginalPhotoPaths {
  const root: string = `${context.filesDir}/${LOCAL_BUNDLE_DIR_NAME}/${bundleDirectoryName}`;
  return {
    root: root,
    manifest: `${root}/manifest.json`,
    reviewJson: `${root}/review.json`,
    originalPhoto: `${root}/${originalFileName}`
  };
}

function createCopySuccessResult(): OriginalPhotoCopyResult {
  return {
    success: true,
    errorType: HomeStorageErrorType.NONE,
    message: '',
    rawMessage: '',
    rawStack: ''
  };
}

function createCopyFailureResult(
  errorType: HomeStorageErrorType,
  message: string,
  rawMessage: string,
  rawStack: string
): OriginalPhotoCopyResult {
  return {
    success: false,
    errorType: errorType,
    message: message,
    rawMessage: rawMessage,
    rawStack: rawStack
  };
}

function copyOriginalPhoto(sourceUri: string, targetPath: string): OriginalPhotoCopyResult {
  let sourceFile: fs.File | null = null;
  try {
    sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY);
  } catch (error) {
    return createCopyFailureResult(
      HomeStorageErrorType.ORIGINAL_READ_FAILED,
      ORIGINAL_READ_FAILED_TEXT,
      describeUnknownError(error),
      describeUnknownStack(error)
    );
  }

  let targetFile: fs.File | null = null;
  try {
    targetFile = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    fs.copyFileSync(sourceFile.fd, targetFile.fd);
  } catch (error) {
    return createCopyFailureResult(
      HomeStorageErrorType.ORIGINAL_COPY_FAILED,
      ORIGINAL_COPY_FAILED_TEXT,
      describeUnknownError(error),
      describeUnknownStack(error)
    );
  } finally {
    if (targetFile !== null) {
      fs.closeSync(targetFile);
    }
    if (sourceFile !== null) {
      fs.closeSync(sourceFile);
    }
  }
  return createCopySuccessResult();
}

function buildManifest(
  document: ReviewCardDocument,
  reviewerText: string,
  bundleId: string,
  dateParts: ReviewBundleDateParts,
  originalRelativePath: string,
  originalFileSize: number,
  originalMimeType: string,
  originalSourceFileName: string
): string {
  const reviewSummary = createReviewCardExchangeSchemaV1(document, reviewerText);
  const manifest: ReviewBundleManifestV2 = {
    bundleVersion: 2,
    bundleType: BUNDLE_TYPE,
    bundleId: bundleId,
    createdAt: dateParts.isoText,
    updatedAt: dateParts.isoText,
    sourceApp: SOURCE_APP,
    sourceAppVersion: SOURCE_APP_VERSION,
    platform: PLATFORM,
    reviewJsonPath: 'review.json',
    exportedImages: [],
    originalPhoto: {
      included: true,
      path: originalRelativePath,
      fileName: originalSourceFileName,
      mimeType: originalMimeType,
      pixelWidth: document.imageWidth > 0 ? document.imageWidth : 0,
      pixelHeight: document.imageHeight > 0 ? document.imageHeight : 0,
      fileSize: originalFileSize
    },
    review: {
      decision: mapReviewJudgementToExchangeDecision(document.content.judgement),
      titleText: reviewSummary.titleText,
      reviewTimeText: reviewSummary.reviewTimeText,
      reviewerText: reviewSummary.reviewerText
    }
  };
  return JSON.stringify(manifest, null, 2);
}

function verifyReviewJsonNotPolluted(reviewJsonPath: string): void {
  const parsed = JSON.parse(fs.readTextSync(reviewJsonPath)) as Record<string, Object>;
  const forbiddenKeys: Array<string> = [
    'bundleId',
    'bundleType',
    'originalPhoto',
    'originalPhotoPath',
    'localPath',
    'remotePath',
    'thumbnailPath',
    'exportedImages',
    'checksum'
  ];
  const actualKeys: Array<string> = Object.keys(parsed);
  const pollutedKeys: Array<string> = forbiddenKeys.filter((key: string): boolean => actualKeys.includes(key));
  if (pollutedKeys.length > 0) {
    throw new Error(`review.json 不允许包含 bundle 字段：${pollutedKeys.join(', ')}`);
  }
}

function verifyBundle(paths: ReviewBundleOriginalPhotoPaths, originalRelativePath: string): void {
  assertFileExists(paths.manifest, 'manifest.json');
  assertFileExists(paths.reviewJson, 'review.json');
  assertFileExists(paths.originalPhoto, originalRelativePath);

  const manifestText: string = fs.readTextSync(paths.manifest);
  const manifest: ReviewBundleManifestV2 = JSON.parse(manifestText) as ReviewBundleManifestV2;
  if (manifest.bundleVersion !== 2 ||
    manifest.bundleType !== BUNDLE_TYPE ||
    typeof manifest.bundleId !== 'string' ||
    manifest.bundleId.length === 0 ||
    manifest.reviewJsonPath !== 'review.json' ||
    !Array.isArray(manifest.exportedImages) ||
    !manifest.originalPhoto ||
    manifest.originalPhoto.included !== true ||
    manifest.originalPhoto.path !== originalRelativePath ||
    manifest.originalPhoto.fileSize <= 0) {
    throw new Error('manifest.json v2 字段不完整');
  }

  if (manifest.thumbnailPath !== undefined) {
    const thumbnailPath: string = manifest.thumbnailPath;
    if (thumbnailPath.trim().length === 0) {
      throw new Error('manifest.thumbnailPath 无效');
    }
    assertFileExists(`${paths.root}/${thumbnailPath}`, 'thumbnailPath');
  }

  verifyReviewJsonNotPolluted(paths.reviewJson);
}

function buildUploadFiles(
  paths: ReviewBundleOriginalPhotoPaths,
  originalRelativePath: string
): Array<HomeStorageUploadFileEntry> {
  return [
    { localPath: paths.manifest, remoteRelativePath: 'manifest.json' },
    { localPath: paths.reviewJson, remoteRelativePath: 'review.json' },
    { localPath: paths.originalPhoto, remoteRelativePath: originalRelativePath }
  ];
}

function resolveUploadFailureMessage(result: HomeStorageOperationResult): string {
  if (result.errorType === HomeStorageErrorType.NOT_CONFIGURED ||
    result.errorType === HomeStorageErrorType.INCOMPLETE_CONFIG ||
    result.errorType === HomeStorageErrorType.UNREACHABLE ||
    result.errorType === HomeStorageErrorType.AUTH_FAILED ||
    result.errorType === HomeStorageErrorType.DIRECTORY_CREATE_FAILED) {
    return result.message;
  }
  return ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT;
}

export class ReviewBundleOriginalPhotoExportService {
  static async exportOriginalPhotoReviewBundleToHomeStorage(
    context: common.UIAbilityContext,
    document: ReviewCardDocument,
    reviewerText: string
  ): Promise<ReviewBundleOriginalPhotoExportResult> {
    const createdAt: number = Date.now();
    const dateParts: ReviewBundleDateParts = resolveDateParts(createdAt);
    const bundleId: string = `review-bundle-${dateParts.year}${dateParts.month}${dateParts.day}-${dateParts.hour}${dateParts.minute}${dateParts.second}-${document.createdAt}-${safeHash(`${document.createdAt}-${document.updatedAt}-${createdAt}-original`)}`;
    const bundleDirectoryName: string = sanitizeBundleName(`review_${dateParts.year}${dateParts.month}${dateParts.day}_${dateParts.hour}${dateParts.minute}${dateParts.second}_${safeHash(bundleId)}`);
    const extension: string = resolveSafeOriginalExtension(document);
    const originalFileName: string = `original.${extension}`;
    const originalRelativePath: string = originalFileName;
    const paths: ReviewBundleOriginalPhotoPaths = buildLocalPaths(context, bundleDirectoryName, originalFileName);
    const remoteDirectory: string = bundleDirectoryName;
    const reviewId: number = document.createdAt;

    try {
      const hasOriginalSource: boolean = hasDisplayableImageUri(document.imageUri);
      const sourceUriScheme: string = resolveUriScheme(document.imageUri);
      const sourceUriDigest: string = safeUriDigest(document.imageUri);
      const sourceFileName: string = resolveSourceFileName(document);
      const mimeType: string = resolveMimeType(extension);
      console.info(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_start review_id=${reviewId} bundleId=${bundleId} document_file_name=${sourceFileName.length > 0 ? 'present' : 'empty'} original_source_uri=${hasOriginalSource ? 'present' : 'missing'} image_uri=${hasOriginalSource ? 'present' : 'missing'} uri_scheme=${sourceUriScheme} uri_digest=${sourceUriDigest} uri_length=${document.imageUri.length} local=${paths.root}`);
      console.info(`[ReviewBundleOriginalPhotoExport] remote_target_directory review_id=${reviewId} bundleId=${bundleId} remote=${remoteDirectory}`);

      if (!hasOriginalSource) {
        console.error(`[ReviewBundleOriginalPhotoExport] original_read_failed review_id=${reviewId} bundleId=${bundleId} type=${HomeStorageErrorType.ORIGINAL_READ_FAILED} reason=missing_source_uri image_uri=missing`);
        console.error(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_failed review_id=${reviewId} bundleId=${bundleId} type=${HomeStorageErrorType.ORIGINAL_READ_FAILED} error=missing_source_uri stack=`);
        return {
          success: false,
          localBundlePath: '',
          remotePath: '',
          bundleId: bundleId,
          bundleDirectoryName: bundleDirectoryName,
          message: ORIGINAL_READ_FAILED_TEXT,
          errorType: HomeStorageErrorType.ORIGINAL_READ_FAILED
        };
      }

      ensureDirectory(paths.root);
      console.info(`[ReviewBundleOriginalPhotoExport] local_directories_ready root=${paths.root}`);

      console.info(`[ReviewBundleOriginalPhotoExport] original_copy_start review_id=${reviewId} bundleId=${bundleId} target=${originalRelativePath} read_method=fs.openSync_read_only uri_scheme=${sourceUriScheme} uri_digest=${sourceUriDigest}`);
      const copyResult: OriginalPhotoCopyResult = copyOriginalPhoto(document.imageUri, paths.originalPhoto);
      if (!copyResult.success) {
        const failedToken: string = copyResult.errorType === HomeStorageErrorType.ORIGINAL_READ_FAILED ? 'original_read_failed' : 'original_copy_failed';
        console.error(`[ReviewBundleOriginalPhotoExport] ${failedToken} review_id=${reviewId} bundleId=${bundleId} type=${copyResult.errorType} raw_message=${copyResult.rawMessage} raw_stack=${copyResult.rawStack}`);
        console.error(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_failed review_id=${reviewId} bundleId=${bundleId} type=${copyResult.errorType} error=${copyResult.rawMessage} stack=${copyResult.rawStack}`);
        return {
          success: false,
          localBundlePath: paths.root,
          remotePath: '',
          bundleId: bundleId,
          bundleDirectoryName: bundleDirectoryName,
          message: copyResult.message,
          errorType: copyResult.errorType
        };
      }
      const originalSize: number = fileSize(paths.originalPhoto);
      if (originalSize <= 0) {
        console.error(`[ReviewBundleOriginalPhotoExport] original_copy_failed review_id=${reviewId} bundleId=${bundleId} type=${HomeStorageErrorType.ORIGINAL_COPY_FAILED} reason=empty_file fileSize=${originalSize}`);
        console.error(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_failed review_id=${reviewId} bundleId=${bundleId} type=${HomeStorageErrorType.ORIGINAL_COPY_FAILED} error=empty_file stack=`);
        return {
          success: false,
          localBundlePath: paths.root,
          remotePath: '',
          bundleId: bundleId,
          bundleDirectoryName: bundleDirectoryName,
          message: ORIGINAL_COPY_FAILED_TEXT,
          errorType: HomeStorageErrorType.ORIGINAL_COPY_FAILED
        };
      }
      console.info(`[ReviewBundleOriginalPhotoExport] original_copy_success review_id=${reviewId} bundleId=${bundleId} localPath=${paths.originalPhoto} fileSize=${originalSize} ext=${extension} mimeType=${mimeType}`);

      writeTextFile(paths.reviewJson, stringifyReviewCardExchangeSchemaV1(document, reviewerText));
      console.info(`[ReviewBundleOriginalPhotoExport] review_json_write_success path=${paths.reviewJson} bytes=${fileSize(paths.reviewJson)}`);
      writeTextFile(paths.manifest, buildManifest(
        document,
        reviewerText,
        bundleId,
        dateParts,
        originalRelativePath,
        originalSize,
        mimeType,
        sourceFileName
      ));
      console.info(`[ReviewBundleOriginalPhotoExport] manifest_v2_write_success path=${paths.manifest} bytes=${fileSize(paths.manifest)}`);

      console.info(`[ReviewBundleOriginalPhotoExport] local_bundle_v2_validation_start review_id=${reviewId} bundleId=${bundleId}`);
      try {
        verifyBundle(paths, originalRelativePath);
      } catch (error) {
        const validationMessage: string = describeUnknownError(error);
        const validationStack: string = describeUnknownStack(error);
        console.error(`[ReviewBundleOriginalPhotoExport] local_bundle_v2_validation_failed review_id=${reviewId} bundleId=${bundleId} type=${HomeStorageErrorType.LOCAL_BUNDLE_VALIDATION_FAILED} message=${validationMessage} stack=${validationStack}`);
        console.error(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_failed review_id=${reviewId} bundleId=${bundleId} type=${HomeStorageErrorType.LOCAL_BUNDLE_VALIDATION_FAILED} error=${validationMessage} stack=${validationStack}`);
        return {
          success: false,
          localBundlePath: paths.root,
          remotePath: '',
          bundleId: bundleId,
          bundleDirectoryName: bundleDirectoryName,
          message: ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT,
          errorType: HomeStorageErrorType.LOCAL_BUNDLE_VALIDATION_FAILED
        };
      }
      console.info(`[ReviewBundleOriginalPhotoExport] local_bundle_v2_validation_success review_id=${reviewId} bundleId=${bundleId}`);

      const availabilityResult: HomeStorageOperationResult = await HomeStorageService.checkAvailability(context);
      console.info(`[ReviewBundleOriginalPhotoExport] home_storage_reachability_result review_id=${reviewId} bundleId=${bundleId} success=${availabilityResult.success} type=${availabilityResult.errorType} message=${availabilityResult.message}`);
      if (!availabilityResult.success) {
        console.error(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_failed review_id=${reviewId} bundleId=${bundleId} type=${availabilityResult.errorType} error=${availabilityResult.message} stack=`);
        return {
          success: false,
          localBundlePath: paths.root,
          remotePath: availabilityResult.remotePath,
          bundleId: bundleId,
          bundleDirectoryName: bundleDirectoryName,
          message: availabilityResult.message,
          errorType: availabilityResult.errorType
        };
      }

      console.info(`[ReviewBundleOriginalPhotoExport] bundle_v2_upload_start review_id=${reviewId} bundleId=${bundleId} remote=${remoteDirectory}`);
      console.info(`[ReviewBundleOriginalPhotoExport] original_upload_start review_id=${reviewId} bundleId=${bundleId} remote=${remoteDirectory} bytes=${originalSize}`);
      const uploadResult: HomeStorageOperationResult = await HomeStorageService.uploadFilesToDirectory(
        context,
        remoteDirectory,
        buildUploadFiles(paths, originalRelativePath)
      );
      if (!uploadResult.success) {
        console.error(`[ReviewBundleOriginalPhotoExport] original_upload_failed review_id=${reviewId} bundleId=${bundleId} remote=${remoteDirectory} type=${uploadResult.errorType} message=${uploadResult.message}`);
        console.error(`[ReviewBundleOriginalPhotoExport] bundle_v2_upload_failed review_id=${reviewId} bundleId=${bundleId} type=${uploadResult.errorType} message=${uploadResult.message}`);
        console.error(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_failed review_id=${reviewId} bundleId=${bundleId} type=${uploadResult.errorType} error=${uploadResult.message} stack=`);
        return {
          success: false,
          localBundlePath: paths.root,
          remotePath: uploadResult.remotePath,
          bundleId: bundleId,
          bundleDirectoryName: bundleDirectoryName,
          message: resolveUploadFailureMessage(uploadResult),
          errorType: uploadResult.errorType
        };
      }

      console.info(`[ReviewBundleOriginalPhotoExport] original_upload_success review_id=${reviewId} bundleId=${bundleId} remote=${uploadResult.remotePath}`);
      console.info(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_success review_id=${reviewId} bundleId=${bundleId} remote=${uploadResult.remotePath}`);
      return {
        success: true,
        localBundlePath: paths.root,
        remotePath: uploadResult.remotePath,
        bundleId: bundleId,
        bundleDirectoryName: bundleDirectoryName,
        message: ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT,
        errorType: HomeStorageErrorType.NONE
      };
    } catch (error) {
      const message: string = describeUnknownError(error);
      const stack: string = describeUnknownStack(error);
      console.error(`[ReviewBundleOriginalPhotoExport] bundle_v2_export_failed review_id=${reviewId} bundleId=${bundleId} type=${HomeStorageErrorType.UPLOAD_FAILED} error=${message} stack=${stack}`);
      return {
        success: false,
        localBundlePath: paths.root,
        remotePath: '',
        bundleId: bundleId,
        bundleDirectoryName: bundleDirectoryName,
        message: ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT,
        errorType: HomeStorageErrorType.UPLOAD_FAILED
      };
    }
  }
}
