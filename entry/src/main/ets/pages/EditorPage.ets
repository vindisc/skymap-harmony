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
import { AppColors, AppPageHeader, PhotoSummaryCard, PrimaryButton, SecondaryButton } from '../components/AppDesign';

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

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.document = ReviewCardStore.getCurrentDocument();
    this.imageUri = this.document.imageUri;
    this.imageWidth = this.document.imageWidth;
    this.imageHeight = this.document.imageHeight;
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
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  private scrollToFocusedField(field: string): void {
    let offset: number = 0;
    if (field === 'firstLook') {
      offset = 260;
    } else if (field === 'judgement') {
      offset = 470;
    } else if (field === 'blocker') {
      offset = 690;
    }

    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: offset,
      animation: { duration: 220, curve: Curve.EaseOut }
    });
  }

  build() {
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
        }
        .width('100%')

        AppPageHeader({
          title: '写一张照片复盘',
          subtitle: '像写短评一样记录第一眼、判断和卡点，生成卡片前随时可以补充。'
        })
          .margin({ top: 18 })

        PhotoSummaryCard({
          imageUri: this.imageUri,
          imageWidth: this.imageWidth,
          imageHeight: this.imageHeight
        })
          .margin({ top: 18, bottom: 24 })

        ReviewInputForm({
          title: $title,
          firstLook: $firstLook,
          judgement: $judgement,
          blocker: $blocker,
          onFieldFocus: (field: string) => {
            this.scrollToFocusedField(field);
          }
        })

        Column() {
          PrimaryButton({
            label: '生成复盘卡',
            onTap: () => {
              this.saveAndPreview();
            }
          })

          Text('生成时会自动保存到最近记录，之后仍可返回继续编辑。')
            .fontSize(12)
            .fontColor(AppColors.mutedText)
            .lineHeight(18)
            .margin({ top: 10 })
            .width('100%')
        }
        .width('100%')
        .margin({ top: 26 })
      }
      .padding({ left: 20, right: 20, top: 18, bottom: 42 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
