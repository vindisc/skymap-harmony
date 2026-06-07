import {
  createDefaultReviewCardDocument,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { formatReviewTime, getImageRatioLabel, getImageSizeText } from '../utils/ImageLayoutUtils';
import { AppColors } from './AppDesign';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

@Component
export struct ReadingReviewRecord {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  @Builder
  MetaLabel(label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(AppColors.mutedText)
      .padding({ left: 8, right: 8, top: 5, bottom: 5 })
      .borderRadius(5)
      .backgroundColor('#EEE9E0')
  }

  @Builder
  Section(label: string, value: string) {
    Column() {
      Column() {
        Text(label)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.mutedText)
          .width('100%')

        Text(value.length > 0 ? value : '待补充')
          .fontSize(17)
          .fontColor(AppColors.text)
          .lineHeight(28)
          .width('100%')
          .wordBreak(WordBreak.BREAK_WORD)
          .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
          .margin({ top: 10 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 16, bottom: 20 })
      .width('100%')

      Divider()
        .strokeWidth(1)
        .color(AppColors.border)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
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
        cornerRadius: 14
      })

      Column() {
        Text(this.document.content.title.length > 0 ? this.document.content.title : '这张照片是否成立')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(36)
          .width('100%')
          .wordBreak(WordBreak.BREAK_WORD)
          .margin({ top: 22 })

        Row({ space: 8 }) {
          this.MetaLabel(formatReviewTime(this.document.updatedAt))
          this.MetaLabel(getImageRatioLabel(
            this.document.imageWidth,
            this.document.imageHeight,
            this.document.imageSizeFallbackUsed
          ))
        }
        .width('100%')
        .margin({ top: 14 })

        if (this.document.imageSizeFallbackUsed) {
          Text(getImageSizeText(this.document.imageWidth, this.document.imageHeight, true))
            .fontSize(12)
            .fontColor(AppColors.secondaryText)
            .lineHeight(18)
            .margin({ top: 10 })
            .width('100%')
        }

        this.Section('第一眼落点', this.document.content.firstLook)
        this.Section('是否成立', this.document.content.judgement)
        this.Section('卡点', this.document.content.blocker)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
