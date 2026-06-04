import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveReviewCardTheme, ReviewCardTheme } from '../model/ReviewCardTheme';
import { getImageRatioLabel } from '../utils/ImageLayoutUtils';

@Component
export struct HorizontalReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  @Builder
  PhotoBlock() {
    Column() {
      Text(getImageRatioLabel(this.document.imageWidth, this.document.imageHeight))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2329')
      Text(`${this.document.imageWidth} x ${this.document.imageHeight}`)
        .fontSize(12)
        .fontColor('#68707D')
        .margin({ top: 6 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .aspectRatio(1.6)
    .borderRadius(6)
    .backgroundColor('#DCE7E1')
  }

  @Builder
  InfoColumn(label: string, value: string, theme: ReviewCardTheme) {
    Column() {
      Text(label)
        .fontSize(theme.captionSize)
        .fontColor(theme.mutedTextColor)
        .fontWeight(FontWeight.Medium)
      Text(value.length > 0 ? value : '待填写')
        .fontSize(theme.bodySize)
        .fontColor(theme.textColor)
        .lineHeight(theme.bodySize + 5)
        .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(12)
    .layoutWeight(1)
    .constraintSize({ minHeight: 96 })
    .borderRadius(6)
    .backgroundColor(theme.panelColor)
  }

  build() {
    Column() {
      this.PhotoBlock()
      Column() {
        Text(this.document.content.title)
          .fontSize(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).titleSize)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')
          .width('100%')
        Row({ space: 8 }) {
          this.InfoColumn('第一眼落点', this.document.content.firstLook, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
          this.InfoColumn('是否成立', this.document.content.judgement, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
          this.InfoColumn('卡点', this.document.content.blocker, resolveReviewCardTheme(this.document.config.background, this.document.config.textSize))
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .padding(16)
      .width('100%')
    }
    .padding(14)
    .width('100%')
    .borderRadius(8)
    .backgroundColor(resolveReviewCardTheme(this.document.config.background, this.document.config.textSize).canvasColor)
    .shadow({ radius: 14, color: '#1A000000', offsetX: 0, offsetY: 6 })
  }
}
