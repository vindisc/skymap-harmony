import { ReviewCardLayoutResolution, ReviewCardLayoutType } from '../model/ReviewCardModel';

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
  const resolution = resolveReviewImageLayout(width, height, fallbackUsed);
  if (!resolution.hasExactSize) {
    return 'unknown';
  }

  if (resolution.layoutType === ReviewCardLayoutType.HORIZONTAL) {
    return 'horizontal';
  }

  if (resolution.layoutType === ReviewCardLayoutType.VERTICAL) {
    return 'vertical';
  }

  return 'square';
}

export function getImageAspectRatio(width: number, height: number, fallbackUsed: boolean = false): number {
  return resolveReviewImageLayout(width, height, fallbackUsed).aspectRatio;
}

export function getImageRatioLabel(width: number, height: number, fallbackUsed: boolean = false): string {
  const kind = getImageRatioKind(width, height, fallbackUsed);
  if (kind === 'unknown') {
    return '尺寸待确认';
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
    return '当前按兜底尺寸预览';
  }

  return `${width} x ${height}`;
}

export function resolveReviewImageLayout(width: number, height: number, fallbackUsed: boolean = false): ReviewCardLayoutResolution {
  const hasExactSize: boolean = !fallbackUsed && width > 0 && height > 0;
  if (!hasExactSize) {
    return {
      layoutType: ReviewCardLayoutType.SQUARE,
      aspectRatio: 1,
      usedFallbackSize: true,
      hasExactSize: false
    };
  }

  const ratio: number = width / height;
  let layoutType: ReviewCardLayoutType = ReviewCardLayoutType.SQUARE;
  if (ratio >= HORIZONTAL_ASPECT_RATIO) {
    layoutType = ReviewCardLayoutType.HORIZONTAL;
  } else if (ratio <= VERTICAL_ASPECT_RATIO) {
    layoutType = ReviewCardLayoutType.VERTICAL;
  }

  return {
    layoutType: layoutType,
    aspectRatio: ratio,
    usedFallbackSize: false,
    hasExactSize: true
  };
}

export function formatReviewTime(timestamp: number): string {
  const date = new Date(timestamp);
  const year = `${date.getFullYear()}`;
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  const hour = `${date.getHours()}`.padStart(2, '0');
  const minute = `${date.getMinutes()}`.padStart(2, '0');
  return `${year}-${month}-${day} ${hour}:${minute}`;
}

export function isSampleImageUri(imageUri: string): boolean {
  return imageUri.startsWith('sample://');
}

export function hasDisplayableImageUri(imageUri: string): boolean {
  return imageUri.length > 0 && !isSampleImageUri(imageUri);
}
