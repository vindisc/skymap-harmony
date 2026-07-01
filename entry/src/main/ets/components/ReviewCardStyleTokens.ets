import { ElevationTokens, RadiusTokens, ShadowToken, SpacingTokens } from '../theme/DesignTokens';

export class ReviewCardStyleTokens {
  static readonly canvasColor: string = '#FFFEFC';
  static readonly canvasMutedColor: string = '#F4EFE7';
  static readonly inkColor: string = '#16181D';
  static readonly bodyColor: string = '#2E333A';
  static readonly labelColor: string = '#9097A0';
  static readonly hairlineColor: string = '#E1D9CC';
  static readonly accentColor: string = '#7C947E';
  static readonly shadowColor: string = '#12000000';
  static readonly previewCardShadow: ShadowToken = ElevationTokens.medium;
  static readonly mobileCardShadow: ShadowToken = ElevationTokens.high;
  static readonly exportCardShadow: ShadowToken = ElevationTokens.high;

  static readonly cardRadius: number = RadiusTokens.md;
  static readonly photoRadius: number = RadiusTokens.sm;
  static readonly cardPadding: number = SpacingTokens.lg;
  static readonly textInset: number = SpacingTokens.xs;
  static readonly sectionGap: number = SpacingTokens.xl;

  static readonly titleSize: number = 22;
  static readonly titleLineHeight: number = 30;
  static readonly bodySize: number = 15;
  static readonly bodyLineHeight: number = 24;
  static readonly labelSize: number = 12;
  static readonly labelLineHeight: number = 16;

  static resolveRenderShadow(displayMode: string): ShadowToken {
    return displayMode === 'export'
      ? ReviewCardStyleTokens.exportCardShadow
      : ReviewCardStyleTokens.previewCardShadow;
  }
}
