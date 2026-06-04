import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveReviewCardTheme } from '../model/ReviewCardTheme';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';
import { ReviewCardMetrics, ReviewInfoGroup, ReviewTitle } from './ReviewCardParts';

@Component
export struct VerticalReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  @Builder
  PhotoBlock() {
    ReviewPhotoBlock({
      imageUri: this.document.imageUri,
      imageWidth: this.document.imageWidth,
      imageHeight: this.document.imageHeight,
      aspectRatioValue: 0.68,
      compact: true,
      cornerRadius: ReviewCardMetrics.photoRadius
    })
    .width('43%')
  }

  build() {
    Row({ space: ReviewCardMetrics.contentInset }) {
      this.PhotoBlock()
      Column() {
        ReviewTitle({
          title: this.document.content.title,
          titleSize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).titleSize
        })
        ReviewInfoGroup({
          content: this.document.content,
          bodySize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).bodySize,
          captionSize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).captionSize,
          layout: 'column',
          compact: true
        })
          .margin({ top: ReviewCardMetrics.titleInfoGap })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .padding(ReviewCardMetrics.shellPadding)
    .width('100%')
    .borderRadius(ReviewCardMetrics.shellRadius)
    .backgroundColor(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).canvasColor)
    .border({ width: 1, color: '#ECEFF2' })
    .shadow({ radius: 22, color: '#1A000000', offsetX: 0, offsetY: 10 })
  }
}
