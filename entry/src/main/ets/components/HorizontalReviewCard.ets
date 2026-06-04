import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveReviewCardTheme } from '../model/ReviewCardTheme';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';
import { ReviewCardMetrics, ReviewInfoGroup, ReviewTitle } from './ReviewCardParts';

@Component
export struct HorizontalReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  @Builder
  PhotoBlock() {
    ReviewPhotoBlock({
      imageUri: this.document.imageUri,
      imageWidth: this.document.imageWidth,
      imageHeight: this.document.imageHeight,
      aspectRatioValue: 1.52,
      cornerRadius: ReviewCardMetrics.photoRadius
    })
  }

  build() {
    Column() {
      this.PhotoBlock()
      Column() {
        ReviewTitle({
          title: this.document.content.title,
          titleSize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).titleSize + 1
        })
        ReviewInfoGroup({
          content: this.document.content,
          bodySize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).bodySize,
          captionSize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).captionSize,
          layout: 'row'
        })
          .margin({ top: ReviewCardMetrics.titleInfoGap })
      }
      .padding({
        left: ReviewCardMetrics.contentInset,
        right: ReviewCardMetrics.contentInset,
        top: ReviewCardMetrics.photoTitleGap,
        bottom: ReviewCardMetrics.contentInset
      })
      .width('100%')
    }
    .padding(ReviewCardMetrics.shellPadding)
    .width('100%')
    .borderRadius(ReviewCardMetrics.shellRadius)
    .backgroundColor(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).canvasColor)
    .border({ width: 1, color: '#ECEFF2' })
    .shadow({ radius: 22, color: '#1A000000', offsetX: 0, offsetY: 10 })
  }
}
