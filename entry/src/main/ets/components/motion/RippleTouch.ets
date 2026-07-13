import { AppColors } from '../AppDesign';
import { MotionTokens } from '../../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../../theme/MotionQualityContext';

@Builder
function EmptyRippleContent() {
  Column() {}
}

@Component
export struct RippleTouch {
  @Prop tint: ResourceColor = AppColors.primary;
  @BuilderParam content: () => void = EmptyRippleContent;
  @State rippleScale: number = 0;
  @State rippleOpacity: number = 0;
  @State originX: number = 0;
  @State originY: number = 0;
  private resetTimerId: number = -1;

  aboutToDisappear(): void {
    if (this.resetTimerId >= 0) {
      clearTimeout(this.resetTimerId);
      this.resetTimerId = -1;
    }
  }

  private play(event: TouchEvent): void {
    if (event.touches.length > 0) {
      this.originX = event.touches[0].x;
      this.originY = event.touches[0].y;
    }
    this.rippleScale = 0.1;
    this.rippleOpacity = 0.18;
    setTimeout(() => {
      this.rippleScale = 1;
      this.rippleOpacity = 0;
    }, 24);
    this.resetTimerId = setTimeout(() => {
      this.rippleScale = 0;
      this.resetTimerId = -1;
    }, MotionTokens.durationStandard);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.content()

      Circle()
        .width(240)
        .height(240)
        .fill(this.tint)
        .opacity(this.rippleOpacity)
        .scale({ x: this.rippleScale, y: this.rippleScale })
        .position({ x: this.originX - 120, y: this.originY - 120 })
        .animation({
          duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
          curve: MotionQualityContext.resolveCurve(MotionCurveRole.EMPHASIZED)
        })
        .hitTestBehavior(HitTestMode.None)
    }
    .clip(true)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.play(event);
      }
    })
  }
}
