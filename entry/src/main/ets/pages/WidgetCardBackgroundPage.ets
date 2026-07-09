import common from '@ohos.app.ability.common';
import {
  AppBottomSafeAreaFill,
  AppColors,
  AppMetrics,
  AppTypography,
  SettingsPageHeader
} from '../components/AppDesign';
import { LearningProgressFormService } from '../services/LearningProgressFormService';
import {
  REVIEW_WIDGET_CARD_BACKGROUND_PLAIN,
  REVIEW_WIDGET_CARD_BACKGROUND_TEXTURE,
  ReviewSettingsService
} from '../services/ReviewSettingsService';
import { ToastService } from '../services/ToastService';
import { ElevationTokens } from '../theme/DesignTokens';

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
      ToastService.show(this.getUIContext(), `卡片背景已切换为${this.resolveWidgetCardBackgroundBadge()}`);
    } catch (error) {
      console.error(`[WidgetCardBackgroundPage] 保存卡片背景失败：${error}`);
      ToastService.show(this.getUIContext(), '卡片背景保存失败，请重试');
    }
  }

  @Builder
  WidgetBackgroundOption(title: string, subtitle: string, style: string, textured: boolean) {
    Column({ space: 6 }) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(AppColors.surface)

        if (textured) {
          Image($r('app.media.widget_card_texture'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .opacity(0.46)
            .hitTestBehavior(HitTestMode.None)
        }

        Text('Aa')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
      }
      .width(58)
      .height(42)
      .borderRadius(14)
      .clip(true)
      .border({
        width: 1,
        color: this.widgetCardBackgroundStyle === style ? AppColors.primary : AppColors.border
      })

      Text(title)
        .fontSize(AppTypography.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.widgetCardBackgroundStyle === style ? AppColors.primary : AppColors.text)
        .lineHeight(AppTypography.metaLineHeight)
        .maxLines(1)

      Text(subtitle)
        .fontSize(10)
        .fontColor(AppColors.secondaryText)
        .lineHeight(14)
        .maxLines(1)
    }
    .layoutWeight(1)
    .height(104)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(AppMetrics.inputRadius)
    .backgroundColor(this.widgetCardBackgroundStyle === style ? AppColors.primarySoft : AppColors.surfaceTint)
    .border({
      width: this.widgetCardBackgroundStyle === style ? 1.5 : 1,
      color: this.widgetCardBackgroundStyle === style ? AppColors.primary : AppColors.border
    })
    .onClick(() => {
      this.saveWidgetCardBackgroundStyle(style);
    })
  }

  @Builder
  BackgroundOptionsCard() {
    Column({ space: AppMetrics.space10 }) {
      Row({ space: AppMetrics.space10 }) {
        this.WidgetBackgroundOption('白色', '当前样式', REVIEW_WIDGET_CARD_BACKGROUND_PLAIN, false)
        this.WidgetBackgroundOption('纹理', '浅螺旋纹', REVIEW_WIDGET_CARD_BACKGROUND_TEXTURE, true)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: AppMetrics.cardPadding,
      right: AppMetrics.cardPadding,
      top: AppMetrics.space10,
      bottom: AppMetrics.space10
    })
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AppBottomSafeAreaFill()

      Scroll() {
        Column({ space: AppMetrics.sectionGap }) {
          SettingsPageHeader({
            title: '卡片背景'
          })

          this.BackgroundOptionsCard()
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: AppMetrics.settingsSubpageTopPadding,
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
      .translate({ y: AppMetrics.settingsSubpageTopCompensation })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
