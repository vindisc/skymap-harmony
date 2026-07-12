import common from '@ohos.app.ability.common';
import {
  AppBottomSafeAreaFill,
  AppColors,
  AppMetrics,
  AppTypography,
  SettingsEntryTone,
  SettingsLinkRow,
  SettingsPageHeader
} from '../components/AppDesign';
import { LearningProgressFormService } from '../services/LearningProgressFormService';
import {
  REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN,
  REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN_CORNER,
  REVIEW_WIDGET_CARD_BACKGROUND_PLAIN,
  ReviewSettingsService
} from '../services/ReviewSettingsService';
import { ToastService } from '../services/ToastService';

@Entry
@Component
struct WidgetCardBackgroundPage {
  @State widgetCardBackgroundStyle: string = REVIEW_WIDGET_CARD_BACKGROUND_PLAIN;

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.loadWidgetCardBackgroundStyle();
  }

  onPageShow(): void {
    this.loadWidgetCardBackgroundStyle();
  }

  private async loadWidgetCardBackgroundStyle(): Promise<void> {
    this.widgetCardBackgroundStyle = await ReviewSettingsService.loadWidgetCardBackgroundStyle(this.getAbilityContext());
  }

  private resolveWidgetCardBackgroundBadge(): string {
    return ReviewSettingsService.resolveWidgetCardBackgroundLabel(this.widgetCardBackgroundStyle);
  }

  private async saveWidgetCardBackgroundStyle(style: string): Promise<void> {
    if (style === this.widgetCardBackgroundStyle) {
      return;
    }

    try {
      const context = this.getAbilityContext();
      const savedStyle: string = await ReviewSettingsService.saveWidgetCardBackgroundStyle(context, style);
      this.widgetCardBackgroundStyle = savedStyle;
      await LearningProgressFormService.refreshAllForms(context);
      ToastService.success(this.getUIContext(), `卡片背景已切换为${this.resolveWidgetCardBackgroundBadge()}`);
    } catch (error) {
      console.error(`[WidgetCardBackgroundPage] 保存卡片背景失败：${error}`);
      ToastService.error(this.getUIContext(), '卡片背景保存失败，请重试');
    }
  }

  @Builder
  WidgetBackgroundOption(title: string, subtitle: string, style: string) {
    SettingsLinkRow({
      title: title,
      value: subtitle,
      status: this.widgetCardBackgroundStyle === style ? '当前使用' : '',
      tone: SettingsEntryTone.DEFAULT,
      dense: true,
      onTap: () => {
        this.saveWidgetCardBackgroundStyle(style);
      }
    })
  }

  @Builder
  BackgroundOptions() {
    Column({ space: AppMetrics.cardGap }) {
      this.WidgetBackgroundOption('素纸', '清爽留白', REVIEW_WIDGET_CARD_BACKGROUND_PLAIN)
      this.WidgetBackgroundOption('密集回纹', '低对比度连续铺陈', REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN)
      this.WidgetBackgroundOption('回纹角花', '四角沿边，保留中央留白', REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN_CORNER)
    }
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AppBottomSafeAreaFill()

      Scroll() {
        Column({ space: AppMetrics.sectionGap }) {
          SettingsPageHeader({
            title: '卡片背景'
          })

          Text('选定后会立即同步到桌面卡片。回纹以低对比度铺在底层，不影响数据阅读。')
            .fontSize(AppTypography.body)
            .lineHeight(AppTypography.bodyLineHeight)
            .fontColor(AppColors.secondaryText)
            .width('100%')

          this.BackgroundOptions()
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
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(AppColors.pageBackground)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
