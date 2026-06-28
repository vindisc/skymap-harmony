import fs from 'node:fs';

const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const exportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewJsonExportService.ets', 'utf8');

let failed = false;

const requiredPreviewStrings = [
  "this.ExportSheetAction(this.isExportingReviewJson ? REVIEW_FLOW_EXPORT_PENDING_TEXT : '导出 review.json'",
  'private async exportReviewJson(): Promise<void>',
  'await this.markExportedQuietly(result.path)',
  'this.actionFeedbackText = result.message.length > 0 ? result.message : REVIEW_FLOW_EXPORT_SUCCESS_TEXT;',
  'this.actionFeedbackText = result.message;',
  'this.actionFeedbackText = result.message.length > 0 ? result.message : REVIEW_FLOW_EXPORT_FAILED_TEXT;'
];

for (const token of requiredPreviewStrings) {
  if (!previewPageSource.includes(token)) {
    failed = true;
    console.error(`PreviewPage missing review.json export token: ${token}`);
  }
}

const requiredServiceStrings = [
  "const REVIEW_JSON_EXPORT_DIR_NAME: string = 'review_exchange';",
  "const REVIEW_JSON_EXTENSION: string = 'review.json';",
  'stringifyReviewCardExchangeSchemaV1(document, reviewerName)',
  'new picker.DocumentViewPicker(context)',
  "fileSuffixChoices: ['JSON 文件|json']",
  '已导出 ${fileName}',
  '未选择保存位置，已保留备份',
  'review.json 导出失败，请稍后重试'
];

for (const token of requiredServiceStrings) {
  if (!exportServiceSource.includes(token)) {
    failed = true;
    console.error(`ReviewJsonExportService missing token: ${token}`);
  }
}

function resolveExportFileName(sourceFileName, updatedAt) {
  const stem = (sourceFileName
    .replace(/\.[^.]+$/, '')
    .replace(/[^0-9A-Za-z\u4E00-\u9FFF._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^[-._]+|[-._]+$/g, '')
    .slice(0, 48) || 'review-1718260000000');
  const date = new Date(updatedAt);
  const pad = (value) => `${value}`.padStart(2, '0');
  const timestamp = `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}-${pad(date.getHours())}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
  return `${timestamp}-${stem}.review.json`;
}

const namedFile = resolveExportFileName('IMG_2048.JPG', Date.UTC(2026, 5, 13, 12, 30, 45));
if (namedFile !== '20260613-203045-IMG_2048.review.json') {
  failed = true;
  console.error(`Unexpected named review.json file: ${namedFile}`);
}

const fallbackFile = resolveExportFileName('', Date.UTC(2026, 5, 13, 12, 30, 45));
if (fallbackFile !== '20260613-203045-review-1718260000000.review.json') {
  failed = true;
  console.error(`Unexpected fallback review.json file: ${fallbackFile}`);
}

if (exportServiceSource.includes("sourceFileName.length > 0 ? sanitizeFileStem(sourceFileName) : 'review'")) {
  failed = true;
  console.error('ReviewJsonExportService must not generate the generic review.review.json fallback name.');
}

if (failed) {
  process.exit(1);
}

console.log(`review json export: ${namedFile}`);
