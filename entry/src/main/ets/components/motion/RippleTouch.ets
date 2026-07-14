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
  @Prop clipRadius: number = 0;
  @BuilderParam content: () => void = EmptyRippleContent;
  @State rippleScale: number = 0;
  @State rippleOpacity: number = 0;
  @State originX: number = 0;
  @State originY: number = 0;
  private startTimerId: number = -1;
  private resetTimerId: number = -1;

  aboutToDisappear(): void {
    this.cancelTimers();
  }

  private cancelTimers(): void {
    if (this.startTimerId >= 0) {
      clearTimeout(this.startTimerId);
      this.startTimerId = -1;
    }
    if (this.resetTimerId >= 0) {
      clearTimeout(this.resetTimerId);
      this.resetTimerId = -1;
    }
  }

  private play(event: TouchEvent): void {
    this.cancelTimers();
    if (event.touches.length > 0) {
      this.originX = event.touches[0].x;
      this.originY = event.touches[0].y;
    }
    this.rippleScale = 0.1;
    this.rippleOpacity = 0.18;
    this.startTimerId = setTimeout(() => {
      this.rippleScale = 1;
      this.rippleOpacity = 0;
      this.startTimerId = -1;
    }, MotionTokens.durationFrame);
    this.resetTimerId = setTimeout(() => {
      this.rippleScale = 0;
      this.resetTimerId = -1;
    }, MotionTokens.durationStandard);
  }

  @Builder
  RippleLayer() {
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

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.content()
    }
    .overlay(
      () => {
        this.RippleLayer();
      },
      { align: Alignment.TopStart }
    )
    .borderRadius(this.clipRadius)
    .clip(true)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.play(event);
      }
    })
  }
}
