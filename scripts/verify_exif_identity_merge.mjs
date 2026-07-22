import fs from 'node:fs';

const exifSource = fs.readFileSync(
  'entry/src/main/ets/services/ExifReaderService.ets',
  'utf8'
);

let failed = false;

function requireIncludes(token, scope) {
  if (!exifSource.includes(token)) {
    failed = true;
    console.error(`${scope} missing token: ${token}`);
  }
}

function forbidIncludes(token, scope) {
  if (exifSource.includes(token)) {
    failed = true;
    console.error(`${scope} must not contain: ${token}`);
  }
}

[
  'image.PropertyKey.MAKE',
  'image.PropertyKey.MODEL',
  'image.PropertyKey.LENS_MAKE',
  'fallbackPayload = await fallbackReader()',
  'return mergeExifPayload(primaryPayload, fallbackPayload)',
  'cameraMake: preferExifValue(primary.cameraMake, fallback.cameraMake)',
  'cameraModel: preferExifValue(primary.cameraModel, fallback.cameraModel)',
  'lensMake: preferExifValue(primary.lensMake, fallback.lensMake)'
].forEach((token) => requireIncludes(token, 'EXIF identity field merge'));

forbidIncludes(
  'if (!isExifPayloadEmpty(primaryPayload))',
  'EXIF fallback must not stop after unrelated fields are read'
);

if (failed) {
  process.exit(1);
}

console.log('EXIF identity merge verified: fd and URI results supplement camera and lens identity fields');
