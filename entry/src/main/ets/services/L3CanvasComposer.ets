import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import libjpegEncoder, { JpegEncoderHandle } from 'libjpeg_encoder.so';
import { AppColors, ExportCardColors } from '../components/AppDesign';
import { CompactReviewTextStyle } from '../components/LongFormExportReviewCard';
import { ReviewCardStyleTokens } from '../components/ReviewCardStyleTokens';
import { normalizeReviewJudgement, ReviewCardDocument } from '../model/ReviewCardModel';
import { formatReviewTime } from '../utils/ImageLayoutUtils';
import { L3CanvasGeometry, resolveL3CanvasGeometry, RotatedPixelMapSize } from './L3CanvasSpec';

export interface L3CanvasComposeInput {
  context: common.UIAbilityContext;
  document: ReviewCardDocument;
  reviewerName: string;
  outputPath: string;
}

export interface L3CanvasComposeResult {
  success: boolean;
  outputPath: string;
  outputWidth: number;
  outputHeight: number;
  totalMs: number;
  message: string;
}

interface SourceImageLayout {
  encodedWidth: number;
  encodedHeight: number;
  orientation: number;
  rotationDegrees: number;
  rotatedSize: RotatedPixelMapSize;
}

interface TextCommand {
  text: string;
  x: number;
  baselineY: number;
  font: string;
  color: string;
  align: CanvasTextAlign;
}

interface RectCommand {
  x: number;
  y: number;
  width: number;
  height: number;
  color: string;
  radius: number;
}

interface TextLayout {
  texts: Array<TextCommand>;
  rects: Array<RectCommand>;
}

interface ReviewField {
  label: string;
  value: string;
}

const STRIP_HEIGHT_PX: number = 256;
const JPEG_QUALITY: number = 95;
const RGBA_BYTES_PER_PIXEL: number = 4;
const RGB_BYTES_PER_PIXEL: number = 3;
const BASELINE_META_FONT_PX: number = 18;
const BASELINE_LABEL_FONT_PX: number = 15;
const BASELINE_TITLE_LINE_HEIGHT_PX: number = 44;
const BASELINE_BODY_LINE_HEIGHT_PX: number = 31;
const BASELINE_LABEL_LINE_HEIGHT_PX: number = 20;
const BASELINE_META_LINE_HEIGHT_PX: number = 24;

function appendMessage(message: string, detail: string): string {
  return message.length > 0 ? `${message}；${detail}` : detail;
}

function describeComposeError(error: Error | Object, stripIndex: number, stage: string): string {
  const location: string = stripIndex >= 0
    ? `stripIndex=${stripIndex}, stage=${stage}`
    : `stage=${stage}`;
  if (error instanceof Error) {
    const businessError: BusinessError = error as BusinessError;
    const codeText: string = typeof businessError.code === 'number' ? `${businessError.code}` : 'unknown';
    return `${codeText}: ${error.message} @ ${location}`;
  }
  return `${error} @ ${location}`;
}

function ensureParentDirectory(outputPath: string): void {
  const slashIndex: number = outputPath.lastIndexOf('/');
  if (slashIndex <= 0) {
    return;
  }
  const parentDir: string = outputPath.slice(0, slashIndex);
  if (fs.accessSync(parentDir)) {
    return;
  }
  fs.mkdirSync(parentDir, true);
}

function resolveRotationDegrees(orientation: number): number {
  if (orientation === 3) {
    return 180;
  }
  if (orientation === 6) {
    return 90;
  }
  if (orientation === 8) {
    return 270;
  }
  return 0;
}

async function resolveSourceLayout(source: image.ImageSource): Promise<SourceImageLayout> {
  const info: image.ImageInfo = await source.getImageInfo();
  let orientation: number = 1;
  try {
    const orientationText: string = await source.getImageProperty(image.PropertyKey.ORIENTATION);
    const parsedOrientation: number = parseInt(orientationText, 10);
    if (parsedOrientation === 1 || parsedOrientation === 3 || parsedOrientation === 6 || parsedOrientation === 8) {
      orientation = parsedOrientation;
    }
  } catch (error) {
    orientation = 1;
  }
  const swapsAxes: boolean = orientation === 6 || orientation === 8;
  return {
    encodedWidth: info.size.width,
    encodedHeight: info.size.height,
    orientation: orientation,
    rotationDegrees: resolveRotationDegrees(orientation),
    rotatedSize: {
      width: swapsAxes ? info.size.height : info.size.width,
      height: swapsAxes ? info.size.width : info.size.height
    }
  };
}

async function validateRegionRotation(source: image.ImageSource, layout: SourceImageLayout): Promise<void> {
  if (layout.orientation !== 6 && layout.orientation !== 8) {
    return;
  }
  const sampleSize: number = Math.min(512, layout.encodedWidth, layout.encodedHeight);
  const sample: image.PixelMap = await source.createPixelMap({
    desiredRegion: {
      x: 0,
      y: 0,
      size: {
        width: sampleSize,
        height: sampleSize
      }
    },
    rotate: layout.rotationDegrees,
    desiredPixelFormat: image.PixelMapFormat.RGBA_8888
  });
  await sample.release();
}

async function decodePhotoStrip(
  source: image.ImageSource,
  layout: SourceImageLayout,
  rotatedY: number,
  stripHeight: number,
  stripIndex: number
): Promise<image.PixelMap> {
  let regionX: number = 0;
  let regionY: number = rotatedY;
  let regionWidth: number = layout.encodedWidth;
  let regionHeight: number = stripHeight;
  if (layout.orientation === 3) {
    regionY = layout.encodedHeight - (rotatedY + stripHeight);
  } else if (layout.orientation === 6) {
    regionX = layout.encodedWidth - (rotatedY + stripHeight);
    regionY = 0;
    regionWidth = stripHeight;
    regionHeight = layout.encodedHeight;
  } else if (layout.orientation === 8) {
    regionX = rotatedY;
    regionY = 0;
    regionWidth = stripHeight;
    regionHeight = layout.encodedHeight;
  }
  console.info(
    `[L3CanvasComposer] step 8.${stripIndex}.decode: region=${regionX},${regionY},` +
    `${regionWidth}x${regionHeight}, rotate=${layout.rotationDegrees}`
  );
  return source.createPixelMap({
    desiredRegion: {
      x: regionX,
      y: regionY,
      size: {
        width: regionWidth,
        height: regionHeight
      }
    },
    rotate: layout.rotationDegrees,
    desiredPixelFormat: image.PixelMapFormat.RGBA_8888
  });
}

function normalizeText(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

function judgementText(value: string): string {
  const judgement: string = normalizeReviewJudgement(value);
  if (judgement === '成立' || judgement === '不成立') {
    return judgement;
  }
  return '待判断';
}

function fontValue(sizePx: number, bold: boolean): string {
  return `${bold ? 'bold ' : ''}${Math.max(1, Math.round(sizePx))}px ${bold ? 'NotoSansSC-Bold' : 'NotoSansSC-Regular'}`;
}

function wrapText(
  context: OffscreenCanvasRenderingContext2D,
  text: string,
  maxWidth: number,
  font: string
): Array<string> {
  const normalized: string = normalizeText(text);
  if (normalized.length === 0) {
    return [];
  }
  context.font = font;
  const lines: Array<string> = [];
  let currentLine: string = '';
  for (let index: number = 0; index < normalized.length; index += 1) {
    const candidate: string = `${currentLine}${normalized[index]}`;
    if (currentLine.length > 0 && context.measureText(candidate).width > maxWidth) {
      lines.push(currentLine);
      currentLine = normalized[index];
    } else {
      currentLine = candidate;
    }
  }
  if (currentLine.length > 0) {
    lines.push(currentLine);
  }
  return lines;
}

function appendTextLines(
  layout: TextLayout,
  context: OffscreenCanvasRenderingContext2D,
  text: string,
  x: number,
  startY: number,
  maxWidth: number,
  font: string,
  color: string,
  lineHeight: number,
  align: CanvasTextAlign = 'left'
): number {
  const lines: Array<string> = wrapText(context, text, maxWidth, font);
  let baselineY: number = startY;
  lines.forEach((line: string): void => {
    layout.texts.push({
      text: line,
      x: x,
      baselineY: baselineY,
      font: font,
      color: color,
      align: align
    });
    baselineY += lineHeight;
  });
  return baselineY;
}

function createReviewField(label: string, value: string): ReviewField {
  return {
    label: label,
    value: value
  };
}

function allFields(document: ReviewCardDocument): Array<ReviewField> {
  const fields: Array<ReviewField> = [];
  fields.push(createReviewField('视觉落点', document.content.visualFocus));
  fields.push(createReviewField('落点原因', document.content.focusReason));
  fields.push(createReviewField('视线路径', document.content.visualPath));
  fields.push(createReviewField('画面事实', document.content.visibleFacts));
  fields.push(createReviewField('核心关系', document.content.coreRelation));
  fields.push(createReviewField('判断', judgementText(document.content.judgement)));
  fields.push(createReviewField('延伸理解', document.content.extendedUnderstanding));
  fields.push(createReviewField('当前卡点', document.content.currentBlocker));
  return fields.filter((field: ReviewField): boolean => normalizeText(field.value).length > 0);
}

function horizontalColumns(document: ReviewCardDocument): Array<Array<ReviewField>> {
  const processFields: Array<ReviewField> = [];
  processFields.push(createReviewField('视觉落点', document.content.visualFocus));
  processFields.push(createReviewField('视线路径', document.content.visualPath));
  processFields.push(createReviewField('画面事实', document.content.visibleFacts));
  const summaryFields: Array<ReviewField> = [];
  summaryFields.push(createReviewField('最强关系', document.content.coreRelation));
  summaryFields.push(createReviewField('卡点', document.content.currentBlocker));
  summaryFields.push(createReviewField('复盘信息', document.content.extendedUnderstanding));
  const columns: Array<Array<ReviewField>> = [];
  columns.push(processFields);
  columns.push(summaryFields);
  return columns;
}

function buildTextLayout(
  document: ReviewCardDocument,
  reviewerName: string,
  geometry: L3CanvasGeometry,
  measureContext: OffscreenCanvasRenderingContext2D
): TextLayout {
  const result: TextLayout = { texts: [], rects: [] };
  const scale: number = geometry.scale;
  const contentX: number = geometry.photoOffsetX;
  const contentWidth: number = geometry.photoWidth;
  const titleFont: string = fontValue(geometry.titleFontPx, true);
  const bodyFont: string = fontValue(geometry.bodyFontPx, false);
  const labelFont: string = fontValue(BASELINE_LABEL_FONT_PX * scale, false);
  const metaFont: string = fontValue(BASELINE_META_FONT_PX * scale, false);
  const titleLineHeight: number = BASELINE_TITLE_LINE_HEIGHT_PX * scale;
  const bodyLineHeight: number = BASELINE_BODY_LINE_HEIGHT_PX * scale;
  const labelLineHeight: number = BASELINE_LABEL_LINE_HEIGHT_PX * scale;
  const metaLineHeight: number = BASELINE_META_LINE_HEIGHT_PX * scale;
  const metaText: string = normalizeText(reviewerName).length > 0
    ? `${formatReviewTime(document.updatedAt)} / ${normalizeText(reviewerName)}`
    : formatReviewTime(document.updatedAt);
  let cursorY: number = geometry.photoOffsetY + geometry.photoHeight + 20 * scale;

  if (geometry.isHorizontal) {
    const titlePanelHeight: number = 108 * scale;
    result.rects.push({
      x: contentX,
      y: cursorY,
      width: contentWidth,
      height: titlePanelHeight,
      color: ExportCardColors.titlePanelBg,
      radius: geometry.cornerRadiusPx
    });
    let titleY: number = cursorY + 36 * scale;
    titleY = appendTextLines(
      result,
      measureContext,
      document.content.title,
      contentX + 30 * scale,
      titleY,
      contentWidth * 0.7,
      titleFont,
      ReviewCardStyleTokens.inkColor,
      titleLineHeight
    );
    appendTextLines(
      result,
      measureContext,
      metaText,
      contentX + 30 * scale,
      Math.max(titleY, cursorY + 76 * scale),
      contentWidth * 0.7,
      metaFont,
      ExportCardColors.metaText,
      metaLineHeight
    );
    appendTextLines(
      result,
      measureContext,
      judgementText(document.content.judgement),
      contentX + contentWidth - 30 * scale,
      cursorY + 62 * scale,
      contentWidth * 0.2,
      metaFont,
      ExportCardColors.judgementText,
      metaLineHeight,
      'right'
    );
    cursorY += titlePanelHeight + 14 * scale;
    const panelHeight: number = Math.max(0, geometry.canvasHeight - cursorY - 56 * scale);
    result.rects.push({
      x: contentX,
      y: cursorY,
      width: contentWidth,
      height: panelHeight,
      color: AppColors.onPrimary,
      radius: geometry.cornerRadiusPx
    });
    const gap: number = 70 * scale;
    const columnWidth: number = (contentWidth - geometry.panelPaddingPx * 2 - gap) / 2;
    horizontalColumns(document).forEach((fields: Array<ReviewField>, columnIndex: number): void => {
      const columnX: number = contentX + geometry.panelPaddingPx + columnIndex * (columnWidth + gap);
      let fieldY: number = cursorY + geometry.panelPaddingPx + labelLineHeight;
      fields.forEach((field: ReviewField): void => {
        if (normalizeText(field.value).length === 0) {
          return;
        }
        fieldY = appendTextLines(result, measureContext, field.label, columnX, fieldY, columnWidth,
          labelFont, ExportCardColors.labelText, labelLineHeight);
        fieldY += 4 * scale;
        fieldY = appendTextLines(result, measureContext, field.value, columnX, fieldY, columnWidth,
          bodyFont, ExportCardColors.bodyText, bodyLineHeight);
        fieldY += 9 * scale;
      });
    });
  } else {
    cursorY = appendTextLines(result, measureContext, document.content.title, contentX, cursorY + titleLineHeight,
      contentWidth, titleFont, ReviewCardStyleTokens.inkColor, titleLineHeight);
    cursorY += 6 * scale;
    appendTextLines(result, measureContext, metaText, contentX, cursorY, contentWidth,
      metaFont, ExportCardColors.metaText, metaLineHeight);
    appendTextLines(result, measureContext, judgementText(document.content.judgement),
      contentX + contentWidth, cursorY, contentWidth * 0.25, metaFont, ExportCardColors.metaText, metaLineHeight, 'right');
    cursorY += metaLineHeight + 14 * scale;
    allFields(document).forEach((field: ReviewField): void => {
      cursorY = appendTextLines(result, measureContext, field.label, contentX, cursorY,
        contentWidth, labelFont, ExportCardColors.metaText, labelLineHeight);
      cursorY += 4 * scale;
      cursorY = appendTextLines(result, measureContext, field.value, contentX, cursorY,
        contentWidth, bodyFont, ReviewCardStyleTokens.bodyColor, bodyLineHeight);
      cursorY += 16 * scale;
    });
  }
  return result;
}

function renderGlobalTextLayout(
  context: OffscreenCanvasRenderingContext2D,
  layout: TextLayout,
  stripY: number,
  stripHeight: number
): void {
  layout.rects.forEach((rect: RectCommand): void => {
    if (rect.y < stripY + stripHeight && rect.y + rect.height > stripY) {
      context.fillStyle = rect.color;
      context.beginPath();
      context.roundRect(rect.x, rect.y - stripY, rect.width, rect.height, rect.radius);
      context.fill();
    }
  });
  layout.texts.forEach((command: TextCommand): void => {
    if (command.baselineY >= stripY && command.baselineY < stripY + stripHeight) {
      context.font = command.font;
      context.fillStyle = command.color;
      context.textAlign = command.align;
      context.textBaseline = 'alphabetic';
      context.fillText(command.text, command.x, command.baselineY - stripY);
    }
  });
}

function rgbaToRgb(
  rgbaBuffer: ArrayBuffer,
  width: number,
  height: number,
  bytesPerRow: number
): ArrayBuffer {
  const rgba: Uint8Array = new Uint8Array(rgbaBuffer);
  const rgb: Uint8Array = new Uint8Array(width * height * RGB_BYTES_PER_PIXEL);
  let rgbIndex: number = 0;
  for (let y: number = 0; y < height; y += 1) {
    const rowStart: number = y * bytesPerRow;
    for (let x: number = 0; x < width; x += 1) {
      const rgbaOffset: number = rowStart + x * RGBA_BYTES_PER_PIXEL;
      rgb[rgbIndex] = rgba[rgbaOffset];
      rgb[rgbIndex + 1] = rgba[rgbaOffset + 1];
      rgb[rgbIndex + 2] = rgba[rgbaOffset + 2];
      rgbIndex += RGB_BYTES_PER_PIXEL;
    }
  }
  return rgb.buffer;
}

export class L3CanvasComposer {
  static async compose(input: L3CanvasComposeInput): Promise<L3CanvasComposeResult> {
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
      console.info('[L3CanvasComposer] step 1: createImageSource ok');
      activeStage = 'resolveSourceLayout';
      const sourceLayout: SourceImageLayout = await resolveSourceLayout(source);
      console.info(
        `[L3CanvasComposer] step 2: sourceLayout orientation=${sourceLayout.orientation}, ` +
        `encodedSize=${sourceLayout.encodedWidth}x${sourceLayout.encodedHeight}, ` +
        `rotatedSize=${sourceLayout.rotatedSize.width}x${sourceLayout.rotatedSize.height}`
      );
      activeStage = 'validateRegionRotation';
      await validateRegionRotation(source, sourceLayout);
      console.info('[L3CanvasComposer] step 3: validate ok');
      activeStage = 'resolveGeometry';
      const geometry: L3CanvasGeometry = resolveL3CanvasGeometry(input.document, sourceLayout.rotatedSize);
      outputWidth = geometry.canvasWidth;
      outputHeight = geometry.canvasHeight;
      console.info(`[L3CanvasComposer] step 4: geometry canvas=${outputWidth}x${outputHeight}`);
      activeStage = 'openOutputFile';
      ensureParentDirectory(input.outputPath);
      if (fs.accessSync(input.outputPath)) {
        fs.unlinkSync(input.outputPath);
      }
      outputFile = fs.openSync(
        input.outputPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
      );
      console.info(`[L3CanvasComposer] step 5: output fd=${outputFile.fd}`);
      activeStage = 'startJpeg';
      encoderHandle = libjpegEncoder.startJpeg(outputFile.fd, outputWidth, outputHeight, JPEG_QUALITY);
      console.info(`[L3CanvasComposer] step 6: encoder handle=${encoderHandle.handleId}`);

      activeStage = 'buildTextLayout';
      const measureCanvas: OffscreenCanvas = new OffscreenCanvas(1, 1);
      const measureContext: OffscreenCanvasRenderingContext2D = measureCanvas.getContext('2d');
      const textLayout: TextLayout = buildTextLayout(input.document, input.reviewerName, geometry, measureContext);
      console.info('[L3CanvasComposer] step 7: text layout ok');

      let stripIndex: number = 0;
      for (let stripY: number = 0; stripY < outputHeight; stripY += STRIP_HEIGHT_PX) {
        activeStripIndex = stripIndex;
        const actualStripHeight: number = Math.min(STRIP_HEIGHT_PX, outputHeight - stripY);
        activeStage = 'createOffscreenCanvas';
        console.info(
          `[L3CanvasComposer] step 8.${stripIndex}: strip y=${stripY} h=${actualStripHeight} start`
        );
        const canvas: OffscreenCanvas = new OffscreenCanvas(outputWidth, actualStripHeight);
        const context: OffscreenCanvasRenderingContext2D = canvas.getContext('2d');
        activeStage = 'fillBackground';
        context.fillStyle = geometry.bgColorHex;
        context.fillRect(0, 0, outputWidth, actualStripHeight);

        const photoTop: number = geometry.photoOffsetY;
        const photoBottom: number = photoTop + geometry.photoHeight;
        const intersectionTop: number = Math.max(stripY, photoTop);
        const intersectionBottom: number = Math.min(stripY + actualStripHeight, photoBottom);
        if (intersectionBottom > intersectionTop) {
          const rotatedSourceY: number = intersectionTop - photoTop;
          const photoStripHeight: number = intersectionBottom - intersectionTop;
          activeStage = 'decodePhotoStrip';
          currentPhotoPixelMap = await decodePhotoStrip(
            source,
            sourceLayout,
            rotatedSourceY,
            photoStripHeight,
            stripIndex
          );
          console.info(`[L3CanvasComposer] step 8.${stripIndex}.decode ok`);
          activeStage = 'getDecodedImageInfo';
          const decodedInfo: image.ImageInfo = await currentPhotoPixelMap.getImageInfo();
          if (decodedInfo.size.width !== geometry.photoWidth || decodedInfo.size.height !== photoStripHeight) {
            throw new Error(
              `desiredRegion + rotate 尺寸异常：${decodedInfo.size.width}x${decodedInfo.size.height}`
            );
          }
          activeStage = 'drawImage';
          context.save();
          context.beginPath();
          context.roundRect(
            geometry.photoOffsetX,
            geometry.photoOffsetY - stripY,
            geometry.photoWidth,
            geometry.photoHeight,
            geometry.cornerRadiusPx
          );
          context.clip();
          context.drawImage(
            currentPhotoPixelMap,
            geometry.photoOffsetX,
            intersectionTop - stripY,
            geometry.photoWidth,
            photoStripHeight
          );
          context.restore();
          console.info(`[L3CanvasComposer] step 8.${stripIndex}.drawImage ok`);
          activeStage = 'releasePhotoPixelMap';
          await currentPhotoPixelMap.release();
          currentPhotoPixelMap = null;
        }

        activeStage = 'renderTextLayout';
        renderGlobalTextLayout(context, textLayout, stripY, actualStripHeight);
        activeStage = 'getCanvasPixelMap';
        currentCanvasPixelMap = context.getPixelMap(0, 0, outputWidth, actualStripHeight);
        console.info(`[L3CanvasComposer] step 8.${stripIndex}.getPixelMap ok`);
        activeStage = 'readPixelsToBuffer';
        const pixelBytesTotal: number = currentCanvasPixelMap.getPixelBytesNumber();
        const bytesPerRow: number = currentCanvasPixelMap.getBytesNumberPerRow();
        const rgbaBuffer: ArrayBuffer = new ArrayBuffer(pixelBytesTotal);
        await currentCanvasPixelMap.readPixelsToBuffer(rgbaBuffer);
        console.info(
          `[L3CanvasComposer] step 8.${stripIndex}.readPixelsToBuffer ok, ` +
          `pixelBytes=${pixelBytesTotal}, bytesPerRow=${bytesPerRow}, expected=${outputWidth * RGBA_BYTES_PER_PIXEL}`
        );
        activeStage = 'releaseCanvasPixelMap';
        await currentCanvasPixelMap.release();
        currentCanvasPixelMap = null;
        activeStage = 'rgbaToRgb';
        const rgbBuffer: ArrayBuffer = rgbaToRgb(
          rgbaBuffer,
          outputWidth,
          actualStripHeight,
          bytesPerRow
        );
        activeStage = 'writeStrip';
        libjpegEncoder.writeStrip(encoderHandle, actualStripHeight, rgbBuffer);
        console.info(`[L3CanvasComposer] step 8.${stripIndex}.writeStrip ok`);
        stripIndex += 1;
      }

      activeStage = 'finalizeJpeg';
      libjpegEncoder.finalizeJpeg(encoderHandle);
      encoderHandle = null;
      fs.closeSync(outputFile);
      outputFile = null;
      completed = true;
      message = 'L3 原图分辨率合成完成';
    } catch (error) {
      message = `L3 原图分辨率合成失败：${describeComposeError(error, activeStripIndex, activeStage)}`;
      console.error(`[L3CanvasComposer] ${message}`);
    } finally {
      if (currentCanvasPixelMap) {
        try {
          await currentCanvasPixelMap.release();
        } catch (error) {
          message = appendMessage(message, `Canvas PixelMap 释放失败：${error}`);
          completed = false;
        }
      }
      if (currentPhotoPixelMap) {
        try {
          await currentPhotoPixelMap.release();
        } catch (error) {
          message = appendMessage(message, `照片 PixelMap 释放失败：${error}`);
          completed = false;
        }
      }
      if (encoderHandle) {
        try {
          libjpegEncoder.abortJpeg(encoderHandle);
        } catch (error) {
          message = appendMessage(message, `JPEG encoder abort 失败：${error}`);
        }
      }
      if (outputFile) {
        try {
          fs.closeSync(outputFile);
        } catch (error) {
          message = appendMessage(message, `输出文件关闭失败：${error}`);
          completed = false;
        }
      }
      if (source) {
        try {
          await source.release();
        } catch (error) {
          message = appendMessage(message, `ImageSource 释放失败：${error}`);
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
