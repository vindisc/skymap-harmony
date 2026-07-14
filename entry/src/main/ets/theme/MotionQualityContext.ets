import common from '@ohos.app.ability.common';
import { MotionQuality, ReviewSettingsService } from '../services/ReviewSettingsService';
import { MotionTokens } from './DesignTokens';

export enum MotionCurveRole {
  EMPHASIZED = 'emphasized',
  SPRING_SOFT = 'spring_soft',
  SPRING_RESPONSIVE = 'spring_responsive',
  SPRING_BOUNCY = 'spring_bouncy',
  LANDING = 'landing'
}

export class MotionQualityContext {
  private static quality: MotionQuality = MotionQuality.FULL;
  private static ceremonyOccupied: boolean = false;

  static async initialize(context: common.UIAbilityContext): Promise<MotionQuality> {
    const quality: MotionQuality = await ReviewSettingsService.loadMotionQuality(context);
    MotionQualityContext.setQuality(quality);
    return quality;
  }

  static setQuality(quality: MotionQuality): void {
    MotionQualityContext.quality = quality;
  }

  static getQuality(): MotionQuality {
    return MotionQualityContext.quality;
  }

  static resolveDuration(fullDuration: number): number {
    if (MotionQualityContext.quality === MotionQuality.MINIMAL) {
      return Math.min(fullDuration, MotionTokens.durationQuick);
    }
    if (MotionQualityContext.quality === MotionQuality.CALM) {
      return Math.min(fullDuration, MotionTokens.durationStandard);
    }
    return fullDuration;
  }

  static resolveCurve(role: MotionCurveRole): Curve | ICurve {
    if (MotionQualityContext.quality === MotionQuality.MINIMAL) {
      return MotionTokens.curveDecelerate;
    }
    if (MotionQualityContext.quality === MotionQuality.CALM) {
      return role === MotionCurveRole.LANDING
        ? MotionTokens.curveDeceleratedLanding
        : MotionTokens.curveEmphasized;
    }
    if (role === MotionCurveRole.SPRING_SOFT) {
      return MotionTokens.curveSpringSoft;
    }
    if (role === MotionCurveRole.SPRING_RESPONSIVE) {
      return MotionTokens.curveSpringResponsive;
    }
    if (role === MotionCurveRole.SPRING_BOUNCY) {
      return MotionTokens.curveSpringBouncy;
    }
    if (role === MotionCurveRole.LANDING) {
      return MotionTokens.curveDeceleratedLanding;
    }
    return MotionTokens.curveEmphasized;
  }

  static shouldPlayStagger(): boolean {
    return MotionQualityContext.quality !== MotionQuality.MINIMAL;
  }

  static shouldPlayCeremony(): boolean {
    return MotionQualityContext.quality === MotionQuality.FULL;
  }

  // 预留：未来若决定 MINIMAL 档自动关闭星河效果，只需修改此处；当前仅镜像用户开关。
  static shouldPlayShatter(userEnabled: boolean): boolean {
    return userEnabled;
  }

  static tryAcquireCeremonySlot(): boolean {
    if (!MotionQualityContext.shouldPlayCeremony() || MotionQualityContext.ceremonyOccupied) {
      return false;
    }
    MotionQualityContext.ceremonyOccupied = true;
    return true;
  }

  static releaseCeremonySlot(): void {
    MotionQualityContext.ceremonyOccupied = false;
  }
}
