import { AppColors } from '../AppDesign';
import { MotionTokens } from '../../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../../theme/MotionQualityContext';

export type CeremonyKind = 'review-done' | 'streak-record' | 'smb-first-connect';

@Component
export struct CeremonyBurst {
  @Prop kind: CeremonyKind = 'review-done';
  onFinish: () => void = () => {};
  @State playing: boolean = false;
  @State ringExpanded: boolean = false;
  private finishTimerId: number = -1;
  private startTimerId: number = -1;
  private acquired: boolean = false;

  aboutToAppear(): void {
    this.acquired = MotionQualityContext.tryAcquireCeremonySlot();
    if (!this.acquired) {
      this.onFinish();
      return;
    }
    this.playing = true;
    this.startTimerId = setTimeout(() => {
      this.ringExpanded = true;
      this.startTimerId = -1;
    }, MotionTokens.durationInstant);
    this.finishTimerId = setTimeout(() => {
      this.finish();
    }, MotionTokens.durationCeremony);
  }

  aboutToDisappear(): void {
    this.cancelTimer();
    this.releaseSlot();
  }

  private finish(): void {
    this.cancelTimer();
    this.playing = false;
    this.releaseSlot();
    this.onFinish();
  }

  private cancelTimer(): void {
    if (this.finishTimerId >= 0) {
      clearTimeout(this.finishTimerId);
      this.finishTimerId = -1;
    }
    if (this.startTimerId >= 0) {
      clearTimeout(this.startTimerId);
      this.startTimerId = -1;
    }
  }

  private releaseSlot(): void {
    if (!this.acquired) {
      return;
    }
    MotionQualityContext.releaseCeremonySlot();
    this.acquired = false;
  }

  private resolveAccentColor(): string {
    if (this.kind === 'smb-first-connect') {
      return AppColors.tagGreenText;
    }
    if (this.kind === 'streak-record') {
      return AppColors.tagAmberText;
    }
    return AppColors.primary;
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(this.ringExpanded ? 180 : 32)
        .height(this.ringExpanded ? 180 : 32)
        .fill('#00FFFFFF')
        .stroke(this.resolveAccentColor())
        .strokeWidth(this.ringExpanded ? 1 : 4)
        .opacity(this.ringExpanded ? 0 : 0.72)
        .animation({
          duration: MotionTokens.durationCeremony,
          curve: MotionQualityContext.resolveCurve(MotionCurveRole.EMPHASIZED)
        })

      if (this.playing) {
        Particle({
          particles: [
            {
              emitter: {
                particle: {
                  type: ParticleType.POINT,
                  config: { radius: 2 },
                  count: 36,
                  lifetime: 480,
                  lifetimeRange: 80
                },
                emitRate: 90,
                position: ['50%', '50%'],
                size: [1, 1],
                shape: ParticleEmitterShape.RECTANGLE
              },
              color: { range: [this.resolveAccentColor(), AppColors.onPrimary] },
              opacity: {
                range: [1, 1],
                updater: {
                  type: ParticleUpdater.CURVE,
                  config: [
                    { from: 1, to: 0, startMillis: 120, endMillis: 480, curve: Curve.EaseOut }
                  ]
                }
              },
              scale: { range: [0.6, 1.2] },
              velocity: { speed: [48, 96], angle: [0, 360] }
            }
          ]
        })
        .width(220)
        .height(220)
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
