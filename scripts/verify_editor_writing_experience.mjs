import fs from 'node:fs';

const editorPageSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');
const reviewInputFormSource = fs.readFileSync('entry/src/main/ets/components/ReviewInputForm.ets', 'utf8');

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
assertIncludes(editorPageSource, 'enum EditorFieldScrollIntent', 'EditorPage must distinguish first focus from caret-follow scrolling.');
assertIncludes(editorPageSource, 'EditorFieldScrollIntent.START', 'EditorPage must align a focused field start below the photo.');
assertIncludes(editorPageSource, 'EditorFieldScrollIntent.CARET', 'EditorPage must follow long-text growth while typing.');
assertIncludes(editorPageSource, 'onFieldChange: (field: string) => {', 'EditorPage must respond when a text field grows.');
assertIncludes(editorPageSource, 'this.scheduleFieldIntoView(field, EDITOR_KEYBOARD_HEIGHT_SCROLL_DELAY, EditorFieldScrollIntent.CARET);',
  'EditorPage must keep the caret area visible as multiline fields expand.');

assertIncludes(reviewInputFormSource, 'const REVIEW_FIELD_LABEL_GAP: number = AppMetrics.space8;', 'ReviewInputForm labels must sit closer to inputs.');
assertIncludes(reviewInputFormSource, 'const REVIEW_FORM_FIELD_GAP: number = AppMetrics.cardGap;', 'ReviewInputForm field gaps must stay compact.');
assertIncludes(reviewInputFormSource, '.style(TextContentStyle.DEFAULT)', 'ReviewInputForm TextArea must avoid inline-mode internal scrolling.');
assertIncludes(reviewInputFormSource, '.barState(BarState.Off)', 'ReviewInputForm TextArea must not show its own scrollbar.');
assertIncludes(reviewInputFormSource, '.enableKeyboardOnFocus(true)', 'ReviewInputForm inputs must reliably summon the keyboard on focus.');
assertIncludes(reviewInputFormSource, '.caretColor(AppColors.primary)', 'ReviewInputForm caret must use the visible primary color.');
assertIncludes(reviewInputFormSource, '.caretStyle({ width: 2, color: AppColors.primary })', 'ReviewInputForm TextArea caret must be visibly sized.');
assertIncludes(reviewInputFormSource, '.padding({ left: AppMetrics.space16, right: AppMetrics.space16, top: 12, bottom: 12 })',
  'ReviewInputForm TextArea vertical padding must match the editor height estimate.');
assertIncludes(reviewInputFormSource, 'this.onFieldChange(fieldKey);', 'ReviewInputForm multiline changes must notify the editor page.');
assertIncludes(reviewInputFormSource, "this.onFieldChange('title');", 'ReviewInputForm title changes must notify the editor page.');
assertNotIncludes(reviewInputFormSource, 'Column({ space: AppMetrics.space16 }) {\n      this.FieldLabel(label, labelSize)',
  'ReviewInputForm label-to-input gap must not regress to 16vp.');

if (failed) {
  process.exit(1);
}

console.log('editor writing experience verified: compact photo header, tighter form rhythm, keyboard-aware focus, no TextArea inner scrollbar');
