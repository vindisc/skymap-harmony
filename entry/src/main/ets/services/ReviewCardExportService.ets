import componentSnapshot from '@ohos.arkui.componentSnapshot';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import common from '@ohos.app.ability.common';

export interface ReviewCardExportResult {
  success: boolean;
  cancelled: boolean;
  savedToPhotoLibrary: boolean;
  path: string;
  backupPath: string;
  message: string;
}

export interface ReviewCardBundleSnapshotResult {
  success: boolean;
  reviewCardPath: string;
  thumbnailPath: string;
  message: string;
}

export const REVIEW_CARD_EXPORT_ID: string = 'review-card-export';
const EXPORT_DIR_NAME: string = 'review_exports';
const EXPORT_TITLE_PREFIX: string = 'skymap-review-card';
const EXPORT_EXTENSION: string = 'jpg';
const EXPORT_MIME_TYPE: string = 'image/jpeg';
const BUNDLE_REVIEW_CARD_MIME_TYPE: string = 'image/png';
const BUNDLE_THUMBNAIL_MIME_TYPE: string = 'image/jpeg';

function createExportTitle(): string {
  return `${EXPORT_TITLE_PREFIX}-${Date.now()}`;
}

function saveJpgToSandbox(context: common.UIAbilityContext, data: ArrayBuffer, title: string): string {
  const outputDir = `${context.filesDir}/${EXPORT_DIR_NAME}`;
  try {
    fs.mkdirSync(outputDir, true);
  } catch (error) {
  }

  const outputPath = `${outputDir}/${title}.${EXPORT_EXTENSION}`;
  const file = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, data);
  } finally {
    fs.closeSync(file);
  }
  return outputPath;
}

function ensureParentDirectory(outputPath: string): void {
  const slashIndex: number = outputPath.lastIndexOf('/');
  if (slashIndex <= 0) {
    return;
  }
  try {
    fs.mkdirSync(outputPath.slice(0, slashIndex), true);
  } catch (error) {
  }
}

function writeImageToSandbox(outputPath: string, data: ArrayBuffer): string {
  ensureParentDirectory(outputPath);
  const file = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, data);
  } finally {
    fs.closeSync(file);
  }
  return outputPath;
}

function copySandboxFileToMediaUri(sourcePath: string, mediaUri: string): void {
  const sourceFile = fs.openSync(sourcePath, fs.OpenMode.READ_ONLY);
  const targetFile = fs.openSync(mediaUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
  try {
    fs.copyFileSync(sourceFile.fd, targetFile.fd);
  } finally {
    fs.closeSync(sourceFile);
    fs.closeSync(targetFile);
  }
}

async function saveJpgToPhotoLibrary(context: common.UIAbilityContext, outputPath: string, title: string): Promise<string> {
  const helper = photoAccessHelper.getPhotoAccessHelper(context);
  try {
    const sandboxUri = fileUri.getUriFromPath(outputPath);
    const mediaUris: Array<string> = await helper.showAssetsCreationDialog(
      [sandboxUri],
      [
        {
          title: title,
          fileNameExtension: EXPORT_EXTENSION,
          photoType: photoAccessHelper.PhotoType.IMAGE
        }
      ]
    );
    const mediaUri = mediaUris.length > 0 ? mediaUris[0] : '';
    if (mediaUri.length > 0) {
      copySandboxFileToMediaUri(outputPath, mediaUri);
    }
    return mediaUri;
  } finally {
    try {
      await helper.release();
    } catch (error) {
    }
  }
}

export class ReviewCardExportService {
  private static isExporting: boolean = false;

  static async exportSnapshot(
    context: common.UIAbilityContext,
    componentId: string,
    onSnapshotReady: () => void = () => {}
  ): Promise<ReviewCardExportResult> {
    if (ReviewCardExportService.isExporting) {
      return {
        success: false,
        cancelled: false,
        savedToPhotoLibrary: false,
        path: '',
        backupPath: '',
        message: '正在导出，请稍候'
      };
    }

    ReviewCardExportService.isExporting = true;
    let pixelMap: image.PixelMap | undefined = undefined;
    let backupPath: string = '';
    try {
      pixelMap = await componentSnapshot.get(componentId);
      const packer = image.createImagePacker();
      const data = await packer.packToData(pixelMap, {
        format: EXPORT_MIME_TYPE,
        quality: 95
      });

      const title = createExportTitle();
      backupPath = saveJpgToSandbox(context, data, title);
      try {
        onSnapshotReady();
      } catch (error) {
      }
      const mediaUri = await saveJpgToPhotoLibrary(context, backupPath, title);

      return {
        success: mediaUri.length > 0,
        cancelled: mediaUri.length === 0,
        savedToPhotoLibrary: mediaUri.length > 0,
        path: mediaUri,
        backupPath: backupPath,
        message: mediaUri.length > 0
          ? '已导出到图库'
          : '未完成保存，已保留备份'
      };
    } catch (error) {
      if (backupPath.length > 0) {
        return {
          success: false,
          cancelled: false,
          savedToPhotoLibrary: false,
          path: backupPath,
          backupPath: backupPath,
          message: '未完成保存，已保留备份'
        };
      }
      return {
        success: false,
        cancelled: false,
        savedToPhotoLibrary: false,
        path: '',
        backupPath: '',
        message: '导出失败，请稍后重试'
      };
    } finally {
      if (pixelMap) {
        await pixelMap.release();
      }
      ReviewCardExportService.isExporting = false;
    }
  }

  static async exportBundleSnapshot(
    componentId: string,
    reviewCardPath: string,
    thumbnailPath: string,
    onSnapshotReady: () => void = () => {}
  ): Promise<ReviewCardBundleSnapshotResult> {
    if (ReviewCardExportService.isExporting) {
      return {
        success: false,
        reviewCardPath: '',
        thumbnailPath: '',
        message: '正在导出，请稍候'
      };
    }

    ReviewCardExportService.isExporting = true;
    let pixelMap: image.PixelMap | undefined = undefined;
    try {
      pixelMap = await componentSnapshot.get(componentId);
      const packer = image.createImagePacker();
      const reviewCardData = await packer.packToData(pixelMap, {
        format: BUNDLE_REVIEW_CARD_MIME_TYPE,
        quality: 100
      });
      const thumbnailData = await packer.packToData(pixelMap, {
        format: BUNDLE_THUMBNAIL_MIME_TYPE,
        quality: 72
      });

      writeImageToSandbox(reviewCardPath, reviewCardData);
      writeImageToSandbox(thumbnailPath, thumbnailData);
      try {
        onSnapshotReady();
      } catch (error) {
      }

      return {
        success: true,
        reviewCardPath: reviewCardPath,
        thumbnailPath: thumbnailPath,
        message: '已生成复盘包图片'
      };
    } catch (error) {
      return {
        success: false,
        reviewCardPath: '',
        thumbnailPath: '',
        message: '复盘包图片生成失败'
      };
    } finally {
      if (pixelMap) {
        await pixelMap.release();
      }
      ReviewCardExportService.isExporting = false;
    }
  }
}
