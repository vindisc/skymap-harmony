import fs from 'node:fs';

const layoutPath = process.argv[2];
if (!layoutPath || !fs.existsSync(layoutPath)) {
  process.exit(2);
}

const root = JSON.parse(fs.readFileSync(layoutPath, 'utf8'));
const acceptedTexts = new Set(['允许', '保存', '确定', '继续', '添加', '完成']);
const findFirstPhoto = process.argv.includes('--first-photo');
const findComplete = process.argv.includes('--complete');
let match = null;
let completeMatch = null;
const photoMatches = [];

function visit(node) {
  if (!node || match) return;
  if (Array.isArray(node)) {
    for (const child of node) visit(child);
    return;
  }
  const attributes = node.attributes ?? {};
  const text = `${attributes.text ?? attributes.originalText ?? ''}`.trim();
  const clickable = `${attributes.clickable ?? ''}` === 'true';
  const bounds = `${attributes.bounds ?? ''}`;
  if (findComplete && clickable && `${attributes.id ?? ''}` === 'Complete') {
    const completeBounds = bounds.match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/);
    if (completeBounds) {
      completeMatch = {
        x: Math.round((Number(completeBounds[1]) + Number(completeBounds[3])) / 2),
        y: Math.round((Number(completeBounds[2]) + Number(completeBounds[4])) / 2)
      };
    }
  }
  if (findFirstPhoto && clickable && `${attributes.id ?? ''}` === 'imageGridItem') {
    const photoBounds = bounds.match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/);
    if (photoBounds) {
      photoMatches.push({
        x: Math.round((Number(photoBounds[1]) + Number(photoBounds[3])) / 2),
        y: Math.round((Number(photoBounds[2]) + Number(photoBounds[4])) / 2),
        left: Number(photoBounds[1]),
        top: Number(photoBounds[2])
      });
    }
  }
  const normalizedText = text.replace(/\s*\(\d+\)\s*$/, '');
  if (clickable && acceptedTexts.has(normalizedText)) {
    const values = bounds.match(/\[(\d+),(\d+)\]\[(\d+),(\d+)\]/);
    if (values) {
      match = {
        x: Math.round((Number(values[1]) + Number(values[3])) / 2),
        y: Math.round((Number(values[2]) + Number(values[4])) / 2),
        text: normalizedText
      };
      return;
    }
  }
  for (const child of node.children ?? []) visit(child);
}

visit(root);
if (findComplete) {
  if (!completeMatch) process.exit(1);
  console.log(`${completeMatch.x} ${completeMatch.y} 完成`);
  process.exit(0);
}
if (findFirstPhoto) {
  photoMatches.sort((left, right) => left.top - right.top || left.left - right.left);
  const firstPhoto = photoMatches[0];
  if (!firstPhoto) process.exit(1);
  console.log(`${firstPhoto.x} ${firstPhoto.y} 最新受控照片`);
  process.exit(0);
}
if (!match) process.exit(1);
console.log(`${match.x} ${match.y} ${match.text}`);
