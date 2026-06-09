import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { AppColors, PrimaryButton } from '../components/AppDesign';
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
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)

      Blank()
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height(30)
  }

  build() {
    Column() {
      this.Header()

      Column({ space: 10 }) {
        Text('复盘人')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .width('100%')

        TextInput({ text: this.reviewerName, placeholder: '可留空' })
          .height(48)
          .borderRadius(10)
          .fontSize(16)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surfaceMuted)
          .padding({ left: 16, right: 16 })
          .border({ width: 1, color: AppColors.border })
          .onChange((value: string) => {
            this.reviewerName = value;
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ top: 28 })

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
    .padding({ left: 22, right: 22, top: 18, bottom: 34 })
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
