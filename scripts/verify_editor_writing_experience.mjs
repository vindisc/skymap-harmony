import fs from 'node:fs';

const editorPageSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');
const reviewInputFormSource = fs.readFileSync('entry/src/main/ets/components/ReviewInputForm.ets', 'utf8');
const reviewTextMetricsSource = fs.readFileSync('entry/src/main/ets/utils/ReviewTextMetrics.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function assertIncludes(source, marker, message) {
  assert(source.includes(marker), message);
}

function assertNotIncludes(source, marker, message) {
  assert(!source.includes(marker), message);
}

assertNotIncludes(editorPageSource, "Text('写复盘')", 'EditorPage must not reserve first-screen space for the 写复盘 title.');
assertNotIncludes(editorPageSource, 'EDITOR_PHOTO_TITLE_HEIGHT', 'EditorPage photo header height must not include a hidden title slot.');
assertNotIncludes(editorPageSource, 'EDITOR_PHOTO_TITLE_GAP', 'EditorPage photo header must not keep the old title/image gap.');
assertIncludes(editorPageSource, 'const EDITOR_PHOTO_HEADER_TOP_PADDING: number = 4;', 'EditorPage should keep the photo header tight at the top.');
assertIncludes(editorPageSource, 'const EDITOR_PHOTO_HEADER_BOTTOM_PADDING: number = 10;', 'EditorPage should keep a compact photo-to-form gap.');
assertIncludes(editorPageSource, 'const EDITOR_PHOTO_VIEWPORT_RATIO: number = 0.30;', 'EditorPage photo should leave more first-screen writing room.');
assertIncludes(editorPageSource, 'const EDITOR_KEYBOARD_VISIBLE_RESERVE: number = 54;', 'EditorPage keyboard math must reserve visible caret breathing room.');
assertIncludes(editorPageSource, 'const EDITOR_KEYBOARD_SCROLL_DELAY: number = 96;', 'EditorPage first-focus keyboard scroll delay must stay under 120ms.');
assertIncludes(editorPageSource, 'const EDITOR_KEYBOARD_HEIGHT_SCROLL_DELAY: number = 48;', 'EditorPage keyboard-height follow-up scroll delay must stay short.');
assertIncludes(editorPageSource, 'enum EditorFieldScrollIntent', 'EditorPage must distinguish first focus from caret-follow scrolling.');
assertIncludes(editorPageSource, 'EditorFieldScrollIntent.START', 'EditorPage must align a focused field start below the photo.');
assertIncludes(editorPageSource, 'EditorFieldScrollIntent.CARET', 'EditorPage must follow long-text growth while typing.');
assertIncludes(editorPageSource, 'this.scrollFieldIntoView(field, EditorFieldScrollIntent.START);', 'EditorPage must predictively scroll as soon as a field receives focus.');
assertIncludes(editorPageSource, 'onFieldChange: (field: string) => {', 'EditorPage must respond when a text field grows.');
assertIncludes(editorPageSource, 'private measuredFieldHeights: Map<string, number> = new Map();',
  'EditorPage must track measured field heights instead of relying only on estimates.');
assertIncludes(editorPageSource, 'private handleFieldHeightChange(field: string, height: number): void {',
  'EditorPage must react when a field actually changes height.');
assertIncludes(editorPageSource, 'this.measuredFieldHeights.set(field, height);',
  'EditorPage must persist measured field heights for scroll math.');
assertIncludes(editorPageSource, 'previousHeight <= 0 || this.focusedField !== field || !this.isKeyboardActive()',
  'EditorPage must ignore initial measurements and only follow the focused field while typing.');
assertIncludes(editorPageSource, 'this.scheduleFieldIntoView(field, EDITOR_KEYBOARD_HEIGHT_SCROLL_DELAY, EditorFieldScrollIntent.CARET);',
  'EditorPage must keep the caret area visible when multiline fields actually grow.');
assertIncludes(editorPageSource, 'estimateReviewTextLineCount(', 'EditorPage scroll math must use the shared review text metric.');
assertIncludes(editorPageSource, 'estimateReviewTextWrapUnitsPerLine(', 'EditorPage fallback height math must use the shared wrap-width metric.');
assertIncludes(editorPageSource, "if (field === 'judgement') {", 'EditorPage must keep the select field height distinct from textarea math.');
assertIncludes(editorPageSource, 'AppMetrics.controlHeight', 'EditorPage judgement fallback height must use the shared control height.');
assertIncludes(editorPageSource, "import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';",
  'EditorPage must use shared elevation and motion tokens.');
assertIncludes(editorPageSource, 'duration: MotionTokens.durationStandard',
  'EditorPage focus scroll animation must use the shared motion duration.');
assertIncludes(editorPageSource, 'curve: MotionTokens.curveDecelerate',
  'EditorPage focus scroll animation must use the shared motion curve.');
assertIncludes(editorPageSource, '.shadow(ElevationTokens.medium)',
  'EditorPage photo header must have production-level visual separation.');
assertIncludes(editorPageSource, '.shadow(ElevationTokens.subtle)',
  'EditorPage save action area must keep a subtle elevated layer.');
assertIncludes(editorPageSource, '.borderRadius(AppMetrics.panelRadius)',
  'EditorPage save action area must use the shared panel radius.');

assertIncludes(reviewInputFormSource, 'const REVIEW_FIELD_LABEL_GAP: number = AppMetrics.space8;', 'ReviewInputForm labels must sit closer to inputs.');
assertIncludes(reviewInputFormSource, 'const REVIEW_FORM_FIELD_GAP: number = AppMetrics.space16;', 'ReviewInputForm field gaps must provide production-level breathing room.');
assertIncludes(reviewInputFormSource, 'estimateReviewTextLineCount(', 'ReviewInputForm TextArea height must use the shared review text metric.');
assertIncludes(reviewInputFormSource, '.height(resolveReviewTextAreaHeight(this.value, this.defaultLines, this.wrapUnitsPerLine))',
  'ReviewInputForm TextArea height must be derived from the shared wrap-width estimate.');
assertIncludes(reviewInputFormSource, '.style(TextContentStyle.DEFAULT)', 'ReviewInputForm TextArea must avoid inline-mode internal scrolling.');
assertIncludes(reviewInputFormSource, '.barState(BarState.Off)', 'ReviewInputForm TextArea must not show its own scrollbar.');
assertIncludes(reviewInputFormSource, '.enableKeyboardOnFocus(true)', 'ReviewInputForm inputs must reliably summon the keyboard on focus.');
assertIncludes(reviewInputFormSource, '.caretColor(AppColors.primary)', 'ReviewInputForm caret must use the visible primary color.');
assertIncludes(reviewInputFormSource, '.caretStyle({ width: 2, color: AppColors.primary })', 'ReviewInputForm TextArea caret must be visibly sized.');
assertIncludes(reviewInputFormSource, 'estimateReviewTextWrapUnitsPerLine(300, PRIMARY_FIELD_INPUT_SIZE)',
  'ReviewInputForm must keep a shared wrap-width fallback for textarea sizing.');
assertIncludes(reviewInputFormSource, 'const REVIEW_TEXTAREA_VERTICAL_INSET: number = 14;', 'ReviewInputForm TextArea padding should stay symmetric.');
assertIncludes(reviewInputFormSource, 'top: REVIEW_TEXTAREA_VERTICAL_INSET,', 'ReviewInputForm TextArea should keep the top inset explicit.');
assertIncludes(reviewInputFormSource, 'bottom: REVIEW_TEXTAREA_VERTICAL_INSET', 'ReviewInputForm TextArea should keep the bottom inset explicit.');
assertIncludes(reviewInputFormSource, '@State focusedField: string = \'\';', 'ReviewInputForm must own visible focus state.');
assertIncludes(reviewInputFormSource, '.shadow(this.isFocused ? ElevationTokens.focus : ElevationTokens.none)',
  'ReviewInputForm multiline fields must show focus elevation.');
assertIncludes(reviewInputFormSource, '.animation({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate })',
  'ReviewInputForm select focus changes must animate quickly.');
assertIncludes(reviewInputFormSource, 'this.onFieldChange();', 'ReviewInputForm multiline changes must notify the editor page.');
assertIncludes(reviewInputFormSource, "this.onFieldChange('title');", 'ReviewInputForm title changes must notify the editor page.');
assertIncludes(reviewInputFormSource, '.onAreaChange((oldValue: Area, newValue: Area) => {', 'ReviewInputForm fields must report real rendered height changes.');
assertIncludes(reviewInputFormSource, "this.onFieldHeightChange(this.fieldKey, nextHeight);", 'ReviewInputForm textarea fields must surface measured heights.');
assertIncludes(reviewInputFormSource, "this.onFieldHeightChange('judgement', nextHeight);", 'ReviewInputForm select field must surface measured height.');
assertIncludes(reviewInputFormSource, "this.onFieldHeightChange('title', nextHeight);", 'ReviewInputForm title field must surface measured height.');
assertNotIncludes(reviewInputFormSource, 'Column({ space: AppMetrics.space16 }) {\n      this.FieldLabel(label, labelSize)',
  'ReviewInputForm label-to-input gap must not regress to 16vp.');
assertIncludes(reviewTextMetricsSource, 'return Math.max(8, (safeContentWidth / safeFontSize) * 0.9);',
  'Review text metric helper must keep the tighter wrap-width factor that matches the multiline editor.');
assertIncludes(fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8'), '.backgroundColor(AppColors.surfaceMuted)',
  'PhotoWritingHero fixed frame must not blend into the page background.');

if (failed) {
  process.exit(1);
}

console.log('editor writing experience verified: compact photo header, tighter form rhythm, keyboard-aware focus, no TextArea inner scrollbar');
