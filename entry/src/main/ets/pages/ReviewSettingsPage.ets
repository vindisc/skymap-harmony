import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { AppColors, AppMetrics, AppTypography, PrimaryButton } from '../components/AppDesign';
import { ReviewSettingsService } from '../services/ReviewSettingsService';

@Entry
@Component
struct ReviewSettingsPage {
  private loadRequestId: number = 0;
  @State reviewerName: string = '';
  @State isSaving: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    const requestId = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    const reviewerName = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.reviewerName = reviewerName;
  }

  private async saveSettings(): Promise<void> {
    if (this.isSaving) {
      return;
    }

    this.isSaving = true;
    try {
      this.reviewerName = await ReviewSettingsService.saveReviewerName(this.getAbilityContext(), this.reviewerName);
      promptAction.showToast({ message: '已保存复盘设置' });
    } catch (error) {
      promptAction.showToast({ message: '保存失败，请稍后重试' });
    } finally {
      this.isSaving = false;
    }
  }

  @Builder
  Header() {
    Row() {
      Blank()

      Text('复盘设置')
        .fontSize(AppTypography.level2)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.level2LineHeight)

      Blank()
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height(AppTypography.level2LineHeight)
  }

  build() {
    Column() {
      this.Header()

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
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ top: AppMetrics.space32 })

      Blank()

      PrimaryButton({
        label: this.isSaving ? '保存中...' : '保存',
        isDisabled: this.isSaving,
        onTap: () => {
          this.saveSettings();
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
