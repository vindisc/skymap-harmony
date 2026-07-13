import { MotionTokens } from '../../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../../theme/MotionQualityContext';

@Builder
function EmptySharedHeroContent() {
  Column() {}
}

@Component
export struct SharedHero {
  @Prop tag: string = '';
  @BuilderParam content: () => void = EmptySharedHeroContent;

  build() {
    Column() {
      this.content()
    }
    .geometryTransition(`review-hero-${this.tag}`)
    .animation({
      duration: MotionQualityContext.resolveDuration(MotionTokens.durationHero),
      curve: MotionQualityContext.resolveCurve(MotionCurveRole.LANDING)
    })
  }
}
