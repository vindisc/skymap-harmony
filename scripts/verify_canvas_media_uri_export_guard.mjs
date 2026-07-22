import fs from 'node:fs';

const helperSource = fs.readFileSync(
  'entry/src/main/ets/services/CanvasPhotoStripHelpers.ets',
  'utf8'
);
const l0ComposerSource = fs.readFileSync(
  'entry/src/main/ets/services/L0CanvasComposer.ets',
  'utf8'
);

let failed = false;

function requireIncludes(source, token, scope) {
  if (!source.includes(token)) {
    failed = true;
    console.error(`${scope} missing token: ${token}`);
  }
}

[
  "normalizedUri.startsWith('file://media/')",
  "normalizedUri.startsWith('datashare://media/')",
  'fs.openSync(imageUri, fs.OpenMode.READ_ONLY)',
  'image.createImageSource(file.fd)',
  'requireCanvasImageSource(',
  'closeCanvasImageSourceFile(file: fs.File | null)'
].forEach((token) => requireIncludes(helperSource, token, 'Canvas media URI source'));

[
  'openCanvasImageSource(input.document.imageUri)',
  'sourceFile = sourceHandle.file',
  'await resolveCanvasSourceLayout(source)',
  'closeCanvasImageSourceFile(sourceFile)'
].forEach((token) => requireIncludes(l0ComposerSource, token, 'L0 original-resolution export'));

if (failed) {
  process.exit(1);
}

console.log('canvas media URI export guard verified: fd-first source, lifetime retention, empty-source guard');
