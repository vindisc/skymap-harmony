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
    return '示例照片';
  }

  const ratio: number = width / height;
  if (ratio >= 1.15) {
    return '示例横图';
  }

  if (ratio <= 0.85) {
    return '示例竖图';
  }

  return '示例方图';
}

