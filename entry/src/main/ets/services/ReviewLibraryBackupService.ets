import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import picker from '@ohos.file.picker';
import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';
import {
  cloneReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardHistoryItem
} from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from './ReviewCardHistoryService';
import { ReviewCardRdbReplacementItem, ReviewCardRdbService } from './ReviewCardRdbService';
import { ReviewCardRdbMapper, ReviewCardRdbRow } from './ReviewCardRdbModel';
import { ReviewSettingsService } from './ReviewSettingsService';
import { isSampleImageUri } from '../utils/ImageLayoutUtils';

export const REVIEW_LIBRARY_BACKUP_SCHEMA_NAME: string = 'JianYuReviewLibraryBackup';
export const REVIEW_LIBRARY_BACKUP_SCHEMA_VERSION: string = 'v2';
export const REVIEW_LIBRARY_BACKUP_EXTENSION: string = 'jybackup';
const REVIEW_LIBRARY_BACKUP_LEGACY_SCHEMA_VERSION: string = 'v1';
const REVIEW_LIBRARY_BACKUP_APP_VERSION: string = '0.1.0';
const REVIEW_LIBRARY_BACKUP_CHECKSUM_ALGORITHM: string = 'SHA-256';
const REVIEW_LIBRARY_BACKUP_GUIDE_PREFERENCES: string = 'review_library_backup_guide';
const REVIEW_LIBRARY_BACKUP_GUIDE_SHOWN_KEY: string = 'first_restore_guide_shown';
const REVIEW_LIBRARY_BACKUP_MAX_TEXT_LENGTH: number = 300 * 1024 * 1024;
const REVIEW_LIBRARY_BACKUP_MAX_IMAGE_BYTES: number = 30 * 1024 * 1024;
const REVIEW_LIBRARY_BACKUP_MAX_TOTAL_IMAGE_BYTES: number = 200 * 1024 * 1024;
const REVIEW_LIBRARY_BACKUP_MAX_SELECT_NUMBER: number = 100;
const REVIEW_LIBRARY_RESTORED_IMAGE_DIR: string = 'review_library_restored_images';

export interface ReviewLibraryBackupImageV2 {
  fileName: string;
  byteLength: number;
  checksum: string;
  dataBase64: string;
}

export interface ReviewLibraryBackupRecordV1 {
  reviewId: string;
  document: ReviewCardDocument;
  exportedPath: string;
  image?: ReviewLibraryBackupImageV2;
}

export interface ReviewLibraryBackupSettingsV1 {
  reviewerName: string;
  widgetCardBackgroundStyle: string;
  shatterAnimationEnabled: boolean;
}

export interface ReviewLibraryBackupPayloadV1 {
  createdAt: number;
  appVersion: string;
  reviewCount: number;
  reviews: Array<ReviewLibraryBackupRecordV1>;
  settings: ReviewLibraryBackupSettingsV1;
}

export interface ReviewLibraryBackupEnvelopeV1 {
  schemaName: string;
  schemaVersion: string;
  checksumAlgorithm: string;
  checksum: string;
  payload: ReviewLibraryBackupPayloadV1;
}

export interface ReviewLibraryBackupExportResult {
  success: boolean;
  cancelled: boolean;
  itemCount: number;
  imageCount: number;
  fileName: string;
  message: string;
}

export interface ReviewLibraryBackupInspection {
  success: boolean;
  cancelled: boolean;
  itemCount: number;
  fileCount: number;
  imageCount: number;
  missingImageCount: number;
  createdAt: number;
  fileName: string;
  message: string;
  payload?: ReviewLibraryBackupPayloadV1;
}

export interface ReviewLibraryBackupRestoreResult {
  success: boolean;
  itemCount: number;
  restoredImageCount: number;
  missingImageCount: number;
  settingsRestored: boolean;
  message: string;
}

interface ParsedBackupFile {
  fileName: string;
  schemaVersion: string;
  payload: ReviewLibraryBackupPayloadV1;
}

function encodeUtf8(value: string): Uint8Array {
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
  return new Uint8Array(bytes);
}

function sha256(value: string): string {
  return sha256Bytes(encodeUtf8(value));
}

function sha256Bytes(value: Uint8Array): string {
  const md: cryptoFramework.Md = cryptoFramework.createMd('SHA256');
  md.updateSync({ data: value });
  const digest: cryptoFramework.DataBlob = md.digestSync();
  const bytes: Uint8Array = new Uint8Array(digest.data);
  let result: string = '';
  for (let index = 0; index < bytes.length; index += 1) {
    result += bytes[index].toString(16).padStart(2, '0');
  }
  return result;
}

function encodeBase64(value: Uint8Array): string {
  const helper: util.Base64Helper = new util.Base64Helper();
  return helper.encodeToStringSync(value);
}

function decodeBase64(value: string): Uint8Array {
  const helper: util.Base64Helper = new util.Base64Helper();
  return helper.decodeSync(value);
}

function readBinaryFile(path: string, maxBytes: number): Uint8Array {
  const file: fs.File = fs.openSync(path, fs.OpenMode.READ_ONLY);
  try {
    const stat = fs.statSync(file.fd);
    if (stat.size <= 0) {
      throw new Error('图片文件为空');
    }
    if (stat.size > maxBytes) {
      throw new Error(`单张图片超过 ${Math.floor(maxBytes / 1024 / 1024)} MB`);
    }
    const result: Uint8Array = new Uint8Array(stat.size);
    let totalRead: number = 0;
    while (totalRead < stat.size) {
      const chunkLength: number = Math.min(1024 * 1024, stat.size - totalRead);
      const chunkBuffer: ArrayBuffer = new ArrayBuffer(chunkLength);
      const readLength: number = fs.readSync(file.fd, chunkBuffer);
      if (readLength <= 0) {
        break;
      }
      result.set(new Uint8Array(chunkBuffer, 0, readLength), totalRead);
      totalRead += readLength;
    }
    if (totalRead !== stat.size) {
      throw new Error('图片文件读取不完整');
    }
    return result;
  } finally {
    fs.closeSync(file);
  }
}

function writeBinaryFile(path: string, value: Uint8Array): void {
  const file: fs.File = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, value.buffer);
  } finally {
    fs.closeSync(file);
  }
}

function writeTextFile(path: string, value: string): void {
  const file: fs.File = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, encodeUtf8(value).buffer);
  } finally {
    fs.closeSync(file);
  }
}

function copyFile(sourcePath: string, targetPath: string): void {
  const sourceFile: fs.File = fs.openSync(sourcePath, fs.OpenMode.READ_ONLY);
  const targetFile: fs.File = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.copyFileSync(sourceFile.fd, targetFile.fd);
  } finally {
    fs.closeSync(sourceFile);
    fs.closeSync(targetFile);
  }
}

function formatTimestamp(timestamp: number): string {
  const date = new Date(timestamp);
  const pad = (value: number): string => `${value}`.padStart(2, '0');
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}-${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
}

function resolveFileNameFromUri(uri: string): string {
  const cleanUri: string = uri.split('?')[0].split('#')[0];
  const parts: Array<string> = cleanUri.split('/');
  const rawName: string = parts.length > 0 ? parts[parts.length - 1] : '';
  try {
    return decodeURIComponent(rawName);
  } catch (error) {
    return rawName;
  }
}

function resolveImageExtension(imageUri: string): string {
  const fileName: string = resolveFileNameFromUri(imageUri).toLowerCase();
  const dotIndex: number = fileName.lastIndexOf('.');
  if (dotIndex >= 0) {
    const extension: string = fileName.slice(dotIndex + 1).replace(/[^a-z0-9]/g, '');
    if (extension === 'jpeg') {
      return 'jpg';
    }
    if (extension === 'jpg' || extension === 'png' || extension === 'webp' ||
      extension === 'heic' || extension === 'heif') {
      return extension;
    }
  }
  return 'jpg';
}

function createBackupImage(document: ReviewCardDocument, reviewId: string): ReviewLibraryBackupImageV2 | undefined {
  if (document.imageUri.trim().length === 0 || isSampleImageUri(document.imageUri)) {
    return undefined;
  }
  let bytes: Uint8Array;
  try {
    bytes = readBinaryFile(document.imageUri, REVIEW_LIBRARY_BACKUP_MAX_IMAGE_BYTES);
  } catch (error) {
    throw new Error(`复盘“${document.content.title || reviewId}”原图读取失败：${error}`);
  }
  return {
    fileName: `${reviewId}.${resolveImageExtension(document.imageUri)}`,
    byteLength: bytes.byteLength,
    checksum: sha256Bytes(bytes),
    dataBase64: encodeBase64(bytes)
  };
}

function cloneBackupImage(image: ReviewLibraryBackupImageV2 | undefined): ReviewLibraryBackupImageV2 | undefined {
  if (!image) {
    return undefined;
  }
  return {
    fileName: image.fileName,
    byteLength: image.byteLength,
    checksum: image.checksum,
    dataBase64: image.dataBase64
  };
}

function hasExpectedImage(document: ReviewCardDocument): boolean {
  return document.imageUri.trim().length > 0 && !isSampleImageUri(document.imageUri);
}

function ensureRestoredImageDirectory(context: common.UIAbilityContext): string {
  const directory: string = `${context.filesDir}/${REVIEW_LIBRARY_RESTORED_IMAGE_DIR}`;
  fs.mkdirSync(directory, true);
  return directory;
}

function cleanupRestoredImages(directory: string, retainedPaths: Set<string>): void {
  try {
    const fileNames: Array<string> = fs.listFileSync(directory);
    fileNames.forEach((fileName: string): void => {
      const path: string = `${directory}/${fileName}`;
      if (!retainedPaths.has(path)) {
        try {
          fs.unlinkSync(path);
        } catch (error) {
        }
      }
    });
  } catch (error) {
  }
}

function normalizeText(value: string | undefined): string {
  return typeof value === 'string' ? value : '';
}

function normalizeSettings(settings: ReviewLibraryBackupSettingsV1): ReviewLibraryBackupSettingsV1 {
  if (!settings) {
    throw new Error('备份内容缺少设置');
  }
  return {
    reviewerName: normalizeText(settings.reviewerName),
    widgetCardBackgroundStyle: normalizeText(settings.widgetCardBackgroundStyle),
    shatterAnimationEnabled: settings.shatterAnimationEnabled !== false
  };
}

function normalizeBackupImage(
  image: ReviewLibraryBackupImageV2 | undefined,
  schemaVersion: string
): ReviewLibraryBackupImageV2 | undefined {
  if (!image) {
    return undefined;
  }
  if (schemaVersion !== REVIEW_LIBRARY_BACKUP_SCHEMA_VERSION) {
    return undefined;
  }
  if (typeof image.fileName !== 'string' || image.fileName.trim().length === 0 ||
    typeof image.dataBase64 !== 'string' || image.dataBase64.length === 0 ||
    typeof image.byteLength !== 'number' || image.byteLength <= 0 ||
    typeof image.checksum !== 'string' || image.checksum.length === 0) {
    throw new Error('备份包含无效原图数据');
  }
  const bytes: Uint8Array = decodeBase64(image.dataBase64);
  if (bytes.byteLength !== image.byteLength || sha256Bytes(bytes) !== image.checksum) {
    throw new Error('备份原图完整性校验失败');
  }
  return {
    fileName: image.fileName,
    byteLength: image.byteLength,
    checksum: image.checksum,
    dataBase64: image.dataBase64
  };
}

function validatePayload(
  payload: ReviewLibraryBackupPayloadV1,
  schemaVersion: string
): Array<ReviewLibraryBackupRecordV1> {
  if (!payload || !Array.isArray(payload.reviews)) {
    throw new Error('备份内容缺少复盘列表');
  }
  if (payload.reviewCount !== payload.reviews.length) {
    throw new Error('备份记录数量校验失败');
  }

  const usedIds: Set<string> = new Set<string>();
  const records: Array<ReviewLibraryBackupRecordV1> = [];
  payload.reviews.forEach((record: ReviewLibraryBackupRecordV1): void => {
    if (!record || typeof record.reviewId !== 'string' || record.reviewId.trim().length === 0) {
      throw new Error('备份包含无效复盘 ID');
    }
    if (usedIds.has(record.reviewId)) {
      throw new Error('备份包含重复复盘 ID');
    }
    if (!record.document || typeof record.document.createdAt !== 'number' || record.document.createdAt <= 0) {
      throw new Error('备份包含无效复盘内容');
    }
    if (record.reviewId !== getReviewDocumentKey(record.document)) {
      throw new Error('备份复盘 ID 与内容不一致');
    }
    usedIds.add(record.reviewId);
    const normalizedRecord: ReviewLibraryBackupRecordV1 = {
      reviewId: record.reviewId,
      document: cloneReviewCardDocument(record.document),
      exportedPath: normalizeText(record.exportedPath)
    };
    const image: ReviewLibraryBackupImageV2 | undefined = normalizeBackupImage(record.image, schemaVersion);
    if (image) {
      normalizedRecord.image = image;
    }
    records.push(normalizedRecord);
  });
  return records;
}

async function loadBackupSettings(context: common.UIAbilityContext): Promise<ReviewLibraryBackupSettingsV1> {
  return {
    reviewerName: await ReviewSettingsService.loadReviewerName(context),
    widgetCardBackgroundStyle: await ReviewSettingsService.loadWidgetCardBackgroundStyle(context),
    shatterAnimationEnabled: await ReviewSettingsService.loadShatterAnimationEnabled(context)
  };
}

function isSupportedSchemaVersion(schemaVersion: string): boolean {
  return schemaVersion === REVIEW_LIBRARY_BACKUP_SCHEMA_VERSION ||
    schemaVersion === REVIEW_LIBRARY_BACKUP_LEGACY_SCHEMA_VERSION;
}

function parseBackupFile(
  context: common.UIAbilityContext,
  selectedUri: string,
  index: number
): ParsedBackupFile {
  const fileName: string = resolveFileNameFromUri(selectedUri);
  const sandboxPath: string =
    `${context.cacheDir}/selected-review-library-backup-${index}.${REVIEW_LIBRARY_BACKUP_EXTENSION}`;
  copyFile(selectedUri, sandboxPath);
  try {
    const rawText: string = fs.readTextSync(sandboxPath);
    if (rawText.length <= 0 || rawText.length > REVIEW_LIBRARY_BACKUP_MAX_TEXT_LENGTH) {
      throw new Error('文件为空或超过 300 MB');
    }
    const envelope: ReviewLibraryBackupEnvelopeV1 = JSON.parse(rawText) as ReviewLibraryBackupEnvelopeV1;
    if (envelope.schemaName !== REVIEW_LIBRARY_BACKUP_SCHEMA_NAME) {
      throw new Error('不是见遇完整备份文件');
    }
    if (!isSupportedSchemaVersion(envelope.schemaVersion)) {
      throw new Error(`暂不支持备份版本 ${envelope.schemaVersion}`);
    }
    if (envelope.checksumAlgorithm !== REVIEW_LIBRARY_BACKUP_CHECKSUM_ALGORITHM) {
      throw new Error('备份校验算法不受支持');
    }
    const expectedChecksum: string = sha256(JSON.stringify(envelope.payload));
    if (expectedChecksum !== envelope.checksum) {
      throw new Error('完整性校验失败，文件可能已损坏');
    }
    const records: Array<ReviewLibraryBackupRecordV1> =
      validatePayload(envelope.payload, envelope.schemaVersion);
    const payload: ReviewLibraryBackupPayloadV1 = {
      createdAt: envelope.payload.createdAt,
      appVersion: normalizeText(envelope.payload.appVersion),
      reviewCount: records.length,
      reviews: records,
      settings: normalizeSettings(envelope.payload.settings)
    };
    return {
      fileName: fileName,
      schemaVersion: envelope.schemaVersion,
      payload: payload
    };
  } catch (error) {
    throw new Error(`${fileName || `第 ${index + 1} 个文件`}：${error}`);
  } finally {
    try {
      fs.unlinkSync(sandboxPath);
    } catch (error) {
    }
  }
}

function shouldReplaceMergedRecord(
  existing: ReviewLibraryBackupRecordV1,
  candidate: ReviewLibraryBackupRecordV1
): boolean {
  if (candidate.document.updatedAt !== existing.document.updatedAt) {
    return candidate.document.updatedAt > existing.document.updatedAt;
  }
  return !existing.image && candidate.image !== undefined;
}

function cloneBackupRecord(record: ReviewLibraryBackupRecordV1): ReviewLibraryBackupRecordV1 {
  const cloned: ReviewLibraryBackupRecordV1 = {
    reviewId: record.reviewId,
    document: cloneReviewCardDocument(record.document),
    exportedPath: record.exportedPath
  };
  const image: ReviewLibraryBackupImageV2 | undefined = cloneBackupImage(record.image);
  if (image) {
    cloned.image = image;
  }
  return cloned;
}

function mergeBackupRecord(
  existing: ReviewLibraryBackupRecordV1,
  candidate: ReviewLibraryBackupRecordV1
): ReviewLibraryBackupRecordV1 {
  const merged: ReviewLibraryBackupRecordV1 = shouldReplaceMergedRecord(existing, candidate)
    ? cloneBackupRecord(candidate)
    : cloneBackupRecord(existing);
  if (!merged.image) {
    const fallbackImage: ReviewLibraryBackupImageV2 | undefined = candidate.image ?? existing.image;
    const clonedImage: ReviewLibraryBackupImageV2 | undefined = cloneBackupImage(fallbackImage);
    if (clonedImage) {
      merged.image = clonedImage;
    }
  }
  return merged;
}

export class ReviewLibraryBackupService {
  static async countBackupItems(context: common.UIAbilityContext): Promise<number> {
    return ReviewCardRdbService.countReviews(context, { includeDeleted: false });
  }

  static async exportToUserFile(context: common.UIAbilityContext): Promise<ReviewLibraryBackupExportResult> {
    const rows: Array<ReviewCardRdbRow> = await ReviewCardRdbService.listReviewRows(context, { includeDeleted: false });
    const records: Array<ReviewLibraryBackupRecordV1> = [];
    let imageCount: number = 0;
    let totalImageBytes: number = 0;
    rows.forEach((row: ReviewCardRdbRow): void => {
      const item: ReviewCardHistoryItem | undefined = ReviewCardRdbMapper.toHistoryItem(row);
      if (!item) {
        throw new Error(`复盘 ${row.id} 无法解析，已停止备份`);
      }
      const record: ReviewLibraryBackupRecordV1 = {
        reviewId: row.id,
        document: cloneReviewCardDocument(item.document),
        exportedPath: item.exportedPath
      };
      const image: ReviewLibraryBackupImageV2 | undefined = createBackupImage(item.document, row.id);
      if (image) {
        totalImageBytes += image.byteLength;
        if (totalImageBytes > REVIEW_LIBRARY_BACKUP_MAX_TOTAL_IMAGE_BYTES) {
          throw new Error('备份原图总大小超过 200 MB，请减少复盘数量后分批备份');
        }
        record.image = image;
        imageCount += 1;
      }
      records.push(record);
    });

    const now: number = Date.now();
    const payload: ReviewLibraryBackupPayloadV1 = {
      createdAt: now,
      appVersion: REVIEW_LIBRARY_BACKUP_APP_VERSION,
      reviewCount: records.length,
      reviews: records,
      settings: await loadBackupSettings(context)
    };
    const payloadText: string = JSON.stringify(payload);
    const envelope: ReviewLibraryBackupEnvelopeV1 = {
      schemaName: REVIEW_LIBRARY_BACKUP_SCHEMA_NAME,
      schemaVersion: REVIEW_LIBRARY_BACKUP_SCHEMA_VERSION,
      checksumAlgorithm: REVIEW_LIBRARY_BACKUP_CHECKSUM_ALGORITHM,
      checksum: sha256(payloadText),
      payload: payload
    };
    const fileName: string = `见遇完整备份-${formatTimestamp(now)}.${REVIEW_LIBRARY_BACKUP_EXTENSION}`;
    const sandboxPath: string = `${context.cacheDir}/${fileName}`;
    const verifyPath: string = `${context.cacheDir}/verify-${fileName}`;
    const envelopeText: string = JSON.stringify(envelope, null, 2);
    writeTextFile(sandboxPath, envelopeText);
    try {
      const documentPicker = new picker.DocumentViewPicker(context);
      const selectedUris: Array<string> = await documentPicker.save({
        newFileNames: [fileName],
        fileSuffixChoices: ['见遇备份|jybackup']
      });
      if (selectedUris.length <= 0) {
        return {
          success: false,
          cancelled: true,
          itemCount: records.length,
          imageCount: imageCount,
          fileName: fileName,
          message: '已取消备份'
        };
      }
      copyFile(sandboxPath, selectedUris[0]);
      copyFile(selectedUris[0], verifyPath);
      const savedText: string = fs.readTextSync(verifyPath);
      if (savedText !== envelopeText) {
        throw new Error('备份文件写入校验失败，请更换保存位置后重试');
      }
      const result: ReviewLibraryBackupExportResult = {
        success: true,
        cancelled: false,
        itemCount: records.length,
        imageCount: imageCount,
        fileName: fileName,
        message: `已备份 ${records.length} 条复盘和 ${imageCount} 张照片`
      };
      return result;
    } finally {
      try {
        fs.unlinkSync(sandboxPath);
      } catch (error) {
      }
      try {
        fs.unlinkSync(verifyPath);
      } catch (error) {
      }
    }
  }

  static async selectAndInspectBackup(context: common.UIAbilityContext): Promise<ReviewLibraryBackupInspection> {
    const documentPicker = new picker.DocumentViewPicker(context);
    // 部分手机文件选择器会隐藏自定义后缀，文件合法性统一由下方内容校验判定。
    const selectedUris: Array<string> = await documentPicker.select({
      maxSelectNumber: REVIEW_LIBRARY_BACKUP_MAX_SELECT_NUMBER
    });
    if (selectedUris.length <= 0) {
      return {
        success: false,
        cancelled: true,
        itemCount: 0,
        fileCount: 0,
        imageCount: 0,
        missingImageCount: 0,
        createdAt: 0,
        fileName: '',
        message: '已取消恢复'
      };
    }

    const parsedFiles: Array<ParsedBackupFile> = [];
    for (let index = 0; index < selectedUris.length; index += 1) {
      parsedFiles.push(parseBackupFile(context, selectedUris[index], index));
    }
    parsedFiles.sort((left: ParsedBackupFile, right: ParsedBackupFile): number => {
      return left.payload.createdAt - right.payload.createdAt;
    });

    const mergedRecords: Map<string, ReviewLibraryBackupRecordV1> =
      new Map<string, ReviewLibraryBackupRecordV1>();
    parsedFiles.forEach((parsed: ParsedBackupFile): void => {
      parsed.payload.reviews.forEach((record: ReviewLibraryBackupRecordV1): void => {
        const existing: ReviewLibraryBackupRecordV1 | undefined = mergedRecords.get(record.reviewId);
        if (!existing) {
          mergedRecords.set(record.reviewId, cloneBackupRecord(record));
        } else {
          mergedRecords.set(record.reviewId, mergeBackupRecord(existing, record));
        }
      });
    });

    const newest: ParsedBackupFile = parsedFiles[parsedFiles.length - 1];
    const records: Array<ReviewLibraryBackupRecordV1> = Array.from(mergedRecords.values());
    records.sort((left: ReviewLibraryBackupRecordV1, right: ReviewLibraryBackupRecordV1): number => {
      return right.document.updatedAt - left.document.updatedAt;
    });
    let imageCount: number = 0;
    let missingImageCount: number = 0;
    records.forEach((record: ReviewLibraryBackupRecordV1): void => {
      if (record.image) {
        imageCount += 1;
      } else if (hasExpectedImage(record.document)) {
        missingImageCount += 1;
      }
    });
    const payload: ReviewLibraryBackupPayloadV1 = {
      createdAt: newest.payload.createdAt,
      appVersion: newest.payload.appVersion,
      reviewCount: records.length,
      reviews: records,
      settings: newest.payload.settings
    };
    const fileCount: number = parsedFiles.length;
    const inspection: ReviewLibraryBackupInspection = {
      success: true,
      cancelled: false,
      itemCount: records.length,
      fileCount: fileCount,
      imageCount: imageCount,
      missingImageCount: missingImageCount,
      createdAt: payload.createdAt,
      fileName: fileCount === 1 ? newest.fileName : `${fileCount} 个备份文件`,
      message: `已合并 ${fileCount} 个备份，共 ${records.length} 条复盘`,
      payload: payload
    };
    return inspection;
  }

  static async restoreInspectedBackup(
    context: common.UIAbilityContext,
    inspection: ReviewLibraryBackupInspection
  ): Promise<ReviewLibraryBackupRestoreResult> {
    if (!inspection.success || !inspection.payload) {
      return {
        success: false,
        itemCount: 0,
        restoredImageCount: 0,
        missingImageCount: 0,
        settingsRestored: false,
        message: '备份尚未通过校验'
      };
    }

    const replacements: Array<ReviewCardRdbReplacementItem> = [];
    const restoredImageDirectory: string = ensureRestoredImageDirectory(context);
    const retainedImagePaths: Set<string> = new Set<string>();
    const createdImagePaths: Array<string> = [];
    let restoredImageCount: number = 0;
    try {
      inspection.payload.reviews.forEach((record: ReviewLibraryBackupRecordV1): void => {
        const document: ReviewCardDocument = cloneReviewCardDocument(record.document);
        if (record.image) {
          const bytes: Uint8Array = decodeBase64(record.image.dataBase64);
          if (bytes.byteLength !== record.image.byteLength || sha256Bytes(bytes) !== record.image.checksum) {
            throw new Error(`复盘“${document.content.title || record.reviewId}”原图校验失败`);
          }
          const imagePath: string = `${restoredImageDirectory}/${Date.now()}-${record.reviewId}.` +
            resolveImageExtension(record.image.fileName);
          writeBinaryFile(imagePath, bytes);
          document.imageUri = fileUri.getUriFromPath(imagePath);
          retainedImagePaths.add(imagePath);
          createdImagePaths.push(imagePath);
          restoredImageCount += 1;
        }
        const historyItem: ReviewCardHistoryItem = {
          document: document,
          exportedPath: record.exportedPath
        };
        const replacement: ReviewCardRdbReplacementItem = {
          reviewId: record.reviewId,
          item: historyItem
        };
        replacements.push(replacement);
      });
      await ReviewCardHistoryService.replaceAllFromBackup(context, replacements);
    } catch (error) {
      createdImagePaths.forEach((path: string): void => {
        try {
          fs.unlinkSync(path);
        } catch (unlinkError) {
        }
      });
      throw new Error(`恢复失败：${error}`);
    }
    cleanupRestoredImages(restoredImageDirectory, retainedImagePaths);

    let settingsRestored: boolean = true;
    try {
      const settings: ReviewLibraryBackupSettingsV1 = inspection.payload.settings;
      await ReviewSettingsService.saveReviewerName(context, settings.reviewerName);
      await ReviewSettingsService.saveWidgetCardBackgroundStyle(context, settings.widgetCardBackgroundStyle);
      await ReviewSettingsService.saveShatterAnimationEnabled(context, settings.shatterAnimationEnabled);
    } catch (error) {
      settingsRestored = false;
    }
    const missingImageCount: number = inspection.missingImageCount;
    let message: string = `已恢复 ${replacements.length} 条复盘和 ${restoredImageCount} 张照片`;
    if (missingImageCount > 0) {
      message += `，${missingImageCount} 张照片未包含在旧备份中`;
    }
    if (!settingsRestored) {
      message += '，部分设置未恢复';
    }
    return {
      success: true,
      itemCount: replacements.length,
      restoredImageCount: restoredImageCount,
      missingImageCount: missingImageCount,
      settingsRestored: settingsRestored,
      message: message
    };
  }

  static async shouldOfferFirstLaunchRestore(context: common.UIAbilityContext): Promise<boolean> {
    const store = await preferences.getPreferences(context, { name: REVIEW_LIBRARY_BACKUP_GUIDE_PREFERENCES });
    const hasShown = await store.get(REVIEW_LIBRARY_BACKUP_GUIDE_SHOWN_KEY, false);
    if (hasShown === true) {
      return false;
    }
    const shouldOffer: boolean = await ReviewCardRdbService.countReviews(context) === 0;
    await store.put(REVIEW_LIBRARY_BACKUP_GUIDE_SHOWN_KEY, true);
    await store.flush();
    return shouldOffer;
  }
}
