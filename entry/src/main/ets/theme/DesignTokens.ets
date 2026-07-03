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
  static readonly durationInstant: number = 80;
  static readonly durationQuick: number = 150;
  static readonly durationStandard: number = 250;
  static readonly durationSlow: number = 400;
  static readonly curveStandard: Curve = Curve.EaseInOut;
  static readonly curveDecelerate: Curve = Curve.EaseOut;
  static readonly curveAccelerate: Curve = Curve.EaseIn;
  static readonly scalePressed: number = 0.96;
  static readonly scaleSubtle: number = 0.98;
  static readonly scaleSoftPressed: number = 0.97;
}
