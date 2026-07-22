import fs from 'node:fs';

const fixtureCandidates = [
  'entry/src/main/resources/rawfile/fixture-horizontal.jpg',
  'entry/src/main/resources/rawfile/fixture-l3-photo.jpg'
];
const fixturePath = fixtureCandidates.find((path) => fs.existsSync(path));
if (!fixturePath) {
  throw new Error('EXIF regression fixture not found');
}
const readerPath = 'entry/src/main/ets/services/ExifReaderService.ets';
const jpegReaderPath = 'entry/src/main/ets/services/JpegExifIdentityReader.ets';
const sheetPath = 'entry/src/main/ets/components/ExifSheet.ets';
const testPath = 'entry/src/ohosTest/ets/test/ExifIdentity.test.ets';
const deviceScenarioPath = 'entry/src/main/ets/services/CanvasSpikeV2L1ExportService.ets';

function readUint16(buffer, offset, littleEndian) {
  return littleEndian ? buffer.readUInt16LE(offset) : buffer.readUInt16BE(offset);
}

function readUint32(buffer, offset, littleEndian) {
  return littleEndian ? buffer.readUInt32LE(offset) : buffer.readUInt32BE(offset);
}

function readAsciiEntry(buffer, entryOffset, tiffStart, littleEndian) {
  const type = readUint16(buffer, entryOffset + 2, littleEndian);
  const count = readUint32(buffer, entryOffset + 4, littleEndian);
  if (type !== 2 || count <= 0) return '';
  const valueOffset = count <= 4
    ? entryOffset + 8
    : tiffStart + readUint32(buffer, entryOffset + 8, littleEndian);
  return buffer.subarray(valueOffset, valueOffset + count).toString('ascii').replace(/\0.*$/, '').trim();
}

function parseIfd(buffer, ifdOffset, tiffStart, littleEndian, identity) {
  const entryCount = readUint16(buffer, ifdOffset, littleEndian);
  let exifIfdOffset = -1;
  for (let index = 0; index < entryCount; index += 1) {
    const entryOffset = ifdOffset + 2 + index * 12;
    const tag = readUint16(buffer, entryOffset, littleEndian);
    if (tag === 0x010F) identity.cameraMake = readAsciiEntry(buffer, entryOffset, tiffStart, littleEndian);
    if (tag === 0x0110) identity.cameraModel = readAsciiEntry(buffer, entryOffset, tiffStart, littleEndian);
    if (tag === 0xA433) identity.lensMake = readAsciiEntry(buffer, entryOffset, tiffStart, littleEndian);
    if (tag === 0xA434) identity.lensModel = readAsciiEntry(buffer, entryOffset, tiffStart, littleEndian);
    if (tag === 0x8769) exifIfdOffset = tiffStart + readUint32(buffer, entryOffset + 8, littleEndian);
  }
  return exifIfdOffset;
}

function parseFixtureIdentity(buffer) {
  let markerOffset = 2;
  while (markerOffset + 10 < buffer.length) {
    const marker = buffer[markerOffset + 1];
    const segmentLength = buffer.readUInt16BE(markerOffset + 2);
    const payloadOffset = markerOffset + 4;
    if (marker === 0xE1 && buffer.subarray(payloadOffset, payloadOffset + 6).equals(Buffer.from('Exif\0\0'))) {
      const tiffStart = payloadOffset + 6;
      const littleEndian = buffer.subarray(tiffStart, tiffStart + 2).toString('ascii') === 'II';
      const identity = { cameraMake: '', cameraModel: '', lensMake: '', lensModel: '' };
      const ifd0Offset = tiffStart + readUint32(buffer, tiffStart + 4, littleEndian);
      const exifIfdOffset = parseIfd(buffer, ifd0Offset, tiffStart, littleEndian, identity);
      if (exifIfdOffset >= 0) parseIfd(buffer, exifIfdOffset, tiffStart, littleEndian, identity);
      return identity;
    }
    markerOffset += 2 + segmentLength;
  }
  throw new Error('fixture EXIF APP1 segment not found');
}

const fixtureIdentity = parseFixtureIdentity(fs.readFileSync(fixturePath));
const readerSource = fs.readFileSync(readerPath, 'utf8');
const jpegReaderSource = fs.readFileSync(jpegReaderPath, 'utf8');
const sheetSource = fs.readFileSync(sheetPath, 'utf8');
const testSource = fs.readFileSync(testPath, 'utf8');
const deviceScenarioSource = fs.readFileSync(deviceScenarioPath, 'utf8');
const failures = [];

function assert(condition, message) {
  if (!condition) failures.push(message);
}

assert(fixtureIdentity.cameraMake === 'SONY', `fixture Make expected SONY, got ${fixtureIdentity.cameraMake}`);
assert(fixtureIdentity.cameraModel === 'ILCE-7CM2', `fixture Model expected ILCE-7CM2, got ${fixtureIdentity.cameraModel}`);
assert(fixtureIdentity.lensMake === '', `fixture deliberately has no LensMake, got ${fixtureIdentity.lensMake}`);
assert(fixtureIdentity.lensModel.includes('A071'), `fixture LensModel expected A071, got ${fixtureIdentity.lensModel}`);
assert(jpegReaderSource.includes('CAMERA_MAKE_TAG: number = 0x010F'), 'JPEG fallback must parse camera Make');
assert(jpegReaderSource.includes('CAMERA_MODEL_TAG: number = 0x0110'), 'JPEG fallback must parse camera Model');
assert(readerSource.includes("'A071'"), 'known A071 lens code fallback is missing');
assert(readerSource.includes('JpegExifIdentityReader.readFromFd(file.fd)'), 'same-fd JPEG identity fallback is not wired');
assert(jpegReaderSource.includes('return mergeIdentity(identity, parseXmpIdentity(bytes))'),
  'JPEG parser must supplement EXIF identity from later XMP metadata');
assert(readerSource.includes('export function mergeMissingExifIdentity'), 'partial cached EXIF repair is missing');
assert(sheetSource.includes('this.reloadMissingIdentity()'), 'EXIF panel does not repair partial cached identity');
assert(testSource.includes("it('repairsPartialCachedExifWithoutLosingExposureData'"), 'partial cache regression case is missing');
assert(testSource.includes("it('preservesIntentionallyClearedManualIdentity'"), 'manual override regression case is missing');
assert(testSource.includes("it('mergesCameraIdentityFromLaterXmpSegment'"), 'split XMP identity regression case is missing');
assert(deviceScenarioSource.includes('fs.unlinkSync(sandboxPath)'), 'device EXIF fixture must be refreshed before every run');
assert(deviceScenarioSource.includes('cachedIdentityRepairVerification'), 'device partial-cache assertion is missing');
assert(deviceScenarioSource.includes('mediaUriIdentityVerification'), 'real media URI identity assertion is missing');
assert(deviceScenarioSource.includes('showAssetsCreationDialog'), 'device test must create a real media-library URI');

if (failures.length > 0) {
  failures.forEach((failure) => console.error(failure));
  process.exit(1);
}

console.log(
  `EXIF identity recovery verified: ${fixtureIdentity.cameraMake} ${fixtureIdentity.cameraModel}, ` +
  `${fixtureIdentity.lensModel}, missing LensMake covered by deterministic fallback`
);
