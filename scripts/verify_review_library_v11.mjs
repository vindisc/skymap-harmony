import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const detailPageSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const exportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewJsonExportService.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const projectModelSource = fs.readFileSync('entry/src/main/ets/model/ProjectModel.ets', 'utf8');
const projectServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewProjectService.ets', 'utf8');

let failed = false;

const requiredHomeTokens = [
  "Text('复盘库')",
  'ProjectHomeCard({'
];

for (const token of requiredHomeTokens) {
  if (!homePageSource.includes(token)) {
    failed = true;
    console.error(`HomePage missing token: ${token}`);
  }
}

const requiredDetailTokens = [
  "title: '复盘库'",
  "TextInput({ text: this.searchText, placeholder: '搜索标题、核心关系、卡点、文件名' })",
  "this.FilterChip('成立', ReviewJudgementStatus.VALID)",
  "this.FilterChip('待判断', ReviewJudgementStatus.UNSURE)",
  "this.FilterChip('不成立', ReviewJudgementStatus.INVALID)",
  "Button('创建第一条复盘')",
  'ReviewProjectService.filterItems('
];

for (const token of requiredDetailTokens) {
  if (!detailPageSource.includes(token)) {
    failed = true;
    console.error(`ProjectDetailPage missing token: ${token}`);
  }
}

const requiredExportTokens = [
  "review.json 已导出到系统文件：${fileName}，现在可直接发送给 Mac 导入",
  "review.json 已保存到系统文件：${result.fileName}。现在可直接发送给 Mac 导入。"
];

if (!exportServiceSource.includes(requiredExportTokens[0])) {
  failed = true;
  console.error(`ReviewJsonExportService missing token: ${requiredExportTokens[0]}`);
}

if (!previewPageSource.includes(requiredExportTokens[1])) {
  failed = true;
  console.error(`PreviewPage missing token: ${requiredExportTokens[1]}`);
}

if (!projectModelSource.includes("export const DEFAULT_PROJECT_NAME: string = '复盘库';")) {
  failed = true;
  console.error('ProjectModel must keep default project name as 复盘库.');
}

if (!projectServiceSource.includes('static filterItems(') || !projectServiceSource.includes('static resolvePhotoFileName(')) {
  failed = true;
  console.error('ReviewProjectService must expose review library filtering helpers.');
}

const items = [
  {
    document: {
      imageUri: '/data/storage/el2/base/files/IMG_1001.JPG',
      content: {
        title: '逆光人像',
        coreRelation: '人物与窗边高光',
        currentBlocker: '高光太抢',
        judgement: '成立'
      }
    }
  },
  {
    document: {
      imageUri: '/data/storage/el2/base/files/IMG_1002.JPG',
      content: {
        title: '街头抓拍',
        coreRelation: '路人与标牌',
        currentBlocker: '主体不够集中',
        judgement: '不成立'
      }
    }
  }
];

function normalizeJudgement(value) {
  const text = typeof value === 'string' ? value.trim() : '';
  if (text === '成立' || text.includes('成立')) {
    return text.includes('不成立') ? '不成立' : '成立';
  }
  if (text === '不成立' || text.includes('不成立')) {
    return '不成立';
  }
  return '不确定';
}

function resolvePhotoFileName(imageUri) {
  return `${imageUri}`.replace(/\\/g, '/').split('/').pop() || '';
}

function filterItems(rawItems, rawQuery, decisionFilter) {
  const query = `${rawQuery}`.trim().toLocaleLowerCase();
  return rawItems.filter((item) => {
    const judgement = normalizeJudgement(item.document.content.judgement);
    if (decisionFilter === '成立' && judgement !== '成立') {
      return false;
    }
    if (decisionFilter === '不确定' && judgement !== '不确定') {
      return false;
    }
    if (decisionFilter === '不成立' && judgement !== '不成立') {
      return false;
    }
    if (query.length === 0) {
      return true;
    }
    const searchable = [
      item.document.content.title,
      item.document.content.coreRelation,
      item.document.content.currentBlocker,
      resolvePhotoFileName(item.document.imageUri)
    ].join('\n').toLocaleLowerCase();
    return searchable.includes(query);
  });
}

if (filterItems(items, '窗边高光', 'all').length !== 1) {
  failed = true;
  console.error('Expected search to match coreRelation text.');
}

if (filterItems(items, 'IMG_1002', 'all').length !== 1) {
  failed = true;
  console.error('Expected search to match photo file name.');
}

if (filterItems(items, '', '不成立').length !== 1) {
  failed = true;
  console.error('Expected decision filter to isolate invalid reviews.');
}

if (failed) {
  process.exit(1);
}

console.log('review library v1.1: entry, search, decision filter, export hint verified');
