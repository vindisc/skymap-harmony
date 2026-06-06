export type SampleImageKind = 'horizontal' | 'vertical' | 'square';

export interface SampleImageInfo {
  imageUri: string;
  imageWidth: number;
  imageHeight: number;
}

export const HORIZONTAL_ASPECT_RATIO: number = 1.15;
export const VERTICAL_ASPECT_RATIO: number = 0.87;

export type ImageRatioKind = 'horizontal' | 'vertical' | 'square' | 'unknown';

export function getSampleImage(kind: SampleImageKind): SampleImageInfo {
  if (kind === 'vertical') {
    return {
      imageUri: 'sample://vertical',
      imageWidth: 900,
      imageHeight: 1400
    };
  }

  if (kind === 'square') {
    return {
      imageUri: 'sample://square',
      imageWidth: 1200,
      imageHeight: 1200
    };
  }

  return {
    imageUri: 'sample://horizontal',
    imageWidth: 1600,
    imageHeight: 1000
  };
}

export function getImageRatioKind(width: number, height: number, fallbackUsed: boolean = false): ImageRatioKind {
  if (fallbackUsed || width <= 0 || height <= 0) {
    return 'unknown';
  }

  const ratio: number = width / height;
  if (ratio >= HORIZONTAL_ASPECT_RATIO) {
    return 'horizontal';
  }

  if (ratio <= VERTICAL_ASPECT_RATIO) {
    return 'vertical';
  }

  return 'square';
}

export function getImageAspectRatio(width: number, height: number, fallbackUsed: boolean = false): number {
  if (fallbackUsed || width <= 0 || height <= 0) {
    return 1;
  }

  return width / height;
}

export function getImageRatioLabel(width: number, height: number, fallbackUsed: boolean = false): string {
  const kind = getImageRatioKind(width, height, fallbackUsed);
  if (kind === 'unknown') {
    return '照片';
  }

  if (kind === 'horizontal') {
    return '横图';
  }

  if (kind === 'vertical') {
    return '竖图';
  }

  return '方图';
}

export function getImageSizeText(width: number, height: number, fallbackUsed: boolean = false): string {
  if (fallbackUsed || width <= 0 || height <= 0) {
    return '';
  }

  return `${width} x ${height}`;
}

export function getPreviewPhotoAspectRatio(width: number, height: number, fallbackUsed: boolean = false): number {
  const kind = getImageRatioKind(width, height, fallbackUsed);
  if (kind === 'unknown') {
    return 1.05;
  }

  const ratio = getImageAspectRatio(width, height, fallbackUsed);
  if (kind === 'horizontal') {
    return Math.min(1.9, Math.max(1.2, ratio));
  }

  if (kind === 'vertical') {
    return Math.min(0.92, Math.max(0.72, ratio));
  }

  return 1;
}

export function getExportPhotoAspectRatio(width: number, height: number, fallbackUsed: boolean = false): number {
  const kind = getImageRatioKind(width, height, fallbackUsed);
  if (kind === 'unknown') {
    return 1.05;
  }

  const ratio = getImageAspectRatio(width, height, fallbackUsed);
  if (kind === 'horizontal') {
    return Math.min(2.05, Math.max(1.2, ratio));
  }

  if (kind === 'vertical') {
    return Math.min(0.9, Math.max(0.68, ratio));
  }

  return 1;
}

export function formatReviewTime(timestamp: number): string {
  const date = new Date(timestamp);
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  const hour = `${date.getHours()}`.padStart(2, '0');
  const minute = `${date.getMinutes()}`.padStart(2, '0');
  return `${month}-${day} ${hour}:${minute}`;
}

export function isSampleImageUri(imageUri: string): boolean {
  return imageUri.startsWith('sample://');
}

export function hasDisplayableImageUri(imageUri: string): boolean {
  return imageUri.length > 0 && !isSampleImageUri(imageUri);
}
