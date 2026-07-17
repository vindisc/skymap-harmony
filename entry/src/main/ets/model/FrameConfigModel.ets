export interface FrameConfigSpec {
  outerPaddingRatio: number;
  innerPaddingRatio: number;
  cornerRadiusRatio: number;
  backgroundColorHex: string;
  textColorHex: string;
  secondaryTextColorHex: string;
  titleFontRatio: number;
  bodyFontRatio: number;
  labelFontRatio: number;
  lineSpacingRatio: number;
  fieldSpacingRatio: number;
  logoAssetId: string;
  watermarkText: string;
}

export const FRAME_CONFIG_FALLBACK: FrameConfigSpec = {
  outerPaddingRatio: 0.032,
  innerPaddingRatio: 0.006,
  cornerRadiusRatio: 0.006,
  backgroundColorHex: '#FFFFFF',
  textColorHex: '#161616',
  secondaryTextColorHex: '#5F6368',
  titleFontRatio: 0.026,
  bodyFontRatio: 0.017,
  labelFontRatio: 0.012,
  lineSpacingRatio: 0.55,
  fieldSpacingRatio: 1.15,
  logoAssetId: '',
  watermarkText: ''
};

function pickRatio(value: number | undefined, fallback: number): number {
  if (typeof value === 'number' && value > 0 && value < 1.5 && Number.isFinite(value)) {
    return value;
  }
  return fallback;
}

function pickRatioAllowZero(value: number | undefined, fallback: number): number {
  if (typeof value === 'number' && value >= 0 && value < 1.5 && Number.isFinite(value)) {
    return value;
  }
  return fallback;
}

function pickHex(value: string | undefined, fallback: string): string {
  if (typeof value === 'string' && /^#[0-9A-Fa-f]{6}$/.test(value)) {
    return value.toUpperCase();
  }
  return fallback;
}

export function normalizeFrameConfig(
  input: FrameConfigSpec | undefined,
  fallback: FrameConfigSpec = FRAME_CONFIG_FALLBACK
): FrameConfigSpec {
  if (input === undefined) {
    return {
      outerPaddingRatio: fallback.outerPaddingRatio,
      innerPaddingRatio: fallback.innerPaddingRatio,
      cornerRadiusRatio: fallback.cornerRadiusRatio,
      backgroundColorHex: fallback.backgroundColorHex,
      textColorHex: fallback.textColorHex,
      secondaryTextColorHex: fallback.secondaryTextColorHex,
      titleFontRatio: fallback.titleFontRatio,
      bodyFontRatio: fallback.bodyFontRatio,
      labelFontRatio: fallback.labelFontRatio,
      lineSpacingRatio: fallback.lineSpacingRatio,
      fieldSpacingRatio: fallback.fieldSpacingRatio,
      logoAssetId: fallback.logoAssetId,
      watermarkText: fallback.watermarkText
    };
  }
  return {
    outerPaddingRatio: pickRatio(input.outerPaddingRatio, fallback.outerPaddingRatio),
    innerPaddingRatio: pickRatioAllowZero(input.innerPaddingRatio, fallback.innerPaddingRatio),
    cornerRadiusRatio: pickRatioAllowZero(input.cornerRadiusRatio, fallback.cornerRadiusRatio),
    backgroundColorHex: pickHex(input.backgroundColorHex, fallback.backgroundColorHex),
    textColorHex: pickHex(input.textColorHex, fallback.textColorHex),
    secondaryTextColorHex: pickHex(input.secondaryTextColorHex, fallback.secondaryTextColorHex),
    titleFontRatio: pickRatio(input.titleFontRatio, fallback.titleFontRatio),
    bodyFontRatio: pickRatio(input.bodyFontRatio, fallback.bodyFontRatio),
    labelFontRatio: pickRatio(input.labelFontRatio, fallback.labelFontRatio),
    lineSpacingRatio: pickRatio(input.lineSpacingRatio, fallback.lineSpacingRatio),
    fieldSpacingRatio: pickRatio(input.fieldSpacingRatio, fallback.fieldSpacingRatio),
    logoAssetId: typeof input.logoAssetId === 'string' ? input.logoAssetId : '',
    watermarkText: typeof input.watermarkText === 'string' ? input.watermarkText : ''
  };
}
