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
import { AppColors, PhotoSummaryCard, PrimaryButton, SecondaryButton } from '../components/AppDesign';

@Entry
@Component
struct EditorPage {
  private scroller: Scroller = new Scroller();
  private document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State title: string = DEFAULT_REVIEW_TITLE;
  @State firstLook: string = '';
  @State judgement: string = '';
  @State blocker: string = '';
  @State imageUri: string = '';
  @State imageWidth: number = 1600;
  @State imageHeight: number = 1000;
  @State imageSizeFallbackUsed: boolean = false;
  @State isInputFocused: boolean = false;

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
    this.document.content.judgement = this.judgement;
    this.document.content.blocker = this.blocker;
  }

  private async saveAndPreview(): Promise<void> {
    this.syncDocumentFromInput();
    this.document = ReviewCardStore.saveCurrentDocument(this.document);
    await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
    router.replaceUrl({ url: PREVIEW_PAGE });
  }

  private scrollToFocusedField(field: string): void {
    this.isInputFocused = true;
    let offset: number = 0;
    if (field === 'title') {
      offset = 120;
    } else if (field === 'firstLook') {
      offset = 310;
    } else if (field === 'judgement') {
      offset = 520;
    } else if (field === 'blocker') {
      offset = 760;
    }

    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: offset,
      animation: { duration: 220, curve: Curve.EaseOut }
    });
  }

  build() {
    Column() {
      Scroll(this.scroller) {
        Column() {
          Row() {
            SecondaryButton({
              label: '返回',
              onTap: () => {
                router.back();
              }
            })
              .width(82)
            Blank()
            Text('写复盘')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .lineHeight(28)
            Blank()
            Blank()
              .width(82)
          }
          .alignItems(VerticalAlign.Center)
          .width('100%')

          PhotoSummaryCard({
            imageUri: this.imageUri,
            imageWidth: this.imageWidth,
            imageHeight: this.imageHeight,
            imageSizeFallbackUsed: this.imageSizeFallbackUsed
          })
            .margin({ top: 18, bottom: 22 })

          ReviewInputForm({
            title: $title,
            firstLook: $firstLook,
            judgement: $judgement,
            blocker: $blocker,
            onFieldFocus: (field: string) => {
              this.scrollToFocusedField(field);
            },
            onFieldBlur: () => {
              this.isInputFocused = false;
            }
          })
        }
        .padding({ left: 20, right: 20, top: 18, bottom: this.isInputFocused ? 48 : 126 })
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      if (!this.isInputFocused) {
        Column() {
          PrimaryButton({
            label: '生成复盘卡',
            onTap: () => {
              this.saveAndPreview();
            }
          })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 16 })
        .width('100%')
        .backgroundColor(AppColors.surface)
        .shadow({ radius: 10, color: '#10000000', offsetX: 0, offsetY: -3 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
