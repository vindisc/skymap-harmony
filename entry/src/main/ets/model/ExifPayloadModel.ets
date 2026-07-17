export enum ExifSource {
  AUTO = 'auto',
  MANUAL = 'manual',
  MIXED = 'mixed'
}

export interface ExifPayload {
  cameraMake: string;
  cameraModel: string;
  lensMake: string;
  lensModel: string;
  focalLength: string;
  aperture: string;
  shutter: string;
  iso: string;
  captureDate: string;
  location: string;
  source: ExifSource;
  manuallyOverridden: Array<string>;
}

export const EXIF_PAYLOAD_EMPTY: ExifPayload = {
  cameraMake: '',
  cameraModel: '',
  lensMake: '',
  lensModel: '',
  focalLength: '',
  aperture: '',
  shutter: '',
  iso: '',
  captureDate: '',
  location: '',
  source: ExifSource.AUTO,
  manuallyOverridden: []
};

export function isExifPayloadEmpty(payload: ExifPayload): boolean {
  return payload.cameraMake.length === 0
    && payload.cameraModel.length === 0
    && payload.lensMake.length === 0
    && payload.lensModel.length === 0
    && payload.focalLength.length === 0
    && payload.aperture.length === 0
    && payload.shutter.length === 0
    && payload.iso.length === 0
    && payload.captureDate.length === 0
    && payload.location.length === 0;
}

export function normalizeExifPayload(input: ExifPayload | undefined): ExifPayload {
  if (input === undefined) {
    return {
      cameraMake: EXIF_PAYLOAD_EMPTY.cameraMake,
      cameraModel: EXIF_PAYLOAD_EMPTY.cameraModel,
      lensMake: EXIF_PAYLOAD_EMPTY.lensMake,
      lensModel: EXIF_PAYLOAD_EMPTY.lensModel,
      focalLength: EXIF_PAYLOAD_EMPTY.focalLength,
      aperture: EXIF_PAYLOAD_EMPTY.aperture,
      shutter: EXIF_PAYLOAD_EMPTY.shutter,
      iso: EXIF_PAYLOAD_EMPTY.iso,
      captureDate: EXIF_PAYLOAD_EMPTY.captureDate,
      location: EXIF_PAYLOAD_EMPTY.location,
      source: EXIF_PAYLOAD_EMPTY.source,
      manuallyOverridden: []
    };
  }
  const overrides: Array<string> = Array.isArray(input.manuallyOverridden)
    ? input.manuallyOverridden.filter((key: string): boolean => typeof key === 'string')
    : [];
  return {
    cameraMake: typeof input.cameraMake === 'string' ? input.cameraMake : '',
    cameraModel: typeof input.cameraModel === 'string' ? input.cameraModel : '',
    lensMake: typeof input.lensMake === 'string' ? input.lensMake : '',
    lensModel: typeof input.lensModel === 'string' ? input.lensModel : '',
    focalLength: typeof input.focalLength === 'string' ? input.focalLength : '',
    aperture: typeof input.aperture === 'string' ? input.aperture : '',
    shutter: typeof input.shutter === 'string' ? input.shutter : '',
    iso: typeof input.iso === 'string' ? input.iso : '',
    captureDate: typeof input.captureDate === 'string' ? input.captureDate : '',
    location: typeof input.location === 'string' ? input.location : '',
    source: input.source === ExifSource.MANUAL || input.source === ExifSource.MIXED
      ? input.source
      : ExifSource.AUTO,
    manuallyOverridden: overrides
  };
}
