import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import libjpegEncoder, { JpegEncoderHandle } from 'libjpeg_encoder.so';

export interface CanvasSpikeV2DecodeVerification {
  successful: boolean;
  decodedWidth: number;
  decodedHeight: number;
}

export interface CanvasSpikeV2Report {
  poc: 'encoder_only';
  widthPx: number;
  heightPx: number;
  stripCount: number;
  stripHeightPx: number;
  finalStripHeightPx: number;
  stripTimesMs: number[];
  totalMs: number;
  jpegBytes: number;
  decodeVerification: CanvasSpikeV2DecodeVerification;
  timestampMs: number;
  passed: boolean;
  notes: string;
}

const OUTPUT_WIDTH_PX: number = 7008;
const OUTPUT_HEIGHT_PX: number = 4672;
const STRIP_HEIGHT_PX: number = 256;
const RGB_BYTES_PER_PIXEL: number = 3;
const JPEG_QUALITY: number = 95;
const MAX_TOTAL_MS: number = 10000;
const OUTPUT_FILE_NAME: string = 'canvas-spike-v2-encoder.jpg';
const REPORT_FILE_NAME: string = 'canvas-spike-v2-encoder-report.json';

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

function appendNote(notes: string, note: string): string {
  return notes.length > 0 ? `${notes}；${note}` : note;
}

function writeReport(context: common.UIAbilityContext, report: CanvasSpikeV2Report): void {
  const outputPath: string = `${context.filesDir}/${REPORT_FILE_NAME}`;
  const file: fs.File = fs.openSync(
    outputPath,
    fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
  );
  try {
    fs.writeSync(file.fd, encodeUtf8(JSON.stringify(report)));
  } finally {
    fs.closeSync(file);
  }
}

function createGradientStrip(startY: number, stripHeight: number): ArrayBuffer {
  const pixels: Uint8Array = new Uint8Array(
    OUTPUT_WIDTH_PX * stripHeight * RGB_BYTES_PER_PIXEL
  );
  let byteIndex: number = 0;
  for (let localY: number = 0; localY < stripHeight; localY += 1) {
    const globalY: number = startY + localY;
    const red: number = globalY % 256;
    for (let x: number = 0; x < OUTPUT_WIDTH_PX; x += 1) {
      pixels[byteIndex] = red;
      pixels[byteIndex + 1] = (x + globalY) % 256;
      pixels[byteIndex + 2] = 128;
      byteIndex += RGB_BYTES_PER_PIXEL;
    }
  }
  return pixels.buffer;
}

async function verifyJpeg(outputPath: string): Promise<CanvasSpikeV2DecodeVerification> {
  const source: image.ImageSource = image.createImageSource(outputPath);
  let verificationPixelMap: image.PixelMap | undefined = undefined;
  try {
    const imageInfo: image.ImageInfo = await source.getImageInfo();
    verificationPixelMap = await source.createPixelMap({
      desiredSize: {
        width: 16,
        height: 16
      },
      desiredPixelFormat: image.PixelMapFormat.RGBA_8888
    });
    return {
      successful: imageInfo.size.width === OUTPUT_WIDTH_PX && imageInfo.size.height === OUTPUT_HEIGHT_PX,
      decodedWidth: imageInfo.size.width,
      decodedHeight: imageInfo.size.height
    };
  } finally {
    if (verificationPixelMap) {
      await verificationPixelMap.release();
    }
    await source.release();
  }
}

export class CanvasSpikeV2Service {
  static async runEncoderPoC(context: common.UIAbilityContext): Promise<CanvasSpikeV2Report> {
    const startedAt: number = Date.now();
    const stripCount: number = Math.ceil(OUTPUT_HEIGHT_PX / STRIP_HEIGHT_PX);
    const finalStripHeight: number = OUTPUT_HEIGHT_PX - (stripCount - 1) * STRIP_HEIGHT_PX;
    const outputPath: string = `${context.filesDir}/${OUTPUT_FILE_NAME}`;
    const report: CanvasSpikeV2Report = {
      poc: 'encoder_only',
      widthPx: OUTPUT_WIDTH_PX,
      heightPx: OUTPUT_HEIGHT_PX,
      stripCount: stripCount,
      stripHeightPx: STRIP_HEIGHT_PX,
      finalStripHeightPx: finalStripHeight,
      stripTimesMs: [],
      totalMs: 0,
      jpegBytes: 0,
      decodeVerification: {
        successful: false,
        decodedWidth: 0,
        decodedHeight: 0
      },
      timestampMs: startedAt,
      passed: false,
      notes: ''
    };

    let outputFile: fs.File | null = null;
    let encoderHandle: JpegEncoderHandle | null = null;
    try {
      outputFile = fs.openSync(
        outputPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
      );
      encoderHandle = libjpegEncoder.startJpeg(
        outputFile.fd,
        OUTPUT_WIDTH_PX,
        OUTPUT_HEIGHT_PX,
        JPEG_QUALITY
      );

      for (let stripIndex: number = 0; stripIndex < stripCount; stripIndex += 1) {
        const startY: number = stripIndex * STRIP_HEIGHT_PX;
        const stripHeight: number = Math.min(STRIP_HEIGHT_PX, OUTPUT_HEIGHT_PX - startY);
        const stripStartedAt: number = Date.now();
        const stripBuffer: ArrayBuffer = createGradientStrip(startY, stripHeight);
        libjpegEncoder.writeStrip(encoderHandle, stripHeight, stripBuffer);
        report.stripTimesMs.push(Date.now() - stripStartedAt);
      }

      libjpegEncoder.finalizeJpeg(encoderHandle);
      encoderHandle = null;
      fs.closeSync(outputFile);
      outputFile = null;

      report.jpegBytes = fs.statSync(outputPath).size;
      report.decodeVerification = await verifyJpeg(outputPath);
    } catch (error) {
      report.notes = appendNote(report.notes, `执行失败：${error}`);
    } finally {
      if (encoderHandle) {
        try {
          libjpegEncoder.abortJpeg(encoderHandle);
        } catch (error) {
          report.notes = appendNote(report.notes, `Encoder abort 失败：${error}`);
        }
      }
      if (outputFile) {
        try {
          fs.closeSync(outputFile);
        } catch (error) {
          report.notes = appendNote(report.notes, `输出文件关闭失败：${error}`);
        }
      }
    }

    report.totalMs = Date.now() - startedAt;
    report.passed = report.stripTimesMs.length === stripCount &&
      report.jpegBytes > 0 &&
      report.decodeVerification.successful &&
      report.totalMs < MAX_TOTAL_MS &&
      report.notes.length === 0;

    try {
      writeReport(context, report);
    } catch (error) {
      report.passed = false;
      report.notes = appendNote(report.notes, `报告写入失败：${error}`);
    }
    console.info(`[CanvasSpikeV2] ${JSON.stringify(report)}`);
    return report;
  }
}
