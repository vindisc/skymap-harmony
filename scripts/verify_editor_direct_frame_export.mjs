import fs from 'node:fs';

const editorSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');
const exportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardExportService.ets', 'utf8');
const framePreviewSource = fs.readFileSync('entry/src/main/ets/components/FrameTemplatePreview.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function requireIncludes(source, token, scope) {
  assert(source.includes(token), `${scope} missing token: ${token}`);
}

function forbidIncludes(source, token, scope) {
  assert(!source.includes(token), `${scope} must not contain: ${token}`);
}

[
  'private shouldUseDirectPhotoExport(): boolean',
  'this.currentTemplateLevel === TemplateLevel.L0_FRAME',
  'this.currentTemplateLevel === TemplateLevel.L1_META',
  'private async exportPhotoCard(): Promise<void>',
  'ReviewCardExportService.exportOriginalResolution(',
  "'导出到相册'",
  'FrameTemplatePreview({',
  '.justifyContent(FlexAlign.Start)',
  'CompactContentSection()'
].forEach((token) => requireIncludes(editorSource, token, 'EditorPage direct photo export'));

const exportStart = editorSource.indexOf('private async exportPhotoCard()');
const exportEnd = editorSource.indexOf('\n  private openPreview()', exportStart);
const directExportBody = exportStart >= 0 && exportEnd > exportStart
  ? editorSource.slice(exportStart, exportEnd)
  : '';
forbidIncludes(directExportBody, 'ReviewCardHistoryService', 'frame-only direct export');
forbidIncludes(directExportBody, 'markPendingPhotoReviewedQuietly', 'frame-only direct export');
forbidIncludes(directExportBody, 'openPreview()', 'frame-only direct export');

forbidIncludes(editorSource, '预览为屏幕缩略', 'EditorPage teaching copy');
forbidIncludes(editorSource, '导出保留原图分辨率', 'EditorPage teaching copy');
forbidIncludes(editorSource, '预览暂用复盘卡样式', 'EditorPage placeholder teaching copy');

[
  'resolveTemplate(document.config.templateId).level',
  'level === TemplateLevel.L0_FRAME',
  'L0CanvasComposer.compose({',
  'level === TemplateLevel.L1_META',
  'L1CanvasComposer.compose({',
  'L3CanvasComposer.compose({'
].forEach((token) => requireIncludes(exportServiceSource, token, 'ReviewCardExportService template dispatch'));

[
  'export struct FrameTemplatePreview',
  'frame.outerPaddingRatio',
  'frame.innerPaddingRatio',
  'frame.cornerRadiusRatio',
  'normalizeExifPayload(this.document.exif)',
  '.backgroundColor(this.getFrame().backgroundColorHex)'
].forEach((token) => requireIncludes(framePreviewSource, token, 'FrameTemplatePreview live preview'));

if (failed) {
  process.exit(1);
}

console.log('editor direct frame export verified: live L0/L1 preview, template-aware Canvas dispatch, and no review persistence');
