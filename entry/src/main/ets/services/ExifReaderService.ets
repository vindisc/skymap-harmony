import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import { ExifPayload, ExifSource } from '../model/ExifPayloadModel';
import { JpegExifIdentity, JpegExifIdentityReader } from './JpegExifIdentityReader';

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

const TAMRON_LENS_MODEL_CODES: Array<string> = [
  'A071'
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

export function inferCameraMake(cameraModel: string): string {
  const normalized: string = cameraModel.trim().toUpperCase();
  if (normalized.startsWith('ILCE-') || normalized.startsWith('ILCA-') ||
    normalized.startsWith('NEX-') || normalized.startsWith('DSC-')) {
    return 'SONY';
  }
  return '';
}

export function inferLensMake(lensModel: string): string {
  const normalized: string = lensModel.trim().toUpperCase();
  if (normalized.indexOf('TAMRON') >= 0) {
    return 'TAMRON';
  }
  if (normalized.indexOf('SIGMA') >= 0) {
    return 'SIGMA';
  }
  for (let index: number = 0; index < TAMRON_LENS_MODEL_CODES.length; index += 1) {
    const code: string = TAMRON_LENS_MODEL_CODES[index];
    const codePattern: RegExp = new RegExp(`(^|\\s)${code}($|\\s)`);
    if (codePattern.test(normalized)) {
      return 'TAMRON';
    }
  }
  return '';
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

async function readPayload(source: image.ImageSource): Promise<ExifPayload> {
  const cameraMake: string = await readProperty(source, image.PropertyKey.MAKE);
  const rawCameraModel: string = await readProperty(source, image.PropertyKey.MODEL);
  const lensMake: string = await readProperty(source, image.PropertyKey.LENS_MAKE);
  const lensModel: string = await readProperty(source, image.PropertyKey.LENS_MODEL);
  const rawFocalLength: string = await readProperty(source, image.PropertyKey.FOCAL_LENGTH);
  const rawAperture: string = await readProperty(source, image.PropertyKey.F_NUMBER);
  const rawShutter: string = await readProperty(source, image.PropertyKey.EXPOSURE_TIME);
  const rawIso: string = await readProperty(source, image.PropertyKey.ISO_SPEED_RATINGS);
  const captureDate: string = await readProperty(source, image.PropertyKey.DATE_TIME_ORIGINAL);
  const cameraModel: string = cleanCameraModel(rawCameraModel);
  return {
    cameraMake: cameraMake.length > 0 ? cameraMake : inferCameraMake(cameraModel),
    cameraModel: cameraModel,
    lensMake: lensMake.length > 0 ? lensMake : inferLensMake(lensModel),
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
}

async function readExifByUri(imageUri: string): Promise<ExifPayload> {
  const source: image.ImageSource = image.createImageSource(imageUri);
  try {
    return await readPayload(source);
  } finally {
    await source.release();
  }
}

async function readExifByFd(imageUri: string): Promise<ExifPayload> {
  const file: fs.File = fs.openSync(imageUri, fs.OpenMode.READ_ONLY);
  try {
    const source: image.ImageSource = image.createImageSource(file.fd);
    try {
      const propertyPayload: ExifPayload = await readPayload(source);
      let jpegIdentity: JpegExifIdentity = {
        cameraMake: '',
        cameraModel: '',
        lensMake: '',
        lensModel: ''
      };
      try {
        jpegIdentity = JpegExifIdentityReader.read(imageUri);
      } catch (error) {
        console.warn(`[ExifReaderService] JPEG 身份标签兜底失败：${error}`);
      }
      return mergeExifPayload(propertyPayload, createIdentityPayload(jpegIdentity));
    } finally {
      await source.release();
    }
  } finally {
    fs.closeSync(file);
  }
}

function shouldReadByFdFirst(imageUri: string): boolean {
  const normalizedUri: string = imageUri.trim().toLowerCase();
  return normalizedUri.startsWith('file://media/')
    || normalizedUri.startsWith('datashare://media/')
    || normalizedUri.indexOf('://media/') >= 0;
}

async function readWithFallback(
  primaryReader: () => Promise<ExifPayload>,
  fallbackReader: () => Promise<ExifPayload>
): Promise<ExifPayload> {
  let primaryPayload: ExifPayload | null = null;
  let fallbackPayload: ExifPayload | null = null;
  try {
    primaryPayload = await primaryReader();
  } catch (error) {
  }

  try {
    fallbackPayload = await fallbackReader();
  } catch (error) {
  }

  if (primaryPayload === null && fallbackPayload === null) {
    throw new Error('读取 EXIF 失败：媒体文件描述符和图片地址均不可用');
  }
  if (primaryPayload === null) {
    return fallbackPayload as ExifPayload;
  }
  if (fallbackPayload === null) {
    return primaryPayload;
  }
  return mergeExifPayload(primaryPayload, fallbackPayload);
}

function preferExifValue(primaryValue: string, fallbackValue: string): string {
  return primaryValue.trim().length > 0 ? primaryValue : fallbackValue;
}

function createIdentityPayload(identity: JpegExifIdentity): ExifPayload {
  const cameraModel: string = cleanCameraModel(identity.cameraModel);
  const lensModel: string = identity.lensModel.trim();
  return {
    cameraMake: identity.cameraMake.trim().length > 0
      ? identity.cameraMake.trim()
      : inferCameraMake(cameraModel),
    cameraModel: cameraModel,
    lensMake: identity.lensMake.trim().length > 0
      ? identity.lensMake.trim()
      : inferLensMake(lensModel),
    lensModel: lensModel,
    focalLength: '',
    aperture: '',
    shutter: '',
    iso: '',
    captureDate: '',
    location: '',
    source: ExifSource.AUTO,
    manuallyOverridden: []
  };
}

export function mergeExifPayload(primary: ExifPayload, fallback: ExifPayload): ExifPayload {
  const cameraModel: string = preferExifValue(primary.cameraModel, fallback.cameraModel);
  const lensModel: string = preferExifValue(primary.lensModel, fallback.lensModel);
  const cameraMake: string = preferExifValue(primary.cameraMake, fallback.cameraMake);
  const lensMake: string = preferExifValue(primary.lensMake, fallback.lensMake);
  return {
    cameraMake: cameraMake.length > 0 ? cameraMake : inferCameraMake(cameraModel),
    cameraModel: cameraModel,
    lensMake: lensMake.length > 0 ? lensMake : inferLensMake(lensModel),
    lensModel: lensModel,
    focalLength: preferExifValue(primary.focalLength, fallback.focalLength),
    aperture: preferExifValue(primary.aperture, fallback.aperture),
    shutter: preferExifValue(primary.shutter, fallback.shutter),
    iso: preferExifValue(primary.iso, fallback.iso),
    captureDate: preferExifValue(primary.captureDate, fallback.captureDate),
    location: preferExifValue(primary.location, fallback.location),
    source: ExifSource.AUTO,
    manuallyOverridden: []
  };
}

function canAutoFillIdentity(payload: ExifPayload, field: string): boolean {
  return payload.manuallyOverridden.indexOf(field) < 0;
}

export function hasMissingExifIdentity(payload: ExifPayload): boolean {
  const cameraMakeMissing: boolean = payload.cameraMake.trim().length === 0 &&
    canAutoFillIdentity(payload, 'cameraMake');
  const cameraModelMissing: boolean = payload.cameraModel.trim().length === 0 &&
    canAutoFillIdentity(payload, 'cameraModel');
  const lensMakeMissing: boolean = payload.lensModel.trim().length > 0 &&
    payload.lensMake.trim().length === 0 &&
    canAutoFillIdentity(payload, 'lensMake');
  return cameraMakeMissing || cameraModelMissing || lensMakeMissing;
}

export function mergeMissingExifIdentity(existing: ExifPayload, automatic: ExifPayload): ExifPayload {
  const result: ExifPayload = {
    cameraMake: existing.cameraMake,
    cameraModel: existing.cameraModel,
    lensMake: existing.lensMake,
    lensModel: existing.lensModel,
    focalLength: existing.focalLength,
    aperture: existing.aperture,
    shutter: existing.shutter,
    iso: existing.iso,
    captureDate: existing.captureDate,
    location: existing.location,
    source: existing.source,
    manuallyOverridden: existing.manuallyOverridden.slice()
  };
  if (result.cameraMake.trim().length === 0 && canAutoFillIdentity(result, 'cameraMake')) {
    result.cameraMake = automatic.cameraMake;
  }
  if (result.cameraModel.trim().length === 0 && canAutoFillIdentity(result, 'cameraModel')) {
    result.cameraModel = automatic.cameraModel;
  }
  if (result.lensMake.trim().length === 0 && canAutoFillIdentity(result, 'lensMake')) {
    result.lensMake = automatic.lensMake;
  }
  if (result.lensModel.trim().length === 0 && canAutoFillIdentity(result, 'lensModel')) {
    result.lensModel = automatic.lensModel;
  }
  if (result.cameraMake.trim().length === 0 && canAutoFillIdentity(result, 'cameraMake')) {
    result.cameraMake = inferCameraMake(result.cameraModel);
  }
  if (result.lensMake.trim().length === 0 && canAutoFillIdentity(result, 'lensMake')) {
    result.lensMake = inferLensMake(result.lensModel);
  }
  result.source = result.manuallyOverridden.length === 0 ? ExifSource.AUTO : ExifSource.MIXED;
  return result;
}

export class ExifReaderService {
  static async read(imageUri: string): Promise<ExifPayload> {
    if (shouldReadByFdFirst(imageUri)) {
      return readWithFallback(
        (): Promise<ExifPayload> => readExifByFd(imageUri),
        (): Promise<ExifPayload> => readExifByUri(imageUri)
      );
    }
    return readWithFallback(
      (): Promise<ExifPayload> => readExifByUri(imageUri),
      (): Promise<ExifPayload> => readExifByFd(imageUri)
    );
  }
}
