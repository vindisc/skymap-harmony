import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import hidebug from '@ohos.hidebug';
import image from '@ohos.multimedia.image';

export interface CanvasSpikeV2DecodeReport {
  poc: 'decode_region';
  sourceUri: string;
  sourceBytes: number;
  regionCount: number;
  regionHeightPx: number;
  finalRegionHeightPx: number;
  regionTimesMs: number[];
  totalMs: number;
  timestampMs: number;
  passed: boolean;
  notes: string;
  memoryBeforeMB: number | null;
  memoryPeakMB: number | null;
  memoryAfterMB: number | null;
}

const SOURCE_WIDTH_PX: number = 7008;
const SOURCE_HEIGHT_PX: number = 4672;
const REGION_HEIGHT_PX: number = 256;
const MAX_TOTAL_MS: number = 15000;
const SOURCE_FILE_NAME: string = 'canvas-spike-v2-encoder.jpg';
const REPORT_FILE_NAME: string = 'canvas-spike-v2-decode-report.json';

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

function samplePssMB(): number | null {
  try {
    return Number(hidebug.getPss()) / 1024;
  } catch (error) {
    return null;
  }
}

function updatePeakMemory(report: CanvasSpikeV2DecodeReport, sampleMB: number | null): void {
  if (sampleMB === null) {
    return;
  }
  if (report.memoryPeakMB === null || sampleMB > report.memoryPeakMB) {
    report.memoryPeakMB = sampleMB;
  }
}

function writeReport(context: common.UIAbilityContext, report: CanvasSpikeV2DecodeReport): void {
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

export class CanvasSpikeV2DecodeService {
  static async runDecodeRegionPoC(context: common.UIAbilityContext): Promise<CanvasSpikeV2DecodeReport> {
    const startedAt: number = Date.now();
    const regionCount: number = Math.ceil(SOURCE_HEIGHT_PX / REGION_HEIGHT_PX);
    const finalRegionHeight: number = SOURCE_HEIGHT_PX - (regionCount - 1) * REGION_HEIGHT_PX;
    const sourcePath: string = `${context.filesDir}/${SOURCE_FILE_NAME}`;
    const report: CanvasSpikeV2DecodeReport = {
      poc: 'decode_region',
      sourceUri: sourcePath,
      sourceBytes: 0,
      regionCount: regionCount,
      regionHeightPx: REGION_HEIGHT_PX,
      finalRegionHeightPx: finalRegionHeight,
      regionTimesMs: [],
      totalMs: 0,
      timestampMs: startedAt,
      passed: false,
      notes: '',
      memoryBeforeMB: samplePssMB(),
      memoryPeakMB: null,
      memoryAfterMB: null
    };
    updatePeakMemory(report, report.memoryBeforeMB);

    let sourceFile: fs.File | null = null;
    let imageSource: image.ImageSource | null = null;
    let currentPixelMap: image.PixelMap | null = null;
    let decodedAllRegions: boolean = false;
    let resourceCleanupSuccessful: boolean = true;
    try {
      report.sourceBytes = fs.statSync(sourcePath).size;
      if (report.sourceBytes <= 0) {
        throw new Error(`输入 JPEG 不存在或为空：${sourcePath}`);
      }
      sourceFile = fs.openSync(sourcePath, fs.OpenMode.READ_ONLY);
      imageSource = image.createImageSource(sourceFile.fd);

      for (let regionIndex: number = 0; regionIndex < regionCount; regionIndex += 1) {
        const startY: number = regionIndex * REGION_HEIGHT_PX;
        const regionHeight: number = Math.min(REGION_HEIGHT_PX, SOURCE_HEIGHT_PX - startY);
        const regionStartedAt: number = Date.now();
        currentPixelMap = await imageSource.createPixelMap({
          desiredRegion: {
            x: 0,
            y: startY,
            size: {
              width: SOURCE_WIDTH_PX,
              height: regionHeight
            }
          },
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888
        });
        report.regionTimesMs.push(Date.now() - regionStartedAt);
        updatePeakMemory(report, samplePssMB());
        await currentPixelMap.release();
        currentPixelMap = null;
      }
      decodedAllRegions = true;
    } catch (error) {
      report.notes = appendNote(report.notes, `执行失败：${error}`);
    } finally {
      if (currentPixelMap) {
        try {
          await currentPixelMap.release();
        } catch (error) {
          resourceCleanupSuccessful = false;
          report.notes = appendNote(report.notes, `PixelMap 释放失败：${error}`);
        }
      }
      if (imageSource) {
        try {
          await imageSource.release();
        } catch (error) {
          resourceCleanupSuccessful = false;
          report.notes = appendNote(report.notes, `ImageSource 释放失败：${error}`);
        }
      }
      if (sourceFile) {
        try {
          fs.closeSync(sourceFile);
        } catch (error) {
          resourceCleanupSuccessful = false;
          report.notes = appendNote(report.notes, `输入文件关闭失败：${error}`);
        }
      }
    }

    report.memoryAfterMB = samplePssMB();
    updatePeakMemory(report, report.memoryAfterMB);
    if (report.memoryBeforeMB === null || report.memoryPeakMB === null || report.memoryAfterMB === null) {
      report.notes = appendNote(report.notes, 'hidebug.getPss 内存采样失败，缺失值记为 null');
    }
    report.totalMs = Date.now() - startedAt;
    report.passed = decodedAllRegions &&
      resourceCleanupSuccessful &&
      report.regionTimesMs.length === regionCount &&
      report.totalMs < MAX_TOTAL_MS;

    try {
      writeReport(context, report);
    } catch (error) {
      report.passed = false;
      report.notes = appendNote(report.notes, `报告写入失败：${error}`);
    }
    console.info(`[CanvasSpikeV2Decode] ${JSON.stringify(report)}`);
    return report;
  }
}
