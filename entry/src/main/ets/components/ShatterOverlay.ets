import { AppColors } from './AppDesign';
import { MotionTokens } from '../theme/DesignTokens';

export type ShatterQuality = 'low' | 'medium' | 'high';

interface ShatterDensity {
  point: number;
}

function resolveShatterDensity(quality: ShatterQuality): ShatterDensity {
  if (quality === 'low') {
    return { point: 48 };
  }
  if (quality === 'high') {
    return { point: 128 };
  }
  return { point: 96 };
}

function resolveShatterEmitRate(quality: ShatterQuality): number {
  return Math.ceil(resolveShatterDensity(quality).point * 1000 / MotionTokens.shatterPointLayerMs);
}

@Component
export struct ShatterOverlay {
  @Prop quality: ShatterQuality = 'medium';

  @State pointLayerVisible: boolean = false;

  private pointDelayTimerId: number = -1;

  aboutToAppear(): void {
    this.pointDelayTimerId = setTimeout(() => {
      this.pointLayerVisible = true;
    }, MotionTokens.shatterPointLayerDelayMs);
  }

  aboutToDisappear(): void {
    this.cancelTimers();
  }

  private cancelTimers(): void {
    if (this.pointDelayTimerId >= 0) {
      clearTimeout(this.pointDelayTimerId);
      this.pointDelayTimerId = -1;
    }
  }

  build() {
    Stack() {
      if (this.pointLayerVisible) {
        Particle({
          particles: [
            {
              emitter: {
                particle: {
                  type: ParticleType.POINT,
                  config: {
                    radius: 2
                  },
                  count: resolveShatterDensity(this.quality).point,
                  lifetime: MotionTokens.shatterPointLayerMs,
                  lifetimeRange: 100
                },
                emitRate: resolveShatterEmitRate(this.quality),
                position: [0, 0],
                size: ['100%', '100%'],
                shape: ParticleEmitterShape.RECTANGLE
              },
              color: {
                range: [AppColors.primary, AppColors.tagAmberText]
              },
              opacity: {
                range: [1, 1],
                updater: {
                  type: ParticleUpdater.CURVE,
                  config: [
                    { from: 1, to: 0.2, startMillis: 0, endMillis: 300, curve: Curve.EaseOut },
                    { from: 0.2, to: 0, startMillis: 300, endMillis: MotionTokens.shatterPointLayerMs, curve: Curve.EaseIn }
                  ]
                }
              },
              scale: {
                range: [0.6, 1.2]
              },
              velocity: {
                speed: [24, 72],
                angle: [0, 360]
              }
            }
          ]
        })
          .width('100%')
          .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
  }
}
