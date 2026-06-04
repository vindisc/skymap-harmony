export type SampleImageKind = 'horizontal' | 'vertical' | 'square';

export interface SampleImageInfo {
  imageUri: string;
  imageWidth: number;
  imageHeight: number;
}

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

export function getImageRatioLabel(width: number, height: number): string {
  if (height <= 0) {
    return '照片';
  }

  const ratio: number = width / height;
  if (ratio >= 1.15) {
    return '横图';
  }

  if (ratio <= 0.85) {
    return '竖图';
  }

  return '方图';
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
