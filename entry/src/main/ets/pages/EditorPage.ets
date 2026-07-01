import common from '@ohos.app.ability.common';
import display from '@ohos.display';
import window from '@ohos.window';
import { KeyboardAvoidMode } from '@ohos.arkui.UIContext';
import { PREVIEW_PAGE } from '../app/AppRouter';
import {
  createDefaultReviewCardDocument,
  DEFAULT_REVIEW_TITLE,
  normalizeReviewJudgement,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { ReviewInputForm } from '../components/ReviewInputForm';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import {
  REVIEW_FLOW_SAVE_FAILED_TEXT,
  REVIEW_FLOW_SAVE_PENDING_TEXT,
  REVIEW_FLOW_SAVE_SUCCESS_TEXT
} from '../services/ReviewFlowFeedback';
import { AppColors, AppMetrics, AppTypography, PhotoWritingHero, PrimaryButton } from '../components/AppDesign';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';
import { estimateReviewTextLineCount } from '../utils/ReviewTextMetrics';
import { ToastService } from '../services/ToastService';

const EDITOR_PAGE_HORIZONTAL_PADDING: number = AppMetrics.pagePadding;
const EDITOR_CONTENT_FALLBACK_WIDTH: number = 360;
const EDITOR_VIEWPORT_FALLBACK_HEIGHT: number = 720;
const EDITOR_FORM_BOTTOM_PADDING: number = 34;
const EDITOR_KEYBOARD_BOTTOM_PADDING: number = 42;
const EDITOR_FIELD_SAFE_TOP_GAP: number = 6;
const EDITOR_FIELD_SAFE_BOTTOM_GAP: number = 34;
const EDITOR_KEYBOARD_VISIBLE_RESERVE: number = 54;
const EDITOR_KEYBOARD_SCROLL_DELAY: number = 96;
const EDITOR_KEYBOARD_HEIGHT_SCROLL_DELAY: number = 48;
const EDITOR_KEYBOARD_HEIGHT_CHANGE_THRESHOLD: number = 10;
const EDITOR_PHOTO_HEADER_TOP_PADDING: number = 4;
const EDITOR_PHOTO_HEADER_BOTTOM_PADDING: number = 10;
const EDITOR_PHOTO_MIN_HEIGHT: number = 172;
const EDITOR_PHOTO_MAX_HEIGHT: number = 286;
const EDITOR_PHOTO_VIEWPORT_RATIO: number = 0.30;
const EDITOR_TITLE_FIELD_HEIGHT: number = AppTypography.inputLabelLineHeight + AppMetrics.space8 + AppMetrics.controlHeight;
const EDITOR_FIELD_LABEL_HEIGHT: number = AppTypography.inputLabelLineHeight;
const EDITOR_FIELD_LABEL_GAP: number = 8;
const EDITOR_FIELD_GAP: number = AppMetrics.cardGap;
const EDITOR_TEXTAREA_LINE_HEIGHT: number = AppTypography.inputTextLineHeight;
const EDITOR_TEXTAREA_VERTICAL_PADDING: number = 28;
const EDITOR_TEXTAREA_APPROX_CHARS_PER_LINE: number = 10;

interface EditorPhotoFrameSize {
  width: number;
  height: number;
}

enum EditorFieldScrollIntent {
  START = 'start',
  CARET = 'caret'
}

@Entry
@Component
struct EditorPage {
  private document: ReviewCardDocument = createDefaultReviewCardDocument();
  private editorScroller: Scroller = new Scroller();
  private hostWindow: window.Window | null = null;
  private keyboardHeightChangeCallback: ((height: number) => void) | null = null;
  private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;
  private isPageAlive: boolean = false;
  private scrollRequestId: number = 0;
  private lastKeyboardHeight: number = 0;
  private scheduledScrollField: string = '';
  private scheduledScrollIntent: EditorFieldScrollIntent = EditorFieldScrollIntent.START;
  private shouldDiscardChanges: boolean = false;
  @State title: string = DEFAULT_REVIEW_TITLE;
  @State visualFocus: string = '';
  @State focusReason: string = '';
  @State visualPath: string = '';
  @State visibleFacts: string = '';
  @State coreRelation: string = '';
  @State judgement: string = '';
  @State extendedUnderstanding: string = '';
  @State currentBlocker: string = '';
  @State focusedField: string = '';
  @State imageUri: string = '';
  @State imageWidth: number = 1600;
  @State imageHeight: number = 1000;
  @State imageSizeFallbackUsed: boolean = false;
  @State viewportWidth: number = EDITOR_CONTENT_FALLBACK_WIDTH + EDITOR_PAGE_HORIZONTAL_PADDING * 2;
  @State viewportHeight: number = EDITOR_VIEWPORT_FALLBACK_HEIGHT;
  @State keyboardHeight: number = 0;
  @State isSaving: boolean = false;
  @State isDirty: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.isPageAlive = true;
    this.captureStableViewportSize();
    this.disableSystemKeyboardAvoidance();
    this.registerKeyboardHeightObserver();
    this.document = ReviewCardStore.getCurrentDocument();
    this.imageUri = this.document.imageUri;
    this.imageWidth = this.document.imageWidth;
    this.imageHeight = this.document.imageHeight;
    this.imageSizeFallbackUsed = this.document.imageSizeFallbackUsed;
    this.title = this.document.content.title;
    this.visualFocus = this.document.content.visualFocus;
    this.focusReason = this.document.content.focusReason;
    this.visualPath = this.document.content.visualPath;
    this.visibleFacts = this.document.content.visibleFacts;
    this.coreRelation = this.document.content.coreRelation;
    this.judgement = normalizeReviewJudgement(this.document.content.judgement);
    this.extendedUnderstanding = this.document.content.extendedUnderstanding;
    this.currentBlocker = this.document.content.currentBlocker;
    this.isDirty = false;
    this.shouldDiscardChanges = false;
  }

  private disableSystemKeyboardAvoidance(): void {
    try {
      this.previousKeyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode();
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
    } catch (error) {
      this.previousKeyboardAvoidMode = KeyboardAvoidMode.OFFSET;
    }
  }

  private restoreSystemKeyboardAvoidance(): void {
    try {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode);
    } catch (error) {
    }
  }

  private registerKeyboardHeightObserver(): void {
    this.keyboardHeightChangeCallback = (height: number): void => {
      const nextKeyboardHeight: number = Math.max(0, px2vp(height));
      if (Math.abs(nextKeyboardHeight - this.lastKeyboardHeight) <= EDITOR_KEYBOARD_HEIGHT_CHANGE_THRESHOLD) {
        return;
      }

      this.lastKeyboardHeight = nextKeyboardHeight;
      this.keyboardHeight = nextKeyboardHeight;
      if (nextKeyboardHeight === 0) {
        return;
      }

      this.scheduleFieldIntoView(this.focusedField, EDITOR_KEYBOARD_HEIGHT_SCROLL_DELAY, EditorFieldScrollIntent.START);
    };

    window.getLastWindow(this.getAbilityContext()).then((targetWindow: window.Window) => {
      if (!this.isPageAlive || this.keyboardHeightChangeCallback === null) {
        return;
      }

      this.hostWindow = targetWindow;
      targetWindow.on('keyboardHeightChange', this.keyboardHeightChangeCallback);
    });
  }

  private unregisterKeyboardHeightObserver(): void {
    if (this.hostWindow === null || this.keyboardHeightChangeCallback === null) {
      return;
    }

    try {
      this.hostWindow.off('keyboardHeightChange', this.keyboardHeightChangeCallback);
    } catch (error) {
    }

    this.hostWindow = null;
    this.keyboardHeightChangeCallback = null;
  }

  private captureStableViewportSize(): void {
    try {
      const currentDisplay = display.getDefaultDisplaySync();
      this.viewportWidth = px2vp(currentDisplay.width);
      this.viewportHeight = px2vp(currentDisplay.height);
    } catch (error) {
      this.viewportWidth = EDITOR_CONTENT_FALLBACK_WIDTH + EDITOR_PAGE_HORIZONTAL_PADDING * 2;
      this.viewportHeight = EDITOR_VIEWPORT_FALLBACK_HEIGHT;
    }
  }

  aboutToDisappear(): void {
    this.isPageAlive = false;
    this.unregisterKeyboardHeightObserver();
    this.restoreSystemKeyboardAvoidance();
    if (this.shouldDiscardChanges) {
      return;
    }
    this.syncDocumentFromInput();
    ReviewCardStore.setCurrentDocument(this.document);
  }

  private syncDocumentFromInput(): void {
    this.document.content.title = this.title.length > 0 ? this.title : DEFAULT_REVIEW_TITLE;
    this.document.content.visualFocus = this.visualFocus;
    this.document.content.focusReason = this.focusReason;
    this.document.content.visualPath = this.visualPath;
    this.document.content.visibleFacts = this.visibleFacts;
    this.document.content.coreRelation = this.coreRelation;
    this.document.content.judgement = normalizeReviewJudgement(this.judgement);
    this.document.content.extendedUnderstanding = this.extendedUnderstanding;
    this.document.content.currentBlocker = this.currentBlocker;
  }

  private async saveAndPreview(): Promise<void> {
    if (this.isSaving) {
      return;
    }

    this.isSaving = true;
    this.syncDocumentFromInput();
    this.document = ReviewCardStore.saveCurrentDocument(this.document);
    try {
      await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
      this.isDirty = false;
      ToastService.show(REVIEW_FLOW_SAVE_SUCCESS_TEXT);
      this.getUIContext().getRouter().replaceUrl({ url: PREVIEW_PAGE }).catch((error: Error) => {
        console.error(`[EditorPage] 进入预览页失败：${error.message}`);
      });
    } catch (error) {
      ToastService.show(REVIEW_FLOW_SAVE_FAILED_TEXT);
    } finally {
      this.isSaving = false;
    }
  }

  private isKeyboardActive(): boolean {
    return this.keyboardHeight > 0;
  }

  private getKeyboardInset(): number {
    return this.isKeyboardActive() ? this.keyboardHeight : 0;
  }

  private getEditorBottomPadding(): number {
    if (this.isKeyboardActive()) {
      return this.getKeyboardInset() + EDITOR_KEYBOARD_BOTTOM_PADDING;
    }

    return EDITOR_FORM_BOTTOM_PADDING;
  }

  private getDefaultLines(field: string): number {
    if (field === 'title') {
      return 1;
    }

    switch (field) {
      case 'visualPath':
      case 'visibleFacts':
        return 3;
      case 'judgement':
        return 1;
      default:
        return 2;
    }
  }

  private getContentWidth(): number {
    return Math.max(280, this.viewportWidth - EDITOR_PAGE_HORIZONTAL_PADDING * 2);
  }

  private getPhotoMaxHeight(): number {
    return Math.min(
      EDITOR_PHOTO_MAX_HEIGHT,
      Math.max(EDITOR_PHOTO_MIN_HEIGHT, this.viewportHeight * EDITOR_PHOTO_VIEWPORT_RATIO)
    );
  }

  private getPhotoAspectRatio(): number {
    if (this.imageWidth > 0 && this.imageHeight > 0) {
      return this.imageWidth / this.imageHeight;
    }

    return 1;
  }

  private getPhotoFrameSize(): EditorPhotoFrameSize {
    const contentWidth: number = this.getContentWidth();
    const maxHeight: number = this.getPhotoMaxHeight();
    const aspectRatio: number = this.getPhotoAspectRatio();
    const widthBasedHeight: number = contentWidth / aspectRatio;

    if (widthBasedHeight <= maxHeight) {
      return {
        width: contentWidth,
        height: Math.max(EDITOR_PHOTO_MIN_HEIGHT, widthBasedHeight)
      };
    }

    return {
      width: Math.min(contentWidth, maxHeight * aspectRatio),
      height: maxHeight
    };
  }

  private getPhotoFrameWidth(): number {
    return this.getPhotoFrameSize().width;
  }

  private getPhotoFrameHeight(): number {
    return this.getPhotoFrameSize().height;
  }

  private getPhotoHeaderHeight(): number {
    return EDITOR_PHOTO_HEADER_TOP_PADDING +
      this.getPhotoFrameHeight() +
      EDITOR_PHOTO_HEADER_BOTTOM_PADDING;
  }

  private estimateTextAreaHeight(field: string, value: string): number {
    const visibleLines: number = estimateReviewTextLineCount(
      value,
      this.getDefaultLines(field),
      EDITOR_TEXTAREA_APPROX_CHARS_PER_LINE
    );
    return visibleLines * EDITOR_TEXTAREA_LINE_HEIGHT + EDITOR_TEXTAREA_VERTICAL_PADDING;
  }

  private getReviewFieldHeight(field: string, value: string): number {
    return EDITOR_FIELD_LABEL_HEIGHT + EDITOR_FIELD_LABEL_GAP + this.estimateTextAreaHeight(field, value);
  }

  private getFieldValue(field: string): string {
    switch (field) {
      case 'visualFocus':
        return this.visualFocus;
      case 'focusReason':
        return this.focusReason;
      case 'visualPath':
        return this.visualPath;
      case 'visibleFacts':
        return this.visibleFacts;
      case 'coreRelation':
        return this.coreRelation;
      case 'judgement':
        return this.judgement;
      case 'extendedUnderstanding':
        return this.extendedUnderstanding;
      case 'currentBlocker':
        return this.currentBlocker;
      default:
        return '';
    }
  }

  private getFieldTopOffset(field: string): number {
    if (field === 'title') {
      return 0;
    }

    const fieldOrder: Array<string> = [
      'visualFocus',
      'focusReason',
      'visualPath',
      'visibleFacts',
      'coreRelation',
      'judgement',
      'extendedUnderstanding',
      'currentBlocker'
    ];
    let offset: number = EDITOR_TITLE_FIELD_HEIGHT + EDITOR_FIELD_GAP;

    for (let index = 0; index < fieldOrder.length; index += 1) {
      const fieldKey: string = fieldOrder[index];
      if (fieldKey === field) {
        return offset;
      }
      offset += this.getReviewFieldHeight(fieldKey, this.getFieldValue(fieldKey)) + EDITOR_FIELD_GAP;
    }

    return 0;
  }

  private getFocusedFieldHeight(field: string): number {
    if (field === 'title') {
      return EDITOR_TITLE_FIELD_HEIGHT;
    }

    return this.getReviewFieldHeight(field, this.getFieldValue(field));
  }

  private getCurrentScrollOffset(): number {
    try {
      return this.editorScroller.currentOffset().yOffset;
    } catch (error) {
      return 0;
    }
  }

  private getFormVisibleHeight(): number {
    const keyboardReserve: number = this.isKeyboardActive() ? EDITOR_KEYBOARD_VISIBLE_RESERVE : 0;
    return Math.max(
      120,
      this.viewportHeight - this.getPhotoHeaderHeight() - this.getKeyboardInset() - keyboardReserve
    );
  }

  private getFieldScrollOffset(field: string, intent: EditorFieldScrollIntent): number {
    const fieldTop: number = this.getFieldTopOffset(field);
    const fieldBottom: number = fieldTop + this.getFocusedFieldHeight(field);
    const currentOffset: number = this.getCurrentScrollOffset();
    const visibleHeight: number = this.getFormVisibleHeight();
    const safeTop: number = currentOffset + EDITOR_FIELD_SAFE_TOP_GAP;
    const safeBottom: number = currentOffset + visibleHeight - EDITOR_FIELD_SAFE_BOTTOM_GAP;

    if (intent === EditorFieldScrollIntent.START) {
      return Math.max(0, fieldTop - EDITOR_FIELD_SAFE_TOP_GAP);
    }

    if (fieldBottom > safeBottom) {
      return Math.max(0, fieldBottom - visibleHeight + EDITOR_FIELD_SAFE_BOTTOM_GAP);
    }

    if (fieldTop < safeTop) {
      return Math.max(0, fieldTop - EDITOR_FIELD_SAFE_TOP_GAP);
    }

    return Math.max(0, currentOffset);
  }

  private scrollFieldIntoView(field: string, intent: EditorFieldScrollIntent): void {
    const targetOffset: number = this.getFieldScrollOffset(field, intent);
    this.editorScroller.scrollTo({
      xOffset: 0,
      yOffset: targetOffset,
      animation: {
        duration: MotionTokens.durationStandard,
        curve: MotionTokens.curveDecelerate
      }
    });
  }

  private focusField(field: string): void {
    this.focusedField = field;
    this.scrollFieldIntoView(field, EditorFieldScrollIntent.START);
    this.scheduleFieldIntoView(field, EDITOR_KEYBOARD_SCROLL_DELAY, EditorFieldScrollIntent.START);
  }

  private handleFieldChange(field: string): void {
    this.isDirty = true;
    if (this.focusedField !== field || !this.isKeyboardActive()) {
      return;
    }

    this.scheduleFieldIntoView(field, EDITOR_KEYBOARD_HEIGHT_SCROLL_DELAY, EditorFieldScrollIntent.CARET);
  }

  private scheduleFieldIntoView(field: string, delay: number, intent: EditorFieldScrollIntent): void {
    if (field.length === 0) {
      return;
    }

    if (this.scheduledScrollField === field && this.scheduledScrollIntent === intent) {
      return;
    }

    this.scheduledScrollField = field;
    this.scheduledScrollIntent = intent;
    this.scrollRequestId += 1;
    const requestId: number = this.scrollRequestId;
    setTimeout(() => {
      if (requestId === this.scrollRequestId) {
        this.scheduledScrollField = '';
      }
      if (requestId !== this.scrollRequestId || this.focusedField !== field) {
        return;
      }

      this.scrollFieldIntoView(field, intent);
    }, delay);
  }

  private showUnsavedDialog(): void {
    AlertDialog.show({
      title: '有未保存的更改',
      message: '是否放弃当前编辑内容？',
      autoCancel: true,
      primaryButton: {
        value: '继续编辑',
        action: () => {
        }
      },
      secondaryButton: {
        value: '放弃',
        fontColor: AppColors.danger,
        action: () => {
          this.shouldDiscardChanges = true;
          this.getUIContext().getRouter().back();
        }
      }
    });
  }

  onBackPress(): boolean {
    if (!this.isDirty || this.isSaving) {
      return false;
    }

    this.showUnsavedDialog();
    return true;
  }

  @Builder
  SaveActionSection() {
    Column() {
      if (!this.isKeyboardActive()) {
        PrimaryButton({
          label: this.isSaving ? REVIEW_FLOW_SAVE_PENDING_TEXT : '保存并进入阅读',
          isDisabled: this.isSaving,
          onTap: () => {
            this.saveAndPreview();
          }
        })
      }
    }
    .padding(AppMetrics.space12)
    .width('100%')
    .borderRadius(AppMetrics.panelRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  PhotoHeader() {
    Column() {
      Column() {
        PhotoWritingHero({
          imageUri: this.imageUri,
          imageWidth: this.imageWidth,
          imageHeight: this.imageHeight,
          imageSizeFallbackUsed: this.imageSizeFallbackUsed,
          fixedFrame: true
        })
          .width(this.getPhotoFrameWidth())
          .height(this.getPhotoFrameHeight())
      }
      .width(this.getPhotoFrameWidth())
      .height(this.getPhotoFrameHeight())
      .alignSelf(ItemAlign.Center)
      .borderRadius(AppMetrics.cardRadius)
      .clip(true)
      .backgroundColor(AppColors.surfaceElevated)
      .border({ width: 1, color: AppColors.border })
      .shadow(ElevationTokens.medium)
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: EDITOR_PAGE_HORIZONTAL_PADDING,
      right: EDITOR_PAGE_HORIZONTAL_PADDING,
      top: EDITOR_PHOTO_HEADER_TOP_PADDING,
      bottom: EDITOR_PHOTO_HEADER_BOTTOM_PADDING
    })
    .width('100%')
    .height(this.getPhotoHeaderHeight())
    .backgroundColor(AppColors.pageBackground)
    .zIndex(2)
  }

  build() {
    Column() {
      this.PhotoHeader()

      Scroll(this.editorScroller) {
        Column({ space: AppMetrics.space16 }) {
          ReviewInputForm({
            title: $title,
            visualFocus: $visualFocus,
            focusReason: $focusReason,
            visualPath: $visualPath,
            visibleFacts: $visibleFacts,
            coreRelation: $coreRelation,
            judgement: $judgement,
            extendedUnderstanding: $extendedUnderstanding,
            currentBlocker: $currentBlocker,
            onFieldFocus: (field: string) => {
              this.focusField(field);
            },
            onFieldChange: (field: string) => {
              this.handleFieldChange(field);
            },
            onFieldBlur: () => {
              this.focusedField = '';
            }
          })

          this.SaveActionSection()
        }
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: 0,
          bottom: this.getEditorBottomPadding()
        })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
