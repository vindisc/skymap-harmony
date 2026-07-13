import { AppColors, AppMetrics, AppTypography } from './AppDesign';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';

export enum StatusBannerTone {
  SUCCESS = 'success',
  INFO = 'info',
  WARNING = 'warning',
  ERROR = 'error',
  PROGRESS = 'progress'
}

interface StatusBannerPalette {
  text: string;
  background: string;
  border: string;
}

function resolveStatusBannerPalette(tone: StatusBannerTone): StatusBannerPalette {
  if (tone === StatusBannerTone.ERROR) {
    return {
      text: AppColors.danger,
      background: AppColors.dangerSoft,
      border: AppColors.danger
    };
  }
  if (tone === StatusBannerTone.WARNING) {
    return {
      text: AppColors.tagAmberText,
      background: AppColors.tagAmber,
      border: AppColors.borderStrong
    };
  }
  if (tone === StatusBannerTone.SUCCESS) {
    return {
      text: AppColors.tagGreenText,
      background: AppColors.tagGreen,
      border: AppColors.borderStrong
    };
  }
  if (tone === StatusBannerTone.PROGRESS) {
    return {
      text: AppColors.secondaryText,
      background: AppColors.surfaceElevated,
      border: AppColors.border
    };
  }
  return {
    text: AppColors.tagBlueText,
    background: AppColors.tagBlue,
    border: AppColors.border
  };
}

@Component
export struct InlineStatusBanner {
  @Prop tone: StatusBannerTone = StatusBannerTone.INFO;
  @Prop message: string = '';
  @Prop a11yLabel: string = '';

  build() {
    if (this.message.length > 0) {
      Text(this.message)
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(resolveStatusBannerPalette(this.tone).text)
        .lineHeight(AppTypography.bodyLineHeight)
        .textAlign(TextAlign.Center)
        .padding({
          left: AppMetrics.space16,
          right: AppMetrics.space16,
          top: AppMetrics.space10,
          bottom: AppMetrics.space10
        })
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(resolveStatusBannerPalette(this.tone).background)
        .border({ width: 1, color: resolveStatusBannerPalette(this.tone).border })
        .shadow(ElevationTokens.subtle)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .accessibilityText(this.a11yLabel.length > 0 ? this.a11yLabel : this.message)
        .transition(TransitionEffect.OPACITY.animation({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveStandard }))
    }
  }
}

@Component
export struct FloatingStatusBanner {
  @Prop tone: StatusBannerTone = StatusBannerTone.PROGRESS;
  @Prop message: string = '';
  @Prop a11yLabel: string = '';

  build() {
    if (this.message.length > 0) {
      Column() {
        InlineStatusBanner({
          tone: this.tone,
          message: this.message,
          a11yLabel: this.a11yLabel
        })
      }
      .width('100%')
      .padding({ bottom: AppMetrics.space8 })
      .zIndex(8)
      .transition(TransitionEffect.OPACITY.animation({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveStandard }))
    }
  }
}
