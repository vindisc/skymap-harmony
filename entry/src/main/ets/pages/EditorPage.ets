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

  private goBack(): void {
    this.syncDocumentFromInput();
    ReviewCardStore.saveCurrentDocument(this.document);
    router.back();
  }

  private getFocusScrollOffset(field: string): number {
    let offset: number = 0;
    if (field === 'title') {
      offset = 180;
    } else if (field === 'firstLook') {
      offset = 560;
    } else if (field === 'judgement') {
      offset = 900;
    } else if (field === 'blocker') {
      offset = 1260;
    }

    return offset;
  }

  private scrollToFocusedField(field: string): void {
    const offset: number = this.getFocusScrollOffset(field);
    setTimeout(() => {
      this.scroller.scrollTo({
        xOffset: 0,
        yOffset: offset,
        animation: { duration: 180, curve: Curve.EaseOut }
      });
    }, 260);
  }

  build() {
    Column() {
      Scroll(this.scroller) {
        Column() {
          Row() {
            Button('返回')
              .height(34)
              .width(64)
              .borderRadius(7)
              .fontSize(13)
              .fontColor(AppColors.secondaryText)
              .backgroundColor('#00000000')
              .onClick(() => {
                this.goBack();
              })

            Text('写复盘')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .lineHeight(28)
            Blank()
          }
          .alignItems(VerticalAlign.Center)
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
            judgement: $judgement,
            blocker: $blocker,
            onFieldFocus: (field: string) => {
              this.scrollToFocusedField(field);
            },
            onFieldBlur: () => {
            }
          })

          PrimaryButton({
            label: '保存并进入阅读',
            onTap: () => {
              this.saveAndPreview();
            }
          })
            .margin({ top: 26 })
        }
        .padding({ left: 20, right: 20, top: 18, bottom: 120 })
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
