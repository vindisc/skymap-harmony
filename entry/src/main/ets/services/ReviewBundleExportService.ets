import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import {
  createReviewCardExchangeSchemaV1,
  mapReviewJudgementToExchangeDecision,
  stringifyReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';
import { ReviewCardExportService, ReviewCardBundleSnapshotResult } from './ReviewCardExportService';
import { HomeStorageOperationResult, HomeStorageService, HomeStorageUploadFileEntry } from './HomeStorageService';

export interface ReviewBundleExportResult {
  success: boolean;
  localBundlePath: string;
  remotePath: string;
  bundleId: string;
  bundleDirectoryName: string;
  message: string;
}

interface ReviewBundlePaths {
  root: string;
  manifest: string;
  reviewJson: string;
  reviewCardImage: string;
  thumbnail: string;
  assetsReadme: string;
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

interface ReviewBundleExportedImageManifest {
  path: string;
  type: string;
  width: number;
  height: number;
  createdAt: string;
}

interface ReviewBundleOriginalPhotoManifest {
  included: boolean;
  fileName: string;
  pixelWidth: number;
  pixelHeight: number;
}

interface ReviewBundleReviewSummaryManifest {
  decision: string;
  titleText: string;
  reviewTimeText: string;
  reviewerText: string;
}

interface ReviewBundleManifestV1 {
  bundleVersion: number;
  bundleId: string;
  createdAt: string;
  updatedAt: string;
  sourceApp: string;
  sourceAppVersion: string;
  platform: string;
  reviewJsonPath: string;
  exportedImages: Array<ReviewBundleExportedImageManifest>;
  thumbnailPath: string;
  originalPhoto: ReviewBundleOriginalPhotoManifest;
  review: ReviewBundleReviewSummaryManifest;
}

const LOCAL_BUNDLE_DIR_NAME: string = 'review_bundles';
const SOURCE_APP: string = 'skymap-harmonyos';
const SOURCE_APP_VERSION: string = '0.1.0';
const PLATFORM: string = 'HarmonyOS';
const REVIEW_CARD_IMAGE_PATH: string = 'exports/review-card.png';
const THUMBNAIL_PATH: string = 'thumbnails/thumb.jpg';
const ASSETS_README_PATH: string = 'assets/README.md';

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
  fs.mkdirSync(path, true);
}

function writeTextFile(path: string, value: string): void {
  const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, encodeUtf8(value));
  } finally {
    fs.closeSync(file);
  }
}

function describeError(error: Error): string {
  return error.message;
}

function describeStack(error: Error): string {
  return typeof error.stack === 'string' ? error.stack : '';
}

function fileSize(path: string): number {
  try {
    return fs.statSync(path).size;
  } catch (error) {
    return -1;
  }
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

function buildLocalPaths(context: common.UIAbilityContext, bundleDirectoryName: string): ReviewBundlePaths {
  const root: string = `${context.filesDir}/${LOCAL_BUNDLE_DIR_NAME}/${bundleDirectoryName}`;
  return {
    root: root,
    manifest: `${root}/manifest.json`,
    reviewJson: `${root}/review.json`,
    reviewCardImage: `${root}/${REVIEW_CARD_IMAGE_PATH}`,
    thumbnail: `${root}/${THUMBNAIL_PATH}`,
    assetsReadme: `${root}/${ASSETS_README_PATH}`
  };
}

function buildManifest(
  document: ReviewCardDocument,
  reviewerText: string,
  bundleId: string,
  dateParts: ReviewBundleDateParts,
  exportWidth: number,
  exportHeight: number
): string {
  const reviewSummary = createReviewCardExchangeSchemaV1(document, reviewerText);
  const exportedImages: Array<ReviewBundleExportedImageManifest> = [
    {
      path: REVIEW_CARD_IMAGE_PATH,
      type: 'review-card',
      width: exportWidth > 0 ? exportWidth : 0,
      height: exportHeight > 0 ? exportHeight : 0,
      createdAt: dateParts.isoText
    }
  ];
  const manifest: ReviewBundleManifestV1 = {
    bundleVersion: 1,
    bundleId: bundleId,
    createdAt: dateParts.isoText,
    updatedAt: dateParts.isoText,
    sourceApp: SOURCE_APP,
    sourceAppVersion: SOURCE_APP_VERSION,
    platform: PLATFORM,
    reviewJsonPath: 'review.json',
    exportedImages: exportedImages,
    thumbnailPath: THUMBNAIL_PATH,
    originalPhoto: {
      included: false,
      fileName: reviewSummary.fileName,
      pixelWidth: document.imageWidth > 0 ? document.imageWidth : 0,
      pixelHeight: document.imageHeight > 0 ? document.imageHeight : 0
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

function buildAssetsReadme(): string {
  return [
    '# assets',
    '',
    'review bundle v1 默认不打包原图。',
    '本目录仅作为后续 originalPhoto.included=true 设计的占位目录。'
  ].join('\n');
}

function verifyBundle(paths: ReviewBundlePaths): void {
  assertFileExists(paths.manifest, 'manifest.json');
  assertFileExists(paths.reviewJson, 'review.json');
  assertFileExists(paths.reviewCardImage, 'exports/review-card.png');
  assertFileExists(paths.thumbnail, 'thumbnails/thumb.jpg');
  assertFileExists(paths.assetsReadme, 'assets/README.md');

  const manifestText: string = fs.readTextSync(paths.manifest);
  const manifest: ReviewBundleManifestV1 = JSON.parse(manifestText) as ReviewBundleManifestV1;
  if (manifest.bundleVersion !== 1 ||
    typeof manifest.bundleId !== 'string' ||
    manifest.bundleId.length === 0 ||
    manifest.reviewJsonPath !== 'review.json' ||
    !Array.isArray(manifest.exportedImages) ||
    manifest.exportedImages.length === 0 ||
    manifest.exportedImages[0].path !== REVIEW_CARD_IMAGE_PATH ||
    !manifest.originalPhoto ||
    manifest.originalPhoto.included !== false) {
    throw new Error('manifest.json 字段不完整');
  }

  JSON.parse(fs.readTextSync(paths.reviewJson)) as Object;
}

function buildUploadFiles(paths: ReviewBundlePaths): Array<HomeStorageUploadFileEntry> {
  return [
    { localPath: paths.manifest, remoteRelativePath: 'manifest.json' },
    { localPath: paths.reviewJson, remoteRelativePath: 'review.json' },
    { localPath: paths.reviewCardImage, remoteRelativePath: REVIEW_CARD_IMAGE_PATH },
    { localPath: paths.thumbnail, remoteRelativePath: THUMBNAIL_PATH },
    { localPath: paths.assetsReadme, remoteRelativePath: ASSETS_README_PATH }
  ];
}

export class ReviewBundleExportService {
  static async exportReviewBundleToHomeStorage(
    context: common.UIAbilityContext,
    document: ReviewCardDocument,
    reviewerText: string,
    componentId: string,
    exportWidth: number,
    exportHeight: number,
    onSnapshotReady: () => void = () => {}
  ): Promise<ReviewBundleExportResult> {
    const createdAt: number = Date.now();
    const dateParts: ReviewBundleDateParts = resolveDateParts(createdAt);
    const bundleId: string = `review-bundle-${dateParts.year}${dateParts.month}${dateParts.day}-${dateParts.hour}${dateParts.minute}${dateParts.second}-${document.createdAt}-${safeHash(`${document.createdAt}-${document.updatedAt}-${createdAt}`)}`;
    const bundleDirectoryName: string = sanitizeBundleName(`review_${dateParts.year}${dateParts.month}${dateParts.day}_${dateParts.hour}${dateParts.minute}${dateParts.second}_${safeHash(bundleId)}`);
    const paths: ReviewBundlePaths = buildLocalPaths(context, bundleDirectoryName);
    const remoteDirectory: string = `Skymap/ReviewBundles/${dateParts.year}/${dateParts.month}/${bundleDirectoryName}`;

    try {
      console.info(`[ReviewBundleExport] start reviewId=${document.createdAt} bundleId=${bundleId} local=${paths.root} remote=${remoteDirectory}`);
      ensureDirectory(`${paths.root}/exports`);
      ensureDirectory(`${paths.root}/thumbnails`);
      ensureDirectory(`${paths.root}/assets`);
      console.info(`[ReviewBundleExport] local_directories_ready root=${paths.root}`);

      writeTextFile(paths.reviewJson, stringifyReviewCardExchangeSchemaV1(document, reviewerText));
      console.info(`[ReviewBundleExport] review_json_written path=${paths.reviewJson} bytes=${fileSize(paths.reviewJson)}`);
      const snapshotResult: ReviewCardBundleSnapshotResult = await ReviewCardExportService.exportBundleSnapshot(
        componentId,
        paths.reviewCardImage,
        paths.thumbnail,
        onSnapshotReady
      );
      if (!snapshotResult.success) {
        console.error(`[ReviewBundleExport] snapshot_failed reviewId=${document.createdAt} bundleId=${bundleId} message=${snapshotResult.message}`);
        return {
          success: false,
          localBundlePath: paths.root,
          remotePath: '',
          bundleId: bundleId,
          bundleDirectoryName: bundleDirectoryName,
          message: snapshotResult.message
        };
      }
      console.info(`[ReviewBundleExport] review_card_written path=${paths.reviewCardImage} bytes=${fileSize(paths.reviewCardImage)}`);
      console.info(`[ReviewBundleExport] thumbnail_written path=${paths.thumbnail} bytes=${fileSize(paths.thumbnail)}`);

      writeTextFile(paths.assetsReadme, buildAssetsReadme());
      console.info(`[ReviewBundleExport] assets_readme_written path=${paths.assetsReadme} bytes=${fileSize(paths.assetsReadme)}`);
      writeTextFile(paths.manifest, buildManifest(document, reviewerText, bundleId, dateParts, exportWidth, exportHeight));
      console.info(`[ReviewBundleExport] manifest_written path=${paths.manifest} bytes=${fileSize(paths.manifest)}`);
      verifyBundle(paths);
      console.info(`[ReviewBundleExport] local_bundle_verified bundleId=${bundleId}`);

      const uploadResult: HomeStorageOperationResult = await HomeStorageService.uploadFilesToDirectory(
        context,
        remoteDirectory,
        buildUploadFiles(paths)
      );
      console.info(`[ReviewBundleExport] upload_finished success=${uploadResult.success} remote=${uploadResult.remotePath} message=${uploadResult.message}`);
      return {
        success: uploadResult.success,
        localBundlePath: paths.root,
        remotePath: uploadResult.remotePath,
        bundleId: bundleId,
        bundleDirectoryName: bundleDirectoryName,
        message: uploadResult.success ? '复盘包已写入家庭存储' : uploadResult.message
      };
    } catch (error) {
      const message: string = error instanceof Error ? describeError(error) : `${error}`;
      const stack: string = error instanceof Error ? describeStack(error) : '';
      console.error(`[ReviewBundleExport] failed reviewId=${document.createdAt} bundleId=${bundleId} local=${paths.root} remote=${remoteDirectory} error=${message} stack=${stack}`);
      return {
        success: false,
        localBundlePath: paths.root,
        remotePath: '',
        bundleId: bundleId,
        bundleDirectoryName: bundleDirectoryName,
        message: message
      };
    }
  }
}
