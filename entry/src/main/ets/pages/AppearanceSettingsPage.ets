import common from '@ohos.app.ability.common';
import {
  HOME_HERO_IMAGE_PAGE,
  MOTION_SETTINGS_PAGE,
  WIDGET_CARD_BACKGROUND_PAGE
} from '../app/AppRouter';
import {
  AppBottomSafeAreaFill,
  AppColors,
  AppMetrics,
  AppTypography,
  SettingsEntryTone,
  SettingsLinkRow,
  SettingsPageHeader,
  SettingsScrollContainer
} from '../components/AppDesign';
import { RippleTouch } from '../components/motion/RippleTouch';
import { HomeHeroImageService } from '../services/HomeHeroImageService';
import {
  MotionQuality,
  REVIEW_WIDGET_CARD_BACKGROUND_PLAIN,
  ReviewSettingsService
} from '../services/ReviewSettingsService';
import { ToastService } from '../services/ToastService';
import { ElevationTokens } from '../theme/DesignTokens';

interface AppearanceSettingsLinkOptions {
  title: string;
  status: string;
  tone: SettingsEntryTone;
  onTap: () => void;
}

@Entry
@Component
struct AppearanceSettingsPage {
  private loadRequestId: number = 0;
  @State homeHeroImageCount: number = 0;
  @State widgetCardBackgroundStyle: string = REVIEW_WIDGET_CARD_BACKGROUND_PLAIN;
  @State motionQuality: MotionQuality = MotionQuality.FULL;
  @State shatterAnimationEnabled: boolean = true;
  @State isSavingShatterSetting: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadData();
  }

  onPageShow(): void {
    this.reloadData();
  }

  private async reloadData(): Promise<void> {
    const requestId: number = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    const context: common.UIAbilityContext = this.getAbilityContext();

    this.homeHeroImageCount = (await HomeHeroImageService.listImages(context)).length;
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.widgetCardBackgroundStyle = await ReviewSettingsService.loadWidgetCardBackgroundStyle(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.motionQuality = await ReviewSettingsService.loadMotionQuality(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.shatterAnimationEnabled = await ReviewSettingsService.loadShatterAnimationEnabled(context);
  }

  private resolveHomeHeroBadge(): string {
    return this.homeHeroImageCount <= 0 ? '默认' : `${this.homeHeroImageCount} 张`;
  }

  private resolveWidgetCardBackgroundBadge(): string {
    return ReviewSettingsService.resolveWidgetCardBackgroundLabel(this.widgetCardBackgroundStyle);
  }

  private openHomeHeroImage(): void {
    this.getUIContext().getRouter().pushUrl({ url: HOME_HERO_IMAGE_PAGE }).catch((error: Error) => {
      console.error(`[AppearanceSettingsPage] 打开首页图片设置失败：${error.message}`);
    });
  }

  private openWidgetCardBackground(): void {
    this.getUIContext().getRouter().pushUrl({ url: WIDGET_CARD_BACKGROUND_PAGE }).catch((error: Error) => {
      console.error(`[AppearanceSettingsPage] 打开卡片背景设置失败：${error.message}`);
    });
  }

  private openMotionSettings(): void {
    this.getUIContext().getRouter().pushUrl({ url: MOTION_SETTINGS_PAGE }).catch((error: Error) => {
      console.error(`[AppearanceSettingsPage] 打开显示与动效设置失败：${error.message}`);
    });
  }

  private async saveShatterAnimationEnabled(enabled: boolean): Promise<void> {
    if (this.isSavingShatterSetting || enabled === this.shatterAnimationEnabled) {
      return;
    }
    const previousValue: boolean = this.shatterAnimationEnabled;
    this.shatterAnimationEnabled = enabled;
    this.isSavingShatterSetting = true;
    try {
      this.shatterAnimationEnabled = await ReviewSettingsService.saveShatterAnimationEnabled(
        this.getAbilityContext(),
        enabled
      );
      ToastService.success(this.getUIContext(), this.shatterAnimationEnabled ? '删除星河效果已开启' : '删除星河效果已关闭');
    } catch (error) {
      this.shatterAnimationEnabled = previousValue;
      ToastService.error(this.getUIContext(), '星河效果设置保存失败，请重试');
    } finally {
      this.isSavingShatterSetting = false;
    }
  }

  @Builder
  RippleSettingsLinkRowContent(options: AppearanceSettingsLinkOptions) {
    SettingsLinkRow({
      title: options.title,
      status: options.status,
      tone: options.tone,
      dense: true,
      scaleOnPress: false,
      onTap: options.onTap
    })
  }

  @Builder
  RippleSettingsLinkRow(options: AppearanceSettingsLinkOptions) {
    RippleTouch({
      clipRadius: AppMetrics.cardRadius,
      content: () => {
        this.RippleSettingsLinkRowContent(options);
      }
    })
      .width('100%')
  }

  @Builder
  ShatterToggleRow() {
    Row({ space: AppMetrics.cardGap }) {
      Text('删除星河效果')
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.bodyLineHeight)
        .maxLines(1)
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.shatterAnimationEnabled })
        .selectedColor(AppColors.primary)
        .enabled(!this.isSavingShatterSetting)
        .opacity(this.isSavingShatterSetting ? 0.64 : 1)
        .onChange((enabled: boolean) => {
          this.saveShatterAnimationEnabled(enabled);
        })
    }
    .alignItems(VerticalAlign.Center)
    .padding({
      left: AppMetrics.cardPadding,
      right: AppMetrics.cardPadding,
      top: AppMetrics.space10,
      bottom: AppMetrics.space10
    })
    .width('100%')
    .constraintSize({ minHeight: 60 })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  AppearanceSettings() {
    Column({ space: AppMetrics.cardGap }) {
      this.RippleSettingsLinkRow({
        title: '首页图片',
        status: this.resolveHomeHeroBadge(),
        tone: this.homeHeroImageCount > 0 ? SettingsEntryTone.SUCCESS : SettingsEntryTone.MUTED,
        onTap: () => {
          this.openHomeHeroImage();
        }
      })

      this.RippleSettingsLinkRow({
        title: '卡片背景',
        status: this.resolveWidgetCardBackgroundBadge(),
        tone: SettingsEntryTone.DEFAULT,
        onTap: () => {
          this.openWidgetCardBackground();
        }
      })

      this.RippleSettingsLinkRow({
        title: '显示与动效',
        status: ReviewSettingsService.resolveMotionQualityLabel(this.motionQuality),
        tone: SettingsEntryTone.DEFAULT,
        onTap: () => {
          this.openMotionSettings();
        }
      })

      this.ShatterToggleRow()
    }
    .width('100%')
  }

  @Builder
  AppearanceSettingsContent() {
    SettingsPageHeader({ title: '外观与动效' })
    this.AppearanceSettings()
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AppBottomSafeAreaFill()

      SettingsScrollContainer({
        content: () => {
          this.AppearanceSettingsContent();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
