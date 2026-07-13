import { MotionTokens } from '../../theme/DesignTokens';

@Component
export struct ShimmerBox {
  @Prop boxWidth: Length = '100%';
  @Prop boxHeight: Length = 20;
  @Prop boxRadius: number = 10;
  @State shimmerOffset: number = -120;
  @State shimmerAnimating: boolean = false;
  private timerId: number = -1;
  private resetTimerId: number = -1;
  private visible: boolean = false;

  aboutToAppear(): void {
    this.visible = true;
    this.startLoop();
  }

  aboutToDisappear(): void {
    this.visible = false;
    this.stopLoop();
  }

  private startLoop(): void {
    if (!this.visible || this.timerId >= 0) {
      return;
    }
    this.shimmerAnimating = true;
    this.shimmerOffset = 120;
    this.timerId = setTimeout(() => {
      this.timerId = -1;
      if (!this.visible) {
        return;
      }
      this.shimmerAnimating = false;
      this.shimmerOffset = -120;
      this.resetTimerId = setTimeout(() => {
        this.resetTimerId = -1;
        this.startLoop();
      }, MotionTokens.durationInstant);
    }, MotionTokens.durationShimmer);
  }

  private stopLoop(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
    if (this.resetTimerId >= 0) {
      clearTimeout(this.resetTimerId);
      this.resetTimerId = -1;
    }
  }

  build() {
    Stack() {
      Column()
        .width('52%')
        .height('100%')
        .linearGradient({
          angle: 90,
          colors: [['#00FFFFFF', 0], ['#66FFFFFF', 0.5], ['#00FFFFFF', 1]]
        })
        .translate({ x: `${this.shimmerOffset}%` })
        .animation({ duration: this.shimmerAnimating ? MotionTokens.durationShimmer : 0, curve: Curve.Linear })
    }
    .width(this.boxWidth)
    .height(this.boxHeight)
    .borderRadius(this.boxRadius)
    .backgroundColor('#FFE8E6E1')
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
  }
}
