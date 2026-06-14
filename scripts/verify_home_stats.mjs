import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const settingsPageSource = fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8');
const projectServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewProjectService.ets', 'utf8');

let failed = false;

const requiredHomeSections = [
  "this.QuickEntryItem(\n            '拍'",
  "this.QuickEntryItem(\n            '库'",
  "this.QuickEntryItem(\n            '传'",
  "this.QuickEntryItem(\n            '设'"
];

for (const marker of requiredHomeSections) {
  if (!homePageSource.includes(marker)) {
    failed = true;
    console.error(`HomePage missing section marker: ${marker}`);
  }
}

if (homePageSource.includes("Text('最近一次')")) {
  failed = true;
  console.error('HomePage must not render an independent 最近一次 module.');
}

if (!homePageSource.includes("label: this.isPickingPhoto ? '正在打开相册...' : '开始复盘'")) {
  if (!homePageSource.includes("this.isPickingPhoto ? '打开相册中' : '立即开始'")) {
    failed = true;
    console.error('HomePage must expose 开始复盘 quick action state.');
  }
}

if (!homePageSource.includes("return this.isHomeStorageConfigured() ? 'SMB 已连接' : '未配置家庭存储';")) {
  failed = true;
  console.error('HomePage must expose sync status text for the sync center entry.');
}

if (!homePageSource.includes("Text('当前状态')")) {
  failed = true;
  console.error('HomePage must keep a compact status summary below the quick actions.');
}

if (!homePageSource.includes('ReviewSettingsService.loadReviewerName(context)')) {
  failed = true;
  console.error('HomePage must load reviewer settings to render the 设置 summary.');
}

if (!settingsPageSource.includes("Text('设置')")) {
  failed = true;
  console.error('ReviewSettingsPage title must be 设置.');
}

if (settingsPageSource.includes("Button('返回')") || settingsPageSource.includes('router.back()')) {
  failed = true;
  console.error('ReviewSettingsPage must not render or handle an explicit back button.');
}

if (!projectServiceSource.includes('stats.validCount += 1') ||
  !projectServiceSource.includes('stats.invalidCount += 1') ||
  !projectServiceSource.includes('stats.unsureCount += 1')) {
  failed = true;
  console.error('ReviewProjectService global stats logic must keep all three judgement buckets.');
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
if (stats.totalCount !== 12 || stats.validCount !== 4 || stats.unsureCount !== 5 || stats.invalidCount !== 3) {
  failed = true;
  console.error(`Unexpected status split: ${JSON.stringify(stats)}`);
}

if (failed) {
  process.exit(1);
}

console.log(`home architecture: sections=4, total=${stats.totalCount}, valid=${stats.validCount}, unsure=${stats.unsureCount}, invalid=${stats.invalidCount}`);
