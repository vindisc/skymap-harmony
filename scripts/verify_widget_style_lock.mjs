import crypto from 'node:crypto';
import fs from 'node:fs';

const lockedCards = [
  {
    name: '2*2 左侧摄影学习小卡',
    path: 'entry/src/main/ets/widget/pages/LearningProgressMediumCard.ets',
    sha256: '651d665a3df894c33a6e30cd45de143622eea3d33b95b71505f9326dca4ada77'
  },
  {
    name: '2*2 右侧今日待复盘小卡',
    path: 'entry/src/main/ets/widget/pages/TodayReviewCard.ets',
    sha256: 'bc927c5429b016d882124c0d98fe2b9b313972a3068ca87f62fa11ba72c9b673'
  },
  {
    name: '2*4 学习进度中型卡',
    path: 'entry/src/main/ets/widget/pages/LearningProgressSummaryMediumCard.ets',
    sha256: 'bf3e95512fb25ea8a30b3675e80fc23b61050ef2bfbcc8cdec1ebd6ae639b499'
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
