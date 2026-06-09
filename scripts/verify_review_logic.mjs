const REVIEW_JUDGEMENT = {
  VALID: '成立',
  UNSURE: '不确定',
  INVALID: '不成立'
};

const REVIEW_SCHEMA_KEYS = [
  'fileName',
  'titleText',
  'reviewTimeText',
  'reviewerText',
  'reviewStructure',
  'decision',
  'firstLookText',
  'attentionReasonText',
  'eyePathText',
  'visualFactText',
  'strongestRelationText',
  'extensionReasonText',
  'blockerText'
];

const HORIZONTAL_ASPECT_RATIO = 1.15;
const VERTICAL_ASPECT_RATIO = 0.87;

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function normalizeReviewJudgement(value) {
  const trimmedValue = typeof value === 'string' ? value.trim() : '';
  if (trimmedValue === REVIEW_JUDGEMENT.VALID) {
    return REVIEW_JUDGEMENT.VALID;
  }
  if (trimmedValue === REVIEW_JUDGEMENT.INVALID) {
    return REVIEW_JUDGEMENT.INVALID;
  }
  if (trimmedValue === REVIEW_JUDGEMENT.UNSURE) {
    return REVIEW_JUDGEMENT.UNSURE;
  }
  if (trimmedValue === '待判断') {
    return REVIEW_JUDGEMENT.UNSURE;
  }
  if (trimmedValue.includes(REVIEW_JUDGEMENT.INVALID)) {
    return REVIEW_JUDGEMENT.INVALID;
  }
  if (trimmedValue.includes('待判断')) {
    return REVIEW_JUDGEMENT.UNSURE;
  }
  if (trimmedValue.includes(REVIEW_JUDGEMENT.UNSURE)) {
    return REVIEW_JUDGEMENT.UNSURE;
  }
  if (trimmedValue.includes(REVIEW_JUDGEMENT.VALID)) {
    return REVIEW_JUDGEMENT.VALID;
  }
  return REVIEW_JUDGEMENT.UNSURE;
}

function mapReviewJudgementToExchangeDecision(value) {
  const judgement = normalizeReviewJudgement(value);
  if (judgement === REVIEW_JUDGEMENT.VALID) {
    return 'works';
  }
  if (judgement === REVIEW_JUDGEMENT.INVALID) {
    return 'notWorks';
  }
  return 'uncertain';
}

function normalizeText(value, fallback = '') {
  return typeof value === 'string' ? value : fallback;
}

function normalizeNumber(value, fallback) {
  return typeof value === 'number' && value > 0 ? value : fallback;
}

function createDefaultDocument() {
  return {
    version: '0.1.0',
    projectId: 'default',
    imageUri: '',
    imageWidth: 1600,
    imageHeight: 1000,
    imageSizeFallbackUsed: false,
    content: {
      title: '这张照片是否成立',
      visualFocus: '',
      focusReason: '',
      visualPath: '',
      visibleFacts: '',
      coreRelation: '',
      judgement: REVIEW_JUDGEMENT.UNSURE,
      extendedUnderstanding: '',
      currentBlocker: ''
    },
    config: {
      templateId: 'review_card',
      layoutMode: 'auto',
      background: 'white',
      textSize: 'standard'
    },
    createdAt: 1,
    updatedAt: 1
  };
}

function cloneReviewCardDocument(document) {
  const fallbackDocument = createDefaultDocument();
  const sourceContent = document.content || fallbackDocument.content;
  const sourceConfig = document.config || fallbackDocument.config;
  const extendedUnderstanding = normalizeText(sourceContent.extendedUnderstanding);
  const judgement = normalizeReviewJudgement(normalizeText(sourceContent.judgement, extendedUnderstanding));
  return {
    version: normalizeText(document.version, fallbackDocument.version),
    projectId: document.projectId && document.projectId.length > 0 ? document.projectId : 'default',
    imageUri: normalizeText(document.imageUri),
    imageWidth: normalizeNumber(document.imageWidth, fallbackDocument.imageWidth),
    imageHeight: normalizeNumber(document.imageHeight, fallbackDocument.imageHeight),
    imageSizeFallbackUsed: document.imageSizeFallbackUsed === true,
    content: {
      title: normalizeText(sourceContent.title, '这张照片是否成立'),
      visualFocus: normalizeText(sourceContent.visualFocus, normalizeText(sourceContent.firstLook)),
      focusReason: normalizeText(sourceContent.focusReason, normalizeText(sourceContent.reason)),
      visualPath: normalizeText(sourceContent.visualPath),
      visibleFacts: normalizeText(sourceContent.visibleFacts),
      coreRelation: normalizeText(sourceContent.coreRelation, normalizeText(sourceContent.strongestRelation)),
      judgement,
      extendedUnderstanding,
      currentBlocker: normalizeText(sourceContent.currentBlocker, normalizeText(sourceContent.blocker))
    },
    config: {
      templateId: normalizeText(sourceConfig.templateId, fallbackDocument.config.templateId),
      layoutMode: sourceConfig.layoutMode || fallbackDocument.config.layoutMode,
      background: sourceConfig.background || fallbackDocument.config.background,
      textSize: sourceConfig.textSize || fallbackDocument.config.textSize
    },
    createdAt: normalizeNumber(document.createdAt, fallbackDocument.createdAt),
    updatedAt: normalizeNumber(document.updatedAt, fallbackDocument.updatedAt)
  };
}

function formatReviewTime(timestamp) {
  const date = new Date(timestamp);
  const year = `${date.getFullYear()}`;
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  const hour = `${date.getHours()}`.padStart(2, '0');
  const minute = `${date.getMinutes()}`.padStart(2, '0');
  return `${year}-${month}-${day} ${hour}:${minute}`;
}

function isSampleImageUri(imageUri) {
  return imageUri.startsWith('sample://');
}

function resolveFileName(document) {
  const imageUri = normalizeText(document.imageUri).trim();
  if (imageUri.length === 0 || isSampleImageUri(imageUri)) {
    return '';
  }

  const withoutQuery = imageUri.split('?')[0].split('#')[0];
  const pathParts = withoutQuery.split('/');
  const rawFileName = pathParts.length > 0 ? pathParts[pathParts.length - 1] : '';
  if (rawFileName.length === 0) {
    return '';
  }

  try {
    return decodeURIComponent(rawFileName);
  } catch {
    return rawFileName;
  }
}

function createReviewCardExchangeSchemaV1(document, reviewerText = '') {
  const cloned = cloneReviewCardDocument(document);
  return {
    fileName: resolveFileName(cloned),
    titleText: normalizeText(cloned.content.title),
    reviewTimeText: formatReviewTime(cloned.updatedAt),
    reviewerText: normalizeText(reviewerText).trim(),
    reviewStructure: 'quickReview',
    decision: mapReviewJudgementToExchangeDecision(cloned.content.judgement),
    firstLookText: normalizeText(cloned.content.visualFocus),
    attentionReasonText: normalizeText(cloned.content.focusReason),
    eyePathText: normalizeText(cloned.content.visualPath),
    visualFactText: normalizeText(cloned.content.visibleFacts),
    strongestRelationText: normalizeText(cloned.content.coreRelation),
    extensionReasonText: normalizeText(cloned.content.extendedUnderstanding),
    blockerText: normalizeText(cloned.content.currentBlocker)
  };
}

function buildGlobalStats(items) {
  const stats = {
    totalCount: items.length,
    validCount: 0,
    unsureCount: 0,
    invalidCount: 0
  };

  items.forEach((item) => {
    const judgement = normalizeReviewJudgement(item.document.content.judgement);
    if (judgement === REVIEW_JUDGEMENT.VALID) {
      stats.validCount += 1;
      return;
    }
    if (judgement === REVIEW_JUDGEMENT.INVALID) {
      stats.invalidCount += 1;
      return;
    }
    stats.unsureCount += 1;
  });

  return stats;
}

function normalizeExcerpt(value) {
  return value.replace(/\s+/g, ' ').trim();
}

function getReviewProjectExcerpt(document) {
  const coreRelation = normalizeExcerpt(document.content.coreRelation);
  if (coreRelation.length > 0) {
    return `核心关系：${coreRelation}`;
  }

  const currentBlocker = normalizeExcerpt(document.content.currentBlocker);
  if (currentBlocker.length > 0) {
    return currentBlocker;
  }

  const extendedUnderstanding = normalizeExcerpt(document.content.extendedUnderstanding);
  if (extendedUnderstanding.length > 0) {
    return extendedUnderstanding;
  }

  return '还没有提炼核心关系';
}

function resolveReviewImageLayout(width, height, fallbackUsed = false) {
  const hasExactSize = !fallbackUsed && width > 0 && height > 0;
  if (!hasExactSize) {
    return {
      layoutType: 'square',
      aspectRatio: 1,
      usedFallbackSize: true,
      hasExactSize: false
    };
  }

  const aspectRatio = width / height;
  if (aspectRatio >= HORIZONTAL_ASPECT_RATIO) {
    return {
      layoutType: 'horizontal',
      aspectRatio,
      usedFallbackSize: false,
      hasExactSize: true
    };
  }

  if (aspectRatio <= VERTICAL_ASPECT_RATIO) {
    return {
      layoutType: 'vertical',
      aspectRatio,
      usedFallbackSize: false,
      hasExactSize: true
    };
  }

  return {
    layoutType: 'square',
    aspectRatio,
    usedFallbackSize: false,
    hasExactSize: true
  };
}

const judgementCases = [
  ['', REVIEW_JUDGEMENT.UNSURE],
  [undefined, REVIEW_JUDGEMENT.UNSURE],
  ['成立', REVIEW_JUDGEMENT.VALID],
  ['不成立', REVIEW_JUDGEMENT.INVALID],
  ['待判断', REVIEW_JUDGEMENT.UNSURE],
  ['不确定', REVIEW_JUDGEMENT.UNSURE],
  ['判断为成立', REVIEW_JUDGEMENT.VALID],
  ['判断为不成立', REVIEW_JUDGEMENT.INVALID]
];

judgementCases.forEach(([input, expected]) => {
  assert(normalizeReviewJudgement(input) === expected, `normalizeReviewJudgement(${input}) should be ${expected}`);
});

assert(mapReviewJudgementToExchangeDecision('成立') === 'works', '成立 should map to works');
assert(mapReviewJudgementToExchangeDecision('待判断') === 'uncertain', '待判断 should map to uncertain');
assert(mapReviewJudgementToExchangeDecision('不成立') === 'notWorks', '不成立 should map to notWorks');

const sparseDocument = createDefaultDocument();
sparseDocument.imageUri = 'file:///photos/DSC%2001.jpg?size=large';
sparseDocument.updatedAt = Date.UTC(2026, 5, 7, 13, 8);
sparseDocument.content = {
  title: '测试复盘',
  visualFocus: '主体',
  focusReason: '',
  visualPath: '',
  visibleFacts: '',
  coreRelation: '',
  judgement: '待判断',
  extendedUnderstanding: '',
  currentBlocker: ''
};

const schema = createReviewCardExchangeSchemaV1(sparseDocument, '  Bo  ');
assert(JSON.stringify(Object.keys(schema)) === JSON.stringify(REVIEW_SCHEMA_KEYS), 'exchange schema keys changed or missing');
assert(schema.fileName === 'DSC 01.jpg', `fileName should decode URI file name, got ${schema.fileName}`);
assert(schema.reviewerText === 'Bo', `reviewerText should be trimmed, got ${schema.reviewerText}`);
assert(schema.decision === 'uncertain', `decision should be uncertain, got ${schema.decision}`);
assert(schema.attentionReasonText === '', 'empty attentionReasonText key should be retained');
assert(schema.blockerText === '', 'empty blockerText key should be retained');

const statsItems = [
  ['default', '成立'],
  ['default', '不成立'],
  ['side-project', '待判断'],
  ['side-project', '判断为成立'],
  ['default', undefined]
].map(([projectId, judgement], index) => {
  const document = createDefaultDocument();
  document.projectId = projectId;
  document.content.judgement = judgement;
  document.createdAt = index + 1;
  document.updatedAt = index + 1;
  return { document, exportedPath: '' };
});

const stats = buildGlobalStats(statsItems);
assert(stats.totalCount === 5, `global stats should include all projects, got ${stats.totalCount}`);
assert(stats.validCount === 2, `validCount should be 2, got ${stats.validCount}`);
assert(stats.unsureCount === 2, `unsureCount should be 2, got ${stats.unsureCount}`);
assert(stats.invalidCount === 1, `invalidCount should be 1, got ${stats.invalidCount}`);

const excerptDocument = createDefaultDocument();
assert(getReviewProjectExcerpt(excerptDocument) === '还没有提炼核心关系', 'empty excerpt fallback changed');
excerptDocument.content.extendedUnderstanding = '  延伸\n理解  ';
assert(getReviewProjectExcerpt(excerptDocument) === '延伸 理解', 'extendedUnderstanding fallback changed');
excerptDocument.content.currentBlocker = ' 当前卡点 ';
assert(getReviewProjectExcerpt(excerptDocument) === '当前卡点', 'currentBlocker fallback changed');
excerptDocument.content.coreRelation = ' 核心关系 ';
assert(getReviewProjectExcerpt(excerptDocument) === '核心关系：核心关系', 'coreRelation fallback changed');

const layoutCases = [
  [1600, 1000, false, 'horizontal', 1.6, false, true],
  [1152, 1536, false, 'vertical', 0.75, false, true],
  [1200, 1200, false, 'square', 1, false, true],
  [1600, 1000, true, 'square', 1, true, false],
  [0, 1000, false, 'square', 1, true, false]
];

layoutCases.forEach(([width, height, fallbackUsed, expectedType, expectedRatio, expectedFallback, expectedExact]) => {
  const result = resolveReviewImageLayout(width, height, fallbackUsed);
  assert(result.layoutType === expectedType, `${width}x${height} should be ${expectedType}, got ${result.layoutType}`);
  assert(Math.abs(result.aspectRatio - expectedRatio) < 0.0001, `${width}x${height} ratio should be ${expectedRatio}, got ${result.aspectRatio}`);
  assert(result.usedFallbackSize === expectedFallback, `${width}x${height} fallback flag should be ${expectedFallback}`);
  assert(result.hasExactSize === expectedExact, `${width}x${height} exact flag should be ${expectedExact}`);
});

const legacyDocument = cloneReviewCardDocument({
  version: '0.1.0',
  projectId: '',
  imageUri: '',
  imageWidth: 0,
  imageHeight: 0,
  content: {
    firstLook: '旧视觉落点',
    reason: '旧落点原因',
    strongestRelation: '旧核心关系',
    extendedUnderstanding: '判断为不成立',
    blocker: '旧卡点'
  },
  createdAt: 0,
  updatedAt: 0
});

assert(legacyDocument.projectId === 'default', 'legacy empty projectId should fall back to default');
assert(legacyDocument.imageWidth === 1600 && legacyDocument.imageHeight === 1000, 'legacy invalid image size should fall back');
assert(legacyDocument.content.visualFocus === '旧视觉落点', 'legacy firstLook should map to visualFocus');
assert(legacyDocument.content.focusReason === '旧落点原因', 'legacy reason should map to focusReason');
assert(legacyDocument.content.coreRelation === '旧核心关系', 'legacy strongestRelation should map to coreRelation');
assert(legacyDocument.content.judgement === REVIEW_JUDGEMENT.INVALID, 'legacy judgement in extendedUnderstanding should be recovered');
assert(legacyDocument.content.currentBlocker === '旧卡点', 'legacy blocker should map to currentBlocker');

if (failed) {
  process.exit(1);
}

console.log('review logic: judgement, schema, stats, excerpt, layout, legacy compatibility ok');
