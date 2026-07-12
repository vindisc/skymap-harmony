import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import cryptoFramework from '@ohos.security.cryptoFramework';
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

export const REVIEW_LIBRARY_BACKUP_SCHEMA_NAME: string = 'JianYuReviewLibraryBackup';
export const REVIEW_LIBRARY_BACKUP_SCHEMA_VERSION: string = 'v1';
export const REVIEW_LIBRARY_BACKUP_EXTENSION: string = 'jybackup';
const REVIEW_LIBRARY_BACKUP_APP_VERSION: string = '0.1.0';
const REVIEW_LIBRARY_BACKUP_CHECKSUM_ALGORITHM: string = 'SHA-256';
const REVIEW_LIBRARY_BACKUP_GUIDE_PREFERENCES: string = 'review_library_backup_guide';
const REVIEW_LIBRARY_BACKUP_GUIDE_SHOWN_KEY: string = 'first_restore_guide_shown';
const REVIEW_LIBRARY_BACKUP_MAX_TEXT_LENGTH: number = 32 * 1024 * 1024;

export interface ReviewLibraryBackupRecordV1 {
  reviewId: string;
  document: ReviewCardDocument;
  exportedPath: string;
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
  fileName: string;
  message: string;
}

export interface ReviewLibraryBackupInspection {
  success: boolean;
  cancelled: boolean;
  itemCount: number;
  createdAt: number;
  fileName: string;
  message: string;
  payload?: ReviewLibraryBackupPayloadV1;
}

export interface ReviewLibraryBackupRestoreResult {
  success: boolean;
  itemCount: number;
  settingsRestored: boolean;
  message: string;
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
  const md: cryptoFramework.Md = cryptoFramework.createMd('SHA256');
  md.updateSync({ data: encodeUtf8(value) });
  const digest: cryptoFramework.DataBlob = md.digestSync();
  const bytes: Uint8Array = new Uint8Array(digest.data);
  let result: string = '';
  for (let index = 0; index < bytes.length; index += 1) {
    result += bytes[index].toString(16).padStart(2, '0');
  }
  return result;
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

function validatePayload(payload: ReviewLibraryBackupPayloadV1): Array<ReviewLibraryBackupRecordV1> {
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
    records.push({
      reviewId: record.reviewId,
      document: cloneReviewCardDocument(record.document),
      exportedPath: normalizeText(record.exportedPath)
    });
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

export class ReviewLibraryBackupService {
  static async countBackupItems(context: common.UIAbilityContext): Promise<number> {
    return ReviewCardRdbService.countReviews(context, { includeDeleted: false });
  }

  static async exportToUserFile(context: common.UIAbilityContext): Promise<ReviewLibraryBackupExportResult> {
    const rows: Array<ReviewCardRdbRow> = await ReviewCardRdbService.listReviewRows(context, { includeDeleted: false });
    const records: Array<ReviewLibraryBackupRecordV1> = [];
    rows.forEach((row: ReviewCardRdbRow): void => {
      const item: ReviewCardHistoryItem | undefined = ReviewCardRdbMapper.toHistoryItem(row);
      if (!item) {
        throw new Error(`复盘 ${row.id} 无法解析，已停止备份`);
      }
      records.push({
        reviewId: row.id,
        document: cloneReviewCardDocument(item.document),
        exportedPath: item.exportedPath
      });
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
        fileName: fileName,
        message: `已备份 ${records.length} 条复盘`
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
      maxSelectNumber: 1
    });
    if (selectedUris.length <= 0) {
      return {
        success: false,
        cancelled: true,
        itemCount: 0,
        createdAt: 0,
        fileName: '',
        message: '已取消恢复'
      };
    }

    const selectedUri: string = selectedUris[0];
    const fileName: string = resolveFileNameFromUri(selectedUri);
    const sandboxPath: string = `${context.cacheDir}/selected-review-library-backup.${REVIEW_LIBRARY_BACKUP_EXTENSION}`;
    copyFile(selectedUri, sandboxPath);
    try {
      const rawText: string = fs.readTextSync(sandboxPath);
      if (rawText.length <= 0 || rawText.length > REVIEW_LIBRARY_BACKUP_MAX_TEXT_LENGTH) {
        throw new Error('备份文件为空或超过 32 MB');
      }
      const envelope: ReviewLibraryBackupEnvelopeV1 = JSON.parse(rawText) as ReviewLibraryBackupEnvelopeV1;
      if (envelope.schemaName !== REVIEW_LIBRARY_BACKUP_SCHEMA_NAME) {
        throw new Error('不是见遇完整备份文件');
      }
      if (envelope.schemaVersion !== REVIEW_LIBRARY_BACKUP_SCHEMA_VERSION) {
        throw new Error(`暂不支持备份版本 ${envelope.schemaVersion}`);
      }
      if (envelope.checksumAlgorithm !== REVIEW_LIBRARY_BACKUP_CHECKSUM_ALGORITHM) {
        throw new Error('备份校验算法不受支持');
      }
      const expectedChecksum: string = sha256(JSON.stringify(envelope.payload));
      if (expectedChecksum !== envelope.checksum) {
        throw new Error('备份完整性校验失败，文件可能已损坏');
      }
      const records: Array<ReviewLibraryBackupRecordV1> = validatePayload(envelope.payload);
      const payload: ReviewLibraryBackupPayloadV1 = {
        createdAt: envelope.payload.createdAt,
        appVersion: normalizeText(envelope.payload.appVersion),
        reviewCount: records.length,
        reviews: records,
        settings: normalizeSettings(envelope.payload.settings)
      };
      const inspection: ReviewLibraryBackupInspection = {
        success: true,
        cancelled: false,
        itemCount: records.length,
        createdAt: payload.createdAt,
        fileName: fileName,
        message: `已验证 ${records.length} 条复盘`,
        payload: payload
      };
      return inspection;
    } finally {
      try {
        fs.unlinkSync(sandboxPath);
      } catch (error) {
      }
    }
  }

  static async restoreInspectedBackup(
    context: common.UIAbilityContext,
    inspection: ReviewLibraryBackupInspection
  ): Promise<ReviewLibraryBackupRestoreResult> {
    if (!inspection.success || !inspection.payload) {
      return {
        success: false,
        itemCount: 0,
        settingsRestored: false,
        message: '备份尚未通过校验'
      };
    }

    const replacements: Array<ReviewCardRdbReplacementItem> = [];
    inspection.payload.reviews.forEach((record: ReviewLibraryBackupRecordV1): void => {
      const historyItem: ReviewCardHistoryItem = {
        document: cloneReviewCardDocument(record.document),
        exportedPath: record.exportedPath
      };
      const replacement: ReviewCardRdbReplacementItem = {
        reviewId: record.reviewId,
        item: historyItem
      };
      replacements.push(replacement);
    });
    await ReviewCardHistoryService.replaceAllFromBackup(context, replacements);

    let settingsRestored: boolean = true;
    try {
      const settings: ReviewLibraryBackupSettingsV1 = inspection.payload.settings;
      await ReviewSettingsService.saveReviewerName(context, settings.reviewerName);
      await ReviewSettingsService.saveWidgetCardBackgroundStyle(context, settings.widgetCardBackgroundStyle);
      await ReviewSettingsService.saveShatterAnimationEnabled(context, settings.shatterAnimationEnabled);
    } catch (error) {
      settingsRestored = false;
    }
    return {
      success: true,
      itemCount: replacements.length,
      settingsRestored: settingsRestored,
      message: settingsRestored
        ? `已恢复 ${replacements.length} 条复盘和常用设置`
        : `已恢复 ${replacements.length} 条复盘，部分设置未恢复`
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
