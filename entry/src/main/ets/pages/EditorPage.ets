import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { PREVIEW_PAGE } from '../app/AppRouter';
import {
  createDefaultReviewCardDocument,
  DEFAULT_REVIEW_TITLE,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { ReviewInputForm } from '../components/ReviewInputForm';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { AppColors, PhotoWritingHero, PrimaryButton } from '../components/AppDesign';

const EDITOR_BOTTOM_ACTION_PADDING: number = 126;
const EDITOR_KEYBOARD_BOTTOM_PADDING: number = 420;
const EDITOR_TITLE_FIELD_HEIGHT: number = 78;
const EDITOR_FIELD_LABEL_HEIGHT: number = 18;
const EDITOR_FIELD_LABEL_GAP: number = 10;
const EDITOR_FIELD_GAP: number = 18;
const EDITOR_TEXTAREA_LINE_HEIGHT: number = 28;
const EDITOR_TEXTAREA_VERTICAL_PADDING: number = 28;
const EDITOR_TEXTAREA_APPROX_CHARS_PER_LINE: number = 14;
const EDITOR_FIXED_PHOTO_HEIGHT: number = 312;

@Entry
@Component
struct EditorPage {
  private document: ReviewCardDocument = createDefaultReviewCardDocument();
  private editorScroller: Scroller = new Scroller();
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

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
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
    this.judgement = this.document.content.judgement;
    this.extendedUnderstanding = this.document.content.extendedUnderstanding;
    this.currentBlocker = this.document.content.currentBlocker;
  }

  aboutToDisappear(): void {
    this.syncDocumentFromInput();
    ReviewCardStore.saveCurrentDocument(this.document);
  }

  private syncDocumentFromInput(): void {
    this.document.content.title = this.title.length > 0 ? this.title : DEFAULT_REVIEW_TITLE;
    this.document.content.visualFocus = this.visualFocus;
    this.document.content.focusReason = this.focusReason;
    this.document.content.visualPath = this.visualPath;
    this.document.content.visibleFacts = this.visibleFacts;
    this.document.content.coreRelation = this.coreRelation;
    this.document.content.judgement = this.judgement;
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
    return this.focusedField.length > 0;
  }

  private getDefaultLines(field: string): number {
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

  private getFieldScrollOffset(field: string): number {
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
        return Math.max(0, offset - 16);
      }
      offset += this.getReviewFieldHeight(fieldKey, this.getFieldValue(fieldKey)) + EDITOR_FIELD_GAP;
    }

    return 0;
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
    setTimeout(() => {
      this.scrollFieldIntoView(field);
    }, 80);
    setTimeout(() => {
      this.scrollFieldIntoView(field);
    }, 260);
  }

  @Builder
  BottomActionBar() {
    Column() {
      PrimaryButton({
        label: '保存并进入阅读',
        onTap: () => {
          this.saveAndPreview();
        }
      })
    }
    .padding({ left: 20, right: 20, top: 10, bottom: 20 })
    .width('100%')
    .backgroundColor(AppColors.pageBackground)
  }

  @Builder
  PhotoHeader() {
    Column({ space: 10 }) {
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
        .layoutWeight(1)
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .width('100%')
    .height(EDITOR_FIXED_PHOTO_HEIGHT)
    .backgroundColor(AppColors.pageBackground)
    .zIndex(2)
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.PhotoHeader()

          Scroll(this.editorScroller) {
            Column() {
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
            }
            .padding({
              left: 20,
              right: 20,
              top: 0,
              bottom: this.isKeyboardActive() ? EDITOR_KEYBOARD_BOTTOM_PADDING : EDITOR_BOTTOM_ACTION_PADDING
            })
            .width('100%')
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')

        if (!this.isKeyboardActive()) {
          this.BottomActionBar()
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
