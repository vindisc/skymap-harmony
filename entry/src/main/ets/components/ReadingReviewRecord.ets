import {
  createDefaultReviewCardDocument,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { formatReviewTime } from '../utils/ImageLayoutUtils';
import { AppColors } from './AppDesign';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

@Component
export struct ReadingReviewRecord {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop saveStateLabel: string = '';

  @Builder
  MetaTag(label: string) {
    Text(label)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.secondaryText)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(6)
      .backgroundColor('#F1ECE3')
  }

  @Builder
  Section(label: string, value: string, showDivider: boolean) {
    Column() {
      if (showDivider) {
        Divider()
          .strokeWidth(1)
          .color(AppColors.border)
          .opacity(0.32)
          .width('100%')
          .margin({ bottom: 18 })
      }

      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.mutedText)
        .width('100%')

      Text(value.length > 0 ? value : '待补充')
        .fontSize(18)
        .fontColor(value.length > 0 ? AppColors.text : AppColors.secondaryText)
        .lineHeight(30)
        .width('100%')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
        .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: showDivider ? 0 : 4, bottom: 26 })
  }

  build() {
    Column() {
      ReviewPhotoBlock({
        imageUri: this.document.imageUri,
        imageWidth: this.document.imageWidth,
        imageHeight: this.document.imageHeight,
        imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
        aspectRatioValue: this.document.imageWidth > 0 && this.document.imageHeight > 0
          ? this.document.imageWidth / this.document.imageHeight
          : 1,
        fitMode: ImageFit.Contain,
        cornerRadius: 18
      })

      Column() {
        Text(this.document.content.title.length > 0 ? this.document.content.title : '这张照片是否成立')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(40)
          .width('100%')
          .wordBreak(WordBreak.BREAK_WORD)
          .margin({ top: 28 })

        Row({ space: 10 }) {
          Text(formatReviewTime(this.document.updatedAt))
            .fontSize(12)
            .fontColor(AppColors.secondaryText)

          if (this.saveStateLabel.length > 0) {
            this.MetaTag(this.saveStateLabel)
          }
        }
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .margin({ top: 12 })

        Column() {
          this.Section('第一眼落点', this.document.content.firstLook, false)
          this.Section('是否成立', this.document.content.judgement, true)
          this.Section('卡点', this.document.content.blocker, true)
        }
        .margin({ top: 18 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
