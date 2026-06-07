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
const EDITOR_KEYBOARD_BOTTOM_PADDING: number = 34;
const EDITOR_STICKY_PHOTO_HEIGHT: string = '26%';

@Entry
@Component
struct EditorPage {
  private document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State title: string = DEFAULT_REVIEW_TITLE;
  @State visualFocus: string = '';
  @State focusReason: string = '';
  @State visualPath: string = '';
  @State visibleFacts: string = '';
  @State coreRelation: string = '';
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
  StickyPhotoHeader() {
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
        imageSizeFallbackUsed: this.imageSizeFallbackUsed
      })
        .layoutWeight(1)
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 20, right: 20, top: 12, bottom: 10 })
    .width('100%')
    .height(EDITOR_STICKY_PHOTO_HEIGHT)
    .backgroundColor(AppColors.pageBackground)
    .zIndex(2)
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          this.StickyPhotoHeader()

          Scroll() {
          Column() {
            ReviewInputForm({
              title: $title,
              visualFocus: $visualFocus,
              focusReason: $focusReason,
              visualPath: $visualPath,
              visibleFacts: $visibleFacts,
              coreRelation: $coreRelation,
              extendedUnderstanding: $extendedUnderstanding,
              currentBlocker: $currentBlocker,
              onFieldFocus: (field: string) => {
                this.focusedField = field;
              },
              onFieldBlur: () => {
                this.focusedField = '';
              }
            })
          }
          .padding({
            left: 20,
            right: 20,
            top: 8,
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
