import router from '@ohos.router';
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
import { AppColors, PhotoWritingHero, PrimaryButton } from '../components/AppDesign';

const EDITOR_PAGE_HORIZONTAL_PADDING: number = 20;
const EDITOR_CONTENT_FALLBACK_WIDTH: number = 360;
const EDITOR_VIEWPORT_FALLBACK_HEIGHT: number = 720;
const EDITOR_FORM_BOTTOM_PADDING: number = 34;
const EDITOR_KEYBOARD_BOTTOM_PADDING: number = 42;
const EDITOR_FIELD_SAFE_TOP_GAP: number = 12;
const EDITOR_FIELD_SAFE_BOTTOM_GAP: number = 26;
const EDITOR_KEYBOARD_SCROLL_DELAY: number = 220;
const EDITOR_KEYBOARD_HEIGHT_SCROLL_DELAY: number = 80;
const EDITOR_PHOTO_TITLE_HEIGHT: number = 24;
const EDITOR_PHOTO_TITLE_GAP: number = 8;
const EDITOR_PHOTO_HEADER_TOP_PADDING: number = 8;
const EDITOR_PHOTO_HEADER_BOTTOM_PADDING: number = 10;
const EDITOR_PHOTO_MIN_HEIGHT: number = 188;
const EDITOR_PHOTO_MAX_HEIGHT: number = 300;
const EDITOR_PHOTO_VIEWPORT_RATIO: number = 0.32;
const EDITOR_TITLE_FIELD_HEIGHT: number = 78;
const EDITOR_FIELD_LABEL_HEIGHT: number = 18;
const EDITOR_FIELD_LABEL_GAP: number = 10;
const EDITOR_FIELD_GAP: number = 18;
const EDITOR_TEXTAREA_LINE_HEIGHT: number = 28;
const EDITOR_TEXTAREA_VERTICAL_PADDING: number = 28;
const EDITOR_TEXTAREA_APPROX_CHARS_PER_LINE: number = 14;

interface EditorPhotoFrameSize {
  width: number;
  height: number;
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
      this.keyboardHeight = Math.max(0, px2vp(height));
      if (this.keyboardHeight === 0) {
        return;
      }

      this.scheduleFieldIntoView(this.focusedField, EDITOR_KEYBOARD_HEIGHT_SCROLL_DELAY);
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
    this.syncDocumentFromInput();
    this.document = ReviewCardStore.saveCurrentDocument(this.document);
    await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
    router.replaceUrl({ url: PREVIEW_PAGE });
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
      EDITOR_PHOTO_TITLE_HEIGHT +
      EDITOR_PHOTO_TITLE_GAP +
      this.getPhotoFrameHeight() +
      EDITOR_PHOTO_HEADER_BOTTOM_PADDING;
  }

  private estimateTextAreaHeight(field: string, value: string): number {
    if (value.length === 0) {
      return this.getDefaultLines(field) * EDITOR_TEXTAREA_LINE_HEIGHT + EDITOR_TEXTAREA_VERTICAL_PADDING;
    }

    const rows: Array<string> = value.split('\n');
    let lineCount: number = 0;
    for (let index = 0; index < rows.length; index += 1) {
      lineCount += Math.max(1, Math.ceil(rows[index].length / EDITOR_TEXTAREA_APPROX_CHARS_PER_LINE));
    }

    const visibleLines: number = Math.max(this.getDefaultLines(field), lineCount);
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
    return Math.max(
      120,
      this.viewportHeight - this.getPhotoHeaderHeight() - this.getKeyboardInset()
    );
  }

  private getFieldScrollOffset(field: string): number {
    const fieldTop: number = this.getFieldTopOffset(field);
    const fieldBottom: number = fieldTop + this.getFocusedFieldHeight(field);
    const currentOffset: number = this.getCurrentScrollOffset();
    const visibleHeight: number = this.getFormVisibleHeight();
    const safeTop: number = currentOffset + EDITOR_FIELD_SAFE_TOP_GAP;
    const safeBottom: number = currentOffset + visibleHeight - EDITOR_FIELD_SAFE_BOTTOM_GAP;

    if (fieldBottom > safeBottom) {
      return Math.max(0, fieldBottom - visibleHeight + EDITOR_FIELD_SAFE_BOTTOM_GAP);
    }

    if (fieldTop < safeTop) {
      return Math.max(0, fieldTop - EDITOR_FIELD_SAFE_TOP_GAP);
    }

    return Math.max(0, currentOffset);
  }

  private scrollFieldIntoView(field: string): void {
    const targetOffset: number = this.getFieldScrollOffset(field);
    this.editorScroller.scrollTo({
      xOffset: 0,
      yOffset: targetOffset,
      animation: {
        duration: 240,
        curve: Curve.EaseOut
      }
    });
  }

  private focusField(field: string): void {
    this.focusedField = field;
    this.scheduleFieldIntoView(field, EDITOR_KEYBOARD_SCROLL_DELAY);
  }

  private scheduleFieldIntoView(field: string, delay: number): void {
    if (field.length === 0) {
      return;
    }

    this.scrollRequestId += 1;
    const requestId: number = this.scrollRequestId;
    setTimeout(() => {
      if (requestId !== this.scrollRequestId || this.focusedField !== field) {
        return;
      }

      this.scrollFieldIntoView(field);
    }, delay);
  }

  @Builder
  SaveActionSection() {
    Column() {
      if (!this.isKeyboardActive()) {
        PrimaryButton({
          label: '保存并进入阅读',
          onTap: () => {
            this.saveAndPreview();
          }
        })
      }
    }
    .width('100%')
  }

  @Builder
  PhotoHeader() {
    Column({ space: EDITOR_PHOTO_TITLE_GAP }) {
      Text('写复盘')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(24)
        .width('100%')

      PhotoWritingHero({
        imageUri: this.imageUri,
        imageWidth: this.imageWidth,
        imageHeight: this.imageHeight,
        imageSizeFallbackUsed: this.imageSizeFallbackUsed,
        fixedFrame: true
      })
        .width(this.getPhotoFrameWidth())
        .height(this.getPhotoFrameHeight())
        .alignSelf(ItemAlign.Center)
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
        Column({ space: 18 }) {
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
            onFieldBlur: () => {
              this.focusedField = '';
            }
          })

          this.SaveActionSection()
        }
        .padding({
          left: 20,
          right: 20,
          top: 0,
          bottom: this.getEditorBottomPadding()
        })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
