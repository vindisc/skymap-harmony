import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { LengthMetricsUnit } from '@kit.ArkUI';
import libjpegEncoder, { JpegEncoderHandle } from 'libjpeg_encoder.so';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveTemplate, TemplateId } from '../model/TemplateModel';
import {
  appendCanvasComposeMessage,
  CANVAS_JPEG_QUALITY,
  CANVAS_RGBA_BYTES_PER_PIXEL,
  CANVAS_STRIP_HEIGHT_PX,
  CanvasRotatedImageSize,
  CanvasSourceImageLayout,
  canvasRgbaToRgb,
  decodeCanvasPhotoStrip,
  describeCanvasComposeError,
  ensureCanvasOutputParentDirectory,
  resolveCanvasSourceLayout,
  validateCanvasRegionRotation
} from './CanvasPhotoStripHelpers';

export interface L0CanvasComposeInput {
  context: common.UIAbilityContext;
  document: ReviewCardDocument;
  outputPath: string;
}

export interface L0CanvasComposeResult {
  success: boolean;
  outputPath: string;
  outputWidth: number;
  outputHeight: number;
  totalMs: number;
  message: string;
}

interface L0CanvasGeometry {
  canvasWidth: number;
  canvasHeight: number;
  outerPaddingPx: number;
  imageOffsetX: number;
  imageOffsetY: number;
  imageWidth: number;
  imageHeight: number;
}

const L0_BACKGROUND_COLOR: string = '#FFFFFF';

function resolveL0CanvasGeometry(
  document: ReviewCardDocument,
  rotatedSize: CanvasRotatedImageSize
): L0CanvasGeometry {
  const fallbackRatio: number = resolveTemplate(TemplateId.WHITE_EQUAL).defaults.frame.outerPaddingRatio;
  const outerPaddingRatio: number = document.config.frame?.outerPaddingRatio ?? fallbackRatio;
  const longEdge: number = Math.max(rotatedSize.width, rotatedSize.height);
  const outerPaddingPx: number = Math.round(longEdge * outerPaddingRatio);
  return {
    canvasWidth: rotatedSize.width + outerPaddingPx * 2,
    canvasHeight: rotatedSize.height + outerPaddingPx * 2,
    outerPaddingPx: outerPaddingPx,
    imageOffsetX: outerPaddingPx,
    imageOffsetY: outerPaddingPx,
    imageWidth: rotatedSize.width,
    imageHeight: rotatedSize.height
  };
}

export class L0CanvasComposer {
  static async compose(input: L0CanvasComposeInput): Promise<L0CanvasComposeResult> {
    const startedAt: number = Date.now();
    let outputWidth: number = 0;
    let outputHeight: number = 0;
    let message: string = '';
    let source: image.ImageSource | null = null;
    let outputFile: fs.File | null = null;
    let encoderHandle: JpegEncoderHandle | null = null;
    let currentPhotoPixelMap: image.PixelMap | null = null;
    let currentCanvasPixelMap: image.PixelMap | null = null;
    let completed: boolean = false;
    let activeStripIndex: number = -1;
    let activeStage: string = 'createImageSource';
    try {
      source = image.createImageSource(input.document.imageUri);
      console.info('[L0CanvasComposer] step 1: createImageSource ok');
      activeStage = 'resolveSourceLayout';
      const sourceLayout: CanvasSourceImageLayout = await resolveCanvasSourceLayout(source);
      console.info(
        `[L0CanvasComposer] step 2: sourceLayout orientation=${sourceLayout.orientation}, ` +
        `encodedSize=${sourceLayout.encodedWidth}x${sourceLayout.encodedHeight}, ` +
        `rotatedSize=${sourceLayout.rotatedSize.width}x${sourceLayout.rotatedSize.height}`
      );
      activeStage = 'validateRegionRotation';
      await validateCanvasRegionRotation(source, sourceLayout);
      console.info('[L0CanvasComposer] step 3: validate ok');
      activeStage = 'resolveGeometry';
      const geometry: L0CanvasGeometry = resolveL0CanvasGeometry(input.document, sourceLayout.rotatedSize);
      outputWidth = geometry.canvasWidth;
      outputHeight = geometry.canvasHeight;
      console.info(
        `[L0CanvasComposer] step 4: geometry canvas=${outputWidth}x${outputHeight}, ` +
        `outerPadding=${geometry.outerPaddingPx}`
      );
      activeStage = 'openOutputFile';
      ensureCanvasOutputParentDirectory(input.outputPath);
      if (fs.accessSync(input.outputPath)) {
        fs.unlinkSync(input.outputPath);
      }
      outputFile = fs.openSync(
        input.outputPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
      );
      console.info(`[L0CanvasComposer] step 5: output fd=${outputFile.fd}`);
      activeStage = 'startJpeg';
      encoderHandle = libjpegEncoder.startJpeg(
        outputFile.fd,
        outputWidth,
        outputHeight,
        CANVAS_JPEG_QUALITY
      );
      console.info(`[L0CanvasComposer] step 6: encoder handle=${encoderHandle.handleId}`);

      let stripIndex: number = 0;
      for (let stripY: number = 0; stripY < outputHeight; stripY += CANVAS_STRIP_HEIGHT_PX) {
        activeStripIndex = stripIndex;
        const actualStripHeight: number = Math.min(CANVAS_STRIP_HEIGHT_PX, outputHeight - stripY);
        activeStage = 'createOffscreenCanvas';
        console.info(`[L0CanvasComposer] step 8.${stripIndex}: strip y=${stripY} h=${actualStripHeight} start`);
        const canvas: OffscreenCanvas = new OffscreenCanvas(
          outputWidth,
          actualStripHeight,
          LengthMetricsUnit.PX
        );
        const context: OffscreenCanvasRenderingContext2D = canvas.getContext('2d');
        activeStage = 'fillBackground';
        context.fillStyle = L0_BACKGROUND_COLOR;
        context.fillRect(0, 0, outputWidth, actualStripHeight);

        const photoTop: number = geometry.imageOffsetY;
        const photoBottom: number = photoTop + geometry.imageHeight;
        const intersectionTop: number = Math.max(stripY, photoTop);
        const intersectionBottom: number = Math.min(stripY + actualStripHeight, photoBottom);
        if (intersectionBottom > intersectionTop) {
          const rotatedSourceY: number = intersectionTop - photoTop;
          const photoStripHeight: number = intersectionBottom - intersectionTop;
          activeStage = 'decodePhotoStrip';
          currentPhotoPixelMap = await decodeCanvasPhotoStrip(
            source,
            sourceLayout,
            rotatedSourceY,
            photoStripHeight,
            stripIndex,
            'L0CanvasComposer'
          );
          activeStage = 'getDecodedImageInfo';
          const decodedInfo: image.ImageInfo = await currentPhotoPixelMap.getImageInfo();
          const decodedBytes: number = currentPhotoPixelMap.getPixelBytesNumber();
          const decodedRowBytes: number = currentPhotoPixelMap.getBytesNumberPerRow();
          const expectedDecodedRowBytes: number = geometry.imageWidth * CANVAS_RGBA_BYTES_PER_PIXEL;
          if (decodedInfo.size.width !== geometry.imageWidth ||
            decodedInfo.size.height !== photoStripHeight ||
            decodedInfo.pixelFormat !== image.PixelMapFormat.RGBA_8888 ||
            decodedRowBytes < expectedDecodedRowBytes ||
            decodedBytes < decodedRowBytes * photoStripHeight) {
            throw new Error(
              `desiredRegion PixelMap 物理信息异常：size=${decodedInfo.size.width}x${decodedInfo.size.height}, ` +
              `pixelFormat=${decodedInfo.pixelFormat}, pixelBytes=${decodedBytes}, rowBytes=${decodedRowBytes}`
            );
          }
          activeStage = 'drawImage';
          context.drawImage(
            currentPhotoPixelMap,
            geometry.imageOffsetX,
            intersectionTop - stripY,
            geometry.imageWidth,
            photoStripHeight
          );
          activeStage = 'releasePhotoPixelMap';
          await currentPhotoPixelMap.release();
          currentPhotoPixelMap = null;
        }

        activeStage = 'getCanvasPixelMap';
        currentCanvasPixelMap = context.getPixelMap(0, 0, outputWidth, actualStripHeight);
        activeStage = 'readPixelsToBuffer';
        const pixelBytesTotal: number = currentCanvasPixelMap.getPixelBytesNumber();
        const bytesPerRow: number = currentCanvasPixelMap.getBytesNumberPerRow();
        const rgbaBuffer: ArrayBuffer = new ArrayBuffer(pixelBytesTotal);
        await currentCanvasPixelMap.readPixelsToBuffer(rgbaBuffer);
        activeStage = 'releaseCanvasPixelMap';
        await currentCanvasPixelMap.release();
        currentCanvasPixelMap = null;
        activeStage = 'rgbaToRgb';
        const rgbBuffer: ArrayBuffer = canvasRgbaToRgb(
          rgbaBuffer,
          outputWidth,
          actualStripHeight,
          bytesPerRow
        );
        activeStage = 'writeStrip';
        libjpegEncoder.writeStrip(encoderHandle, actualStripHeight, rgbBuffer);
        console.info(`[L0CanvasComposer] step 8.${stripIndex}.writeStrip ok`);
        stripIndex += 1;
      }

      activeStage = 'finalizeJpeg';
      libjpegEncoder.finalizeJpeg(encoderHandle);
      encoderHandle = null;
      fs.closeSync(outputFile);
      outputFile = null;
      completed = true;
      message = 'L0 原图分辨率合成完成';
    } catch (error) {
      message = `L0 原图分辨率合成失败：${describeCanvasComposeError(error, activeStripIndex, activeStage)}`;
      console.error(`[L0CanvasComposer] ${message}`);
    } finally {
      if (currentCanvasPixelMap) {
        try {
          await currentCanvasPixelMap.release();
        } catch (error) {
          message = appendCanvasComposeMessage(message, `Canvas PixelMap 释放失败：${error}`);
          completed = false;
        }
      }
      if (currentPhotoPixelMap) {
        try {
          await currentPhotoPixelMap.release();
        } catch (error) {
          message = appendCanvasComposeMessage(message, `照片 PixelMap 释放失败：${error}`);
          completed = false;
        }
      }
      if (encoderHandle) {
        try {
          libjpegEncoder.abortJpeg(encoderHandle);
        } catch (error) {
          message = appendCanvasComposeMessage(message, `JPEG encoder abort 失败：${error}`);
        }
      }
      if (outputFile) {
        try {
          fs.closeSync(outputFile);
        } catch (error) {
          message = appendCanvasComposeMessage(message, `输出文件关闭失败：${error}`);
          completed = false;
        }
      }
      if (source) {
        try {
          await source.release();
        } catch (error) {
          message = appendCanvasComposeMessage(message, `ImageSource 释放失败：${error}`);
          completed = false;
        }
      }
    }

    return {
      success: completed,
      outputPath: completed ? input.outputPath : '',
      outputWidth: outputWidth,
      outputHeight: outputHeight,
      totalMs: Date.now() - startedAt,
      message: message
    };
  }
}
