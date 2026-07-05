import {
  AppColors,
  AppMetrics,
  AppTypography,
  ReviewJudgementBadge,
  SecondaryButton,
  TagLabel
} from './AppDesign';
import { ElevationTokens } from '../theme/DesignTokens';
import {
  createEmptyReviewAssistantInsight,
  ReviewAssistantDraftAction,
  ReviewAssistantInsight,
  ReviewAssistantPromptItem
} from '../services/ReviewAssistantService';

@Component
export struct ReviewAssistantPanel {
  @Prop insight: ReviewAssistantInsight = createEmptyReviewAssistantInsight();
  onApplyDraft: (action: ReviewAssistantDraftAction) => void = () => {};
  onFocusField: (field: string) => void = () => {};

  @Builder
  SectionTitle(title: string, subtitle: string = '') {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(AppTypography.sectionTitle)
        .fontWeight(700)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.sectionTitleLineHeight)
        .width('100%')
      if (subtitle.length > 0) {
        Text(subtitle)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Column({ space: AppMetrics.space16 }) {
      Row() {
        this.SectionTitle('AI 复盘助手', '只基于你当前填写的内容生成建议，不会上传照片。')
        Blank()
        TagLabel({
          label: `${this.insight.readinessScore}%`,
          color: AppColors.primary,
          tagBackground: AppColors.primarySoft
        })
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')

      Column({ space: AppMetrics.space10 }) {
        Text(`已完成 ${this.insight.completedFieldCount}/${this.insight.totalFieldCount}`)
          .fontSize(AppTypography.meta)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.primary)
          .width('100%')
        Text(this.insight.summary)
          .fontSize(AppTypography.body)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(AppMetrics.cardPadding)
      .width('100%')
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(AppColors.primarySoft)

      Column({ space: AppMetrics.space10 }) {
        Text('下一步最值得补什么')
          .fontSize(AppTypography.cardTitle)
          .fontWeight(700)
          .fontColor(AppColors.text)
          .width('100%')
        Text(this.insight.nextQuestion)
          .fontSize(AppTypography.body)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(AppMetrics.cardPadding)
      .width('100%')
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(AppColors.surfaceElevated)
      .border({ width: 1, color: AppColors.border })

      Column({ space: AppMetrics.space10 }) {
        Text('判断建议')
          .fontSize(AppTypography.cardTitle)
          .fontWeight(700)
          .fontColor(AppColors.text)
          .width('100%')
        ReviewJudgementBadge({ value: this.insight.suggestedJudgement })
        Text(this.insight.suggestedJudgementReason)
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(AppMetrics.cardPadding)
      .width('100%')
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(AppColors.surfaceElevated)
      .border({ width: 1, color: AppColors.border })

      if (this.insight.strengths.length > 0) {
        Column({ space: AppMetrics.space10 }) {
          Text('已经做得不错')
            .fontSize(AppTypography.cardTitle)
            .fontWeight(700)
            .fontColor(AppColors.text)
            .width('100%')
          ForEach(this.insight.strengths, (strength: string, index: number) => {
            Text(`${index + 1}. ${strength}`)
              .fontSize(AppTypography.body)
              .fontColor(AppColors.text)
              .lineHeight(AppTypography.bodyLineHeight)
              .width('100%')
          })
        }
        .alignItems(HorizontalAlign.Start)
        .padding(AppMetrics.cardPadding)
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surfaceElevated)
        .border({ width: 1, color: AppColors.border })
      }

      if (this.insight.missingPrompts.length > 0) {
        Column({ space: AppMetrics.space12 }) {
          Text('关键追问')
            .fontSize(AppTypography.cardTitle)
            .fontWeight(700)
            .fontColor(AppColors.text)
            .width('100%')
          ForEach(this.insight.missingPrompts, (prompt: ReviewAssistantPromptItem) => {
            Column({ space: AppMetrics.space10 }) {
              Text(prompt.label)
                .fontSize(AppTypography.meta)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.primary)
                .width('100%')
              Text(prompt.question)
                .fontSize(AppTypography.body)
                .fontColor(AppColors.text)
                .lineHeight(AppTypography.bodyLineHeight)
                .width('100%')
              Text(prompt.reason)
                .fontSize(AppTypography.caption)
                .fontColor(AppColors.secondaryText)
                .lineHeight(AppTypography.captionLineHeight)
                .width('100%')
              SecondaryButton({
                label: `去补充${prompt.label}`,
                onTap: () => {
                  this.onFocusField(prompt.key);
                }
              })
            }
            .alignItems(HorizontalAlign.Start)
            .padding(AppMetrics.cardPadding)
            .width('100%')
            .borderRadius(AppMetrics.cardRadius)
            .backgroundColor(AppColors.surfaceTint)
            .border({ width: 1, color: AppColors.border })
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      if (this.insight.draftActions.length > 0) {
        Column({ space: AppMetrics.space12 }) {
          Text('可直接带入的建议')
            .fontSize(AppTypography.cardTitle)
            .fontWeight(700)
            .fontColor(AppColors.text)
            .width('100%')
          ForEach(this.insight.draftActions, (action: ReviewAssistantDraftAction) => {
            Column({ space: AppMetrics.space10 }) {
              Text(action.label)
                .fontSize(AppTypography.meta)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.primary)
                .width('100%')
              Text(action.text)
                .fontSize(AppTypography.body)
                .fontColor(AppColors.text)
                .lineHeight(AppTypography.bodyLineHeight)
                .maxLines(5)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
              SecondaryButton({
                label: action.label,
                onTap: () => {
                  this.onApplyDraft(action);
                }
              })
            }
            .alignItems(HorizontalAlign.Start)
            .padding(AppMetrics.cardPadding)
            .width('100%')
            .borderRadius(AppMetrics.cardRadius)
            .backgroundColor(AppColors.surfaceElevated)
            .border({ width: 1, color: AppColors.border })
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.borderStrong })
    .shadow(ElevationTokens.subtle)
  }
}
