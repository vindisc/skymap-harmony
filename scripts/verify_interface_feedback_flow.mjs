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
assert(feedbackSource.includes("REVIEW_FLOW_IMAGE_EXPORT_SUCCESS_TEXT: string = '已保存到图库最近项目'"), 'Image export success copy must say where the user can find the result.');
assert(!feedbackSource.includes('REVIEW_FLOW_DELETE_CONFIRM_'), 'Delete confirmation copy must stay retired.');

assert(homeSource.includes('REVIEW_FLOW_IMPORT_PENDING_TEXT'), 'Home page should use shared import pending copy.');
assert(homeSource.includes('REVIEW_FLOW_HOME_RELOAD_FAILED_TEXT'), 'Home page failure panel should use non-technical copy.');
assert(homeSource.includes('REVIEW_FLOW_HOME_COPY_ISSUE_TEXT'), 'Home page should offer copying issue info instead of diagnostics wording.');

assert(editorSource.includes('REVIEW_FLOW_SAVE_PENDING_TEXT'), 'Editor save button should use shared loading copy.');
assert(editorSource.includes('REVIEW_FLOW_SAVE_SUCCESS_TEXT'), 'Editor should use shared save success copy.');
assert(editorSource.includes('REVIEW_FLOW_SAVE_FAILED_TEXT'), 'Editor should use shared save failure copy.');

assert(previewSource.includes('@State exportState: ExportState = ExportState.IDLE;'), 'Preview should track export state centrally.');
assert(previewSource.includes('floatingStatusMessage'), 'Preview should keep floating status message state.');
assert(previewSource.includes('FloatingStatusBanner({'), 'Preview should render floating feedback via the shared banner component.');
assert(previewSource.includes('markExportedQuietly'), 'Preview should separate export success from exported-state writeback.');
assert(previewSource.includes('result.cancelled'), 'Preview should treat cancelled export separately from failed export.');
assert(previewSource.includes('this.isSaving ||') && previewSource.includes('this.exportState !== ExportState.IDLE'), 'Preview busy gate should block repeated actions across save/export/bundle export.');
assert(previewSource.includes('ExportSheetAction(label: string, description: string, isDisabled: boolean'), 'Preview export sheet actions should support descriptions and disabled state.');
assert(previewSource.includes("this.ActionButton(this.exportState === ExportState.IMAGE ? REVIEW_FLOW_EXPORT_PENDING_TEXT : '导出图片', true, this.isActionBusy(), () => {"), 'Preview primary action should export the image directly.');
assert(previewSource.includes('this.MoreActionButton(this.isActionBusy(), () => {'), 'Preview should keep secondary export choices behind a More action.');
assert(previewSource.includes('REVIEW_FLOW_IMAGE_EXPORT_SUCCESS_TEXT'), 'Preview image export should use user-visible photo-library success copy.');
assert(previewSource.includes('REVIEW_FLOW_EXPORT_SUCCESS_TEXT'), 'Preview should use shared export success copy.');
assert(previewSource.includes('REVIEW_FLOW_EXPORT_FAILED_TEXT'), 'Preview should use shared export failure copy.');
assert(previewSource.includes('@State pressedActionKey: string = \'\';'), 'Preview actions should keep shared pressed state.');
assert(previewSource.includes('private updatePressedAction(event: TouchEvent, key: string, isDisabled: boolean): void'), 'Preview actions should share touch feedback handling.');
assert(previewSource.includes('.shadow(isDisabled ? ElevationTokens.none : (this.isPressed(label) ? ElevationTokens.subtle : ElevationTokens.low))'),
  'Preview floating action bar should keep lightweight token-based button elevation.');
assert(previewSource.includes('.scale({ x: this.isPressed(label) ? MotionTokens.scalePressed : 1'), 'Preview toolbar buttons should scale on press.');
assert(previewSource.includes('PressReactive({') && previewSource.includes("intensity: 'firm'"),
  'Preview export sheet rows should use shared firm press feedback.');
assert(previewSource.includes('.animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })'), 'Preview press feedback should use motion tokens.');

assert(projectSource.includes('this.deleteHistory(document);'), 'Project detail delete action should execute directly.');
assert(!projectSource.includes('confirmDeleteHistory'), 'Project detail delete action must not show a second confirmation.');
assert(projectSource.includes('MotionTokens.shatterDurationMs'), 'Project detail delete action should wait for the visible removal animation.');
assert(projectSource.includes('REVIEW_FLOW_IMPORT_PENDING_TEXT'), 'Project detail create-first-review action should reuse import pending copy.');

assert(mySource.includes('if (ENABLE_RDB_DIAGNOSTICS_ENTRY) {'), 'My page diagnostics entry should be guarded by a debug-only flag.');
assert(mySource.includes("Text('开发诊断')"), 'My page should keep diagnostics code path for development use.');

assert(exportServiceSource.includes('cancelled: boolean;'), 'Image export result should expose a cancelled flag.');
assert(jsonExportServiceSource.includes('cancelled: boolean;'), 'Review JSON export result should expose a cancelled flag.');

if (failed) {
  process.exit(1);
}

console.log('interface feedback flow: shared copy, busy states, cancel semantics, and debug-only diagnostics verified');
