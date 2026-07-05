import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const scanRoots = [
  'entry/src/main/ets/pages',
  'entry/src/main/ets/components',
  'entry/src/main/ets/services'
];

const forbiddenCopy = [
  '继续训练你的摄影判断。',
  '看见积累，继续下一次复盘。',
  '开始第一条复盘后',
  '管理复盘人、家庭存储和版本信息',
  '配置 SMB 地址、共享目录和登录凭据',
  '查看家庭存储状态，测试连接并进入同步配置。',
  '现在可直接发送给 Mac 导入',
  '搜索复盘，查看导入后的历史记录',
  '当前显示',
  '可先创建第一条复盘',
  '试试换一个关键词',
  '摄影复盘 Beta 用户',
  '请重新选择照片',
  '照片信息暂不可显示，可继续填写。',
  '上传到家庭存储中...',
  '导出复盘图片中...',
  '账户与同步',
  '搜索与回看',
  '按照片、判断和卡点回看你的复盘记录。',
  '完成复盘后，这里会展示你的判断变化。',
  '复盘身份、存储同步和应用状态。',
  '影响新建复盘、导出和家庭存储连接。'
];

const requiredCopy = [
  ['entry/src/main/ets/pages/HomePage.ets', "label: this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '导入照片，开始复盘'"],
  ['entry/src/main/ets/pages/MyPage.ets', "AppPageHeader({\n            title: '我的'\n          })"],
  ['entry/src/main/ets/pages/ProjectDetailPage.ets', "placeholder: '标题、关系、卡点、文件名'"],
  ['entry/src/main/ets/pages/ProjectDetailPage.ets', "this.HeaderRow()"],
  ['entry/src/main/ets/pages/ProjectDetailPage.ets', ".height(AppMetrics.filterChipHeight)"],
  ['entry/src/main/ets/pages/ProjectDetailPage.ets', ".constraintSize({ minWidth: value === 'all' ? 60 : 72 })"],
  ['entry/src/main/ets/pages/ProjectDetailPage.ets', ".fontSize(13)"],
  ['entry/src/main/ets/pages/PreviewPage.ets', ".height(AppMetrics.toolbarButtonHeight)"],
  ['entry/src/main/ets/pages/PreviewPage.ets', "this.ExportSheetAction('复制复盘数据', '复制当前复盘的文本数据。', this.isActionBusy(), () => {"],
  ['entry/src/main/ets/pages/ReviewSettingsPage.ets', "Text('连接与凭据')"],
  ['entry/src/main/ets/components/ReviewPhotoBlock.ets', "Text(hasDisplayableImageUri(this.imageUri) && this.loadFailed ? '照片暂不可见' : '照片')"]
];

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

function collectFiles(dir, targetFiles) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectFiles(fullPath, targetFiles);
      continue;
    }
    if (entry.isFile() && entry.name.endsWith('.ets')) {
      targetFiles.push(fullPath);
    }
  }
}

const sourceFiles = [];
for (const scanRoot of scanRoots) {
  collectFiles(path.join(root, scanRoot), sourceFiles);
}

for (const filePath of sourceFiles) {
  const source = fs.readFileSync(filePath, 'utf8');
  for (const copy of forbiddenCopy) {
    if (source.includes(copy)) {
      fail(`Forbidden explanatory copy "${copy}" in ${path.relative(root, filePath)}`);
    }
  }
}

for (const [filePath, marker] of requiredCopy) {
  const source = fs.readFileSync(filePath, 'utf8');
  if (!source.includes(marker)) {
    fail(`Expected compact copy marker missing in ${filePath}: ${marker}`);
  }
}

if (failed) {
  process.exit(1);
}

console.log('ui copy density verified: explanatory copy removed, compact labels present');
