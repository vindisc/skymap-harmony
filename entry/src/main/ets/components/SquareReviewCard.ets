import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveReviewCardTheme, ReviewCardTheme } from '../model/ReviewCardTheme';
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
      aspectRatioValue: 1
    })
  }

  @Builder
  CompactBlock(label: string, value: string, theme: ReviewCardTheme) {
    Column() {
      Text(label)
        .fontSize(theme.captionSize)
        .fontColor(theme.mutedTextColor)
        .fontWeight(FontWeight.Medium)
      Text(value.length > 0 ? value : '待填写')
        .fontSize(theme.bodySize)
        .fontColor(theme.textColor)
        .lineHeight(theme.bodySize + 5)
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(11)
    .width('100%')
    .borderRadius(6)
    .backgroundColor(theme.panelColor)
  }

  build() {
    Column() {
      this.PhotoBlock()
      Column({ space: 8 }) {
        Text(this.document.content.title)
          .fontSize(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')
          .width('100%')
        this.CompactBlock('第一眼落点', this.document.content.firstLook, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
        this.CompactBlock('是否成立', this.document.content.judgement, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
        this.CompactBlock('卡点', this.document.content.blocker, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
      }
      .padding({ top: 14 })
      .width('100%')
    }
    .padding(14)
    .width('100%')
    .borderRadius(8)
    .backgroundColor(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).canvasColor)
    .shadow({ radius: 14, color: '#1A000000', offsetX: 0, offsetY: 6 })
  }
}
