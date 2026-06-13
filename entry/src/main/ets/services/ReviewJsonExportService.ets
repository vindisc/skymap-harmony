import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
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
  path: string;
  directory: string;
  fileName: string;
  message: string;
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

function resolveExportFileName(document: ReviewCardDocument): string {
  const sourceFileName: string = resolveReviewCardExchangeFileName(document).trim();
  const stem: string = sourceFileName.length > 0 ? sanitizeFileStem(sourceFileName) : 'review';
  return `${formatTimestamp(document.updatedAt)}-${stem}.${REVIEW_JSON_EXTENSION}`;
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

export class ReviewJsonExportService {
  static async exportReviewJson(
    context: common.UIAbilityContext,
    document: ReviewCardDocument
  ): Promise<ReviewJsonExportResult> {
    try {
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(context);
      const reviewJson: string = stringifyReviewCardExchangeSchemaV1(document, reviewerName);
      const directory: string = ensureExportDirectory(context);
      const fileName: string = resolveExportFileName(document);
      const outputPath: string = `${directory}/${fileName}`;
      writeReviewJson(outputPath, reviewJson);
      return {
        success: true,
        path: outputPath,
        directory: directory,
        fileName: fileName,
        message: `review.json 已导出到 ${outputPath}`
      };
    } catch (error) {
      return {
        success: false,
        path: '',
        directory: '',
        fileName: '',
        message: 'review.json 导出失败，请稍后重试'
      };
    }
  }
}
