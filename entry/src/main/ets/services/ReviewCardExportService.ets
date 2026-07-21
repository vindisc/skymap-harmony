import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import common from '@ohos.app.ability.common';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveTemplate, TemplateLevel } from '../model/TemplateModel';
import { L0CanvasComposeResult, L0CanvasComposer } from './L0CanvasComposer';
import { L1CanvasComposeResult, L1CanvasComposer } from './L1CanvasComposer';
import { L3CanvasComposeResult, L3CanvasComposer } from './L3CanvasComposer';

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
  thumbnailPath: string;
  message: string;
}

export const REVIEW_CARD_EXPORT_ID: string = 'review-card-export';
const EXPORT_DIR_NAME: string = 'review_exports';
const EXPORT_TITLE_PREFIX: string = 'skymap-review-card';
const EXPORT_EXTENSION: string = 'jpg';
const EXPORT_MIME_TYPE: string = 'image/jpeg';
const BUNDLE_THUMBNAIL_MIME_TYPE: string = 'image/jpeg';

interface OriginalResolutionComposeResult {
  success: boolean;
  message: string;
}

function errorMessage(error: Error): string {
  return error.message;
}

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
  try {
    const file = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, data);
    } finally {
      fs.closeSync(file);
    }
  } catch (error) {
    throw new Error(`保存导出图片备份失败：${error}`);
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
  try {
    const file = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    try {
      fs.writeSync(file.fd, data);
    } finally {
      fs.closeSync(file);
    }
  } catch (error) {
    throw new Error(`写入复盘包预览图失败：${error}`);
  }
  return outputPath;
}

function assertImageBytes(label: string, data: ArrayBuffer): void {
  if (data.byteLength <= 0) {
    throw new Error(`${label} bytes empty`);
  }
}

function copySandboxFileToMediaUri(sourcePath: string, mediaUri: string): void {
  try {
    const sourceFile = fs.openSync(sourcePath, fs.OpenMode.READ_ONLY);
    try {
      const targetFile = fs.openSync(mediaUri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      try {
        fs.copyFileSync(sourceFile.fd, targetFile.fd);
      } finally {
        fs.closeSync(targetFile);
      }
    } finally {
      fs.closeSync(sourceFile);
    }
  } catch (error) {
    throw new Error(`写入系统图库失败：${error}`);
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
  } catch (error) {
    throw new Error(`保存图片到系统图库失败：${error}`);
  } finally {
    try {
      await helper.release();
    } catch (error) {
    }
  }
}

export class ReviewCardExportService {
  private static isExporting: boolean = false;

  private static async composeOriginalResolution(
    context: common.UIAbilityContext,
    document: ReviewCardDocument,
    reviewerName: string,
    outputPath: string
  ): Promise<OriginalResolutionComposeResult> {
    const level: TemplateLevel = resolveTemplate(document.config.templateId).level;
    if (level === TemplateLevel.L0_FRAME) {
      const result: L0CanvasComposeResult = await L0CanvasComposer.compose({
        context: context,
        document: document,
        outputPath: outputPath
      });
      return { success: result.success, message: result.message };
    }
    if (level === TemplateLevel.L1_META) {
      const result: L1CanvasComposeResult = await L1CanvasComposer.compose({
        context: context,
        document: document,
        outputPath: outputPath
      });
      return { success: result.success, message: result.message };
    }
    if (level === TemplateLevel.L2_NOTE) {
      return { success: false, message: '一句话模板暂未开放导出' };
    }
    const result: L3CanvasComposeResult = await L3CanvasComposer.compose({
      context: context,
      document: document,
      reviewerName: reviewerName,
      outputPath: outputPath
    });
    return { success: result.success, message: result.message };
  }

  static async exportOriginalResolution(
    context: common.UIAbilityContext,
    document: ReviewCardDocument,
    reviewerName: string
  ): Promise<ReviewCardExportResult> {
    if (ReviewCardExportService.isExporting) {
      return {
        success: false,
        cancelled: false,
        savedToPhotoLibrary: false,
        path: '',
        backupPath: '',
        message: '导出进行中'
      };
    }

    ReviewCardExportService.isExporting = true;
    let backupPath: string = '';
    try {
      const timestamp: number = Date.now();
      const outputDir: string = `${context.filesDir}/${EXPORT_DIR_NAME}`;
      fs.mkdirSync(outputDir, true);
      backupPath = `${outputDir}/${timestamp}-original.${EXPORT_EXTENSION}`;
      const composeResult: OriginalResolutionComposeResult =
        await ReviewCardExportService.composeOriginalResolution(context, document, reviewerName, backupPath);
      if (!composeResult.success) {
        return {
          success: false,
          cancelled: false,
          savedToPhotoLibrary: false,
          path: '',
          backupPath: '',
          message: composeResult.message
        };
      }

      const title: string = createExportTitle();
      const mediaUri: string = await saveJpgToPhotoLibrary(context, backupPath, title);
      if (mediaUri.length === 0) {
        return {
          success: false,
          cancelled: true,
          savedToPhotoLibrary: false,
          path: '',
          backupPath: backupPath,
          message: '已取消'
        };
      }
      return {
        success: true,
        cancelled: false,
        savedToPhotoLibrary: true,
        path: mediaUri,
        backupPath: backupPath,
        message: '已导出到图库'
      };
    } catch (error) {
      return {
        success: false,
        cancelled: false,
        savedToPhotoLibrary: false,
        path: '',
        backupPath: '',
        message: error instanceof Error ? error.message : `${error}`
      };
    } finally {
      ReviewCardExportService.isExporting = false;
    }
  }

  static async exportSnapshot(
    context: common.UIAbilityContext,
    uiContext: UIContext,
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
    let packer: image.ImagePacker | undefined = undefined;
    let backupPath: string = '';
    try {
      pixelMap = await uiContext.getComponentSnapshot().get(componentId);
      packer = image.createImagePacker();
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
      if (packer) {
        try {
          await packer.release();
        } catch (error) {
        }
      }
      if (pixelMap) {
        try {
          await pixelMap.release();
        } catch (error) {
        }
      }
      ReviewCardExportService.isExporting = false;
    }
  }

  static async exportBundleSnapshot(
    uiContext: UIContext,
    componentId: string,
    thumbnailPath: string,
    onSnapshotReady: () => void = () => {}
  ): Promise<ReviewCardBundleSnapshotResult> {
    if (ReviewCardExportService.isExporting) {
      return {
        success: false,
        thumbnailPath: '',
        message: '正在导出，请稍候'
      };
    }

    ReviewCardExportService.isExporting = true;
    let pixelMap: image.PixelMap | undefined = undefined;
    let packer: image.ImagePacker | undefined = undefined;
    try {
      pixelMap = await uiContext.getComponentSnapshot().get(componentId);
      packer = image.createImagePacker();
      const thumbnailData = await packer.packToData(pixelMap, {
        format: BUNDLE_THUMBNAIL_MIME_TYPE,
        quality: 72
      });
      assertImageBytes('thumb.jpg', thumbnailData);
      writeImageToSandbox(thumbnailPath, thumbnailData);
      try {
        onSnapshotReady();
      } catch (error) {
      }

      return {
        success: true,
        thumbnailPath: thumbnailPath,
        message: '已生成复盘包 JPG 图片'
      };
    } catch (error) {
      return {
        success: false,
        thumbnailPath: '',
        message: `复盘包图片生成失败：${error instanceof Error ? errorMessage(error) : `${error}`}`
      };
    } finally {
      if (packer) {
        try {
          await packer.release();
        } catch (error) {
        }
      }
      if (pixelMap) {
        try {
          await pixelMap.release();
        } catch (error) {
        }
      }
      ReviewCardExportService.isExporting = false;
    }
  }
}
