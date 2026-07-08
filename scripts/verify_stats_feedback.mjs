import fs from 'node:fs';

const statsPageSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const projectServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewProjectService.ets', 'utf8');
const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

const requiredProjectServiceTokens = [
  'export interface ReviewStatsFeedback',
  'export interface ReviewStatsDistributionItem',
  'export interface ReviewStatsBlockerItem',
  'export interface ReviewStatsRecentReviewItem',
  'export function createEmptyReviewStatsFeedback()',
  'static buildStatsFeedback(',
  "trimmedValue === 'works'",
  "trimmedValue === 'uncertain'",
  "trimmedValue === 'notWorks'",
  'cleanStatsDisplayText',
  'resolveReviewUpdatedTime',
  'recent30DaysItems',
  'decisionDistribution: buildStatsDistribution(totalCounts)',
  'recentBlockers: blockers',
  'recentReviews: recentReviews'
];

for (const token of requiredProjectServiceTokens) {
  assert(projectServiceSource.includes(token), `ReviewProjectService missing stats token: ${token}`);
}

const requiredStatsPageTokens = [
  "@Prop @Watch('refreshStatsData') refreshToken",
  'LearningProgressService.loadWithReviewItems(context)',
  'ReviewProjectService.buildStatsFeedback(progressResult.reviewItems)',
  "AppPageHeader({\n            title: '统计'",
  'Scroll() {\n      Column({ space: AppMetrics.cardGap }) {',
  'const STATS_PAGE_TOP_PADDING: number = AppMetrics.space20;',
  'top: STATS_PAGE_TOP_PADDING',
  ".height('100%')\n      .justifyContent(FlexAlign.Start)",
  'LearningOverviewCard()',
  "Text('学习进度')",
  '还没有复盘数据',
  '完成第一张照片复盘后，这里会显示你的判断变化。',
  '最近 30 天',
  '继续复盘后，这里会显示最近 30 天变化。',
  '判断分布',
  '最近卡点',
  '暂时还没有记录卡点。',
  'Stack({ alignContent: Alignment.Start })',
  "import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';",
  'this.OverviewMetric(',
  '.fontSize(AppTypography.statNumber)',
  '.shadow(ElevationTokens.medium)',
  '.shadow(ElevationTokens.subtle)',
  'resolveDistributionProgressWidth',
  'Math.max(item.rate, 4)',
  '.animation({ duration: MotionTokens.durationStandard, curve: MotionTokens.curveDecelerate })'
];

for (const token of requiredStatsPageTokens) {
  assert(statsPageSource.includes(token), `StatsPage missing v1 token: ${token}`);
}

assert(!statsPageSource.includes("Text('当前记录')"), 'StatsPage must remove the old 当前记录 placeholder section.');
assert(!statsPageSource.includes('PreviewChip'), 'StatsPage must not keep placeholder chip statistics.');
assert(!statsPageSource.includes('累计 ${this.totalCount}'), 'StatsPage must not render stale local total chips.');
assert(!statsPageSource.includes('Progress('), 'StatsPage should not introduce a chart/progress dependency.');
assert(!statsPageSource.includes('Chart'), 'StatsPage should not introduce chart widgets.');
assert(appShellSource.includes('StatsPage({ refreshToken: this.reviewLibraryRefreshToken })'), 'AppShell must still pass review library refresh token to StatsPage.');

const refreshReasons = [
  "notifyReviewLibraryChanged('save_document')",
  "notifyReviewLibraryChanged('update_document')",
  "notifyReviewLibraryChanged('delete_document')",
  "notifyReviewLibraryChanged('mark_exported')",
  "notifyReviewLibraryChanged('review_exchange_recovered')"
];
for (const token of refreshReasons) {
  assert(historyServiceSource.includes(token), `History service must notify stats refresh: ${token}`);
}

const VALID = '成立';
const INVALID = '不成立';
const UNSURE = '不确定';
const DEFAULT_REVIEW_TITLE = '这张照片是否成立';
const DAY = 24 * 60 * 60 * 1000;
const PLACEHOLDER_TEXTS = [
  DEFAULT_REVIEW_TITLE,
  '待填写',
  '暂无记录',
  '未命名复盘',
  '照片预览',
  '第一眼先看到哪里',
  '为什么它会先被看到',
  '视线接着从哪里走到哪里',
  '画面里有哪些可见事实',
  '最重要的 A ↔ B 关系是什么',
  '这张照片为什么成立或不成立',
  '当前最大问题是什么',
  '当前卡点'
];
const GUIDANCE_TOKENS = [
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

function normalizeExcerpt(value) {
  return typeof value === 'string' ? value.replace(/\s+/g, ' ').trim() : '';
}

function normalizeJudgement(value) {
  const trimmedValue = normalizeExcerpt(value);
  if (trimmedValue === 'works') {
    return VALID;
  }
  if (trimmedValue === 'notWorks') {
    return INVALID;
  }
  if (trimmedValue === 'uncertain') {
    return UNSURE;
  }
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

function resolveUpdatedTime(document) {
  return document.updatedAt > 0 ? document.updatedAt : document.createdAt > 0 ? document.createdAt : 0;
}

function sortHistoryItems(items) {
  return [...items].sort((left, right) => {
    const updatedDiff = resolveUpdatedTime(right.document) - resolveUpdatedTime(left.document);
    if (updatedDiff !== 0) {
      return updatedDiff;
    }
    return right.document.createdAt - left.document.createdAt;
  });
}

function stripDisplayNoise(value) {
  return value
    .replace(/https?:\/\/[^\s，。；、]+/g, ' ')
    .replace(/\d{12,}/g, ' ')
    .replace(/[＿_—-]{6,}/g, ' ');
}

function normalizePlaceholderComparison(value) {
  return value.replace(/[？?。.!！:：\s]/g, '');
}

function isPlaceholderText(value) {
  const normalizedValue = normalizeExcerpt(stripDisplayNoise(value));
  if (normalizedValue.length === 0) {
    return true;
  }

  const comparisonValue = normalizePlaceholderComparison(normalizedValue);
  if (PLACEHOLDER_TEXTS.some((placeholder) => comparisonValue === normalizePlaceholderComparison(placeholder))) {
    return true;
  }

  let matchedCount = 0;
  for (const token of GUIDANCE_TOKENS) {
    if (normalizedValue.includes(token)) {
      matchedCount += 1;
    }
  }
  return matchedCount >= 2;
}

function cleanDisplayText(value) {
  const normalizedValue = normalizeExcerpt(stripDisplayNoise(typeof value === 'string' ? value : ''));
  return isPlaceholderText(normalizedValue) ? '' : normalizedValue;
}

function resolvePhotoFileName(document) {
  const imageUri = typeof document.imageUri === 'string' ? document.imageUri.trim() : '';
  if (imageUri.length === 0) {
    return '';
  }
  const normalizedPath = imageUri.replace(/\\/g, '/');
  return normalizedPath.slice(normalizedPath.lastIndexOf('/') + 1).trim();
}

function resolveReviewTitle(document) {
  const title = cleanDisplayText(document.content.title);
  if (title.length > 0) {
    return title;
  }
  const fileName = resolvePhotoFileName(document);
  return fileName.length > 0 ? fileName : '未命名复盘';
}

function countDecisions(items) {
  const counts = {
    totalCount: items.length,
    worksCount: 0,
    uncertainCount: 0,
    notWorksCount: 0
  };
  for (const item of items) {
    const judgement = normalizeJudgement(item.document.content.judgement);
    if (judgement === VALID) {
      counts.worksCount += 1;
    } else if (judgement === INVALID) {
      counts.notWorksCount += 1;
    } else {
      counts.uncertainCount += 1;
    }
  }
  return counts;
}

function rate(count, total) {
  return total <= 0 ? 0 : Math.floor(count * 100 / total);
}

function buildDistribution(counts) {
  return [
    { key: 'works', label: '成立', count: counts.worksCount, rate: rate(counts.worksCount, counts.totalCount) },
    { key: 'uncertain', label: '待判断', count: counts.uncertainCount, rate: rate(counts.uncertainCount, counts.totalCount) },
    { key: 'notWorks', label: '不成立', count: counts.notWorksCount, rate: rate(counts.notWorksCount, counts.totalCount) }
  ];
}

function decisionLabel(value) {
  const judgement = normalizeJudgement(value);
  if (judgement === VALID) {
    return '成立';
  }
  if (judgement === INVALID) {
    return '不成立';
  }
  return '待判断';
}

function buildStatsFeedback(items, now) {
  const sortedItems = sortHistoryItems(items);
  const totalCounts = countDecisions(sortedItems);
  const recentItems = sortedItems.filter((item) => resolveUpdatedTime(item.document) >= now - 30 * DAY);
  const recentCounts = countDecisions(recentItems);
  const blockers = [];
  const recentReviews = [];

  for (const item of sortedItems) {
    const key = `${item.document.createdAt}`;
    if (blockers.length < 3) {
      const blockerText = cleanDisplayText(item.document.content.currentBlocker);
      if (blockerText.length > 0) {
        blockers.push({ key: `${key}-blocker-${blockers.length + 1}`, order: blockers.length + 1, text: blockerText });
      }
    }
    if (recentReviews.length < 3) {
      recentReviews.push({
        key,
        title: resolveReviewTitle(item.document),
        decision: decisionLabel(item.document.content.judgement),
        updatedAt: resolveUpdatedTime(item.document)
      });
    }
  }

  return {
    totalCount: totalCounts.totalCount,
    worksCount: totalCounts.worksCount,
    uncertainCount: totalCounts.uncertainCount,
    notWorksCount: totalCounts.notWorksCount,
    worksRate: rate(totalCounts.worksCount, totalCounts.totalCount),
    latestReviewTime: sortedItems.length > 0 ? resolveUpdatedTime(sortedItems[0].document) : 0,
    recent30DaysCount: recentCounts.totalCount,
    recent30DaysWorksCount: recentCounts.worksCount,
    recent30DaysUncertainCount: recentCounts.uncertainCount,
    recent30DaysNotWorksCount: recentCounts.notWorksCount,
    decisionDistribution: buildDistribution(totalCounts),
    recentBlockers: blockers,
    recentReviews
  };
}

function createReviewItem(options) {
  const createdAt = options.createdAt;
  return {
    document: {
      createdAt,
      updatedAt: options.updatedAt ?? createdAt,
      imageUri: options.imageUri ?? `/photos/${options.title ?? 'review'}.jpg`,
      content: {
        title: options.title ?? '',
        judgement: options.judgement ?? UNSURE,
        currentBlocker: options.currentBlocker ?? '',
        coreRelation: ''
      }
    },
    exportedPath: ''
  };
}

const now = new Date(2026, 5, 26, 12, 0, 0).getTime();

const emptyStats = buildStatsFeedback([], now);
assert(emptyStats.totalCount === 0, 'Empty stats must expose totalCount 0.');
assert(emptyStats.worksRate === 0, 'Empty stats must expose worksRate 0.');
assert(emptyStats.recentBlockers.length === 0 && emptyStats.recentReviews.length === 0, 'Empty stats must not create fake lists.');
assert(emptyStats.decisionDistribution.every((item) => item.rate === 0), 'Empty distribution must not create invalid rates.');

const twelveItems = [
  createReviewItem({ title: '成立 1', judgement: 'works', currentBlocker: '画面关系不够集中', createdAt: now - 1 * DAY, updatedAt: now - 1 * DAY }),
  createReviewItem({ title: '成立 2', judgement: VALID, currentBlocker: '后面小人是否必要', createdAt: now - 2 * DAY, updatedAt: now - 2 * DAY }),
  createReviewItem({ title: '成立 3', judgement: VALID, currentBlocker: '第一眼落点不稳定', createdAt: now - 3 * DAY, updatedAt: now - 3 * DAY }),
  createReviewItem({ title: '成立 4', judgement: '判断为成立', currentBlocker: '当前最大问题是什么？', createdAt: now - 4 * DAY, updatedAt: now - 4 * DAY }),
  createReviewItem({ title: '成立 5', judgement: VALID, currentBlocker: '', createdAt: now - 5 * DAY, updatedAt: now - 5 * DAY }),
  createReviewItem({ title: '成立 6', judgement: VALID, currentBlocker: '第一眼先看到哪里 为什么它会先被看到 当前最大问题是什么', createdAt: now - 6 * DAY, updatedAt: now - 6 * DAY }),
  createReviewItem({ title: '成立 7', judgement: VALID, currentBlocker: '亮部抢走注意力', createdAt: now - 7 * DAY, updatedAt: now - 7 * DAY }),
  createReviewItem({ title: '成立 8', judgement: VALID, currentBlocker: '前景边缘略散', createdAt: now - 8 * DAY, updatedAt: now - 8 * DAY }),
  createReviewItem({ title: '待判断 1', judgement: 'uncertain', currentBlocker: '', createdAt: now - 9 * DAY, updatedAt: now - 9 * DAY }),
  createReviewItem({ title: '待判断 2', judgement: '待判断', currentBlocker: '', createdAt: now - 10 * DAY, updatedAt: now - 10 * DAY }),
  createReviewItem({ title: '待判断 3', judgement: UNSURE, currentBlocker: '', createdAt: now - 45 * DAY, updatedAt: now - 45 * DAY }),
  createReviewItem({ title: '待判断 4', judgement: '', currentBlocker: '', createdAt: now - 60 * DAY, updatedAt: now - 60 * DAY })
];

const twelveStats = buildStatsFeedback(twelveItems, now);
assert(twelveStats.totalCount === 12, `Expected totalCount 12, got ${twelveStats.totalCount}.`);
assert(
  twelveStats.worksCount === 8 && twelveStats.uncertainCount === 4 && twelveStats.notWorksCount === 0,
  `Unexpected decision counts: ${JSON.stringify(twelveStats)}`
);
assert(twelveStats.worksRate === 66, `Expected worksRate floor 66, got ${twelveStats.worksRate}.`);
assert(
  twelveStats.recent30DaysCount === 10 &&
    twelveStats.recent30DaysWorksCount === 8 &&
    twelveStats.recent30DaysUncertainCount === 2 &&
    twelveStats.recent30DaysNotWorksCount === 0,
  `Unexpected recent 30 days stats: ${JSON.stringify(twelveStats)}`
);
assert(twelveStats.decisionDistribution.map((item) => item.rate).join(',') === '66,33,0', 'Distribution rates should be trustworthy and zero-safe.');
assert(
  twelveStats.recentBlockers.map((item) => item.text).join('|') === '画面关系不够集中|后面小人是否必要|第一眼落点不稳定',
  `Recent blockers should filter placeholders and keep newest non-empty values: ${JSON.stringify(twelveStats.recentBlockers)}`
);
assert(twelveStats.recentReviews.length === 3, 'Recent reviews should keep latest three reviews.');
assert(twelveStats.recentReviews[0].title === '成立 1' && twelveStats.recentReviews[0].decision === '成立', 'Recent reviews should sort by updatedAt desc.');

const fallbackTitleStats = buildStatsFeedback([
  createReviewItem({
    title: DEFAULT_REVIEW_TITLE,
    judgement: UNSURE,
    imageUri: 'file:///data/photos/yellow-polo-side.jpg',
    createdAt: now - 1000,
    updatedAt: 0
  })
], now);
assert(fallbackTitleStats.recentReviews[0].title === 'yellow-polo-side.jpg', 'Recent reviews should fall back from placeholder title to file name.');
assert(fallbackTitleStats.latestReviewTime === now - 1000, 'Latest review time should fall back to createdAt when updatedAt is empty.');

const deletedStats = buildStatsFeedback(twelveItems.slice(0, 11), now);
assert(deletedStats.totalCount === 11, 'Deleting one record should reduce total stats.');

const updatedDecisionItems = twelveItems.map((item, index) => {
  if (index === 8) {
    return createReviewItem({
      title: item.document.content.title,
      judgement: 'notWorks',
      currentBlocker: item.document.content.currentBlocker,
      createdAt: item.document.createdAt,
      updatedAt: now + DAY
    });
  }
  return item;
});
const updatedStats = buildStatsFeedback(updatedDecisionItems, now + DAY);
assert(
  updatedStats.worksCount === 8 && updatedStats.uncertainCount === 3 && updatedStats.notWorksCount === 1,
  `Update decision should change distribution: ${JSON.stringify(updatedStats)}`
);
assert(updatedStats.recentReviews[0].decision === '不成立', 'Updated decision should be visible in recent reviews after recompute.');

class StatsPageModel {
  constructor(items) {
    this.items = items;
    this.feedback = buildStatsFeedback([], now);
    this.reloadCount = 0;
    this.refreshToken = 0;
  }

  reload() {
    this.reloadCount += 1;
    this.feedback = buildStatsFeedback(this.items, now + this.reloadCount);
  }

  onRefreshTokenChanged(items) {
    this.items = items;
    this.refreshToken += 1;
    this.reload();
  }
}

const pageModel = new StatsPageModel([]);
pageModel.reload();
assert(pageModel.feedback.totalCount === 0, 'Stats page model should start with empty state.');
pageModel.onRefreshTokenChanged(twelveItems);
assert(pageModel.reloadCount === 2 && pageModel.feedback.totalCount === 12, 'Refresh token changes should recompute stats.');
pageModel.onRefreshTokenChanged(updatedDecisionItems);
assert(pageModel.reloadCount === 3 && pageModel.feedback.notWorksCount === 1, 'Refresh recompute should pick up updated decision distribution.');

if (failed) {
  process.exit(1);
}

console.log(`stats feedback: empty=${emptyStats.totalCount}, total=${twelveStats.totalCount}, worksRate=${twelveStats.worksRate}, recent30=${twelveStats.recent30DaysCount}, blockers=${twelveStats.recentBlockers.length}, refresh=${pageModel.reloadCount}`);
