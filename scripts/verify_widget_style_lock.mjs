import crypto from 'node:crypto';
import fs from 'node:fs';

const lockedCards = [
  {
    name: '2*2 左侧摄影学习小卡',
    path: 'entry/src/main/ets/widget/pages/LearningProgressMediumCard.ets',
    sha256: '41e06783116bb2adf98ff65dad33457c1d09a7fd58d1139746bcf22d50b1bc1e'
  },
  {
    name: '2*2 右侧今日待复盘小卡',
    path: 'entry/src/main/ets/widget/pages/TodayReviewCard.ets',
    sha256: '2bd9d16cbcd3fcb51d6472ba93988c0820259b353f6eb6732842410e35cf224a'
  },
  {
    name: '2*4 学习进度中型卡',
    path: 'entry/src/main/ets/widget/pages/LearningProgressSummaryMediumCard.ets',
    sha256: 'a0703c19a580a94c6d776686ff4523559ceb487297b128dd796e8e07831bf503'
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
