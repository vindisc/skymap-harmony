import fs from 'node:fs';

const previewSource = fs.readFileSync(
  'entry/src/main/ets/components/FrameTemplatePreview.ets',
  'utf8'
);

let failed = false;

function requireIncludes(token, scope) {
  if (!previewSource.includes(token)) {
    failed = true;
    console.error(`${scope} missing token: ${token}`);
  }
}

[
  'Stack() {',
  ".width('100%')",
  ".height('100%')",
  '.borderRadius(geometry.cornerRadius)',
  '.clip(true)'
].forEach((token) => requireIncludes(token, 'Preview photo clipping container'));

[
  '} else {',
  '.width(this.getGeometry().canvasWidth)',
  '.height(this.getGeometry().canvasHeight)',
  '.justifyContent(FlexAlign.Center)',
  '.alignItems(HorizontalAlign.Center)'
].forEach((token) => requireIncludes(token, 'L0 equal-padding preview'));

if (failed) {
  process.exit(1);
}

console.log('frame preview consistency verified: L0 centered margins and container-based live corner clipping');
