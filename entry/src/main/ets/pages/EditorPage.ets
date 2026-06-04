import router from '@ohos.router';
import { PREVIEW_PAGE } from '../app/AppRouter';
import {
  createDefaultReviewCardDocument,
  DEFAULT_REVIEW_TITLE,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { ReviewInputForm } from '../components/ReviewInputForm';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { getImageRatioLabel } from '../utils/ImageLayoutUtils';

@Entry
@Component
struct EditorPage {
  private document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State title: string = DEFAULT_REVIEW_TITLE;
  @State firstLook: string = '';
  @State judgement: string = '';
  @State blocker: string = '';

  aboutToAppear(): void {
    this.document = ReviewCardStore.getCurrentDocument();
    this.title = this.document.content.title;
    this.firstLook = this.document.content.firstLook;
    this.judgement = this.document.content.judgement;
    this.blocker = this.document.content.blocker;
  }

  private saveAndPreview(): void {
    this.document.content.title = this.title.length > 0 ? this.title : DEFAULT_REVIEW_TITLE;
    this.document.content.firstLook = this.firstLook;
    this.document.content.judgement = this.judgement;
    this.document.content.blocker = this.blocker;
    ReviewCardStore.saveCurrentDocument(this.document);
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Button('返回')
              .height(36)
              .borderRadius(6)
              .fontSize(14)
              .onClick(() => {
                router.back();
              })
            Blank()
          }
          .width('100%')

          Text('填写复盘内容')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2329')
            .margin({ top: 18 })
            .width('100%')

          Text(getImageRatioLabel(this.document.imageWidth, this.document.imageHeight))
            .fontSize(14)
            .fontColor('#68707D')
            .margin({ top: 8, bottom: 20 })
            .width('100%')

          ReviewInputForm({
            title: $title,
            firstLook: $firstLook,
            judgement: $judgement,
            blocker: $blocker
          })
        }
        .padding({ left: 20, right: 20, top: 18, bottom: 96 })
        .width('100%')
      }
      .layoutWeight(1)

      Column() {
        Button('生成复盘卡')
          .height(48)
          .width('100%')
          .borderRadius(6)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.saveAndPreview();
          })
      }
      .padding(16)
      .width('100%')
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7F9')
  }
}

