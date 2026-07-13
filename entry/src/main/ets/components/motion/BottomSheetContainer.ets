import { AppColors, AppMetrics } from '../AppDesign';
import { MotionTokens } from '../../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../../theme/MotionQualityContext';

@Builder
function EmptyBottomSheetContent() {
  Column() {}
}

@Component
export struct BottomSheetContainer {
  @Prop @Watch('onVisibilityChanged') visible: boolean = false;
  @BuilderParam content: () => void = EmptyBottomSheetContent;
  onClose: () => void = () => {};
  @State presented: boolean = false;
  @State rendered: boolean = false;
  private timerId: number = -1;

  aboutToAppear(): void {
    this.onVisibilityChanged();
  }

  aboutToDisappear(): void {
    this.cancelTimer();
  }

  private onVisibilityChanged(): void {
    this.cancelTimer();
    if (!this.visible) {
      this.presented = false;
      this.timerId = setTimeout(() => {
        this.rendered = false;
        this.timerId = -1;
      }, MotionQualityContext.resolveDuration(MotionTokens.durationSlow));
      return;
    }
    this.rendered = true;
    this.timerId = setTimeout(() => {
      this.presented = true;
      this.timerId = -1;
    }, 0);
  }

  private cancelTimer(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.modalScrim)
        .opacity(this.presented ? 1 : 0)
        .animation({
          duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
          curve: MotionQualityContext.resolveCurve(MotionCurveRole.EMPHASIZED)
        })
        .onClick(() => {
          this.onClose();
        })

      Column() {
        this.content()
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, bottom: AppMetrics.space24 })
      .width('100%')
      .translate({ y: this.presented ? 0 : MotionTokens.offsetEnterYSheet })
      .opacity(this.presented ? 1 : 0)
      .animation({
        duration: MotionQualityContext.resolveDuration(MotionTokens.durationSlow),
        curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_SOFT)
      })
    }
    .visibility(this.rendered ? Visibility.Visible : Visibility.None)
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
