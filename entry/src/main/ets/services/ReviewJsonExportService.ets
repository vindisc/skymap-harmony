import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import {
  ReviewCardDocument
} from '../model/ReviewCardModel';
import {
  resolveReviewCardExchangeFileName,
  stringifyReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';
import { ReviewSettingsService } from './ReviewSettingsService';

export interface ReviewJsonExportResult {
  success: boolean;
  cancelled: boolean;
  path: string;
  directory: string;
  fileName: string;
  userSelectedUri: string;
  backupPath: string;
  exportedToUserFiles: boolean;
  message: string;
}

export interface ReviewJsonBackupResult {
  success: boolean;
  path: string;
  directory: string;
  fileName: string;
}

const REVIEW_JSON_EXPORT_DIR_NAME: string = 'review_exchange';
const REVIEW_JSON_EXTENSION: string = 'review.json';

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

function formatTimestamp(timestamp: number): string {
  const date = new Date(timestamp);
  const pad = (value: number): string => `${value}`.padStart(2, '0');
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}-${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
}

function sanitizeFileStem(value: string): string {
  const normalized: string = value
    .replace(/\.[^.]+$/, '')
    .replace(/[^0-9A-Za-z\u4E00-\u9FFF._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^[-._]+|[-._]+$/g, '');
  return normalized.length > 0 ? normalized.slice(0, 48) : 'review';
}

function resolveStableFileStem(document: ReviewCardDocument): string {
  const sourceFileName: string = resolveReviewCardExchangeFileName(document).trim();
  if (sourceFileName.length > 0) {
    return sanitizeFileStem(sourceFileName);
  }

  const titleStem: string = sanitizeFileStem(document.content.title.trim());
  if (titleStem !== 'review') {
    return titleStem;
  }

  return `review-${document.createdAt}`;
}

function resolveExportFileName(document: ReviewCardDocument): string {
  const stem: string = resolveStableFileStem(document);
  return `${formatTimestamp(document.updatedAt)}-${stem}.${REVIEW_JSON_EXTENSION}`;
}

function resolveBackupFileName(document: ReviewCardDocument): string {
  const stem: string = resolveStableFileStem(document);
  return `${formatTimestamp(document.createdAt)}-${document.createdAt}-${stem}.${REVIEW_JSON_EXTENSION}`;
}

function ensureExportDirectory(context: common.UIAbilityContext): string {
  const directory: string = `${context.filesDir}/${REVIEW_JSON_EXPORT_DIR_NAME}`;
  try {
    fs.mkdirSync(directory, true);
  } catch (error) {
  }
  return directory;
}

function writeReviewJson(outputPath: string, rawText: string): void {
  const file = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, encodeUtf8(rawText));
  } finally {
    fs.closeSync(file);
  }
}

function copySandboxFileToUri(sourcePath: string, targetUri: string): void {
  const sourceFile = fs.openSync(sourcePath, fs.OpenMode.READ_ONLY);
  const targetFile = fs.openSync(targetUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.copyFileSync(sourceFile.fd, targetFile.fd);
  } finally {
    fs.closeSync(sourceFile);
    fs.closeSync(targetFile);
  }
}

async function exportToUserSelectedDocument(
  context: common.UIAbilityContext,
  sandboxPath: string,
  fileName: string
): Promise<string> {
  const documentPicker = new picker.DocumentViewPicker(context);
  const selectedUris: Array<string> = await documentPicker.save({
    newFileNames: [fileName],
    fileSuffixChoices: ['JSON 文件|json']
  });
  const targetUri: string = selectedUris.length > 0 ? selectedUris[0] : '';
  if (targetUri.length > 0) {
    copySandboxFileToUri(sandboxPath, targetUri);
  }
  return targetUri;
}

export class ReviewJsonExportService {
  static async writeSandboxReviewJsonBackup(
    context: common.UIAbilityContext,
    document: ReviewCardDocument
  ): Promise<ReviewJsonBackupResult> {
    try {
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(context);
      const reviewJson: string = stringifyReviewCardExchangeSchemaV1(document, reviewerName);
      const directory: string = ensureExportDirectory(context);
      const fileName: string = resolveBackupFileName(document);
      const outputPath: string = `${directory}/${fileName}`;
      writeReviewJson(outputPath, reviewJson);
      return {
        success: true,
        path: outputPath,
        directory: directory,
        fileName: fileName
      };
    } catch (error) {
      return {
        success: false,
        path: '',
        directory: '',
        fileName: ''
      };
    }
  }

  static deleteSandboxReviewJsonBackup(context: common.UIAbilityContext, document: ReviewCardDocument): void {
    try {
      const directory: string = ensureExportDirectory(context);
      const fileName: string = resolveBackupFileName(document);
      fs.unlinkSync(`${directory}/${fileName}`);
    } catch (error) {
    }
  }

  static async exportReviewJson(
    context: common.UIAbilityContext,
    document: ReviewCardDocument
  ): Promise<ReviewJsonExportResult> {
    try {
      await ReviewJsonExportService.writeSandboxReviewJsonBackup(context, document);
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(context);
      const reviewJson: string = stringifyReviewCardExchangeSchemaV1(document, reviewerName);
      const directory: string = ensureExportDirectory(context);
      const fileName: string = resolveExportFileName(document);
      const outputPath: string = `${directory}/${fileName}`;
      writeReviewJson(outputPath, reviewJson);
      const targetUri: string = await exportToUserSelectedDocument(context, outputPath, fileName);
      if (targetUri.length === 0) {
        return {
          success: false,
          cancelled: true,
          path: '',
          directory: directory,
          fileName: fileName,
          userSelectedUri: '',
          backupPath: outputPath,
          exportedToUserFiles: false,
          message: '未选择保存位置，已保留备份'
        };
      }
      return {
        success: true,
        cancelled: false,
        path: targetUri,
        directory: directory,
        fileName: fileName,
        userSelectedUri: targetUri,
        backupPath: outputPath,
        exportedToUserFiles: true,
        message: `已导出 ${fileName}`
      };
    } catch (error) {
      return {
        success: false,
        cancelled: false,
        path: '',
        directory: '',
        fileName: '',
        userSelectedUri: '',
        backupPath: '',
        exportedToUserFiles: false,
        message: 'review.json 导出失败，请稍后重试'
      };
    }
  }
}
