import fs from 'node:fs';

const feedbackSource = fs.readFileSync('entry/src/main/ets/services/ReviewFlowFeedback.ets', 'utf8');
const homeSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const editorSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');
const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const projectSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const mySource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const exportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardExportService.ets', 'utf8');
const jsonExportServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewJsonExportService.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

assert(feedbackSource.includes('ENABLE_RDB_DIAGNOSTICS_ENTRY: boolean = false'), 'Diagnostics entry should default to hidden.');
assert(feedbackSource.includes("REVIEW_FLOW_IMPORT_PENDING_TEXT: string = '正在打开照片…'"), 'Import pending copy must be centralized.');
assert(feedbackSource.includes("REVIEW_FLOW_SAVE_PENDING_TEXT: string = '保存中…'"), 'Save pending copy must be centralized.');
assert(feedbackSource.includes("REVIEW_FLOW_EXPORT_PENDING_TEXT: string = '导出中…'"), 'Export pending copy must be centralized.');
assert(feedbackSource.includes("REVIEW_FLOW_DELETE_CONFIRM_MESSAGE: string ="), 'Delete scope copy must be centralized.');

assert(homeSource.includes('REVIEW_FLOW_IMPORT_PENDING_TEXT'), 'Home page should use shared import pending copy.');
assert(homeSource.includes('REVIEW_FLOW_HOME_RELOAD_FAILED_TEXT'), 'Home page failure panel should use non-technical copy.');
assert(homeSource.includes('REVIEW_FLOW_HOME_COPY_ISSUE_TEXT'), 'Home page should offer copying issue info instead of diagnostics wording.');

assert(editorSource.includes('REVIEW_FLOW_SAVE_PENDING_TEXT'), 'Editor save button should use shared loading copy.');
assert(editorSource.includes('REVIEW_FLOW_SAVE_SUCCESS_TEXT'), 'Editor should use shared save success copy.');
assert(editorSource.includes('REVIEW_FLOW_SAVE_FAILED_TEXT'), 'Editor should use shared save failure copy.');

assert(previewSource.includes('@State isExportingReviewJson'), 'Preview should track JSON export pending state.');
assert(previewSource.includes('actionFeedbackText'), 'Preview should keep inline lightweight feedback text.');
assert(previewSource.includes('markExportedQuietly'), 'Preview should separate export success from exported-state writeback.');
assert(previewSource.includes('result.cancelled'), 'Preview should treat cancelled export separately from failed export.');
assert(previewSource.includes('this.isSaving || this.isExporting || this.isExportingReviewJson || this.isUploadingHomeStorage'), 'Preview busy gate should block repeated actions across save/export/upload.');
assert(previewSource.includes('ExportSheetAction(label: string, isDisabled: boolean'), 'Preview export sheet actions should support disabled state.');
assert(previewSource.includes('REVIEW_FLOW_EXPORT_SUCCESS_TEXT'), 'Preview should use shared export success copy.');
assert(previewSource.includes('REVIEW_FLOW_EXPORT_FAILED_TEXT'), 'Preview should use shared export failure copy.');

assert(projectSource.includes('REVIEW_FLOW_DELETE_CONFIRM_TITLE'), 'Project detail delete dialog should use shared confirm title.');
assert(projectSource.includes('REVIEW_FLOW_DELETE_CONFIRM_MESSAGE'), 'Project detail delete dialog should use shared scope copy.');
assert(projectSource.includes('REVIEW_FLOW_DELETE_PENDING_TEXT'), 'Project detail delete action should use shared pending copy.');
assert(projectSource.includes('REVIEW_FLOW_IMPORT_PENDING_TEXT'), 'Project detail create-first-review action should reuse import pending copy.');

assert(mySource.includes('if (ENABLE_RDB_DIAGNOSTICS_ENTRY) {'), 'My page diagnostics entry should be guarded by a debug-only flag.');
assert(mySource.includes("title: '开发诊断'"), 'My page should keep diagnostics code path for development use.');

assert(exportServiceSource.includes('cancelled: boolean;'), 'Image export result should expose a cancelled flag.');
assert(jsonExportServiceSource.includes('cancelled: boolean;'), 'Review JSON export result should expose a cancelled flag.');

if (failed) {
  process.exit(1);
}

console.log('interface feedback flow: shared copy, busy states, cancel semantics, and debug-only diagnostics verified');
