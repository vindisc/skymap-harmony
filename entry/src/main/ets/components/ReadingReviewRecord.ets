import {
  createDefaultReviewCardDocument,
  normalizeReviewJudgement,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { formatReviewTime } from '../utils/ImageLayoutUtils';
import { AppColors, AppMetrics, AppTypography } from './AppDesign';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

@Component
export struct ReadingReviewRecord {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop saveStateLabel: string = '';

  private hasValue(value: string): boolean {
    return value.trim().length > 0;
  }

  private getJudgementLabel(): string {
    const judgement = normalizeReviewJudgement(this.document.content.judgement);
    if (judgement === '成立') {
      return '成立';
    }
    if (judgement === '不成立') {
      return '不成立';
    }
    return '待判断';
  }

  private getSaveStateTextColor(): string {
    if (this.saveStateLabel === '已导出') {
      return AppColors.tagBlueText;
    }
    if (this.saveStateLabel === '未保存') {
      return AppColors.tagAmberText;
    }
    return AppColors.secondaryText;
  }

  private getSaveStateBackground(): string {
    if (this.saveStateLabel === '已导出') {
      return AppColors.tagBlue;
    }
    if (this.saveStateLabel === '未保存') {
      return AppColors.tagAmber;
    }
    return AppColors.surfaceTint;
  }

  @Builder
  MetaTag(label: string) {
    Text(label)
      .fontFamily('NotoSansSC-Regular')
      .fontSize(AppTypography.caption)
      .fontWeight(FontWeight.Medium)
      .fontColor(label === '成立' ? AppColors.tagGreenText : (label === '不成立' ? AppColors.tagAmberText : AppColors.secondaryText))
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(AppMetrics.capsuleRadius)
      .backgroundColor(label === '成立' ? AppColors.tagGreen : (label === '不成立' ? AppColors.tagAmber : AppColors.primarySoft))
  }

  @Builder
  SaveStateTag() {
    if (this.saveStateLabel.length > 0) {
      Text(this.saveStateLabel)
        .fontFamily('NotoSansSC-Regular')
        .fontSize(AppTypography.caption)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getSaveStateTextColor())
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(AppMetrics.capsuleRadius)
        .backgroundColor(this.getSaveStateBackground())
        .maxLines(1)
    }
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
          .margin({ bottom: AppMetrics.space16 })
      }

      Text(label)
        .fontFamily('NotoSansSC-Regular')
        .fontSize(AppTypography.auxiliary)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.mutedText)
        .width('100%')

      Text(value.length > 0 ? value : '待补充')
        .fontFamily('NotoSansSC-Regular')
        .fontSize(AppTypography.body)
        .fontColor(value.length > 0 ? AppColors.text : AppColors.secondaryText)
        .lineHeight(AppTypography.bodyLineHeight)
        .width('100%')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
        .margin({ top: AppMetrics.space8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ top: 0, bottom: AppMetrics.space16 })
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
          .fontFamily('NotoSansSC-Bold')
          .fontSize(AppTypography.level2)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.level2LineHeight)
          .width('100%')
          .wordBreak(WordBreak.BREAK_WORD)
          .margin({ top: AppMetrics.space24 })

        Row({ space: AppMetrics.space16 }) {
          Text(formatReviewTime(this.document.updatedAt))
            .fontFamily('NotoSansSC-Regular')
            .fontSize(AppTypography.auxiliary)
            .fontColor(AppColors.secondaryText)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: AppMetrics.space8 }) {
            this.MetaTag(this.getJudgementLabel())
            this.SaveStateTag()
          }
          .alignItems(VerticalAlign.Center)
        }
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .margin({ top: AppMetrics.space16 })

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
              this.getJudgementLabel(),
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
        .margin({ top: AppMetrics.space16 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
