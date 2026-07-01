import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import {
  AppColors,
  AppMetrics,
  AppTypography,
  PrimaryButton,
  SettingsPageHeader
} from '../components/AppDesign';
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

  private resolvePreviewName(): string {
    const name = this.reviewerName.trim();
    return name.length > 0 ? name : '未设置';
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
      Column({ space: AppMetrics.sectionGap }) {
        SettingsPageHeader({
          title: '复盘人'
        })

        Column({ space: AppMetrics.space8 }) {
          Column({ space: 4 }) {
            Text(this.resolvePreviewName())
              .fontSize(AppTypography.cardTitle)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .lineHeight(AppTypography.cardTitleLineHeight)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .padding(AppMetrics.cardPadding)
          .width('100%')
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(AppColors.surface)
          .border({ width: 1, color: AppColors.border })
        }
        .width('100%')

        Column({ space: AppMetrics.cardGap }) {
          TextInput({ text: this.reviewerName, placeholder: '可留空' })
            .height(AppMetrics.controlHeight)
            .borderRadius(AppMetrics.buttonRadius)
            .fontSize(AppTypography.inputText)
            .fontColor(AppColors.text)
            .placeholderColor(AppColors.placeholderText)
            .backgroundColor(AppColors.surface)
            .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
            .border({ width: 1, color: AppColors.border })
            .onChange((value: string) => {
              this.reviewerName = value;
            })
        }
        .padding(AppMetrics.cardPadding)
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surface)
        .border({ width: 1, color: AppColors.border })

        PrimaryButton({
          label: this.isSaving ? '保存中…' : '保存',
          isDisabled: this.isSaving,
          onTap: () => {
            this.saveReviewerName();
          }
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({
        left: AppMetrics.pagePadding,
        right: AppMetrics.pagePadding,
        top: AppMetrics.pageTopPadding,
        bottom: AppMetrics.pageBottomPadding + AppMetrics.space24
      })
      .height('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
