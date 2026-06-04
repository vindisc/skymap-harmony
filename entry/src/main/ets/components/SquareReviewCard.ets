import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewPhotoArea } from './ReviewPhotoArea';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';

@Component
export struct SquareReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  @Builder
  PhotoBlock() {
    ReviewPhotoArea({
      imageUri: this.document.imageUri,
      imageWidth: this.document.imageWidth,
      imageHeight: this.document.imageHeight,
      aspectRatioValue: 1
    })
  }

  build() {
    Column() {
      this.PhotoBlock()
      Column() {
        ReviewCardTitle({ title: this.document.content.title })
        ReviewInfoGroup({
          firstLook: this.document.content.firstLook,
          judgement: this.document.content.judgement,
          blocker: this.document.content.blocker,
          compact: true
        })
          .margin({ top: 14 })
      }
      .padding({
        left: ReviewCardStyleTokens.textInset,
        right: ReviewCardStyleTokens.textInset,
        top: 17,
        bottom: 2
      })
      .width('100%')
    }
    .padding(ReviewCardStyleTokens.cardPadding)
    .width('100%')
    .borderRadius(ReviewCardStyleTokens.cardRadius)
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
    .border({ width: 1, color: ReviewCardStyleTokens.hairlineColor })
    .shadow({ radius: 22, color: ReviewCardStyleTokens.shadowColor, offsetX: 0, offsetY: 10 })
  }
}
