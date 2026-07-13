import { MotionTokens } from '../../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../../theme/MotionQualityContext';

export type PressReactiveIntensity = 'soft' | 'firm';

@Builder
function EmptyPressReactiveContent() {
  Column() {}
}

@Component
export struct PressReactive {
  @Prop intensity: PressReactiveIntensity = 'soft';
  @Prop haptic: boolean = false;
  @BuilderParam content: () => void = EmptyPressReactiveContent;
  @State pressed: boolean = false;

  private resolvePressedScale(): number {
    return this.intensity === 'firm' ? MotionTokens.scalePressedHard : MotionTokens.scalePressed;
  }

  build() {
    Stack() {
      this.content()
    }
    .scale({
      x: this.pressed ? this.resolvePressedScale() : 1,
      y: this.pressed ? this.resolvePressedScale() : 1
    })
    .animation({
      duration: MotionQualityContext.resolveDuration(MotionTokens.durationQuick),
      curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_RESPONSIVE)
    })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
  }
}
