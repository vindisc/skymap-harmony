import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveReviewCardTheme, ReviewCardTheme } from '../model/ReviewCardTheme';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

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
      compact: true
    })
    .width('46%')
  }

  @Builder
  FieldBlock(label: string, value: string, theme: ReviewCardTheme) {
    Column() {
      Text(label)
        .fontSize(theme.captionSize)
        .fontColor(theme.mutedTextColor)
        .fontWeight(FontWeight.Medium)
        .width('100%')
      Text(value.length > 0 ? value : '待填写')
        .fontSize(theme.bodySize)
        .fontColor(theme.textColor)
        .lineHeight(theme.bodySize + 5)
        .margin({ top: 7 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .width('100%')
    .borderRadius(6)
    .backgroundColor(theme.panelColor)
  }

  build() {
    Row({ space: 12 }) {
      this.PhotoBlock()
      Column({ space: 9 }) {
        Text(this.document.content.title)
          .fontSize(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')
          .lineHeight(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).titleSize + 6)
          .width('100%')
        this.FieldBlock('第一眼落点', this.document.content.firstLook, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
        this.FieldBlock('是否成立', this.document.content.judgement, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
        this.FieldBlock('卡点', this.document.content.blocker, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .padding(14)
    .width('100%')
    .borderRadius(10)
    .backgroundColor(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).canvasColor)
    .shadow({ radius: 18, color: '#1F000000', offsetX: 0, offsetY: 8 })
  }
}
