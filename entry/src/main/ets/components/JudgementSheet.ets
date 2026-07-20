import { normalizeReviewJudgement, ReviewJudgementStatus } from '../model/ReviewCardModel';
import { AppColors, AppMetrics, AppTypography } from './AppDesign';

const JUDGEMENT_OPTIONS: Array<ReviewJudgementStatus> = [
  ReviewJudgementStatus.VALID,
  ReviewJudgementStatus.UNSURE,
  ReviewJudgementStatus.INVALID
];

@Component
export struct JudgementSheet {
  @Prop value: string = ReviewJudgementStatus.UNSURE;
  onUpdate: (value: string) => void = () => {};
  onClose: () => void = () => {};

  build() {
    Column({ space: AppMetrics.space16 }) {
      Row() {
        Text('是否成立')
          .fontFamily('NotoSansSC-Bold')
          .fontSize(AppTypography.sectionTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .layoutWeight(1)

        Button('关闭')
          .fontFamily('NotoSansSC-Regular')
          .fontSize(AppTypography.smallButtonText)
          .fontColor(AppColors.primary)
          .backgroundColor(AppColors.transparent)
          .onClick(() => {
            this.onClose();
          })
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')

      Row({ space: AppMetrics.space8 }) {
        ForEach(JUDGEMENT_OPTIONS, (option: ReviewJudgementStatus) => {
          Button(option)
            .fontFamily(normalizeReviewJudgement(this.value) === option
              ? 'NotoSansSC-Bold'
              : 'NotoSansSC-Regular')
            .fontSize(AppTypography.buttonText)
            .fontWeight(normalizeReviewJudgement(this.value) === option ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(normalizeReviewJudgement(this.value) === option ? AppColors.onPrimary : AppColors.secondaryText)
            .layoutWeight(1)
            .height(AppMetrics.controlHeight)
            .borderRadius(AppMetrics.buttonRadius)
            .backgroundColor(normalizeReviewJudgement(this.value) === option
              ? AppColors.primary
              : AppColors.surfaceTint)
            .onClick(() => {
              this.onUpdate(option);
              this.onClose();
            })
        }, (option: ReviewJudgementStatus) => option)
      }
      .width('100%')
    }
    .width('100%')
    .padding(AppMetrics.cardPadding)
    .borderRadius({ topLeft: AppMetrics.cardRadius, topRight: AppMetrics.cardRadius })
    .backgroundColor(AppColors.surface)
  }
}
