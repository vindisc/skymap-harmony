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
    Scroll() {
      Column({ space: AppMetrics.space24 }) {
        AppPageHeader({
          title: '复盘人',
          subtitle: '设置这台设备默认使用的复盘人名称。'
        })

        Column({ space: AppMetrics.space12 }) {
          Text('复盘人')
            .fontSize(AppTypography.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .width('100%')

          TextInput({ text: this.reviewerName, placeholder: '可留空' })
            .height(48)
            .borderRadius(AppMetrics.cardRadius)
            .fontSize(AppTypography.body)
            .fontColor(AppColors.text)
            .placeholderColor('#9AA1AB')
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
        .padding(AppMetrics.space16)
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surface)
        .border({ width: 1, color: AppColors.border })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space24 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
