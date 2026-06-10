import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import picker from '@ohos.file.picker';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import {
  resolveReviewCardExchangeReviewJsonFileName,
  stringifyReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';

export interface ReviewCardReviewFileExportResult {
  success: boolean;
  cancelled: boolean;
  path: string;
  fileName: string;
  message: string;
}

function writeTextToUri(targetUri: string, text: string): void {
  const file: fs.File = fs.openSync(
    targetUri,
    fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
  );
  try {
    fs.writeSync(file.fd, text, { encoding: 'utf-8' });
    fs.fsyncSync(file.fd);
  } finally {
    fs.closeSync(file);
  }
}

export class ReviewCardReviewFileService {
  static async exportReviewJson(
    context: common.UIAbilityContext,
    document: ReviewCardDocument,
    reviewerText: string = ''
  ): Promise<ReviewCardReviewFileExportResult> {
    const fileName: string = resolveReviewCardExchangeReviewJsonFileName(document);
    const documentPicker = new picker.DocumentViewPicker(context);
    const saveOptions = new picker.DocumentSaveOptions();
    saveOptions.newFileNames = [fileName];

    try {
      const targetUris: Array<string> = await documentPicker.save(saveOptions);
      if (targetUris.length <= 0) {
        return {
          success: false,
          cancelled: true,
          path: '',
          fileName: fileName,
          message: '已取消导出'
        };
      }

      const targetUri: string = targetUris[0];
      writeTextToUri(targetUri, stringifyReviewCardExchangeSchemaV1(document, reviewerText));
      return {
        success: true,
        cancelled: false,
        path: targetUri,
        fileName: fileName,
        message: '已导出复盘文件'
      };
    } catch (error) {
      return {
        success: false,
        cancelled: false,
        path: '',
        fileName: fileName,
        message: '导出复盘文件失败，请稍后重试'
      };
    }
  }
}
