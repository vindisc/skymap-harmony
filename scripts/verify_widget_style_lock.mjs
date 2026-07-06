import crypto from 'node:crypto';
import fs from 'node:fs';

const lockedCards = [
  {
    name: '2*2 左侧摄影学习小卡',
    path: 'entry/src/main/ets/widget/pages/LearningProgressMediumCard.ets',
    sha256: '4c03f98dd9812d13d7af068251be9bc1073417b96fcd0e53242afcf50f95e15b'
  },
  {
    name: '2*2 右侧今日待复盘小卡',
    path: 'entry/src/main/ets/widget/pages/TodayReviewCard.ets',
    sha256: '42b8977eb7a454fad975776d1fe99c4e44b85c020360378df5efd7429f297400'
  },
  {
    name: '2*4 学习进度中型卡',
    path: 'entry/src/main/ets/widget/pages/LearningProgressSummaryMediumCard.ets',
    sha256: 'bd0def0d29999d34f342cbf8d1cdf58199fa19a3aaed36c86862e3fb2e260871'
  }
];

function readNormalized(path) {
  return fs.readFileSync(path, 'utf8').replace(/\r\n/g, '\n');
}

function sha256(source) {
  return crypto.createHash('sha256').update(source).digest('hex');
}

let failed = false;

for (const card of lockedCards) {
  const actual = sha256(readNormalized(card.path));
  if (actual !== card.sha256) {
    failed = true;
    console.error(`${card.name} 样式锁已变更: ${card.path}`);
    console.error(`  expected: ${card.sha256}`);
    console.error(`  actual:   ${actual}`);
  }
}

if (failed) {
  console.error('服务卡片样式已被保护。除非用户在当前任务里明确要求修改这些卡片样式，否则不要更新锁定哈希。');
  process.exit(1);
}

console.log('widget style lock verified: protected card styles unchanged');
