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

@Entry
@Component
struct EditorPage {
  private document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State title: string = DEFAULT_REVIEW_TITLE;
  @State firstLook: string = '';
  @State reason: string = '';
  @State visualPath: string = '';
  @State strongestRelation: string = '';
  @State judgement: string = '';
  @State blocker: string = '';
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
    this.firstLook = this.document.content.firstLook;
    this.reason = this.document.content.reason;
    this.visualPath = this.document.content.visualPath;
    this.strongestRelation = this.document.content.strongestRelation;
    this.judgement = this.document.content.judgement;
    this.blocker = this.document.content.blocker;
  }

  aboutToDisappear(): void {
    this.syncDocumentFromInput();
    ReviewCardStore.saveCurrentDocument(this.document);
  }

  private syncDocumentFromInput(): void {
    this.document.content.title = this.title.length > 0 ? this.title : DEFAULT_REVIEW_TITLE;
    this.document.content.firstLook = this.firstLook;
    this.document.content.reason = this.reason;
    this.document.content.visualPath = this.visualPath;
    this.document.content.strongestRelation = this.strongestRelation;
    this.document.content.judgement = this.judgement;
    this.document.content.blocker = this.blocker;
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
    .padding({ left: 20, right: 20, top: 14, bottom: 28 })
    .width('100%')
    .backgroundColor(AppColors.pageBackground)
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        Scroll() {
          Column() {
            Text('写复盘')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .lineHeight(28)
              .width('100%')

            PhotoWritingHero({
              imageUri: this.imageUri,
              imageWidth: this.imageWidth,
              imageHeight: this.imageHeight,
              imageSizeFallbackUsed: this.imageSizeFallbackUsed
            })
              .margin({ top: 18, bottom: 26 })

            ReviewInputForm({
              title: $title,
              firstLook: $firstLook,
              reason: $reason,
              visualPath: $visualPath,
              strongestRelation: $strongestRelation,
              judgement: $judgement,
              blocker: $blocker,
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
            top: 18,
            bottom: this.isKeyboardActive() ? EDITOR_KEYBOARD_BOTTOM_PADDING : EDITOR_BOTTOM_ACTION_PADDING
          })
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)

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
