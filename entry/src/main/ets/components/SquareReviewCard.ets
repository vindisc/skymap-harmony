import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveReviewCardTheme } from '../model/ReviewCardTheme';
import { AppColors, InfoBlockCard } from './AppDesign';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

@Component
export struct SquareReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  @Builder
  PhotoBlock() {
    ReviewPhotoBlock({
      imageUri: this.document.imageUri,
      imageWidth: this.document.imageWidth,
      imageHeight: this.document.imageHeight,
      aspectRatioValue: 1,
      cornerRadius: 8
    })
  }

  build() {
    Column() {
      this.PhotoBlock()
      Column({ space: 10 }) {
        Text(this.document.content.title)
          .fontSize(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).titleSize + 1)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).titleSize + 8)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        InfoBlockCard({
          label: '第一眼落点',
          value: this.document.content.firstLook,
          bodySize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).bodySize,
          captionSize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).captionSize,
          maxLines: 3
        })
        InfoBlockCard({
          label: '是否成立',
          value: this.document.content.judgement,
          bodySize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).bodySize,
          captionSize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).captionSize,
          maxLines: 3
        })
        InfoBlockCard({
          label: '卡点',
          value: this.document.content.blocker,
          bodySize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).bodySize,
          captionSize: resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).captionSize,
          maxLines: 4
        })
      }
      .padding({ top: 17 })
      .width('100%')
    }
    .padding(14)
    .width('100%')
    .borderRadius(10)
    .backgroundColor(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).canvasColor)
    .border({ width: 1, color: '#ECEFF2' })
    .shadow({ radius: 22, color: '#1A000000', offsetX: 0, offsetY: 10 })
  }
}
