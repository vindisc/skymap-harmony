import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';
import { ReviewPhotoArea } from './ReviewPhotoArea';

@Component
export struct ReadingReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  private getPhotoRatio(): number {
    if (this.document.imageWidth <= 0 || this.document.imageHeight <= 0) {
      return 1.35;
    }

    const ratio: number = this.document.imageWidth / this.document.imageHeight;
    if (ratio >= 1.15) {
      return 1.45;
    }

    if (ratio <= 0.85) {
      return 0.82;
    }

    return 1;
  }

  build() {
    Column() {
      ReviewPhotoArea({
        imageUri: this.document.imageUri,
        imageWidth: this.document.imageWidth,
        imageHeight: this.document.imageHeight,
        aspectRatioValue: this.getPhotoRatio(),
        compact: true
      })

      Column() {
        ReviewCardTitle({ title: this.document.content.title })

        ReviewInfoGroup({
          firstLook: this.document.content.firstLook,
          judgement: this.document.content.judgement,
          blocker: this.document.content.blocker
        })
          .margin({ top: 20 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 2, right: 2, top: 20 })
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(ReviewCardStyleTokens.cardPadding)
    .width('100%')
    .borderRadius(ReviewCardStyleTokens.cardRadius)
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
    .border({ width: 1, color: ReviewCardStyleTokens.hairlineColor })
    .shadow({ radius: 16, color: ReviewCardStyleTokens.shadowColor, offsetX: 0, offsetY: 8 })
  }
}
