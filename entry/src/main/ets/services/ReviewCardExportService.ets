import componentSnapshot from '@ohos.arkui.componentSnapshot';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import common from '@ohos.app.ability.common';

export interface ReviewCardExportResult {
  success: boolean;
  savedToPhotoLibrary: boolean;
  path: string;
  backupPath: string;
  message: string;
}

export const REVIEW_CARD_EXPORT_ID: string = 'review-card-export';
const EXPORT_DIR_NAME: string = 'review_exports';
const EXPORT_TITLE_PREFIX: string = 'skymap-review-card';

function createExportTitle(): string {
  return `${EXPORT_TITLE_PREFIX}-${Date.now()}`;
}

function savePngToSandbox(context: common.UIAbilityContext, data: ArrayBuffer, title: string): string {
  const outputDir = `${context.filesDir}/${EXPORT_DIR_NAME}`;
  try {
    fs.mkdirSync(outputDir, true);
  } catch (error) {
  }

  const outputPath = `${outputDir}/${title}.png`;
  const file = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, data);
  } finally {
    fs.closeSync(file);
  }
  return outputPath;
}

async function savePngToPhotoLibrary(context: common.UIAbilityContext, outputPath: string, title: string): Promise<string> {
  const helper = photoAccessHelper.getPhotoAccessHelper(context);
  try {
    const mediaUris: Array<string> = await helper.showAssetsCreationDialog([
      fileUri.getUriFromPath(outputPath)
    ], [
      {
        title: title,
        fileNameExtension: 'png',
        photoType: photoAccessHelper.PhotoType.IMAGE
      }
    ]);
    if (mediaUris.length <= 0) {
      return '';
    }
    return mediaUris[0];
  } finally {
    try {
      await helper.release();
    } catch (error) {
    }
  }
}

export class ReviewCardExportService {
  static async exportSnapshot(context: common.UIAbilityContext): Promise<ReviewCardExportResult> {
    let pixelMap: image.PixelMap | undefined = undefined;
    let backupPath: string = '';
    try {
      pixelMap = await componentSnapshot.get(REVIEW_CARD_EXPORT_ID);
      const packer = image.createImagePacker();
      const data = await packer.packToData(pixelMap, {
        format: 'image/png',
        quality: 100
      });

      const title = createExportTitle();
      backupPath = savePngToSandbox(context, data, title);
      const mediaUri = await savePngToPhotoLibrary(context, backupPath, title);

      return {
        success: mediaUri.length > 0,
        savedToPhotoLibrary: mediaUri.length > 0,
        path: mediaUri,
        backupPath: backupPath,
        message: mediaUri.length > 0 ? '已保存到系统相册，可在图库最近项目查看' : '未完成相册保存，已保留应用内备份'
      };
    } catch (error) {
      if (backupPath.length > 0) {
        return {
          success: false,
          savedToPhotoLibrary: false,
          path: backupPath,
          backupPath: backupPath,
          message: '系统相册保存未完成，已保留应用内备份'
        };
      }
      return {
        success: false,
        savedToPhotoLibrary: false,
        path: '',
        backupPath: '',
        message: '导出失败，请稍后重试'
      };
    } finally {
      if (pixelMap) {
        await pixelMap.release();
      }
    }
  }
}
