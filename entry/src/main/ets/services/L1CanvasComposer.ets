import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { LengthMetricsUnit } from '@kit.ArkUI';
import libjpegEncoder, { JpegEncoderHandle } from 'libjpeg_encoder.so';
import { normalizeExifPayload } from '../model/ExifPayloadModel';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import { cleanCameraModel } from './ExifReaderService';
import {
  appendCanvasComposeMessage,
  CANVAS_JPEG_QUALITY,
  CANVAS_RGBA_BYTES_PER_PIXEL,
  CANVAS_STRIP_HEIGHT_PX,
  CanvasSourceImageLayout,
  canvasRgbaToRgb,
  decodeCanvasPhotoStrip,
  describeCanvasComposeError,
  ensureCanvasOutputParentDirectory,
  resolveCanvasSourceLayout,
  validateCanvasRegionRotation
} from './CanvasPhotoStripHelpers';
import { L1CanvasGeometry, resolveL1CanvasGeometry } from './L1CanvasSpec';

export interface L1CanvasComposeInput {
  context: common.UIAbilityContext;
  document: ReviewCardDocument;
  outputPath: string;
}

export interface L1CanvasComposeResult {
  success: boolean;
  outputPath: string;
  outputWidth: number;
  outputHeight: number;
  totalMs: number;
  message: string;
}

interface L1TextCommand {
  text: string;
  x: number;
  topY: number;
  heightPx: number;
  font: string;
  color: string;
  align: CanvasTextAlign;
}

interface L1TextLayout {
  commands: Array<L1TextCommand>;
}

function fontValue(sizePx: number, bold: boolean): string {
  return `${bold ? 'bold ' : ''}${Math.max(1, Math.round(sizePx))}px ` +
    `${bold ? 'NotoSansSC-Bold' : 'NotoSansSC-Regular'}`;
}

function joinRightGroup(document: ReviewCardDocument): Array<string> {
  const exif = normalizeExifPayload(document.exif);
  const values: Array<string> = [];
  if (exif.focalLength.length > 0) {
    values.push(exif.focalLength);
  }
  if (exif.aperture.length > 0) {
    values.push(exif.aperture);
  }
  if (exif.shutter.length > 0) {
    values.push(exif.shutter);
  }
  if (exif.iso.length > 0) {
    values.push(exif.iso);
  }
  return values;
}

function measureTextWidth(
  context: OffscreenCanvasRenderingContext2D,
  text: string,
  font: string
): number {
  context.font = font;
  return text.length > 0 ? context.measureText(text).width : 0;
}

function truncateLeftText(
  context: OffscreenCanvasRenderingContext2D,
  text: string,
  maxWidth: number,
  font: string
): string {
  if (text.length === 0 || maxWidth <= 0) {
    return '';
  }
  if (measureTextWidth(context, text, font) <= maxWidth) {
    return text;
  }
  for (let index: number = 1; index < text.length; index += 1) {
    const candidate: string = `⋯${text.slice(index)}`;
    if (measureTextWidth(context, candidate, font) <= maxWidth) {
      return candidate;
    }
  }
  return measureTextWidth(context, '⋯', font) <= maxWidth ? '⋯' : '';
}

function buildTextLayout(
  document: ReviewCardDocument,
  geometry: L1CanvasGeometry,
  context: OffscreenCanvasRenderingContext2D
): L1TextLayout {
  const exif = normalizeExifPayload(document.exif);
  const titleFont: string = fontValue(geometry.titleFontPx, true);
  const bodyFont: string = fontValue(geometry.bodyFontPx, false);
  const leftX: number = geometry.outerPaddingPx + geometry.innerPaddingPx;
  const rightX: number = geometry.canvasWidth - geometry.outerPaddingPx - geometry.innerPaddingPx;
  const availableWidth: number = Math.max(0, rightX - leftX);
  const groupGap: number = geometry.bodyFontPx;
  let leftText: string = cleanCameraModel(exif.cameraModel);
  const rightValues: Array<string> = joinRightGroup(document);
  let droppedRightValue: boolean = false;
  let rightText: string = rightValues.join(' ');
  let leftWidth: number = measureTextWidth(context, leftText, titleFont);
  let rightWidth: number = measureTextWidth(context, rightText, bodyFont);
  while (rightValues.length > 1 && leftWidth + rightWidth + groupGap > availableWidth) {
    rightValues.shift();
    droppedRightValue = true;
    rightText = `⋯${rightValues.join(' ')}`;
    rightWidth = measureTextWidth(context, rightText, bodyFont);
  }
  const reservedRightWidth: number = rightText.length > 0 ? rightWidth + groupGap : 0;
  leftText = truncateLeftText(context, leftText, Math.max(0, availableWidth - reservedRightWidth), titleFont);
  leftWidth = measureTextWidth(context, leftText, titleFont);
  if (rightText.length > 0 && leftText.length === 0 && rightWidth > availableWidth) {
    rightText = truncateLeftText(context, rightText, availableWidth, bodyFont);
  } else if (!droppedRightValue && rightText.length > 0 && leftWidth + rightWidth + groupGap > availableWidth) {
    rightText = truncateLeftText(context, rightText, Math.max(0, availableWidth - leftWidth - groupGap), bodyFont);
  }
  const maxFontPx: number = Math.max(geometry.titleFontPx, geometry.bodyFontPx);
  const textTopY: number = geometry.bottomBarTopY + Math.max(0, (geometry.bottomBarHeightPx - maxFontPx) / 2);
  const commands: Array<L1TextCommand> = [];
  if (leftText.length > 0) {
    commands.push({
      text: leftText,
      x: leftX,
      topY: textTopY,
      heightPx: maxFontPx,
      font: titleFont,
      color: geometry.titleColorHex,
      align: 'left'
    });
  }
  if (rightText.length > 0) {
    commands.push({
      text: rightText,
      x: rightX,
      topY: textTopY,
      heightPx: maxFontPx,
      font: bodyFont,
      color: geometry.secondaryColorHex,
      align: 'right'
    });
  }
  return { commands: commands };
}

function renderTextLayout(
  context: OffscreenCanvasRenderingContext2D,
  layout: L1TextLayout,
  stripY: number,
  stripHeight: number
): void {
  layout.commands.forEach((command: L1TextCommand): void => {
    if (command.topY + command.heightPx > stripY && command.topY < stripY + stripHeight) {
      context.font = command.font;
      context.fillStyle = command.color;
      context.textAlign = command.align;
      context.textBaseline = 'top';
      context.fillText(command.text, command.x, command.topY - stripY);
    }
  });
}

export class L1CanvasComposer {
  static async compose(input: L1CanvasComposeInput): Promise<L1CanvasComposeResult> {
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
      console.info('[L1CanvasComposer] step 1: createImageSource ok');
      activeStage = 'resolveSourceLayout';
      const sourceLayout: CanvasSourceImageLayout = await resolveCanvasSourceLayout(source);
      console.info(
        `[L1CanvasComposer] step 2: sourceLayout orientation=${sourceLayout.orientation}, ` +
        `encodedSize=${sourceLayout.encodedWidth}x${sourceLayout.encodedHeight}, ` +
        `rotatedSize=${sourceLayout.rotatedSize.width}x${sourceLayout.rotatedSize.height}`
      );
      activeStage = 'validateRegionRotation';
      await validateCanvasRegionRotation(source, sourceLayout);
      console.info('[L1CanvasComposer] step 3: validate ok');
      activeStage = 'resolveGeometry';
      const geometry: L1CanvasGeometry = resolveL1CanvasGeometry(input.document, sourceLayout.rotatedSize);
      outputWidth = geometry.canvasWidth;
      outputHeight = geometry.canvasHeight;
      console.info(`[L1CanvasComposer] step 4: geometry canvas=${outputWidth}x${outputHeight}`);
      activeStage = 'openOutputFile';
      ensureCanvasOutputParentDirectory(input.outputPath);
      if (fs.accessSync(input.outputPath)) {
        fs.unlinkSync(input.outputPath);
      }
      outputFile = fs.openSync(
        input.outputPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
      );
      console.info(`[L1CanvasComposer] step 5: output fd=${outputFile.fd}`);
      activeStage = 'startJpeg';
      encoderHandle = libjpegEncoder.startJpeg(
        outputFile.fd,
        outputWidth,
        outputHeight,
        CANVAS_JPEG_QUALITY
      );
      console.info(`[L1CanvasComposer] step 6: encoder handle=${encoderHandle.handleId}`);
      activeStage = 'buildTextLayout';
      const measureCanvas: OffscreenCanvas = new OffscreenCanvas(1, 1, LengthMetricsUnit.PX);
      const measureContext: OffscreenCanvasRenderingContext2D = measureCanvas.getContext('2d');
      const textLayout: L1TextLayout = buildTextLayout(input.document, geometry, measureContext);
      console.info('[L1CanvasComposer] step 7: text layout ok');

      let stripIndex: number = 0;
      for (let stripY: number = 0; stripY < outputHeight; stripY += CANVAS_STRIP_HEIGHT_PX) {
        activeStripIndex = stripIndex;
        const actualStripHeight: number = Math.min(CANVAS_STRIP_HEIGHT_PX, outputHeight - stripY);
        activeStage = 'createOffscreenCanvas';
        const canvas: OffscreenCanvas = new OffscreenCanvas(
          outputWidth,
          actualStripHeight,
          LengthMetricsUnit.PX
        );
        const context: OffscreenCanvasRenderingContext2D = canvas.getContext('2d');
        activeStage = 'fillBackground';
        context.fillStyle = geometry.backgroundColorHex;
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
            'L1CanvasComposer'
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

        activeStage = 'renderTextLayout';
        renderTextLayout(context, textLayout, stripY, actualStripHeight);
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
        console.info(`[L1CanvasComposer] step 8.${stripIndex}.writeStrip ok`);
        stripIndex += 1;
      }

      activeStage = 'finalizeJpeg';
      libjpegEncoder.finalizeJpeg(encoderHandle);
      encoderHandle = null;
      fs.closeSync(outputFile);
      outputFile = null;
      completed = true;
      message = 'L1 原图分辨率合成完成';
    } catch (error) {
      message = `L1 原图分辨率合成失败：${describeCanvasComposeError(error, activeStripIndex, activeStage)}`;
      console.error(`[L1CanvasComposer] ${message}`);
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
