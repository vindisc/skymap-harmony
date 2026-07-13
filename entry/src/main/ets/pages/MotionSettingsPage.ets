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
import { MotionQuality, ReviewSettingsService } from '../services/ReviewSettingsService';
import { ToastService } from '../services/ToastService';
import { MotionQualityContext } from '../theme/MotionQualityContext';

@Entry
@Component
struct MotionSettingsPage {
  @State motionQuality: MotionQuality = MotionQuality.FULL;
  @State isSaving: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.loadMotionQuality();
  }

  private async loadMotionQuality(): Promise<void> {
    this.motionQuality = await MotionQualityContext.initialize(this.getAbilityContext());
  }

  private async saveMotionQuality(value: MotionQuality): Promise<void> {
    if (this.isSaving || value === this.motionQuality) {
      return;
    }
    this.isSaving = true;
    try {
      const savedValue: MotionQuality = await ReviewSettingsService.saveMotionQuality(this.getAbilityContext(), value);
      this.motionQuality = savedValue;
      MotionQualityContext.setQuality(savedValue);
      ToastService.success(
        this.getUIContext(),
        `动效强度已切换为${ReviewSettingsService.resolveMotionQualityLabel(savedValue)}`
      );
    } catch (error) {
      ToastService.error(this.getUIContext(), '动效设置保存失败，请重试');
    } finally {
      this.isSaving = false;
    }
  }

  @Builder
  MotionOption(title: string, subtitle: string, value: MotionQuality) {
    SettingsLinkRow({
      title: title,
      value: subtitle,
      status: this.motionQuality === value ? '当前使用' : '',
      tone: this.motionQuality === value ? SettingsEntryTone.SUCCESS : SettingsEntryTone.DEFAULT,
      dense: true,
      onTap: () => {
        this.saveMotionQuality(value);
      }
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AppBottomSafeAreaFill()

      Scroll() {
        Column({ space: AppMetrics.sectionGap }) {
          SettingsPageHeader({ title: '显示与动效' })

          Column({ space: AppMetrics.space8 }) {
            Text('动效强度')
              .fontSize(AppTypography.cardTitle)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .width('100%')

            Text('控制里程碑动画与页面转场的强度。')
              .fontSize(AppTypography.body)
              .lineHeight(AppTypography.bodyLineHeight)
              .fontColor(AppColors.secondaryText)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Column({ space: AppMetrics.cardGap }) {
            this.MotionOption('完整', '分层转场、弹性回应与里程碑动画', MotionQuality.FULL)
            this.MotionOption('舒缓', '保留方向与层次，关闭弹性超冲和庆祝粒子', MotionQuality.CALM)
            this.MotionOption('最少', '只保留必要的短过渡，不播放分批与粒子动画', MotionQuality.MINIMAL)
          }
          .width('100%')
          .opacity(this.isSaving ? 0.68 : 1)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: AppMetrics.pageTopPadding,
          bottom: AppMetrics.pageBottomPadding + AppMetrics.space24
        })
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
