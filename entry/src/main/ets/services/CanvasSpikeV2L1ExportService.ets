import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import image from '@ohos.multimedia.image';
import { ExifPayload } from '../model/ExifPayloadModel';
import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { TemplateId } from '../model/TemplateModel';
import { applyTemplateToDocument } from '../utils/TemplateApply';
import { ExifReaderService, mergeMissingExifIdentity } from './ExifReaderService';
import { L1CanvasComposeResult, L1CanvasComposer } from './L1CanvasComposer';

export interface CanvasSpikeV2L1ExportReport {
  poc: 'l1_export';
  sourcePath: string;
  outputPath: string;
  outputWidth: number;
  outputHeight: number;
  outputBytes: number;
  totalMs: number;
  decodeVerification: CanvasSpikeV2L1DecodeVerification;
  exifIdentityVerification: CanvasSpikeV2L1ExifIdentityVerification;
  cachedIdentityRepairVerification: CanvasSpikeV2L1CachedIdentityRepairVerification;
  mediaUriIdentityVerification: CanvasSpikeV2L1MediaUriIdentityVerification;
  timestampMs: number;
  passed: boolean;
  notes: string;
}

export interface CanvasSpikeV2L1MediaUriIdentityVerification {
  mediaUri: string;
  selectedMediaUri: string;
  cameraMake: string;
  cameraModel: string;
  lensMake: string;
  lensModel: string;
  passed: boolean;
}

export interface CanvasSpikeV2L1CachedIdentityRepairVerification {
  cameraMake: string;
  cameraModel: string;
  lensMake: string;
  exposurePreserved: boolean;
  passed: boolean;
}

export interface CanvasSpikeV2L1ExifIdentityVerification {
  cameraMake: string;
  cameraModel: string;
  lensMake: string;
  lensModel: string;
  passed: boolean;
}

export interface CanvasSpikeV2L1DecodeVerification {
  successful: boolean;
  decodedWidth: number;
  decodedHeight: number;
}

const SOURCE_FILE_NAME: string = 'fixture-l3-photo.jpg';
const OUTPUT_FILE_NAME: string = 'canvas-spike-v2-l1-export.jpg';
const REPORT_FILE_NAME: string = 'canvas-spike-v2-l1-export-report.json';

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

function writeReport(context: common.UIAbilityContext, report: CanvasSpikeV2L1ExportReport): void {
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
    fs.unlinkSync(sandboxPath);
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

function copyFixtureToMediaUri(sourcePath: string, mediaUri: string): void {
  const sourceFile: fs.File = fs.openSync(sourcePath, fs.OpenMode.READ_ONLY);
  try {
    const targetFile: fs.File = fs.openSync(mediaUri, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    try {
      fs.copyFileSync(sourceFile.fd, targetFile.fd);
    } finally {
      fs.closeSync(targetFile);
    }
  } finally {
    fs.closeSync(sourceFile);
  }
}

async function createFixtureMediaUri(
  context: common.UIAbilityContext,
  sourcePath: string
): Promise<string> {
  const helper = photoAccessHelper.getPhotoAccessHelper(context);
  try {
    const mediaUris: Array<string> = await helper.showAssetsCreationDialog(
      [fileUri.getUriFromPath(sourcePath)],
      [
        {
          title: `skymap-exif-media-uri-test-${Date.now()}`,
          fileNameExtension: 'jpg',
          photoType: photoAccessHelper.PhotoType.IMAGE
        }
      ]
    );
    if (mediaUris.length === 0 || mediaUris[0].length === 0) {
      throw new Error('系统相册未返回测试媒体 URI');
    }
    copyFixtureToMediaUri(sourcePath, mediaUris[0]);
    return mediaUris[0];
  } finally {
    try {
      await helper.release();
    } catch (error) {
    }
  }
}

async function selectFixtureMediaUri(): Promise<string> {
  const picker = new photoAccessHelper.PhotoViewPicker();
  const options = new photoAccessHelper.PhotoSelectOptions();
  options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
  options.maxSelectNumber = 1;
  const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
  if (result.photoUris.length === 0 || result.photoUris[0].length === 0) {
    throw new Error('系统照片选择器未返回测试媒体 URI');
  }
  return result.photoUris[0];
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

function createFixtureDocument(
  sourcePath: string,
  sourceSize: image.Size,
  exif: ExifPayload
): ReviewCardDocument {
  const document: ReviewCardDocument = createDefaultReviewCardDocument();
  document.imageUri = sourcePath;
  document.imageWidth = sourceSize.width;
  document.imageHeight = sourceSize.height;
  document.exif = exif;
  return applyTemplateToDocument(document, TemplateId.META_BOTTOM);
}

async function verifyOutput(outputPath: string): Promise<CanvasSpikeV2L1DecodeVerification> {
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

export class CanvasSpikeV2L1ExportService {
  static async runL1ExportPoC(context: common.UIAbilityContext): Promise<CanvasSpikeV2L1ExportReport> {
    const startedAt: number = Date.now();
    const sourcePath: string = await ensureFixturePhotoInSandbox(context);
    const outputPath: string = `${context.filesDir}/${OUTPUT_FILE_NAME}`;
    const report: CanvasSpikeV2L1ExportReport = {
      poc: 'l1_export',
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
      exifIdentityVerification: {
        cameraMake: '',
        cameraModel: '',
        lensMake: '',
        lensModel: '',
        passed: false
      },
      cachedIdentityRepairVerification: {
        cameraMake: '',
        cameraModel: '',
        lensMake: '',
        exposurePreserved: false,
        passed: false
      },
      mediaUriIdentityVerification: {
        mediaUri: '',
        selectedMediaUri: '',
        cameraMake: '',
        cameraModel: '',
        lensMake: '',
        lensModel: '',
        passed: false
      },
      timestampMs: startedAt,
      passed: false,
      notes: ''
    };
    try {
      const sourceSize: image.Size = await resolveFixtureImageSize(sourcePath);
      const exif: ExifPayload = await ExifReaderService.read(sourcePath);
      report.exifIdentityVerification = {
        cameraMake: exif.cameraMake,
        cameraModel: exif.cameraModel,
        lensMake: exif.lensMake,
        lensModel: exif.lensModel,
        passed: exif.cameraMake === 'SONY' &&
          exif.cameraModel === 'ILCE-7CM2' &&
          exif.lensMake === 'TAMRON' &&
          exif.lensModel.indexOf('A071') >= 0
      };
      const cachedPartialExif: ExifPayload = {
        cameraMake: '',
        cameraModel: '',
        lensMake: '',
        lensModel: exif.lensModel,
        focalLength: exif.focalLength,
        aperture: exif.aperture,
        shutter: exif.shutter,
        iso: exif.iso,
        captureDate: exif.captureDate,
        location: exif.location,
        source: exif.source,
        manuallyOverridden: []
      };
      const repairedExif: ExifPayload = mergeMissingExifIdentity(cachedPartialExif, exif);
      const exposurePreserved: boolean = repairedExif.focalLength === cachedPartialExif.focalLength &&
        repairedExif.aperture === cachedPartialExif.aperture &&
        repairedExif.shutter === cachedPartialExif.shutter &&
        repairedExif.iso === cachedPartialExif.iso;
      report.cachedIdentityRepairVerification = {
        cameraMake: repairedExif.cameraMake,
        cameraModel: repairedExif.cameraModel,
        lensMake: repairedExif.lensMake,
        exposurePreserved: exposurePreserved,
        passed: repairedExif.cameraMake === 'SONY' &&
          repairedExif.cameraModel === 'ILCE-7CM2' &&
          repairedExif.lensMake === 'TAMRON' &&
          exposurePreserved
      };
      const mediaUri: string = await createFixtureMediaUri(context, sourcePath);
      report.mediaUriIdentityVerification.mediaUri = mediaUri;
      console.info(`[ExifDeviceTestMedia] created=${mediaUri}`);
      const selectedMediaUri: string = await selectFixtureMediaUri();
      report.mediaUriIdentityVerification.selectedMediaUri = selectedMediaUri;
      const mediaExif: ExifPayload = await ExifReaderService.read(selectedMediaUri);
      report.mediaUriIdentityVerification = {
        mediaUri: mediaUri,
        selectedMediaUri: selectedMediaUri,
        cameraMake: mediaExif.cameraMake,
        cameraModel: mediaExif.cameraModel,
        lensMake: mediaExif.lensMake,
        lensModel: mediaExif.lensModel,
        passed: mediaExif.cameraMake === 'SONY' &&
          mediaExif.cameraModel === 'ILCE-7CM2' &&
          mediaExif.lensMake === 'TAMRON' &&
          mediaExif.lensModel.indexOf('A071') >= 0
      };
      console.info(
        `[ExifReaderService] SONY A7CM2 sample: make="${exif.cameraMake}" model="${exif.cameraModel}" ` +
        `focalLength="${exif.focalLength}" aperture="${exif.aperture}" ` +
        `shutter="${exif.shutter}" iso="${exif.iso}"`
      );
      const composeResult: L1CanvasComposeResult = await L1CanvasComposer.compose({
        context: context,
        document: createFixtureDocument(sourcePath, sourceSize, exif),
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
        report.exifIdentityVerification.passed &&
        report.cachedIdentityRepairVerification.passed &&
        report.mediaUriIdentityVerification.passed &&
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
    console.info(`[CanvasSpikeV2L1Export] ${JSON.stringify(report)}`);
    return report;
  }
}
