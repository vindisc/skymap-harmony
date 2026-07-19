import image from '@ohos.multimedia.image';
import { ExifPayload, ExifSource } from '../model/ExifPayloadModel';

const CAMERA_MODEL_BRAND_PREFIXES: Array<string> = [
  'SONY ',
  'Sony ',
  'CANON ',
  'Canon ',
  'NIKON ',
  'Nikon ',
  'FUJIFILM ',
  'Fujifilm ',
  'RICOH ',
  'Ricoh ',
  'PANASONIC ',
  'Panasonic '
];

function parseExifNumber(raw: string): number | null {
  const normalized: string = raw.trim();
  if (normalized.length === 0) {
    return null;
  }
  const fractionParts: Array<string> = normalized.split('/');
  if (fractionParts.length === 2) {
    const numerator: number = Number(fractionParts[0]);
    const denominator: number = Number(fractionParts[1]);
    if (Number.isFinite(numerator) && Number.isFinite(denominator) && denominator !== 0) {
      return numerator / denominator;
    }
    return null;
  }
  const value: number = Number(normalized);
  return Number.isFinite(value) ? value : null;
}

function formatExifNumber(value: number): string {
  const rounded: number = Math.round(value * 10000) / 10000;
  return `${rounded}`;
}

function trimAndFormatFocalLength(value: number): string {
  const rounded: number = Math.round(value * 10) / 10;
  return rounded % 1 === 0 ? `${Math.round(rounded)}` : `${rounded}`;
}

export function cleanCameraModel(input: string): string {
  const normalized: string = input.trim();
  for (let index: number = 0; index < CAMERA_MODEL_BRAND_PREFIXES.length; index += 1) {
    const prefix: string = CAMERA_MODEL_BRAND_PREFIXES[index];
    if (normalized.startsWith(prefix)) {
      return normalized.slice(prefix.length);
    }
  }
  return normalized;
}

export function normalizeAperture(raw: string): string {
  const normalized: string = raw.trim();
  if (normalized.length === 0 || normalized.startsWith('f/')) {
    return normalized;
  }
  const value: number | null = parseExifNumber(normalized);
  return value !== null && value > 0 ? `f/${formatExifNumber(value)}` : normalized;
}

export function normalizeShutter(raw: string): string {
  const normalized: string = raw.trim();
  if (normalized.length === 0) {
    return normalized;
  }
  if (normalized.includes('/')) {
    const match: RegExpMatchArray | null = normalized.match(/^(\d+)\s*\/\s*(\d+)/);
    if (match !== null) {
      return `${match[1]}/${match[2]}`;
    }
    return normalized;
  }
  const value: number = Number(normalized);
  if (Number.isFinite(value) && value > 0) {
    if (value < 1) {
      return `1/${Math.max(1, Math.round(1 / value))}`;
    }
    return `${Math.round(value * 10) / 10}s`;
  }
  return normalized;
}

export function normalizeFocalLength(raw: string): string {
  const normalized: string = raw.trim();
  if (normalized.length === 0) {
    return normalized;
  }
  if (normalized.includes('/')) {
    const fractionValue: number | null = parseExifNumber(normalized);
    return fractionValue !== null && fractionValue > 0
      ? `${trimAndFormatFocalLength(fractionValue)}mm`
      : normalized;
  }
  const withoutSpaces: string = normalized.replace(/\s+/g, '');
  const numericText: string = withoutSpaces.endsWith('mm')
    ? withoutSpaces.slice(0, withoutSpaces.length - 2)
    : withoutSpaces;
  const value: number = Number(numericText);
  return Number.isFinite(value) && value > 0
    ? `${trimAndFormatFocalLength(value)}mm`
    : normalized;
}

export function normalizeIso(raw: string): string {
  const normalized: string = raw.trim();
  if (normalized.length === 0 || normalized.startsWith('ISO')) {
    return normalized;
  }
  const value: number | null = parseExifNumber(normalized);
  return value !== null && value > 0 ? `ISO${Math.round(value)}` : `ISO${normalized}`;
}

async function readProperty(source: image.ImageSource, key: image.PropertyKey): Promise<string> {
  try {
    return (await source.getImageProperty(key)).trim();
  } catch (error) {
    return '';
  }
}

export class ExifReaderService {
  static async read(imageUri: string): Promise<ExifPayload> {
    const source: image.ImageSource = image.createImageSource(imageUri);
    try {
      const cameraMake: string = await readProperty(source, image.PropertyKey.MAKE);
      const rawCameraModel: string = await readProperty(source, image.PropertyKey.MODEL);
      const lensMake: string = await readProperty(source, image.PropertyKey.LENS_MAKE);
      const lensModel: string = await readProperty(source, image.PropertyKey.LENS_MODEL);
      const rawFocalLength: string = await readProperty(source, image.PropertyKey.FOCAL_LENGTH);
      const rawAperture: string = await readProperty(source, image.PropertyKey.F_NUMBER);
      const rawShutter: string = await readProperty(source, image.PropertyKey.EXPOSURE_TIME);
      const rawIso: string = await readProperty(source, image.PropertyKey.ISO_SPEED_RATINGS);
      const captureDate: string = await readProperty(source, image.PropertyKey.DATE_TIME_ORIGINAL);
      return {
        cameraMake: cameraMake,
        cameraModel: cleanCameraModel(rawCameraModel),
        lensMake: lensMake,
        lensModel: lensModel,
        focalLength: normalizeFocalLength(rawFocalLength),
        aperture: normalizeAperture(rawAperture),
        shutter: normalizeShutter(rawShutter),
        iso: normalizeIso(rawIso),
        captureDate: captureDate,
        location: '',
        source: ExifSource.AUTO,
        manuallyOverridden: []
      };
    } finally {
      await source.release();
    }
  }
}
