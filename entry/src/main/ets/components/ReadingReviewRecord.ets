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

  private hasValue(value: string): boolean {
    return value.trim().length > 0;
  }

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
          .opacity(0.18)
          .width('100%')
          .margin({ bottom: 10 })
      }

      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.mutedText)
        .width('100%')

      Text(value.length > 0 ? value : '待补充')
        .fontSize(15)
        .fontColor(value.length > 0 ? AppColors.text : AppColors.secondaryText)
        .lineHeight(23)
        .width('100%')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
        .margin({ top: 5 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: showDivider ? 0 : 2, bottom: 14 })
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
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(32)
          .width('100%')
          .wordBreak(WordBreak.BREAK_WORD)
          .margin({ top: 18 })

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
        .margin({ top: 8 })

        Column() {
          if (this.hasValue(this.document.content.visualFocus)) {
            this.Section('视觉落点', this.document.content.visualFocus, false)
          }
          if (this.hasValue(this.document.content.focusReason)) {
            this.Section('落点原因', this.document.content.focusReason, this.hasValue(this.document.content.visualFocus))
          }
          if (this.hasValue(this.document.content.visualPath)) {
            this.Section(
              '视线路径',
              this.document.content.visualPath,
              this.hasValue(this.document.content.visualFocus) || this.hasValue(this.document.content.focusReason)
            )
          }
          if (this.hasValue(this.document.content.visibleFacts)) {
            this.Section(
              '画面事实',
              this.document.content.visibleFacts,
              this.hasValue(this.document.content.visualFocus)
                || this.hasValue(this.document.content.focusReason)
                || this.hasValue(this.document.content.visualPath)
            )
          }
          if (this.hasValue(this.document.content.coreRelation)) {
            this.Section(
              '核心关系',
              this.document.content.coreRelation,
              this.hasValue(this.document.content.visualFocus)
                || this.hasValue(this.document.content.focusReason)
                || this.hasValue(this.document.content.visualPath)
                || this.hasValue(this.document.content.visibleFacts)
            )
          }
          if (this.hasValue(this.document.content.judgement)) {
            this.Section(
              '是否成立',
              this.document.content.judgement,
              this.hasValue(this.document.content.visualFocus)
                || this.hasValue(this.document.content.focusReason)
                || this.hasValue(this.document.content.visualPath)
                || this.hasValue(this.document.content.visibleFacts)
                || this.hasValue(this.document.content.coreRelation)
            )
          }
          if (this.hasValue(this.document.content.extendedUnderstanding)) {
            this.Section(
              '延伸理解',
              this.document.content.extendedUnderstanding,
              this.hasValue(this.document.content.visualFocus)
                || this.hasValue(this.document.content.focusReason)
                || this.hasValue(this.document.content.visualPath)
                || this.hasValue(this.document.content.visibleFacts)
                || this.hasValue(this.document.content.coreRelation)
                || this.hasValue(this.document.content.judgement)
            )
          }
          if (this.hasValue(this.document.content.currentBlocker)) {
            this.Section(
              '当前卡点',
              this.document.content.currentBlocker,
              this.hasValue(this.document.content.visualFocus)
                || this.hasValue(this.document.content.focusReason)
                || this.hasValue(this.document.content.visualPath)
                || this.hasValue(this.document.content.visibleFacts)
                || this.hasValue(this.document.content.coreRelation)
                || this.hasValue(this.document.content.judgement)
                || this.hasValue(this.document.content.extendedUnderstanding)
            )
          }
        }
        .margin({ top: 12 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
