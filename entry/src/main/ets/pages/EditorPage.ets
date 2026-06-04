import router from '@ohos.router';
import { PREVIEW_PAGE } from '../app/AppRouter';
import {
  createDefaultReviewCardDocument,
  DEFAULT_REVIEW_TITLE,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { ReviewInputForm } from '../components/ReviewInputForm';
import { ReviewPhotoBlock } from '../components/ReviewPhotoBlock';
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
  @State imageUri: string = '';
  @State imageWidth: number = 1600;
  @State imageHeight: number = 1000;

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
            .margin({ top: 8 })
            .width('100%')

          Row({ space: 12 }) {
            ReviewPhotoBlock({
              imageUri: this.imageUri,
              imageWidth: this.imageWidth,
              imageHeight: this.imageHeight,
              aspectRatioValue: 1.35,
              compact: true
            })
            .width(112)
            Column() {
              Text(getImageRatioLabel(this.imageWidth, this.imageHeight))
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1F2329')
              Text(`${this.imageWidth} x ${this.imageHeight}`)
                .fontSize(13)
                .fontColor('#68707D')
                .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .alignItems(VerticalAlign.Center)
          .padding(12)
          .width('100%')
          .borderRadius(8)
          .backgroundColor('#FFFFFF')
          .margin({ top: 14, bottom: 22 })

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
