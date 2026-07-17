import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';

export interface CanvasSpikeReport {
  widthPx: number;
  heightPx: number;
  pixelMapAllocMs: number;
  canvasAllocMs: number;
  drawImageMs: number;
  getPixelMapMs: number;
  jpegEncodeMs: number;
  jpegBytes: number;
  memoryBeforeMB: number | null;
  memoryPeakMB: number | null;
  memoryAfterMB: number | null;
  totalMs: number;
  timestampMs: number;
  passed: boolean;
  notes: string;
}

const SPIKE_WIDTH_PX: number = 7008;
const SPIKE_HEIGHT_PX: number = 4672;
const RGBA_BYTES_PER_PIXEL: number = 4;
const MAX_GET_PIXEL_MAP_MS: number = 1000;
const MAX_JPEG_ENCODE_MS: number = 2000;
const MAX_TOTAL_MS: number = 3000;
const REPORT_FILE_NAME: string = 'canvas-spike-report.json';
const MEMORY_SAMPLE_NOTE: string = 'hidebug.getPss API 在 SDK 6.1.1(24) 中未声明，内存采样跳过';

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

function writeReport(context: common.UIAbilityContext, report: CanvasSpikeReport): void {
  const outputPath: string = `${context.filesDir}/${REPORT_FILE_NAME}`;
  const file = fs.openSync(outputPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.writeSync(file.fd, encodeUtf8(JSON.stringify(report)));
  } finally {
    fs.closeSync(file);
  }
}

export class CanvasSpikeService {
  static async runSpike(context: common.UIAbilityContext): Promise<CanvasSpikeReport> {
    const startedAt: number = Date.now();
    const report: CanvasSpikeReport = {
      widthPx: SPIKE_WIDTH_PX,
      heightPx: SPIKE_HEIGHT_PX,
      pixelMapAllocMs: 0,
      canvasAllocMs: 0,
      drawImageMs: 0,
      getPixelMapMs: 0,
      jpegEncodeMs: 0,
      jpegBytes: 0,
      memoryBeforeMB: null,
      memoryPeakMB: null,
      memoryAfterMB: null,
      totalMs: 0,
      timestampMs: startedAt,
      passed: false,
      notes: MEMORY_SAMPLE_NOTE
    };

    let sourceBuffer: ArrayBuffer | undefined = undefined;
    let sourcePixelMap: image.PixelMap | undefined = undefined;
    let canvas: OffscreenCanvas | undefined = undefined;
    let canvasPixelMap: image.PixelMap | undefined = undefined;
    let packer: image.ImagePacker | undefined = undefined;
    let completed: boolean = false;

    try {
      const pixelMapAllocStartedAt: number = Date.now();
      sourceBuffer = new ArrayBuffer(SPIKE_WIDTH_PX * SPIKE_HEIGHT_PX * RGBA_BYTES_PER_PIXEL);
      sourcePixelMap = await image.createPixelMap(sourceBuffer, {
        size: {
          width: SPIKE_WIDTH_PX,
          height: SPIKE_HEIGHT_PX
        },
        pixelFormat: image.PixelMapFormat.RGBA_8888
      });
      report.pixelMapAllocMs = Date.now() - pixelMapAllocStartedAt;

      const canvasAllocStartedAt: number = Date.now();
      canvas = new OffscreenCanvas(SPIKE_WIDTH_PX, SPIKE_HEIGHT_PX);
      const canvasContext: OffscreenCanvasRenderingContext2D = canvas.getContext('2d');
      report.canvasAllocMs = Date.now() - canvasAllocStartedAt;

      const drawImageStartedAt: number = Date.now();
      canvasContext.drawImage(sourcePixelMap, 0, 0, SPIKE_WIDTH_PX, SPIKE_HEIGHT_PX);
      report.drawImageMs = Date.now() - drawImageStartedAt;

      const getPixelMapStartedAt: number = Date.now();
      canvasPixelMap = canvasContext.getPixelMap(0, 0, SPIKE_WIDTH_PX, SPIKE_HEIGHT_PX);
      report.getPixelMapMs = Date.now() - getPixelMapStartedAt;

      packer = image.createImagePacker();
      const jpegEncodeStartedAt: number = Date.now();
      const jpegBuffer: ArrayBuffer = await packer.packToData(canvasPixelMap, {
        format: 'image/jpeg',
        quality: 95
      });
      report.jpegEncodeMs = Date.now() - jpegEncodeStartedAt;
      report.jpegBytes = jpegBuffer.byteLength;
      completed = true;
    } catch (error) {
      report.notes = appendNote(report.notes, `执行失败：${error}`);
    } finally {
      if (packer) {
        try {
          await packer.release();
        } catch (error) {
          completed = false;
          report.notes = appendNote(report.notes, `ImagePacker 释放失败：${error}`);
        }
      }
      if (canvasPixelMap) {
        try {
          await canvasPixelMap.release();
        } catch (error) {
          completed = false;
          report.notes = appendNote(report.notes, `Canvas PixelMap 释放失败：${error}`);
        }
      }
      if (sourcePixelMap) {
        try {
          await sourcePixelMap.release();
        } catch (error) {
          completed = false;
          report.notes = appendNote(report.notes, `测试 PixelMap 释放失败：${error}`);
        }
      }
      canvas = undefined;
      sourceBuffer = undefined;
    }

    report.totalMs = Date.now() - startedAt;
    report.passed = completed &&
      report.getPixelMapMs < MAX_GET_PIXEL_MAP_MS &&
      report.jpegEncodeMs < MAX_JPEG_ENCODE_MS &&
      report.totalMs < MAX_TOTAL_MS;

    try {
      writeReport(context, report);
    } catch (error) {
      report.passed = false;
      report.notes = appendNote(report.notes, `报告写入失败：${error}`);
    }
    console.info(`[CanvasSpike] ${JSON.stringify(report)}`);
    return report;
  }
}
