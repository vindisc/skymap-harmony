import { MotionTokens, ShatterTokens } from '../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../theme/MotionQualityContext';

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
  @State flashVisible: boolean = false;
  @State flashScale: number = 0.3;
  @State flashOpacity: number = 0.9;
  @State particlesVisible: boolean = false;

  private readonly layerCount: number = MotionQualityContext.resolveShatterLayerCount();
  private burstStartTimerId: number = -1;
  private flashEndTimerId: number = -1;

  aboutToAppear(): void {
    this.clearTimers();
    this.flashVisible = true;
    this.flashScale = 0.3;
    this.flashOpacity = 0.9;
    this.particlesVisible = false;
    this.burstStartTimerId = setTimeout(() => {
      this.flashScale = 1.4;
      this.flashOpacity = 0;
      this.particlesVisible = true;
      this.burstStartTimerId = -1;
    }, MotionTokens.durationStagger);
    this.flashEndTimerId = setTimeout(() => {
      this.flashVisible = false;
      this.flashEndTimerId = -1;
    }, MotionTokens.durationStagger + MotionTokens.durationInstant * 2 + 20);
  }

  aboutToDisappear(): void {
    this.clearTimers();
  }

  private clearTimers(): void {
    if (this.burstStartTimerId >= 0) {
      clearTimeout(this.burstStartTimerId);
      this.burstStartTimerId = -1;
    }
    if (this.flashEndTimerId >= 0) {
      clearTimeout(this.flashEndTimerId);
      this.flashEndTimerId = -1;
    }
  }

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
            range: ShatterTokens.mainColorRange
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
            shape: ParticleEmitterShape.ELLIPSE
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
      if (this.flashVisible) {
        Circle()
          .width('40%')
          .height('40%')
          .fill(ShatterTokens.flashColor)
          .opacity(this.flashOpacity)
          .scale({ x: this.flashScale, y: this.flashScale })
          .animation({
            duration: MotionTokens.durationInstant * 2 + 20,
            curve: MotionQualityContext.resolveCurve(MotionCurveRole.EMPHASIZED)
          })
          .hitTestBehavior(HitTestMode.None)
      }

      if (this.particlesVisible) {
        this.MainBurstLayer()

        if (this.layerCount >= 2) {
          this.HaloLayer()
        }

        if (this.layerCount >= 3) {
          this.DriftLayer()
        }
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
  }
}
