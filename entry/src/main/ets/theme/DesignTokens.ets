import curves from '@ohos.curves';

export class TypographyTokens {
  static readonly PageTitle: number = 26;
  static readonly PageSubtitle: number = 14;
  static readonly SectionTitle: number = 16;
  static readonly SectionSubtitle: number = 12;
  static readonly CardTitle: number = 16;
  static readonly CardBody: number = 14;
  static readonly CardMeta: number = 12;
  static readonly ListTitle: number = 16;
  static readonly ListBody: number = 14;
  static readonly ListMeta: number = 12;
  static readonly StatNumber: number = 30;
  static readonly StatLabel: number = 12;
  static readonly ButtonText: number = 14;
  static readonly SmallButtonText: number = 14;
  static readonly InputText: number = 14;
  static readonly InputPlaceholder: number = 14;
  static readonly InputLabel: number = 14;
  static readonly TabIcon: number = 19;
  static readonly TabLabel: number = 11;
}

export class LineHeightTokens {
  static readonly PageTitle: number = 32;
  static readonly PageSubtitle: number = 20;
  static readonly SectionTitle: number = 22;
  static readonly SectionSubtitle: number = 16;
  static readonly CardTitle: number = 22;
  static readonly CardBody: number = 20;
  static readonly CardMeta: number = 16;
  static readonly ListTitle: number = 20;
  static readonly ListBody: number = 20;
  static readonly ListMeta: number = 17;
  static readonly StatNumber: number = 34;
  static readonly StatLabel: number = 16;
  static readonly ButtonText: number = 20;
  static readonly InputText: number = 20;
  static readonly InputLabel: number = 20;
  static readonly TabLabel: number = 14;
}

export class LayoutTokens {
  static readonly TabBarHeight: number = 60;
  static readonly TabBarItemHeight: number = 44;
  static readonly SearchHeight: number = 44;
  static readonly ChipHeight: number = 34;
  static readonly PrimaryButtonHeight: number = 48;
  static readonly SecondaryButtonHeight: number = 44;
  static readonly ListThumbnailSize: number = 68;
  static readonly ListCardMinHeight: number = 96;
  static readonly ListCardMaxHeight: number = 108;
}

export class SpacingTokens {
  static readonly xs: number = 4;
  static readonly sm: number = 8;
  static readonly md: number = 12;
  static readonly lg: number = 16;
  static readonly xl: number = 24;
  static readonly xxl: number = 32;
}

export class RadiusTokens {
  static readonly xs: number = 6;
  static readonly sm: number = 10;
  static readonly md: number = 14;
  static readonly lg: number = 18;
  static readonly xl: number = 24;
  static readonly full: number = 999;
}

export interface ShadowToken {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export class ElevationTokens {
  static readonly none: ShadowToken = {
    radius: 0,
    color: '#00000000',
    offsetX: 0,
    offsetY: 0
  };
  static readonly subtle: ShadowToken = {
    radius: 9,
    color: '#120F0A04',
    offsetX: 0,
    offsetY: 3
  };
  static readonly low: ShadowToken = {
    radius: 10,
    color: '#160F0A04',
    offsetX: 0,
    offsetY: 3
  };
  static readonly medium: ShadowToken = {
    radius: 14,
    color: '#1A0F0A04',
    offsetX: 0,
    offsetY: 4
  };
  static readonly high: ShadowToken = {
    radius: 20,
    color: '#220F0A04',
    offsetX: 0,
    offsetY: 8
  };
  static readonly overlay: ShadowToken = {
    radius: 28,
    color: '#260F0A04',
    offsetX: 0,
    offsetY: 12
  };
  static readonly danger: ShadowToken = {
    radius: 10,
    color: '#26B73A31',
    offsetX: 0,
    offsetY: 3
  };
  static readonly focus: ShadowToken = {
    radius: 8,
    color: '#1A365F75',
    offsetX: 0,
    offsetY: 0
  };
}

export class MotionTokens {
  static readonly durationFrame: number = 16;
  static readonly durationInstant: number = 80;
  static readonly durationQuick: number = 150;
  static readonly durationStandard: number = 250;
  static readonly durationSlow: number = 400;
  static readonly durationHero: number = 520;
  static readonly durationCeremony: number = 780;
  static readonly durationStagger: number = 40;
  static readonly durationStaggerLong: number = 60;
  static readonly durationShimmer: number = 1200;
  static readonly curveStandard: Curve = Curve.EaseInOut;
  static readonly curveDecelerate: Curve = Curve.EaseOut;
  static readonly curveAccelerate: Curve = Curve.EaseIn;
  static readonly curveEmphasized: ICurve = curves.cubicBezierCurve(0.2, 0, 0, 1);
  static readonly curveSpringSoft: ICurve = curves.springMotion(0.55, 0.85);
  static readonly curveSpringResponsive: ICurve = curves.springMotion(0.36, 0.9);
  static readonly curveSpringBouncy: ICurve = curves.interpolatingSpring(9, 1, 220, 22);
  static readonly curveDeceleratedLanding: ICurve = curves.cubicBezierCurve(0.05, 0.7, 0.1, 1);
  static readonly offsetEnterY: number = 12;
  static readonly offsetEnterYCard: number = 20;
  static readonly offsetEnterYSheet: number = 320;
  static readonly offsetExitYToast: number = -24;
  static readonly scalePressed: number = 0.96;
  static readonly scaleSubtle: number = 0.98;
  static readonly scaleSoftPressed: number = 0.97;
  static readonly scalePressedHard: number = 0.96;
  static readonly scaleCeremony: number = 1.06;
  static readonly scaleHeroIntro: number = 1.04;
  static readonly shatterDurationMs: number = 1300;
  static readonly shatterRippleBackMs: number = 280;
}

export class ShatterTokens {
  static readonly washColorActive: string = '#0CFFD98A';
  static readonly washColorIdle: string = '#00FFFFFF';
  static readonly mainRadius: number = 2;
  static readonly mainCountLow: number = 48;
  static readonly mainCountMedium: number = 72;
  static readonly mainCountHigh: number = 96;
  static readonly mainLifetimeMs: number = 700;
  static readonly mainColorRange: ParticleTuple<ResourceColor, ResourceColor> = ['#FFFFFF', '#FFD98A'];
  static readonly mainOpacityStart: number = 1;
  static readonly mainOpacityHold: number = 1;
  static readonly mainOpacityEnd: number = 0;
  static readonly mainOpacityHoldEndMs: number = 400;
  static readonly mainScaleMin: number = 0.4;
  static readonly mainScaleMax: number = 1.6;
  static readonly mainSpeedMin: number = 24;
  static readonly mainSpeedMax: number = 72;

  static readonly haloImageSize: number = 32;
  static readonly haloCountLow: number = 12;
  static readonly haloCountMedium: number = 24;
  static readonly haloCountHigh: number = 40;
  static readonly haloLifetimeMs: number = 900;
  static readonly haloColorStart: string = '#FFFFFF';
  static readonly haloColorEnd: string = '#FFFFFF';
  static readonly haloOpacityStart: number = 0.9;
  static readonly haloOpacityHold: number = 0.6;
  static readonly haloOpacityEnd: number = 0;
  static readonly haloOpacityHoldEndMs: number = 500;
  static readonly haloScaleMin: number = 0.8;
  static readonly haloScaleMax: number = 1.4;
  static readonly haloSpeedMin: number = 8;
  static readonly haloSpeedMax: number = 24;

  static readonly driftRadius: number = 1;
  static readonly driftCountLow: number = 30;
  static readonly driftCountMedium: number = 60;
  static readonly driftCountHigh: number = 90;
  static readonly driftLifetimeMs: number = 1200;
  static readonly driftColorStart: string = '#FFFFFF';
  static readonly driftColorEnd: string = '#B8B8FF';
  static readonly driftOpacityStart: number = 0.8;
  static readonly driftOpacityHold: number = 0.8;
  static readonly driftOpacityEnd: number = 0;
  static readonly driftOpacityHoldEndMs: number = 600;
  static readonly driftScaleMin: number = 0.3;
  static readonly driftScaleMax: number = 0.9;
  static readonly driftSpeedMin: number = 6;
  static readonly driftSpeedMax: number = 18;

  static readonly emissionWindowMs: number = 120;
  static readonly angleMin: number = 0;
  static readonly angleMax: number = 360;
  static readonly fullLayerCount: number = 3;
  static readonly reducedLayerCount: number = 1;
}

export class ToastDurationTokens {
  static readonly success: number = 2200;
  static readonly info: number = 2400;
  static readonly warning: number = 2600;
  static readonly error: number = 2800;
}
