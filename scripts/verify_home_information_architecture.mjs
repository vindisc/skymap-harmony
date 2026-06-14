import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const syncCenterPageSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');
const appRouterSource = fs.readFileSync('entry/src/main/ets/app/AppRouter.ets', 'utf8');
const mainPagesSource = fs.readFileSync('entry/src/main/resources/base/profile/main_pages.json', 'utf8');

let failed = false;

if (homePageSource.includes("Text('最近一次')")) {
  failed = true;
  console.error('HomePage still renders 独立最近一次模块.');
}

if (!homePageSource.includes("this.HomeEntryCard(\n          '同步中心'")) {
  failed = true;
  console.error('HomePage missing 同步中心 entry.');
}

if (!previewPageSource.includes("this.ActionButton('编辑', false, this.isActionBusy(), () => {")) {
  failed = true;
  console.error('PreviewPage must keep 编辑 as a top-level action.');
}

if (!previewPageSource.includes("this.ActionButton(this.isExporting ? '导出中' : '导出', true, this.isActionBusy(), () => {")) {
  failed = true;
  console.error('PreviewPage must keep 导出 as the single top-level export action.');
}

const disallowedTopLevelActions = [
  "this.ActionButton('导出 review.json'",
  "this.ActionButton('复制复盘数据'",
  "this.ActionButton(this.isUploadingHomeStorage ? '上传中' : '上传到家庭存储'"
];

for (const marker of disallowedTopLevelActions) {
  if (previewPageSource.includes(marker)) {
    failed = true;
    console.error(`PreviewPage still exposes deprecated top-level action: ${marker}`);
  }
}

const requiredExportSheetActions = [
  "this.ExportSheetAction(this.isExporting ? '导出图片中...' : '导出图片'",
  "this.ExportSheetAction('导出 review.json'",
  "this.ExportSheetAction(this.isUploadingHomeStorage ? '上传到家庭存储中...' : '上传到家庭存储'",
  "this.ExportSheetAction('复制复盘数据'"
];

for (const marker of requiredExportSheetActions) {
  if (!previewPageSource.includes(marker)) {
    failed = true;
    console.error(`PreviewPage export sheet missing action: ${marker}`);
  }
}

if (!syncCenterPageSource.includes("title: '同步中心'")) {
  failed = true;
  console.error('SyncCenterPage title is missing.');
}

if (!syncCenterPageSource.includes("Button(this.isTesting ? '测试中...' : '测试连接')")) {
  failed = true;
  console.error('SyncCenterPage must provide 测试连接.');
}

if (!syncCenterPageSource.includes("label: '进入配置'")) {
  failed = true;
  console.error('SyncCenterPage must provide 进入配置.');
}

if (!appRouterSource.includes("export const SYNC_CENTER_PAGE: string = 'pages/SyncCenterPage';")) {
  failed = true;
  console.error('AppRouter missing SyncCenterPage route.');
}

if (!mainPagesSource.includes('"pages/SyncCenterPage"')) {
  failed = true;
  console.error('main_pages.json missing SyncCenterPage registration.');
}

if (failed) {
  process.exit(1);
}

console.log('home information architecture verified: sync center exists, latest module removed, export entry consolidated');
