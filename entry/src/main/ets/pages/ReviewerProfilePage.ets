import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { AppColors, AppMetrics, AppPageHeader, AppTypography, PrimaryButton } from '../components/AppDesign';
import { ReviewSettingsService } from '../services/ReviewSettingsService';

@Entry
@Component
struct ReviewerProfilePage {
  @State reviewerName: string = '';
  @State isSaving: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.loadReviewerName();
  }

  private async loadReviewerName(): Promise<void> {
    this.reviewerName = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
  }

  private async saveReviewerName(): Promise<void> {
    if (this.isSaving) {
      return;
    }

    this.isSaving = true;
    try {
      this.reviewerName = await ReviewSettingsService.saveReviewerName(this.getAbilityContext(), this.reviewerName);
      promptAction.showToast({ message: '已保存复盘人' });
    } catch (error) {
      promptAction.showToast({ message: '保存失败，请稍后重试' });
    } finally {
      this.isSaving = false;
    }
  }

  build() {
    Column({ space: AppMetrics.space32 }) {
      AppPageHeader({
        title: '复盘人',
        subtitle: '设置这台设备默认使用的复盘人名称。'
      })

      Column({ space: AppMetrics.cardGap }) {
        Text('复盘人')
          .fontSize(AppTypography.inputLabel)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.inputLabelLineHeight)
          .width('100%')

        TextInput({ text: this.reviewerName, placeholder: '可留空' })
          .height(AppMetrics.controlHeight)
          .borderRadius(AppMetrics.cardRadius)
          .fontSize(AppTypography.inputText)
          .fontColor(AppColors.text)
          .placeholderColor(AppColors.placeholderText)
          .backgroundColor(AppColors.surfaceMuted)
          .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
          .border({ width: 1, color: AppColors.border })
          .onChange((value: string) => {
            this.reviewerName = value;
          })

        PrimaryButton({
          label: this.isSaving ? '保存中...' : '保存',
          isDisabled: this.isSaving,
          onTap: () => {
            this.saveReviewerName();
          }
        })
      }
      .padding(AppMetrics.cardPadding)
      .width('100%')
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(AppColors.surface)
      .border({ width: 1, color: AppColors.border })
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: AppMetrics.pageBottomPadding })
    .backgroundColor(AppColors.pageBackground)
  }
}
