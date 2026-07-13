import { AppColors, AppTypography } from '../AppDesign';
import { MotionTokens } from '../../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../../theme/MotionQualityContext';

const COUNT_UP_FRAME_MS: number = 16;

@Component
export struct CountUpText {
  @Prop @Watch('onValueChanged') value: number = 0;
  @Prop durationMs: number = MotionTokens.durationStandard;
  @Prop suffix: string = '';
  @Prop fontSize: number = AppTypography.statNumber;
  @Prop fontColor: ResourceColor = AppColors.primary;
  @State displayedValue: number = 0;
  @State terminalScale: number = 1;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.displayedValue = this.value;
  }

  aboutToDisappear(): void {
    this.stopTween();
  }

  private onValueChanged(): void {
    this.startTween(this.displayedValue, this.value);
  }

  private startTween(from: number, to: number): void {
    this.stopTween();
    const duration: number = MotionQualityContext.resolveDuration(this.durationMs);
    if (duration <= COUNT_UP_FRAME_MS || from === to) {
      this.displayedValue = to;
      return;
    }
    const startedAt: number = Date.now();
    this.timerId = setInterval(() => {
      const progress: number = Math.min(1, (Date.now() - startedAt) / duration);
      this.displayedValue = Math.round(from + (to - from) * progress);
      if (progress >= 1) {
        this.stopTween();
        this.celebrateTerminalValue();
      }
    }, COUNT_UP_FRAME_MS);
  }

  private celebrateTerminalValue(): void {
    if (!MotionQualityContext.shouldPlayCeremony()) {
      return;
    }
    this.terminalScale = MotionTokens.scaleCeremony;
    setTimeout(() => {
      this.terminalScale = 1;
    }, MotionTokens.durationInstant);
  }

  private stopTween(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Text(`${this.displayedValue}${this.suffix}`)
      .fontSize(this.fontSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.fontColor)
      .maxLines(1)
      .scale({ x: this.terminalScale, y: this.terminalScale })
      .animation({
        duration: MotionTokens.durationQuick,
        curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_BOUNCY)
      })
  }
}
