import router from '@ohos.router';
import {
  createDefaultReviewCardDocument,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { ReviewCardPreview } from '../components/ReviewCardPreview';
import { ReviewCardStore } from '../services/ReviewCardStore';

@Entry
@Component
struct PreviewPage {
  @State document: ReviewCardDocument = createDefaultReviewCardDocument();

  aboutToAppear(): void {
    this.document = ReviewCardStore.getCurrentDocument();
  }

  build() {
    Column() {
      Row() {
        Button('返回编辑')
          .height(36)
          .borderRadius(6)
          .fontSize(14)
          .onClick(() => {
            router.back();
          })
        Blank()
      }
      .padding({ left: 16, right: 16, top: 16 })
      .width('100%')

      Scroll() {
        Column() {
          ReviewCardPreview({ document: this.document })
        }
        .padding(20)
        .width('100%')
      }
      .layoutWeight(1)

      Row({ space: 10 }) {
        Button('保存草稿')
          .height(46)
          .layoutWeight(1)
          .borderRadius(6)
          .fontSize(15)
          .onClick(() => {
            ReviewCardStore.saveCurrentDocument(this.document);
          })
        Button('导出图片')
          .height(46)
          .layoutWeight(1)
          .borderRadius(6)
          .fontSize(15)
          .onClick(() => {
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

