import fs from 'node:fs';

const serviceSource = fs.readFileSync('entry/src/main/ets/services/ReviewProjectService.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

const requiredServiceTokens = [
  'static resolvePhotoFileName(document: ReviewCardDocument): string',
  'static filterItems(',
  'static buildGlobalStats(items: Array<ReviewCardHistoryItem>): ReviewProjectStats',
  'static buildDefaultProjectSummary(items: Array<ReviewCardHistoryItem>): ReviewProjectSummary',
  'static buildHomeSummary(items: Array<ReviewCardHistoryItem>): ReviewProjectSummary',
  'static buildDashboardStats(items: Array<ReviewCardHistoryItem>): ReviewDashboardStats',
  'function sortHistoryItems(items: Array<ReviewCardHistoryItem>): Array<ReviewCardHistoryItem>'
];

for (const token of requiredServiceTokens) {
  assert(serviceSource.includes(token), `ReviewProjectService missing service API token: ${token}`);
}

const DEFAULT_PROJECT_ID = 'default';
const VALID = '成立';
const INVALID = '不成立';
const UNSURE = '不确定';

function normalizeReviewJudgement(value) {
  const trimmedValue = typeof value === 'string' ? value.trim() : '';
  if (trimmedValue === VALID) {
    return VALID;
  }
  if (trimmedValue === INVALID) {
    return INVALID;
  }
  if (trimmedValue === UNSURE || trimmedValue === '待判断') {
    return UNSURE;
  }
  if (trimmedValue.includes(INVALID)) {
    return INVALID;
  }
  if (trimmedValue.includes('待判断') || trimmedValue.includes(UNSURE)) {
    return UNSURE;
  }
  if (trimmedValue.includes(VALID)) {
    return VALID;
  }
  return UNSURE;
}

function normalizeExcerpt(value) {
  return `${value ?? ''}`.replace(/\s+/g, ' ').trim();
}

function ensureProjectId(document) {
  return document.projectId && document.projectId.length > 0 ? document.projectId : DEFAULT_PROJECT_ID;
}

function resolvePhotoFileName(document) {
  const imageUri = typeof document.imageUri === 'string' ? document.imageUri.trim() : '';
  if (imageUri.length === 0) {
    return '';
  }
  const normalizedPath = imageUri.replace(/\\/g, '/');
  return normalizedPath.slice(normalizedPath.lastIndexOf('/') + 1).trim();
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
    if (judgement === VALID) {
      stats.validCount += 1;
      return;
    }
    if (judgement === INVALID) {
      stats.invalidCount += 1;
      return;
    }
    stats.unsureCount += 1;
  });

  return stats;
}

function sortHistoryItems(items) {
  return [...items].sort((left, right) => {
    if (right.document.updatedAt !== left.document.updatedAt) {
      return right.document.updatedAt - left.document.updatedAt;
    }
    return right.document.createdAt - left.document.createdAt;
  });
}

function buildSummaryFromItems(items) {
  const sortedItems = sortHistoryItems(items);
  return {
    items: sortedItems,
    recordCount: sortedItems.length,
    stats: buildGlobalStats(sortedItems),
    latestItem: sortedItems[0],
    latestUpdatedAt: sortedItems[0]?.document.updatedAt ?? 0
  };
}

function buildDefaultProjectSummary(items) {
  return buildSummaryFromItems(items.filter((item) => ensureProjectId(item.document) === DEFAULT_PROJECT_ID));
}

function buildHomeSummary(items) {
  return buildSummaryFromItems(items);
}

function normalizeReviewDayKey(timestamp) {
  const date = new Date(timestamp);
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}

function parseReviewDayKey(dayKey) {
  const parts = dayKey.split('-');
  if (parts.length !== 3) {
    return 0;
  }
  return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])).getTime();
}

function buildDashboardStats(items) {
  const summary = buildHomeSummary(items);
  const uniqueDaySet = new Set();
  summary.items.forEach((item) => {
    uniqueDaySet.add(normalizeReviewDayKey(item.document.createdAt));
  });
  const sortedDays = Array.from(uniqueDaySet)
    .map((dayKey) => parseReviewDayKey(dayKey))
    .filter((value) => value > 0)
    .sort((left, right) => right - left);

  let streakDays = 0;
  let previousDayTime = 0;
  sortedDays.forEach((dayTime, index) => {
    if (index === 0) {
      streakDays = 1;
      previousDayTime = dayTime;
      return;
    }

    const dayDiff = Math.round((previousDayTime - dayTime) / 86400000);
    if (dayDiff === 1) {
      streakDays += 1;
      previousDayTime = dayTime;
    }
  });

  return { streakDays };
}

function filterItems(items, rawQuery, decisionFilter) {
  const query = rawQuery.trim().toLocaleLowerCase();
  return items.filter((item) => {
    const judgement = normalizeReviewJudgement(item.document.content.judgement);
    if (decisionFilter === VALID && judgement !== VALID) {
      return false;
    }
    if (decisionFilter === UNSURE && judgement !== UNSURE) {
      return false;
    }
    if (decisionFilter === INVALID && judgement !== INVALID) {
      return false;
    }
    if (query.length === 0) {
      return true;
    }
    const searchableText = [
      item.document.content.title,
      item.document.content.coreRelation,
      item.document.content.currentBlocker,
      resolvePhotoFileName(item.document)
    ]
      .map((value) => normalizeExcerpt(value).toLocaleLowerCase())
      .join('\n');
    return searchableText.includes(query);
  });
}

function createReviewItem(options) {
  return {
    document: {
      projectId: options.projectId ?? DEFAULT_PROJECT_ID,
      imageUri: options.imageUri ?? '',
      content: {
        title: options.title ?? '',
        judgement: options.judgement ?? '',
        coreRelation: options.coreRelation ?? '',
        currentBlocker: options.currentBlocker ?? ''
      },
      createdAt: options.createdAt,
      updatedAt: options.updatedAt ?? options.createdAt
    },
    exportedPath: ''
  };
}

const judgementItems = [
  '成立',
  '判断为成立',
  '不成立',
  '判断为不成立',
  '不确定',
  '待判断',
  '',
  undefined
].map((judgement, index) => createReviewItem({ judgement, createdAt: index + 1 }));
const judgementStats = buildGlobalStats(judgementItems);
assert(
  judgementStats.totalCount === 8 &&
    judgementStats.validCount === 2 &&
    judgementStats.invalidCount === 2 &&
    judgementStats.unsureCount === 4,
  `Unexpected judgement bucket stats: ${JSON.stringify(judgementStats)}`
);

const mixedProjectItems = [
  createReviewItem({ projectId: 'imported', judgement: INVALID, createdAt: 1, updatedAt: 30 }),
  createReviewItem({ projectId: DEFAULT_PROJECT_ID, judgement: VALID, createdAt: 2, updatedAt: 20 }),
  createReviewItem({ projectId: '', judgement: UNSURE, createdAt: 3, updatedAt: 10 })
];
const homeSummary = buildHomeSummary(mixedProjectItems);
const defaultSummary = buildDefaultProjectSummary(mixedProjectItems);
assert(homeSummary.recordCount === 3 && homeSummary.latestItem.document.projectId === 'imported', 'Home summary must include every project and keep latest item ordering.');
assert(defaultSummary.recordCount === 2 && defaultSummary.stats.validCount === 1 && defaultSummary.stats.unsureCount === 1, 'Default project summary must include blank project ids as the default project only.');

const baseDay = new Date(2026, 5, 16, 9, 0, 0).getTime();
const streakItems = [
  createReviewItem({ createdAt: baseDay }),
  createReviewItem({ createdAt: baseDay + 3600000 }),
  createReviewItem({ createdAt: baseDay - 86400000 }),
  createReviewItem({ createdAt: baseDay - 2 * 86400000 })
];
assert(buildDashboardStats(streakItems).streakDays === 3, 'Dashboard streak must count unique consecutive review days.');
assert(buildDashboardStats([]).streakDays === 0, 'Dashboard streak must be 0 for empty history.');

const searchableItems = [
  createReviewItem({
    title: '暗光人像',
    judgement: VALID,
    coreRelation: '窗边侧光',
    currentBlocker: '肤色偏灰',
    imageUri: 'file:///photos/portrait-one.jpg',
    createdAt: 1
  }),
  createReviewItem({
    title: '街头构图',
    judgement: INVALID,
    coreRelation: '线条关系',
    currentBlocker: '主体不明确',
    imageUri: 'C:\\photos\\street-two.jpg',
    createdAt: 2
  })
];
assert(filterItems(searchableItems, 'portrait-one', '').length === 1, 'Filter must search photo file names.');
assert(filterItems(searchableItems, '主体', INVALID).length === 1, 'Filter must combine query and judgement filters.');
assert(filterItems(searchableItems, '窗边', INVALID).length === 0, 'Filter must reject mismatched judgement filters.');
assert(resolvePhotoFileName(searchableItems[1].document) === 'street-two.jpg', 'Photo file name resolver must normalize Windows-style paths.');

if (failed) {
  process.exit(1);
}

console.log(`review project service: stats=${judgementStats.totalCount}, home=${homeSummary.recordCount}, default=${defaultSummary.recordCount}, streak=${buildDashboardStats(streakItems).streakDays}, filters=3`);
