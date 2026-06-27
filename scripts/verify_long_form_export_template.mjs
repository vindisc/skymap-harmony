import fs from 'node:fs';

const source = fs.readFileSync('entry/src/main/ets/components/LongFormExportReviewCard.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

assert(!source.includes("HorizontalInfoColumn('观看过程'"), 'Horizontal export must not render the large group title: 观看过程.');
assert(!source.includes("HorizontalInfoColumn('判断摘要'"), 'Horizontal export must not render the large group title: 判断摘要.');
assert(!source.includes("Text('观看过程'"), 'Horizontal export must not contain a standalone 观看过程 title Text.');
assert(!source.includes("Text('判断摘要'"), 'Horizontal export must not contain a standalone 判断摘要 title Text.');
assert(!source.includes("HorizontalInfoItem('是否成立'"), 'Horizontal summary column must not duplicate 是否成立.');
assert(source.includes('JudgementPill()'), 'Horizontal title bar must keep the judgement pill builder.');
assert(source.includes('Text(getExportJudgementText(this.document.content.judgement))'), 'Judgement pill must still render normalized judgement text.');
assert(source.includes("createExportInfoItem('最强关系', document.content.coreRelation)"), 'Horizontal summary must keep 最强关系.');
assert(source.includes("createExportInfoItem('卡点', document.content.currentBlocker)"), 'Horizontal summary must keep 卡点.');
assert(source.includes("createExportInfoItem('复盘信息', document.content.extendedUnderstanding)"), 'Horizontal summary must keep 复盘信息.');
assert(source.includes('EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP'), 'Horizontal export must define bottom safe gap.');
assert(source.includes('.margin({ top: EXPORT_CARD_HORIZONTAL_PANEL_TOP_MARGIN, bottom: EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP })'), 'Horizontal panel must keep bottom margin for rounded border visibility.');
assert(source.includes('+ EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP'), 'Canvas height must include horizontal bottom safe gap.');
assert(source.includes('EXPORT_CARD_HORIZONTAL_HEIGHT_SAFETY_PADDING'), 'Height estimate must keep panel safety padding.');
assert(source.includes('countHorizontalExportLines'), 'Horizontal height estimate must use dedicated long-content line counting.');
assert(source.includes('resolveHorizontalExportPanelHeight'), 'Horizontal panel height must be content-based.');
assert(source.includes('.height(this.getHorizontalPanelHeight())'), 'Horizontal panel must use explicit content-based height.');
assert(source.includes('.height(this.getHorizontalPanelDividerHeight())'), 'Horizontal divider must not stretch the panel with 100% height.');
assert(!source.includes(".height('100%')\n        .backgroundColor('#E4DCCE')"), 'Horizontal divider must not use 100% height.');
assert(source.includes('cleanExportDisplayText(value)'), 'Horizontal export must clean display-only noise without changing data.');
assert(source.includes('DefaultTextContent()'), 'Vertical and square exports must keep the default single-column path.');
assert(source.includes('ReviewInfoGroup({'), 'Vertical and square exports must still use ReviewInfoGroup.');
assert(!source.includes('.maxLines(2)'), 'Core export text must not be limited to two lines.');
assert(!source.includes('.maxLines(3)'), 'Core export text must not be limited to three lines.');

const EXPORT_CARD_CANVAS_PADDING = 48;
const EXPORT_CARD_TEXT_TOP_PADDING = 18;
const EXPORT_CARD_META_TOP_MARGIN = 6;
const EXPORT_CARD_META_LINE_HEIGHT = 24;
const EXPORT_CARD_MIN_HEIGHT = 640;
const EXPORT_CARD_TEXT_WIDTH_RATIO = 0.92;
const EXPORT_CARD_BOTTOM_SAFETY_PADDING = 120;
const EXPORT_CARD_HORIZONTAL_BAR_TOP_MARGIN = 20;
const EXPORT_CARD_HORIZONTAL_PANEL_TOP_MARGIN = 14;
const EXPORT_CARD_HORIZONTAL_PANEL_PADDING = 28;
const EXPORT_CARD_HORIZONTAL_COLUMN_GAP = 34;
const EXPORT_CARD_HORIZONTAL_TITLE_BAR_MIN_HEIGHT = 92;
const EXPORT_CARD_HORIZONTAL_PANEL_MIN_HEIGHT = 0;
const EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP = 32;
const EXPORT_CARD_HORIZONTAL_HEIGHT_SAFETY_PADDING = 14;
const EXPORT_CARD_HORIZONTAL_LINE_WIDTH_RATIO = 0.76;

const compact = {
  titleSize: 32,
  titleLineHeight: 44,
  labelSize: 15,
  labelLineHeight: 20,
  bodySize: 22,
  bodyLineHeight: 31,
  valueTopGap: 4,
  dividerBottomGap: 7,
  itemBottomGap: 9
};

const guidanceTokens = [
  '第一眼先看到哪里',
  '为什么它会先被看到',
  '视线接着从哪里走到哪里',
  '画面里有哪些可见事实',
  '最重要的 A ↔ B 关系是什么',
  '这张照片为什么成立或不成立',
  '当前最大问题是什么',
  '第一眼落点',
  '落点原因',
  '视线路径',
  '画面事实',
  '核心关系',
  '延伸理解',
  '当前卡点'
];

function normalizeExportText(value) {
  return value.replace(/\s+/g, ' ').trim();
}

function stripExportDisplayNoise(value) {
  return value
    .replace(/https?:\/\/[^\s，。；、]+/g, ' ')
    .replace(/\d{12,}/g, ' ')
    .replace(/[＿_—-]{6,}/g, ' ');
}

function cleanExportDisplayText(value) {
  const withoutNoise = normalizeExportText(stripExportDisplayNoise(value));
  if (withoutNoise.length === 0) {
    return '';
  }
  let matchedCount = 0;
  for (const token of guidanceTokens) {
    if (withoutNoise.includes(token)) {
      matchedCount += 1;
    }
  }
  return matchedCount >= 2 ? '' : withoutNoise;
}

function countExportLines(value, textWidth, fontSize) {
  const normalizedValue = normalizeExportText(value);
  if (normalizedValue.length === 0) {
    return 0;
  }
  const charsPerLine = Math.max(10, Math.floor(textWidth / (fontSize * EXPORT_CARD_TEXT_WIDTH_RATIO)));
  return Math.max(1, Math.ceil(normalizedValue.length / charsPerLine));
}

function countHorizontalExportLines(value, textWidth, fontSize) {
  const normalizedValue = cleanExportDisplayText(value);
  if (normalizedValue.length === 0) {
    return 0;
  }
  const charsPerLine = Math.max(8, Math.floor(textWidth / (fontSize * EXPORT_CARD_HORIZONTAL_LINE_WIDTH_RATIO)));
  return Math.max(1, Math.ceil(normalizedValue.length / charsPerLine));
}

function infoItem(label, value) {
  return { label, value: cleanExportDisplayText(value) };
}

function horizontalProcessItems(document) {
  return [
    infoItem('视觉落点', document.content.visualFocus),
    infoItem('视线路径', document.content.visualPath),
    infoItem('画面事实', document.content.visibleFacts)
  ].filter((item) => item.value.length > 0);
}

function horizontalSummaryItems(document) {
  return [
    infoItem('最强关系', document.content.coreRelation),
    infoItem('卡点', document.content.currentBlocker),
    infoItem('复盘信息', document.content.extendedUnderstanding)
  ].filter((item) => item.value.length > 0);
}

function infoListHeight(items, textWidth) {
  let height = 0;
  for (const item of items) {
    const bodyLines = countHorizontalExportLines(item.value, textWidth, compact.bodySize);
    height += compact.labelLineHeight
      + compact.valueTopGap
      + Math.max(1, bodyLines) * compact.bodyLineHeight
      + compact.itemBottomGap;
  }
  return height;
}

function horizontalColumnWidth(contentWidth) {
  return Math.max(
    1,
    (contentWidth - EXPORT_CARD_HORIZONTAL_PANEL_PADDING * 2 - EXPORT_CARD_HORIZONTAL_COLUMN_GAP) / 2
  );
}

function horizontalPanelHeight(document, contentWidth) {
  const columnWidth = horizontalColumnWidth(contentWidth);
  const processHeight = infoListHeight(horizontalProcessItems(document), columnWidth);
  const summaryHeight = infoListHeight(horizontalSummaryItems(document), columnWidth);
  return Math.max(
    EXPORT_CARD_HORIZONTAL_PANEL_MIN_HEIGHT,
    EXPORT_CARD_HORIZONTAL_PANEL_PADDING * 2
      + Math.max(processHeight, summaryHeight)
      + EXPORT_CARD_HORIZONTAL_HEIGHT_SAFETY_PADDING
  );
}

function resolveHeight(document, canvasWidth) {
  const contentWidth = Math.max(1, canvasWidth - EXPORT_CARD_CANVAS_PADDING * 2);
  const aspectRatio = document.imageWidth / document.imageHeight;
  const photoHeight = contentWidth / Math.max(0.1, aspectRatio);

  if (document.imageWidth > document.imageHeight) {
    const titleLines = countExportLines(document.content.title, contentWidth * 0.72, compact.titleSize);
    const titleBarHeight = Math.max(
      EXPORT_CARD_HORIZONTAL_TITLE_BAR_MIN_HEIGHT,
      EXPORT_CARD_TEXT_TOP_PADDING
        + Math.max(1, titleLines) * compact.titleLineHeight
        + EXPORT_CARD_META_TOP_MARGIN
        + EXPORT_CARD_META_LINE_HEIGHT
        + 18
    );
    const panelHeight = horizontalPanelHeight(document, contentWidth);

    return Math.max(
      EXPORT_CARD_MIN_HEIGHT,
      Math.ceil(
        EXPORT_CARD_CANVAS_PADDING * 2
          + photoHeight
          + EXPORT_CARD_HORIZONTAL_BAR_TOP_MARGIN
          + titleBarHeight
          + EXPORT_CARD_HORIZONTAL_PANEL_TOP_MARGIN
          + panelHeight
          + EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP
      )
    );
  }

  const fields = [
    document.content.visualFocus,
    document.content.focusReason,
    document.content.visualPath,
    document.content.visibleFacts,
    document.content.coreRelation,
    document.content.judgement,
    document.content.extendedUnderstanding,
    document.content.currentBlocker
  ].filter((value) => normalizeExportText(value).length > 0);
  const titleLines = countExportLines(document.content.title, contentWidth, compact.titleSize);
  const titleHeight = Math.max(1, titleLines) * compact.titleLineHeight;
  let infoHeight = 0;
  fields.forEach((value, index) => {
    const bodyLines = countExportLines(value, contentWidth, compact.bodySize);
    infoHeight += compact.labelLineHeight
      + compact.valueTopGap
      + Math.max(1, bodyLines) * compact.bodyLineHeight
      + compact.itemBottomGap;
    if (index > 0) {
      infoHeight += 1 + compact.dividerBottomGap;
    }
  });
  const textHeight = EXPORT_CARD_TEXT_TOP_PADDING
    + titleHeight
    + EXPORT_CARD_META_TOP_MARGIN
    + EXPORT_CARD_META_LINE_HEIGHT
    + (fields.length > 0 ? 14 + infoHeight : 0);
  return Math.max(
    EXPORT_CARD_MIN_HEIGHT,
    Math.ceil(EXPORT_CARD_CANVAS_PADDING * 2 + photoHeight + textHeight + EXPORT_CARD_BOTTOM_SAFETY_PADDING)
  );
}

const baseHorizontal = {
  imageWidth: 1600,
  imageHeight: 1000,
  content: {
    title: '这张照片是否成立',
    visualFocus: '黄色车身和前轮。',
    focusReason: '色彩和亮度最先把车身推出来。',
    visualPath: '先看车头，再沿车身走到后轮，最后回到背景店招。',
    visibleFacts: '黄色汽车在画面中央，背景有二手车市场招牌。',
    coreRelation: '黄色车身和灰色背景之间的主次关系。',
    judgement: '待判断',
    extendedUnderstanding: '背景信息解释了拍摄环境，但主体仍靠颜色成立。',
    currentBlocker: '背景车辆略抢视线。'
  }
};

const emptyOptional = {
  ...baseHorizontal,
  content: {
    ...baseHorizontal.content,
    currentBlocker: '',
    extendedUnderstanding: ''
  }
};

const sparseHorizontal = {
  ...baseHorizontal,
  content: {
    ...baseHorizontal.content,
    visualPath: '',
    visibleFacts: '',
    currentBlocker: '',
    extendedUnderstanding: ''
  }
};

const longHorizontal = {
  ...baseHorizontal,
  content: {
    ...baseHorizontal.content,
    visualPath: '视线路径'.repeat(220),
    visibleFacts: '画面事实'.repeat(180),
    coreRelation: '最强关系'.repeat(160),
    extendedUnderstanding: '复盘信息'.repeat(160),
    currentBlocker: '卡点说明'.repeat(120)
  }
};

const noisyHorizontal = {
  ...baseHorizontal,
  content: {
    ...baseHorizontal.content,
    visualPath: 'https://pan.quark.cn/s/1e47f157bcef 110101199510014532 ________ 感谢支持，祝您生活愉快。',
    visibleFacts: '第一眼落点 我第一眼看到了哪里？ 视线路径 我的视线从哪里移动到哪里？ 当前卡点 当前最大问题是什么？'
  }
};

const vertical = {
  ...baseHorizontal,
  imageWidth: 900,
  imageHeight: 1400
};

const square = {
  ...baseHorizontal,
  imageWidth: 1200,
  imageHeight: 1200
};

assert(horizontalSummaryItems(baseHorizontal).map((item) => item.label).join('/') === '最强关系/卡点/复盘信息',
  'Horizontal summary order must be 最强关系 / 卡点 / 复盘信息.');
assert(!horizontalSummaryItems(baseHorizontal).some((item) => item.label === '是否成立'),
  'Horizontal summary data must not include 是否成立.');
assert(horizontalSummaryItems(emptyOptional).map((item) => item.label).join('/') === '最强关系',
  'Empty 卡点 and 复盘信息 must be hidden from horizontal summary.');
assert(horizontalProcessItems(noisyHorizontal).every((item) => !item.value.includes('https://')),
  'Display-only URL noise must be removed before horizontal export rendering.');
assert(horizontalProcessItems(noisyHorizontal).every((item) => !/\d{12,}/.test(item.value)),
  'Display-only long numeric noise must be removed before horizontal export rendering.');

const baseHeight = resolveHeight(baseHorizontal, 1520);
const sparseHeight = resolveHeight(sparseHorizontal, 1520);
const sparsePanelHeight = horizontalPanelHeight(sparseHorizontal, 1520 - EXPORT_CARD_CANVAS_PADDING * 2);
const longHeight = resolveHeight(longHorizontal, 1520);
const verticalHeight = resolveHeight(vertical, 1520);
const squareHeight = resolveHeight(square, 1520);

assert(longHeight > baseHeight + 900, `Long horizontal content must increase canvas height, got base=${baseHeight}, long=${longHeight}.`);
assert(sparseHeight < baseHeight, `Short horizontal content must tighten canvas height, got short=${sparseHeight}, base=${baseHeight}.`);
assert(sparsePanelHeight < 170, `Short horizontal panel must not keep a large blank fixed height, got panel=${sparsePanelHeight}.`);
assert(baseHeight >= EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP + EXPORT_CARD_CANVAS_PADDING,
  'Horizontal height must leave bottom safety room beyond canvas padding.');
assert(verticalHeight > 0, 'Vertical export height strategy must remain valid.');
assert(squareHeight > 0, 'Square export height strategy must remain valid.');

if (failed) {
  process.exit(1);
}

console.log(`long form export template: baseHorizontal=${baseHeight}, shortHorizontal=${sparseHeight}, longHorizontal=${longHeight}, vertical=${verticalHeight}, square=${squareHeight}`);
