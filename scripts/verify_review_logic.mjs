import fs from 'node:fs';

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

function readText(path) {
  return fs.readFileSync(path, 'utf8');
}

function parseExchangeInterfaceKeys(source) {
  const match = source.match(/export interface ReviewCardExchangeSchemaV1\s*\{([\s\S]*?)\n\}/);
  if (!match) {
    return [];
  }
  return match[1]
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .map((line) => line.split(':')[0].trim());
}

function parseExchangeDocKeys(markdown) {
  return markdown
    .split('\n')
    .map((line) => {
      const match = line.match(/^\| `([^`]+)` \|/);
      return match ? match[1] : '';
    })
    .filter((key) => key.length > 0);
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

function removeLastFileExtension(fileName) {
  const dotIndex = fileName.lastIndexOf('.');
  return dotIndex > 0 ? fileName.slice(0, dotIndex) : fileName;
}

function sanitizeReviewJsonBaseName(fileName) {
  return removeLastFileExtension(fileName).trim().replace(/[\\/:*?"<>|\r\n\t]+/g, '-').trim();
}

function resolveReviewCardExchangeReviewJsonFileName(document) {
  const sourceFileName = sanitizeReviewJsonBaseName(resolveFileName(document));
  if (sourceFileName.length > 0) {
    return `${sourceFileName}.review.json`;
  }

  const timestamp = document.updatedAt > 0 ? document.updatedAt : Date.now();
  return `review-${timestamp}.json`;
}

function normalizeExchangeSchema(source) {
  const schema = source || {};
  return {
    fileName: normalizeText(schema.fileName),
    titleText: normalizeText(schema.titleText),
    reviewTimeText: normalizeText(schema.reviewTimeText),
    reviewerText: normalizeText(schema.reviewerText),
    reviewStructure: normalizeText(schema.reviewStructure),
    decision: normalizeText(schema.decision),
    firstLookText: normalizeText(schema.firstLookText),
    attentionReasonText: normalizeText(schema.attentionReasonText),
    eyePathText: normalizeText(schema.eyePathText),
    visualFactText: normalizeText(schema.visualFactText),
    strongestRelationText: normalizeText(schema.strongestRelationText),
    extensionReasonText: normalizeText(schema.extensionReasonText),
    blockerText: normalizeText(schema.blockerText)
  };
}

function parseReviewCardExchangeSchemaV1(jsonText) {
  return normalizeExchangeSchema(JSON.parse(jsonText));
}

function mapExchangeDecisionToReviewJudgement(value) {
  if (value === 'works') {
    return REVIEW_JUDGEMENT.VALID;
  }
  if (value === 'notWorks') {
    return REVIEW_JUDGEMENT.INVALID;
  }
  return REVIEW_JUDGEMENT.UNSURE;
}

function parseReviewTimeText(value) {
  const sections = normalizeText(value).trim().split(' ');
  if (sections.length !== 2) {
    return 0;
  }
  const dateParts = sections[0].split('-').map(Number);
  const timeParts = sections[1].split(':').map(Number);
  if (dateParts.length !== 3 || timeParts.length !== 2) {
    return 0;
  }
  const [year, month, day] = dateParts;
  const [hour, minute] = timeParts;
  if (year <= 0 || month < 1 || month > 12 || day < 1 || day > 31 || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return 0;
  }
  const timestamp = new Date(year, month - 1, day, hour, minute, 0, 0).getTime();
  return timestamp > 0 ? timestamp : 0;
}

function createReviewCardDocumentFromExchangeSchemaV1(schema, baseDocument = undefined) {
  const normalizedSchema = normalizeExchangeSchema(schema);
  const next = baseDocument ? cloneReviewCardDocument(baseDocument) : createDefaultDocument();
  const importedReviewTime = parseReviewTimeText(normalizedSchema.reviewTimeText);
  next.content.title = normalizedSchema.titleText.length > 0 ? normalizedSchema.titleText : '这张照片是否成立';
  next.content.visualFocus = normalizedSchema.firstLookText;
  next.content.focusReason = normalizedSchema.attentionReasonText;
  next.content.visualPath = normalizedSchema.eyePathText;
  next.content.visibleFacts = normalizedSchema.visualFactText;
  next.content.coreRelation = normalizedSchema.strongestRelationText;
  next.content.judgement = mapExchangeDecisionToReviewJudgement(normalizedSchema.decision);
  next.content.extendedUnderstanding = normalizedSchema.extensionReasonText;
  next.content.currentBlocker = normalizedSchema.blockerText;
  next.updatedAt = importedReviewTime > 0 ? importedReviewTime : Date.now();
  return cloneReviewCardDocument(next);
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

function createEmptyReviewLibraryFilters() {
  return {
    query: '',
    judgement: '全部判断',
    blocker: '全部卡点',
    reviewer: '全部复盘人'
  };
}

function reviewLibrarySearchableText(item) {
  const content = item.document.content;
  return [
    content.title,
    content.visibleFacts,
    content.coreRelation,
    content.extendedUnderstanding,
    content.currentBlocker,
    content.visualFocus,
    content.focusReason,
    content.visualPath
  ].map((value) => normalizeText(value).trim()).join('\n');
}

function filterReviewLibraryItems(items, filters) {
  const query = normalizeText(filters.query).trim().toLocaleLowerCase();
  const judgement = normalizeText(filters.judgement).trim();
  const blocker = normalizeText(filters.blocker).trim();
  const reviewer = normalizeText(filters.reviewer).trim();
  return items.filter((item) => {
    if (query.length > 0 && !reviewLibrarySearchableText(item).toLocaleLowerCase().includes(query)) {
      return false;
    }
    if (judgement.length > 0 && judgement !== '全部判断' && normalizeReviewJudgement(item.document.content.judgement) !== judgement) {
      return false;
    }
    if (blocker.length > 0 && blocker !== '全部卡点' && !normalizeText(item.document.content.currentBlocker).toLocaleLowerCase().includes(blocker.toLocaleLowerCase())) {
      return false;
    }
    if (reviewer.length > 0 && reviewer !== '全部复盘人' && normalizeText(item.reviewerText).trim().toLocaleLowerCase() !== reviewer.toLocaleLowerCase()) {
      return false;
    }
    return true;
  });
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

const exchangeSchemaSource = readText('entry/src/main/ets/services/ReviewCardExchangeSchema.ets');
const exchangeSchemaDoc = readText('docs/review-card-exchange-schema.md');
const historyServiceSource = readText('entry/src/main/ets/services/ReviewCardHistoryService.ets');
const reviewCardModelSource = readText('entry/src/main/ets/model/ReviewCardModel.ets');
const reviewLibraryServiceSource = readText('entry/src/main/ets/services/ReviewLibraryService.ets');
const projectDetailPageSource = readText('entry/src/main/ets/pages/ProjectDetailPage.ets');
const sourceSchemaKeys = parseExchangeInterfaceKeys(exchangeSchemaSource);
const docSchemaKeys = parseExchangeDocKeys(exchangeSchemaDoc);
assert(JSON.stringify(sourceSchemaKeys) === JSON.stringify(REVIEW_SCHEMA_KEYS), 'ReviewCardExchangeSchemaV1 interface keys differ from expected v1 keys');
assert(JSON.stringify(docSchemaKeys) === JSON.stringify(REVIEW_SCHEMA_KEYS), 'review-card-exchange-schema.md field table differs from expected v1 keys');
assert(exchangeSchemaSource.includes("WORKS = 'works'"), 'exchange decision enum missing works');
assert(exchangeSchemaSource.includes("UNCERTAIN = 'uncertain'"), 'exchange decision enum missing uncertain');
assert(exchangeSchemaSource.includes("NOT_WORKS = 'notWorks'"), 'exchange decision enum missing notWorks');
assert(exchangeSchemaSource.includes('reviewerText: normalizeExchangeText(reviewerText).trim()'), 'reviewerText should come from saved reviewer text and be trimmed');
assert(exchangeSchemaSource.includes('resolveReviewCardExchangeReviewJsonFileName'), 'review JSON export file name resolver is missing');
assert(exchangeSchemaSource.includes('createReviewCardDocumentFromExchangeSchemaV1'), 'review JSON import mapping helper is missing');
assert(historyServiceSource.includes('const MAX_HISTORY_COUNT: number = 200;'), 'MAX_HISTORY_COUNT should support long-term review accumulation at 200 records');
assert(reviewCardModelSource.includes('reviewerText?: string;'), 'ReviewCardHistoryItem should persist optional reviewerText for library filters');
assert(historyServiceSource.includes('reviewerText: normalizeHistoryReviewerText(reviewerText)'), 'history service should persist reviewerText');
assert(reviewLibraryServiceSource.includes('export class ReviewLibraryService'), 'ReviewLibraryService is missing');
assert(reviewLibraryServiceSource.includes('static filter(items: Array<ReviewCardHistoryItem>, filters: ReviewLibraryFilters)'), 'ReviewLibraryService.filter is missing');
assert(projectDetailPageSource.includes("TextInput({ placeholder: '搜索标题、画面事实、核心关系、延伸理解、卡点'"), 'Review Library search input is missing');
assert(projectDetailPageSource.includes("Select([") && projectDetailPageSource.includes("'全部判断'"), 'Review Library decision filter is missing');
assert(projectDetailPageSource.includes("'全部卡点'") && projectDetailPageSource.includes("'全部复盘人'"), 'Review Library blocker/reviewer filters are missing');

assert(mapReviewJudgementToExchangeDecision('成立') === 'works', '成立 should map to works');
assert(mapReviewJudgementToExchangeDecision('待判断') === 'uncertain', '待判断 should map to uncertain');
assert(mapReviewJudgementToExchangeDecision('不成立') === 'notWorks', '不成立 should map to notWorks');

const sparseDocument = createDefaultDocument();
sparseDocument.imageUri = 'file:///photos/DSC%2001.jpg?size=large';
sparseDocument.updatedAt = Date.UTC(2026, 5, 7, 13, 8);
sparseDocument.content = {
  title: '测试复盘',
  visualFocus: '视觉落点',
  focusReason: '落点原因',
  visualPath: '视线路径',
  visibleFacts: '画面事实',
  coreRelation: '核心关系',
  judgement: '成立',
  extendedUnderstanding: '延伸理解',
  currentBlocker: '当前卡点'
};

const schema = createReviewCardExchangeSchemaV1(sparseDocument, '  Bo  ');
assert(JSON.stringify(Object.keys(schema)) === JSON.stringify(REVIEW_SCHEMA_KEYS), 'exchange schema keys changed or missing');
assert(schema.fileName === 'DSC 01.jpg', `fileName should decode URI file name, got ${schema.fileName}`);
assert(schema.reviewerText === 'Bo', `reviewerText should be trimmed, got ${schema.reviewerText}`);
assert(schema.decision === 'works', `decision should be works, got ${schema.decision}`);
assert(schema.firstLookText === sparseDocument.content.visualFocus, 'firstLookText should match current document visualFocus');
assert(schema.attentionReasonText === sparseDocument.content.focusReason, 'attentionReasonText should match current document focusReason');
assert(schema.eyePathText === sparseDocument.content.visualPath, 'eyePathText should match current document visualPath');
assert(schema.visualFactText === sparseDocument.content.visibleFacts, 'visualFactText should match current document visibleFacts');
assert(schema.strongestRelationText === sparseDocument.content.coreRelation, 'strongestRelationText should match current document coreRelation');
assert(schema.extensionReasonText === sparseDocument.content.extendedUnderstanding, 'extensionReasonText should match current document extendedUnderstanding');
assert(schema.blockerText === sparseDocument.content.currentBlocker, 'blockerText should match current document currentBlocker');
assert(resolveReviewCardExchangeReviewJsonFileName(sparseDocument) === 'DSC 01.review.json', 'review JSON file name should remove the photo extension');

const fallbackFileNameDocument = createDefaultDocument();
fallbackFileNameDocument.updatedAt = 1234567890;
assert(resolveReviewCardExchangeReviewJsonFileName(fallbackFileNameDocument) === 'review-1234567890.json', 'empty source file name should fall back to review timestamp JSON name');

const parsedSchema = parseReviewCardExchangeSchemaV1(JSON.stringify(schema, null, 2));
const importedDocument = createReviewCardDocumentFromExchangeSchemaV1(parsedSchema);
assert(parsedSchema.reviewerText === 'Bo', 'import parser should preserve reviewerText for Mac-side model fill');
assert(parsedSchema.reviewTimeText === schema.reviewTimeText, 'import parser should preserve reviewTimeText for Mac-side model fill');
assert(importedDocument.content.title === sparseDocument.content.title, 'import should recover title');
assert(importedDocument.content.visualFocus === sparseDocument.content.visualFocus, 'import should recover visual focus');
assert(importedDocument.content.focusReason === sparseDocument.content.focusReason, 'import should recover focus reason');
assert(importedDocument.content.visualPath === sparseDocument.content.visualPath, 'import should recover visual path');
assert(importedDocument.content.visibleFacts === sparseDocument.content.visibleFacts, 'import should recover visual facts');
assert(importedDocument.content.coreRelation === sparseDocument.content.coreRelation, 'import should recover core relation');
assert(importedDocument.content.judgement === REVIEW_JUDGEMENT.VALID, 'import should recover judgement from decision');
assert(importedDocument.content.extendedUnderstanding === sparseDocument.content.extendedUnderstanding, 'import should recover extended understanding');
assert(importedDocument.content.currentBlocker === sparseDocument.content.currentBlocker, 'import should recover current blocker');
assert(formatReviewTime(importedDocument.updatedAt) === schema.reviewTimeText, 'import should recover review time into updatedAt');

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

const libraryItems = [
  ['窗内的人', '画面里有窗', '窗内 ↔ 窗外', '关系不足', '不成立', 'Bo'],
  ['桥上的影子', '桥和人影', '人 ↔ 桥', '主体弱', '成立', 'Lin'],
  ['街角', '街道转角', '光线 ↔ 人', '关系不足', '不确定', 'Bo']
].map(([title, visibleFacts, coreRelation, blocker, judgement, reviewerText], index) => {
  const document = createDefaultDocument();
  document.content.title = title;
  document.content.visibleFacts = visibleFacts;
  document.content.coreRelation = coreRelation;
  document.content.currentBlocker = blocker;
  document.content.judgement = judgement;
  document.createdAt = index + 10;
  document.updatedAt = index + 10;
  return { document, exportedPath: '', reviewerText };
});

assert(filterReviewLibraryItems(libraryItems, { ...createEmptyReviewLibraryFilters(), query: '窗' }).length === 1, 'library search should match title/facts');
assert(filterReviewLibraryItems(libraryItems, { ...createEmptyReviewLibraryFilters(), judgement: '不成立' }).length === 1, 'library decision filter should match invalid reviews');
assert(filterReviewLibraryItems(libraryItems, { ...createEmptyReviewLibraryFilters(), blocker: '关系不足' }).length === 2, 'library blocker filter should match current blocker');
assert(filterReviewLibraryItems(libraryItems, { ...createEmptyReviewLibraryFilters(), reviewer: 'Bo' }).length === 2, 'library reviewer filter should match reviewerText');

const legacyReviewerItems = libraryItems.concat([{ ...libraryItems[0], reviewerText: '' }]);
assert(filterReviewLibraryItems(legacyReviewerItems, createEmptyReviewLibraryFilters()).length === 4, 'legacy empty reviewer items should stay visible without reviewer filter');
assert(filterReviewLibraryItems(legacyReviewerItems, { ...createEmptyReviewLibraryFilters(), reviewer: 'Bo' }).length === 2, 'legacy empty reviewer items should not match a concrete reviewer filter');

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
