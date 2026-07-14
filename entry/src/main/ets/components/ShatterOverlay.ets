import { ShatterTokens } from '../theme/DesignTokens';
import { MotionQualityContext } from '../theme/MotionQualityContext';

export type ShatterQuality = 'low' | 'medium' | 'high';

interface ShatterDensity {
  main: number;
  halo: number;
  drift: number;
}

function resolveShatterDensity(quality: ShatterQuality): ShatterDensity {
  if (quality === 'low') {
    return {
      main: ShatterTokens.mainCountLow,
      halo: ShatterTokens.haloCountLow,
      drift: ShatterTokens.driftCountLow
    };
  }
  if (quality === 'high') {
    return {
      main: ShatterTokens.mainCountHigh,
      halo: ShatterTokens.haloCountHigh,
      drift: ShatterTokens.driftCountHigh
    };
  }
  return {
    main: ShatterTokens.mainCountMedium,
    halo: ShatterTokens.haloCountMedium,
    drift: ShatterTokens.driftCountMedium
  };
}

function resolveShatterEmitRate(count: number): number {
  return Math.ceil(count * 1000 / ShatterTokens.emissionWindowMs);
}

@Component
export struct ShatterOverlay {
  @Prop quality: ShatterQuality = 'medium';

  private readonly layerCount: number = MotionQualityContext.resolveShatterLayerCount();

  @Builder
  MainBurstLayer() {
    Particle({
      particles: [
        {
          emitter: {
            particle: {
              type: ParticleType.POINT,
              config: {
                radius: ShatterTokens.mainRadius
              },
              count: resolveShatterDensity(this.quality).main,
              lifetime: ShatterTokens.mainLifetimeMs
            },
            emitRate: resolveShatterEmitRate(resolveShatterDensity(this.quality).main),
            position: [0, 0],
            size: ['100%', '100%'],
            shape: ParticleEmitterShape.RECTANGLE
          },
          color: {
            range: [ShatterTokens.mainColorStart, ShatterTokens.mainColorEnd]
          },
          opacity: {
            range: [ShatterTokens.mainOpacityStart, ShatterTokens.mainOpacityHold],
            updater: {
              type: ParticleUpdater.CURVE,
              config: [
                {
                  from: ShatterTokens.mainOpacityStart,
                  to: ShatterTokens.mainOpacityHold,
                  startMillis: 0,
                  endMillis: ShatterTokens.mainOpacityHoldEndMs,
                  curve: Curve.Linear
                },
                {
                  from: ShatterTokens.mainOpacityHold,
                  to: ShatterTokens.mainOpacityEnd,
                  startMillis: ShatterTokens.mainOpacityHoldEndMs,
                  endMillis: ShatterTokens.mainLifetimeMs,
                  curve: Curve.EaseIn
                }
              ]
            }
          },
          scale: {
            range: [ShatterTokens.mainScaleMin, ShatterTokens.mainScaleMax]
          },
          velocity: {
            speed: [ShatterTokens.mainSpeedMin, ShatterTokens.mainSpeedMax],
            angle: [ShatterTokens.angleMin, ShatterTokens.angleMax]
          }
        }
      ]
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  HaloLayer() {
    Particle({
      particles: [
        {
          emitter: {
            particle: {
              type: ParticleType.IMAGE,
              config: {
                src: $r('app.media.particle_halo'),
                size: [ShatterTokens.haloImageSize, ShatterTokens.haloImageSize],
                objectFit: ImageFit.Contain
              },
              count: resolveShatterDensity(this.quality).halo,
              lifetime: ShatterTokens.haloLifetimeMs
            },
            emitRate: resolveShatterEmitRate(resolveShatterDensity(this.quality).halo),
            position: [0, 0],
            size: ['100%', '100%'],
            shape: ParticleEmitterShape.RECTANGLE
          },
          color: {
            range: [ShatterTokens.haloColorStart, ShatterTokens.haloColorEnd]
          },
          opacity: {
            range: [ShatterTokens.haloOpacityStart, ShatterTokens.haloOpacityHold],
            updater: {
              type: ParticleUpdater.CURVE,
              config: [
                {
                  from: ShatterTokens.haloOpacityStart,
                  to: ShatterTokens.haloOpacityHold,
                  startMillis: 0,
                  endMillis: ShatterTokens.haloOpacityHoldEndMs,
                  curve: Curve.EaseOut
                },
                {
                  from: ShatterTokens.haloOpacityHold,
                  to: ShatterTokens.haloOpacityEnd,
                  startMillis: ShatterTokens.haloOpacityHoldEndMs,
                  endMillis: ShatterTokens.haloLifetimeMs,
                  curve: Curve.EaseIn
                }
              ]
            }
          },
          scale: {
            range: [ShatterTokens.haloScaleMin, ShatterTokens.haloScaleMax]
          },
          velocity: {
            speed: [ShatterTokens.haloSpeedMin, ShatterTokens.haloSpeedMax],
            angle: [ShatterTokens.angleMin, ShatterTokens.angleMax]
          }
        }
      ]
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  DriftLayer() {
    Particle({
      particles: [
        {
          emitter: {
            particle: {
              type: ParticleType.POINT,
              config: {
                radius: ShatterTokens.driftRadius
              },
              count: resolveShatterDensity(this.quality).drift,
              lifetime: ShatterTokens.driftLifetimeMs
            },
            emitRate: resolveShatterEmitRate(resolveShatterDensity(this.quality).drift),
            position: [0, 0],
            size: ['100%', '100%'],
            shape: ParticleEmitterShape.RECTANGLE
          },
          color: {
            range: [ShatterTokens.driftColorStart, ShatterTokens.driftColorEnd]
          },
          opacity: {
            range: [ShatterTokens.driftOpacityStart, ShatterTokens.driftOpacityHold],
            updater: {
              type: ParticleUpdater.CURVE,
              config: [
                {
                  from: ShatterTokens.driftOpacityStart,
                  to: ShatterTokens.driftOpacityHold,
                  startMillis: 0,
                  endMillis: ShatterTokens.driftOpacityHoldEndMs,
                  curve: Curve.Linear
                },
                {
                  from: ShatterTokens.driftOpacityHold,
                  to: ShatterTokens.driftOpacityEnd,
                  startMillis: ShatterTokens.driftOpacityHoldEndMs,
                  endMillis: ShatterTokens.driftLifetimeMs,
                  curve: Curve.EaseIn
                }
              ]
            }
          },
          scale: {
            range: [ShatterTokens.driftScaleMin, ShatterTokens.driftScaleMax]
          },
          velocity: {
            speed: [ShatterTokens.driftSpeedMin, ShatterTokens.driftSpeedMax],
            angle: [ShatterTokens.angleMin, ShatterTokens.angleMax]
          }
        }
      ]
    })
      .width('100%')
      .height('100%')
  }

  build() {
    Stack() {
      this.MainBurstLayer()

      if (this.layerCount >= 2) {
        this.HaloLayer()
      }

      if (this.layerCount >= 3) {
        this.DriftLayer()
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
  }
}
