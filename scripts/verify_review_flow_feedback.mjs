import fs from 'node:fs';

const files = {
  home: fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8'),
  editor: fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8'),
  preview: fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8'),
  library: fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8'),
  stats: fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8'),
  my: fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8'),
  photoPicker: fs.readFileSync('entry/src/main/ets/services/PhotoPickerService.ets', 'utf8'),
  photoBlock: fs.readFileSync('entry/src/main/ets/components/ReviewPhotoBlock.ets', 'utf8')
};

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

assert(files.home.includes('isPickingPhoto'), 'Home import must keep a picking state.');
assert(files.home.includes('打开相册中…'), 'Home import button should show lightweight loading copy.');
assert(files.photoPicker.includes('照片导入失败，请重新选择'), 'Import failure copy must be understandable.');

assert(files.editor.includes('@State isSaving'), 'Editor must keep a saving state.');
assert(files.editor.includes('保存中…'), 'Editor save button should show loading copy.');
assert(files.editor.includes('复盘已保存'), 'Editor save success toast must be present.');
assert(files.editor.includes('保存失败，请稍后重试'), 'Editor save failure toast must be present.');
assert(files.editor.includes('isDisabled: this.isSaving'), 'Editor save button must disable while saving.');

assert(files.preview.includes('导出中…'), 'Preview export button should show loading copy.');
assert(files.preview.includes('导出完成'), 'Preview export success toast must be present.');
assert(files.preview.includes('导出失败，请重试'), 'Preview export failure toast must be present.');
assert(files.preview.includes('ReviewCardHistoryService.markExported'), 'Preview export must mark exported state.');

assert(files.library.includes('删除这条复盘？'), 'Delete dialog title must match deletion scope.');
assert(
  files.library.includes('只会删除复盘记录和应用内备份，不会删除原始照片或你已经导出的图片。'),
  'Delete dialog must explain original photos and exported images are untouched.'
);
assert(files.library.includes('@State deletingReviewKey'), 'Library delete must keep a busy key.');
assert(files.library.includes('复盘已删除'), 'Library delete success toast must be present.');
assert(files.library.includes('删除失败，请重试'), 'Library delete failure toast must be present.');
assert(files.library.includes('没有找到匹配的复盘'), 'Search no-result empty state must remain present.');
assert(files.library.includes("Button('×')"), 'Search field must expose a clear button.');
assert(files.library.includes('复盘库暂时无法刷新'), 'Library load failure state must be visible.');

assert(files.photoBlock.includes('照片暂不可见'), 'Thumbnail failure state should be lightweight.');
assert(files.photoBlock.includes('可稍后重试'), 'Thumbnail failure helper copy should be gentle.');

assert(files.stats.includes("@Prop @Watch('refreshStatsData') refreshToken"), 'Stats must still refresh from library token.');
assert(files.stats.includes('统计暂时无法刷新'), 'Stats should expose a load failure state.');
assert(files.stats.includes('最近 30 天'), 'Stats should replace placeholder chips with recent 30 days feedback.');
assert(files.stats.includes('判断分布'), 'Stats should show lightweight decision distribution feedback.');
assert(files.stats.includes('最近卡点'), 'Stats should show recent blocker feedback.');
assert(!files.stats.includes("Text('当前记录')"), 'Stats must remove the old 当前记录 placeholder section.');

assert(files.my.includes("@Prop @Watch('refreshPageData') refreshToken"), 'My page must still refresh from shell token.');
assert(files.my.includes('复盘统计暂时无法刷新'), 'My page should expose a load failure state.');
assert(files.my.includes('运行开发诊断？'), 'Developer diagnostics must be protected by confirmation.');

if (failed) {
  process.exit(1);
}

console.log('review flow feedback: import/save/export/delete/search/loading states verified');
