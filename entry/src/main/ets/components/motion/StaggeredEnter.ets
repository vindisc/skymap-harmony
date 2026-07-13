import { MotionTokens } from '../../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../../theme/MotionQualityContext';

@Builder
function EmptyStaggeredContent() {
  Column() {}
}

export class EnterCoordinator {
  static resolveBatchIndex(batchIndex: number, batchSize: number): number {
    const normalizedSize: number = Math.max(1, batchSize);
    return Math.min(4, Math.floor(Math.max(0, batchIndex) / normalizedSize));
  }

  static resolveDelay(batchIndex: number, batchSize: number, delayMs: number): number {
    if (!MotionQualityContext.shouldPlayStagger()) {
      return 0;
    }
    return EnterCoordinator.resolveBatchIndex(batchIndex, batchSize) * Math.max(0, delayMs);
  }
}

@Component
export struct StaggeredEnter {
  @Prop batchIndex: number = 0;
  @Prop batchSize: number = 1;
  @Prop delayMs: number = MotionTokens.durationStagger;
  @BuilderParam content: () => void = EmptyStaggeredContent;
  @State entered: boolean = false;
  private timerId: number = -1;

  aboutToAppear(): void {
    const delay: number = EnterCoordinator.resolveDelay(this.batchIndex, this.batchSize, this.delayMs);
    this.timerId = setTimeout(() => {
      this.entered = true;
      this.timerId = -1;
    }, delay);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Column() {
      this.content()
    }
    .opacity(this.entered ? 1 : 0)
    .translate({ y: this.entered ? 0 : MotionTokens.offsetEnterY })
    .animation({
      duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
      curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_SOFT)
    })
  }
}
