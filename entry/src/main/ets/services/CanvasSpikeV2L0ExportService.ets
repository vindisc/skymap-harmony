import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { TemplateId } from '../model/TemplateModel';
import { applyTemplateToDocument } from '../utils/TemplateApply';
import { L0CanvasComposeResult, L0CanvasComposer } from './L0CanvasComposer';

export interface CanvasSpikeV2L0ExportReport {
  poc: 'l0_export';
  sourcePath: string;
  outputPath: string;
  outputWidth: number;
  outputHeight: number;
  outputBytes: number;
  totalMs: number;
  decodeVerification: CanvasSpikeV2L0DecodeVerification;
  timestampMs: number;
  passed: boolean;
  notes: string;
}

export interface CanvasSpikeV2L0DecodeVerification {
  successful: boolean;
  decodedWidth: number;
  decodedHeight: number;
}

const SOURCE_FILE_NAME: string = 'fixture-l3-photo.jpg';
const OUTPUT_FILE_NAME: string = 'canvas-spike-v2-l0-export.jpg';
const REPORT_FILE_NAME: string = 'canvas-spike-v2-l0-export-report.json';

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

function writeReport(context: common.UIAbilityContext, report: CanvasSpikeV2L0ExportReport): void {
  const reportPath: string = `${context.filesDir}/${REPORT_FILE_NAME}`;
  if (fs.accessSync(reportPath)) {
    fs.unlinkSync(reportPath);
  }
  const file: fs.File = fs.openSync(
    reportPath,
    fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
  );
  try {
    fs.writeSync(file.fd, encodeUtf8(JSON.stringify(report)));
  } finally {
    fs.closeSync(file);
  }
}

async function ensureFixturePhotoInSandbox(context: common.UIAbilityContext): Promise<string> {
  const sandboxPath: string = `${context.filesDir}/${SOURCE_FILE_NAME}`;
  if (fs.accessSync(sandboxPath)) {
    return sandboxPath;
  }
  const rawContent: Uint8Array = await context.resourceManager.getRawFileContent(SOURCE_FILE_NAME);
  const contentBuffer: ArrayBuffer = new ArrayBuffer(rawContent.byteLength);
  new Uint8Array(contentBuffer).set(rawContent);
  const file: fs.File = fs.openSync(
    sandboxPath,
    fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
  );
  try {
    fs.writeSync(file.fd, contentBuffer);
  } finally {
    fs.closeSync(file);
  }
  return sandboxPath;
}

async function resolveFixtureImageSize(sourcePath: string): Promise<image.Size> {
  const source: image.ImageSource = image.createImageSource(sourcePath);
  try {
    const info: image.ImageInfo = await source.getImageInfo();
    return {
      width: info.size.width,
      height: info.size.height
    };
  } finally {
    await source.release();
  }
}

function createFixtureDocument(sourcePath: string, sourceSize: image.Size): ReviewCardDocument {
  const document: ReviewCardDocument = createDefaultReviewCardDocument();
  document.imageUri = sourcePath;
  document.imageWidth = sourceSize.width;
  document.imageHeight = sourceSize.height;
  return applyTemplateToDocument(document, TemplateId.WHITE_EQUAL);
}

async function verifyOutput(outputPath: string): Promise<CanvasSpikeV2L0DecodeVerification> {
  const source: image.ImageSource = image.createImageSource(outputPath);
  try {
    const info: image.ImageInfo = await source.getImageInfo();
    return {
      successful: info.size.width > 0 && info.size.height > 0,
      decodedWidth: info.size.width,
      decodedHeight: info.size.height
    };
  } finally {
    await source.release();
  }
}

export class CanvasSpikeV2L0ExportService {
  static async runL0ExportPoC(context: common.UIAbilityContext): Promise<CanvasSpikeV2L0ExportReport> {
    const startedAt: number = Date.now();
    const sourcePath: string = await ensureFixturePhotoInSandbox(context);
    const outputPath: string = `${context.filesDir}/${OUTPUT_FILE_NAME}`;
    const report: CanvasSpikeV2L0ExportReport = {
      poc: 'l0_export',
      sourcePath: sourcePath,
      outputPath: outputPath,
      outputWidth: 0,
      outputHeight: 0,
      outputBytes: 0,
      totalMs: 0,
      decodeVerification: {
        successful: false,
        decodedWidth: 0,
        decodedHeight: 0
      },
      timestampMs: startedAt,
      passed: false,
      notes: ''
    };
    try {
      const sourceSize: image.Size = await resolveFixtureImageSize(sourcePath);
      const composeResult: L0CanvasComposeResult = await L0CanvasComposer.compose({
        context: context,
        document: createFixtureDocument(sourcePath, sourceSize),
        outputPath: outputPath
      });
      report.outputWidth = composeResult.outputWidth;
      report.outputHeight = composeResult.outputHeight;
      report.notes = composeResult.message;
      if (composeResult.success) {
        report.outputBytes = fs.statSync(outputPath).size;
        report.decodeVerification = await verifyOutput(outputPath);
      }
      report.passed = composeResult.success &&
        report.outputBytes > 0 &&
        report.decodeVerification.successful &&
        report.decodeVerification.decodedWidth === composeResult.outputWidth &&
        report.decodeVerification.decodedHeight === composeResult.outputHeight;
    } catch (error) {
      report.notes = `执行失败：${error}`;
      report.passed = false;
    }
    report.totalMs = Date.now() - startedAt;
    try {
      writeReport(context, report);
    } catch (error) {
      report.passed = false;
      report.notes = `${report.notes}；报告写入失败：${error}`;
    }
    console.info(`[CanvasSpikeV2L0Export] ${JSON.stringify(report)}`);
    return report;
  }
}
