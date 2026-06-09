import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');

const requiredPrimitiveStates = [
  '@State totalReviewCount: number',
  '@State validReviewCount: number',
  '@State unsureReviewCount: number',
  '@State invalidReviewCount: number'
];

let failed = false;
for (const stateDecl of requiredPrimitiveStates) {
  if (!homePageSource.includes(stateDecl)) {
    failed = true;
    console.error(`HomePage missing primitive state: ${stateDecl}`);
  }
}

if (homePageSource.includes('@State overviewStats')) {
  failed = true;
  console.error('HomePage must not render overview numbers from object @State overviewStats.');
}

if (!homePageSource.includes('this.totalReviewCount = nextOverviewStats.totalCount')) {
  failed = true;
  console.error('HomePage must assign totalReviewCount directly from loaded stats.');
}

function normalizeReviewJudgement(value) {
  const trimmedValue = typeof value === 'string' ? value.trim() : '';
  if (trimmedValue === '成立') {
    return '成立';
  }
  if (trimmedValue === '不成立') {
    return '不成立';
  }
  if (trimmedValue === '不确定' || trimmedValue === '待判断') {
    return '不确定';
  }
  if (trimmedValue.includes('不成立')) {
    return '不成立';
  }
  if (trimmedValue.includes('待判断') || trimmedValue.includes('不确定')) {
    return '不确定';
  }
  if (trimmedValue.includes('成立')) {
    return '成立';
  }
  return '不确定';
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
    if (judgement === '成立') {
      stats.validCount += 1;
      return;
    }
    if (judgement === '不成立') {
      stats.invalidCount += 1;
      return;
    }
    stats.unsureCount += 1;
  });

  return stats;
}

const twelveReviewItems = [
  '成立',
  '成立',
  '成立',
  '不成立',
  '不成立',
  '待判断',
  '不确定',
  '',
  undefined,
  '仍然待判断',
  '判断为成立',
  '判断为不成立'
].map((judgement, index) => {
  return {
    document: {
      projectId: 'default',
      content: {
        judgement
      },
      createdAt: index + 1,
      updatedAt: index + 1
    },
    exportedPath: ''
  };
});

const stats = buildGlobalStats(twelveReviewItems);
const statusSum = stats.validCount + stats.unsureCount + stats.invalidCount;
if (stats.totalCount !== 12) {
  failed = true;
  console.error(`Expected totalCount=12, got ${stats.totalCount}`);
}
if (statusSum !== stats.totalCount) {
  failed = true;
  console.error(`Expected status sum=${stats.totalCount}, got ${statusSum}`);
}
if (stats.validCount !== 4 || stats.unsureCount !== 5 || stats.invalidCount !== 3) {
  failed = true;
  console.error(`Unexpected status split: ${JSON.stringify(stats)}`);
}

if (failed) {
  process.exit(1);
}

console.log(`home stats: total=${stats.totalCount}, valid=${stats.validCount}, unsure=${stats.unsureCount}, invalid=${stats.invalidCount}`);
