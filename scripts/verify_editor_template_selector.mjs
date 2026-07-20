import fs from 'node:fs';

const sourcePath = 'entry/src/main/ets/components/TemplateChipStrip.ets';
const source = fs.readFileSync(sourcePath, 'utf8');

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function readNumberConstant(name) {
  const match = source.match(new RegExp(`const ${name}: number = (\\d+);`));
  assert(match !== null, `TemplateChipStrip must define ${name}.`);
  return Number(match[1]);
}

const width = readNumberConstant('TEMPLATE_CHIP_WIDTH');
const height = readNumberConstant('TEMPLATE_CHIP_HEIGHT');
const previewHeight = readNumberConstant('TEMPLATE_CHIP_PREVIEW_HEIGHT');
const labelLineHeight = readNumberConstant('TEMPLATE_CHIP_LABEL_LINE_HEIGHT');
const padding = readNumberConstant('TEMPLATE_CHIP_PADDING');
const gap = 8;
const requiredHeight = padding * 2 + previewHeight + gap + labelLineHeight;

assert(width >= 88, 'Template chip must be wide enough to show the longest Chinese template name.');
assert(
  height >= requiredHeight,
  `Template chip height ${height} is smaller than its ${requiredHeight}vp content contract.`
);
assert(
  source.includes('.lineHeight(TEMPLATE_CHIP_LABEL_LINE_HEIGHT)'),
  'Template label must keep an explicit line height.'
);
assert(
  source.includes('.textAlign(TextAlign.Center)'),
  'Template label must remain centered below its preview.'
);
assert(
  source.includes('.width(TEMPLATE_CHIP_WIDTH)'),
  'Template chip width must use the shared size contract.'
);
assert(
  (source.match(/\.height\(TEMPLATE_CHIP_HEIGHT\)/g) ?? []).length === 3,
  'Template chip, row and horizontal scroll must share one height contract.'
);
assert(!source.includes('.width(56)'), 'The old narrow template chip width must not return.');
assert(!source.includes('.height(72)'), 'The old overflowing template chip height must not return.');

console.log('editor template selector verified: readable label width and overflow-safe shared height contract');
