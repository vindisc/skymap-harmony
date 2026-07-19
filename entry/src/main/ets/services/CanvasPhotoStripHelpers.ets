import { BusinessError } from '@ohos.base';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';

export interface CanvasRotatedImageSize {
  width: number;
  height: number;
}

export interface CanvasSourceImageLayout {
  encodedWidth: number;
  encodedHeight: number;
  orientation: number;
  rotationDegrees: number;
  rotatedSize: CanvasRotatedImageSize;
}

export const CANVAS_STRIP_HEIGHT_PX: number = 256;
export const CANVAS_JPEG_QUALITY: number = 95;
export const CANVAS_RGBA_BYTES_PER_PIXEL: number = 4;
export const CANVAS_RGB_BYTES_PER_PIXEL: number = 3;

export function appendCanvasComposeMessage(message: string, detail: string): string {
  return message.length > 0 ? `${message}；${detail}` : detail;
}

export function describeCanvasComposeError(error: Error | Object, stripIndex: number, stage: string): string {
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

export function ensureCanvasOutputParentDirectory(outputPath: string): void {
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

export async function resolveCanvasSourceLayout(source: image.ImageSource): Promise<CanvasSourceImageLayout> {
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

export async function validateCanvasRegionRotation(
  source: image.ImageSource,
  layout: CanvasSourceImageLayout
): Promise<void> {
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

export async function decodeCanvasPhotoStrip(
  source: image.ImageSource,
  layout: CanvasSourceImageLayout,
  rotatedY: number,
  stripHeight: number,
  stripIndex: number,
  logTag: string
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
    `[${logTag}] step 8.${stripIndex}.decode: region=${regionX},${regionY},` +
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

export function canvasRgbaToRgb(
  rgbaBuffer: ArrayBuffer,
  width: number,
  height: number,
  bytesPerRow: number
): ArrayBuffer {
  const rgba: Uint8Array = new Uint8Array(rgbaBuffer);
  const rgb: Uint8Array = new Uint8Array(width * height * CANVAS_RGB_BYTES_PER_PIXEL);
  let rgbIndex: number = 0;
  for (let y: number = 0; y < height; y += 1) {
    const rowStart: number = y * bytesPerRow;
    for (let x: number = 0; x < width; x += 1) {
      const rgbaOffset: number = rowStart + x * CANVAS_RGBA_BYTES_PER_PIXEL;
      rgb[rgbIndex] = rgba[rgbaOffset];
      rgb[rgbIndex + 1] = rgba[rgbaOffset + 1];
      rgb[rgbIndex + 2] = rgba[rgbaOffset + 2];
      rgbIndex += CANVAS_RGB_BYTES_PER_PIXEL;
    }
  }
  return rgb.buffer;
}
