import fs from '@ohos.file.fs';

export interface JpegExifIdentity {
  cameraMake: string;
  cameraModel: string;
  lensMake: string;
  lensModel: string;
}

const JPEG_HEADER_READ_LIMIT: number = 256 * 1024;
const EXIF_IFD_POINTER_TAG: number = 0x8769;
const CAMERA_MAKE_TAG: number = 0x010F;
const CAMERA_MODEL_TAG: number = 0x0110;
const LENS_MAKE_TAG: number = 0xA433;
const LENS_MODEL_TAG: number = 0xA434;
const TIFF_ASCII_TYPE: number = 2;
const TIFF_LONG_TYPE: number = 4;

function emptyIdentity(): JpegExifIdentity {
  return {
    cameraMake: '',
    cameraModel: '',
    lensMake: '',
    lensModel: ''
  };
}

function canRead(bytes: Uint8Array, offset: number, length: number): boolean {
  return offset >= 0 && length >= 0 && offset + length <= bytes.length;
}

function readUint16(bytes: Uint8Array, offset: number, littleEndian: boolean): number {
  if (!canRead(bytes, offset, 2)) {
    return -1;
  }
  if (littleEndian) {
    return bytes[offset] + bytes[offset + 1] * 256;
  }
  return bytes[offset] * 256 + bytes[offset + 1];
}

function readUint32(bytes: Uint8Array, offset: number, littleEndian: boolean): number {
  if (!canRead(bytes, offset, 4)) {
    return -1;
  }
  if (littleEndian) {
    return bytes[offset] +
      bytes[offset + 1] * 256 +
      bytes[offset + 2] * 65536 +
      bytes[offset + 3] * 16777216;
  }
  return bytes[offset] * 16777216 +
    bytes[offset + 1] * 65536 +
    bytes[offset + 2] * 256 +
    bytes[offset + 3];
}

function readAscii(bytes: Uint8Array, offset: number, length: number): string {
  if (!canRead(bytes, offset, length)) {
    return '';
  }
  let result: string = '';
  for (let index: number = 0; index < length; index += 1) {
    const value: number = bytes[offset + index];
    if (value === 0) {
      break;
    }
    result += String.fromCharCode(value);
  }
  return result.trim();
}

function readAsciiEntry(
  bytes: Uint8Array,
  entryOffset: number,
  tiffStart: number,
  littleEndian: boolean
): string {
  const type: number = readUint16(bytes, entryOffset + 2, littleEndian);
  const count: number = readUint32(bytes, entryOffset + 4, littleEndian);
  if (type !== TIFF_ASCII_TYPE || count <= 0) {
    return '';
  }
  const valueOffset: number = count <= 4
    ? entryOffset + 8
    : tiffStart + readUint32(bytes, entryOffset + 8, littleEndian);
  return readAscii(bytes, valueOffset, count);
}

function readIfd(
  bytes: Uint8Array,
  ifdOffset: number,
  tiffStart: number,
  littleEndian: boolean,
  identity: JpegExifIdentity
): number {
  if (!canRead(bytes, ifdOffset, 2)) {
    return -1;
  }
  const entryCount: number = readUint16(bytes, ifdOffset, littleEndian);
  if (entryCount < 0 || entryCount > 1024 || !canRead(bytes, ifdOffset + 2, entryCount * 12)) {
    return -1;
  }

  let exifIfdOffset: number = -1;
  for (let index: number = 0; index < entryCount; index += 1) {
    const entryOffset: number = ifdOffset + 2 + index * 12;
    const tag: number = readUint16(bytes, entryOffset, littleEndian);
    if (tag === CAMERA_MAKE_TAG) {
      identity.cameraMake = readAsciiEntry(bytes, entryOffset, tiffStart, littleEndian);
    } else if (tag === CAMERA_MODEL_TAG) {
      identity.cameraModel = readAsciiEntry(bytes, entryOffset, tiffStart, littleEndian);
    } else if (tag === LENS_MAKE_TAG) {
      identity.lensMake = readAsciiEntry(bytes, entryOffset, tiffStart, littleEndian);
    } else if (tag === LENS_MODEL_TAG) {
      identity.lensModel = readAsciiEntry(bytes, entryOffset, tiffStart, littleEndian);
    } else if (tag === EXIF_IFD_POINTER_TAG) {
      const type: number = readUint16(bytes, entryOffset + 2, littleEndian);
      const count: number = readUint32(bytes, entryOffset + 4, littleEndian);
      if (type === TIFF_LONG_TYPE && count === 1) {
        exifIfdOffset = tiffStart + readUint32(bytes, entryOffset + 8, littleEndian);
      }
    }
  }
  return exifIfdOffset;
}

function parseExifSegment(bytes: Uint8Array, payloadOffset: number): JpegExifIdentity {
  const identity: JpegExifIdentity = emptyIdentity();
  if (!canRead(bytes, payloadOffset, 14) ||
    bytes[payloadOffset] !== 0x45 ||
    bytes[payloadOffset + 1] !== 0x78 ||
    bytes[payloadOffset + 2] !== 0x69 ||
    bytes[payloadOffset + 3] !== 0x66 ||
    bytes[payloadOffset + 4] !== 0 ||
    bytes[payloadOffset + 5] !== 0) {
    return identity;
  }

  const tiffStart: number = payloadOffset + 6;
  const littleEndian: boolean = bytes[tiffStart] === 0x49 && bytes[tiffStart + 1] === 0x49;
  const bigEndian: boolean = bytes[tiffStart] === 0x4D && bytes[tiffStart + 1] === 0x4D;
  if ((!littleEndian && !bigEndian) || readUint16(bytes, tiffStart + 2, littleEndian) !== 42) {
    return identity;
  }

  const ifd0Offset: number = tiffStart + readUint32(bytes, tiffStart + 4, littleEndian);
  const exifIfdOffset: number = readIfd(bytes, ifd0Offset, tiffStart, littleEndian, identity);
  if (exifIfdOffset >= 0) {
    readIfd(bytes, exifIfdOffset, tiffStart, littleEndian, identity);
  }
  return identity;
}

export function parseJpegExifIdentity(bytes: Uint8Array): JpegExifIdentity {
  if (bytes.length < 4 || bytes[0] !== 0xFF || bytes[1] !== 0xD8) {
    return emptyIdentity();
  }

  let markerOffset: number = 2;
  while (markerOffset + 4 <= bytes.length) {
    if (bytes[markerOffset] !== 0xFF) {
      markerOffset += 1;
      continue;
    }
    const marker: number = bytes[markerOffset + 1];
    if (marker === 0xDA || marker === 0xD9) {
      break;
    }
    if (marker === 0x00 || marker === 0xFF || (marker >= 0xD0 && marker <= 0xD7)) {
      markerOffset += 2;
      continue;
    }
    const segmentLength: number = readUint16(bytes, markerOffset + 2, false);
    if (segmentLength < 2 || !canRead(bytes, markerOffset + 2, segmentLength)) {
      break;
    }
    if (marker === 0xE1) {
      const identity: JpegExifIdentity = parseExifSegment(bytes, markerOffset + 4);
      if (identity.cameraMake.length > 0 || identity.cameraModel.length > 0 ||
        identity.lensMake.length > 0 || identity.lensModel.length > 0) {
        return identity;
      }
    }
    markerOffset += 2 + segmentLength;
  }
  return emptyIdentity();
}

export class JpegExifIdentityReader {
  static read(imageUri: string): JpegExifIdentity {
    const file: fs.File = fs.openSync(imageUri, fs.OpenMode.READ_ONLY);
    try {
      const fileSize: number = fs.statSync(file.fd).size;
      const readSize: number = Math.min(fileSize, JPEG_HEADER_READ_LIMIT);
      if (readSize <= 0) {
        return emptyIdentity();
      }
      const buffer: ArrayBuffer = new ArrayBuffer(readSize);
      const bytesRead: number = fs.readSync(file.fd, buffer);
      if (bytesRead <= 0) {
        console.warn(`[JpegExifIdentityReader] 文件头读取为空：size=${fileSize}`);
        return emptyIdentity();
      }
      const bytes: Uint8Array = new Uint8Array(buffer, 0, bytesRead);
      return parseJpegExifIdentity(bytes);
    } finally {
      fs.closeSync(file);
    }
  }
}
