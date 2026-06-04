import componentSnapshot from '@ohos.arkui.componentSnapshot';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

export interface ReviewCardExportResult {
  success: boolean;
  path: string;
  message: string;
}

export const REVIEW_CARD_EXPORT_ID: string = 'review-card-export';

export class ReviewCardExportService {
  static async exportSnapshot(context: common.UIAbilityContext): Promise<ReviewCardExportResult> {
    let pixelMap: image.PixelMap | undefined = undefined;
    try {
      pixelMap = await componentSnapshot.get(REVIEW_CARD_EXPORT_ID);
      const packer = image.createImagePacker();
      const data = await packer.packToData(pixelMap, {
        format: 'image/png',
        quality: 100
      });

      const outputDir = `${context.filesDir}/review_exports`;
      try {
        fs.mkdirSync(outputDir, true);
      } catch (error) {
      }

      const outputPath = `${outputDir}/review-card-${Date.now()}.png`;
      const file = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, data);
      } finally {
        fs.closeSync(file);
      }

      return {
        success: true,
        path: outputPath,
        message: '已导出到应用文件目录'
      };
    } catch (error) {
      return {
        success: false,
        path: '',
        message: '导出失败，请稍后重试'
      };
    } finally {
      if (pixelMap) {
        await pixelMap.release();
      }
    }
  }
}

