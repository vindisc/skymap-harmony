import fs from '@ohos.file.fs';

export interface JpegExifIdentity {
  cameraMake: string;
  cameraModel: string;
  lensMake: string;
  lensModel: string;
}

const JPEG_HEADER_READ_LIMIT: number = 2 * 1024 * 1024;
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

function preferIdentityValue(primary: string, supplemental: string): string {
  return primary.trim().length > 0 ? primary : supplemental.trim();
}

function mergeIdentity(primary: JpegExifIdentity, supplemental: JpegExifIdentity): JpegExifIdentity {
  return {
    cameraMake: preferIdentityValue(primary.cameraMake, supplemental.cameraMake),
    cameraModel: preferIdentityValue(primary.cameraModel, supplemental.cameraModel),
    lensMake: preferIdentityValue(primary.lensMake, supplemental.lensMake),
    lensModel: preferIdentityValue(primary.lensModel, supplemental.lensModel)
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

function matchesAscii(bytes: Uint8Array, offset: number, token: string): boolean {
  if (!canRead(bytes, offset, token.length)) {
    return false;
  }
  for (let index: number = 0; index < token.length; index += 1) {
    if (bytes[offset + index] !== token.charCodeAt(index)) {
      return false;
    }
  }
  return true;
}

function findAscii(bytes: Uint8Array, token: string, startOffset: number = 0): number {
  for (let offset: number = Math.max(0, startOffset); offset + token.length <= bytes.length; offset += 1) {
    if (matchesAscii(bytes, offset, token)) {
      return offset;
    }
  }
  return -1;
}

function readXmpAttribute(bytes: Uint8Array, name: string): string {
  let searchOffset: number = 0;
  while (searchOffset < bytes.length) {
    const nameOffset: number = findAscii(bytes, name, searchOffset);
    if (nameOffset < 0) {
      return '';
    }
    let valueOffset: number = nameOffset + name.length;
    while (valueOffset < bytes.length &&
      (bytes[valueOffset] === 0x20 || bytes[valueOffset] === 0x09 ||
        bytes[valueOffset] === 0x0A || bytes[valueOffset] === 0x0D)) {
      valueOffset += 1;
    }
    if (valueOffset < bytes.length && bytes[valueOffset] === 0x3D) {
      valueOffset += 1;
      while (valueOffset < bytes.length && (bytes[valueOffset] === 0x20 || bytes[valueOffset] === 0x09)) {
        valueOffset += 1;
      }
      if (valueOffset < bytes.length && (bytes[valueOffset] === 0x22 || bytes[valueOffset] === 0x27)) {
        const quote: number = bytes[valueOffset];
        const contentOffset: number = valueOffset + 1;
        let endOffset: number = contentOffset;
        while (endOffset < bytes.length && bytes[endOffset] !== quote) {
          endOffset += 1;
        }
        if (endOffset < bytes.length) {
          return readAscii(bytes, contentOffset, endOffset - contentOffset);
        }
      }
    }
    searchOffset = nameOffset + name.length;
  }
  return '';
}

function readXmpElement(bytes: Uint8Array, name: string): string {
  const openingTag: string = `<${name}>`;
  const openingOffset: number = findAscii(bytes, openingTag);
  if (openingOffset < 0) {
    return '';
  }
  const contentOffset: number = openingOffset + openingTag.length;
  const closingOffset: number = findAscii(bytes, `<`, contentOffset);
  if (closingOffset < 0) {
    return '';
  }
  return readAscii(bytes, contentOffset, closingOffset - contentOffset);
}

function readXmpValue(bytes: Uint8Array, names: Array<string>): string {
  for (let index: number = 0; index < names.length; index += 1) {
    const attributeValue: string = readXmpAttribute(bytes, names[index]);
    if (attributeValue.length > 0) {
      return attributeValue;
    }
    const elementValue: string = readXmpElement(bytes, names[index]);
    if (elementValue.length > 0) {
      return elementValue;
    }
  }
  return '';
}

function parseXmpIdentity(bytes: Uint8Array): JpegExifIdentity {
  return {
    cameraMake: readXmpValue(bytes, ['tiff:Make', 'exif:Make']),
    cameraModel: readXmpValue(bytes, ['tiff:Model', 'exif:Model']),
    lensMake: readXmpValue(bytes, ['exifEX:LensMake', 'aux:LensMake']),
    lensModel: readXmpValue(bytes, ['exifEX:LensModel', 'exif:LensModel', 'aux:Lens'])
  };
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

  let identity: JpegExifIdentity = emptyIdentity();
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
      identity = mergeIdentity(identity, parseExifSegment(bytes, markerOffset + 4));
    }
    markerOffset += 2 + segmentLength;
  }
  return mergeIdentity(identity, parseXmpIdentity(bytes));
}

export class JpegExifIdentityReader {
  static readFromFd(fd: number): JpegExifIdentity {
    let originalOffset: number = 0;
    try {
      try {
        originalOffset = fs.lseek(fd, 0, fs.WhenceType.SEEK_CUR);
        fs.lseek(fd, 0, fs.WhenceType.SEEK_SET);
      } catch (error) {
        originalOffset = 0;
      }
      const fileSize: number = fs.statSync(fd).size;
      const readSize: number = Math.min(fileSize, JPEG_HEADER_READ_LIMIT);
      if (readSize <= 0) {
        return emptyIdentity();
      }
      const buffer: ArrayBuffer = new ArrayBuffer(readSize);
      const bytesRead: number = fs.readSync(fd, buffer);
      if (bytesRead <= 0) {
        console.warn(`[JpegExifIdentityReader] 文件头读取为空：size=${fileSize}`);
        return emptyIdentity();
      }
      const bytes: Uint8Array = new Uint8Array(buffer, 0, bytesRead);
      return parseJpegExifIdentity(bytes);
    } finally {
      try {
        fs.lseek(fd, originalOffset, fs.WhenceType.SEEK_SET);
      } catch (error) {
      }
    }
  }

  static read(imageUri: string): JpegExifIdentity {
    const file: fs.File = fs.openSync(imageUri, fs.OpenMode.READ_ONLY);
    try {
      return JpegExifIdentityReader.readFromFd(file.fd);
    } finally {
      fs.closeSync(file);
    }
  }
}
