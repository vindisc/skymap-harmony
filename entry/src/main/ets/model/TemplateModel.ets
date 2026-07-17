import { FrameConfigSpec } from './FrameConfigModel';

export enum TemplateId {
  WHITE_EQUAL = 'white_equal',
  MINIMAL_GALLERY = 'minimal_gallery',
  DATE_BOTTOM = 'date_bottom',
  META_BOTTOM = 'meta_bottom',
  EXIF_CN_BOTTOM = 'exif_cn_bottom',
  SIGNATURE_OVERLAY = 'signature_overlay',
  PERSONAL_INFO_BAR = 'personal_info_bar',
  REVIEW_CARD = 'review_card',
  ADAPTIVE_REVIEW_CARD = 'adaptive_review_card'
}

export enum TemplateLevel {
  L0_FRAME = 'l0Frame',
  L1_META = 'l1Meta',
  L2_NOTE = 'l2Note',
  L3_REVIEW = 'l3Review'
}

export interface TemplateContentBinding {
  useTitle: boolean;
  useCaption: boolean;
  useExif: boolean;
  useReviewFields: boolean;
  useJudgement: boolean;
  useReviewer: boolean;
  useDate: boolean;
  useLogo: boolean;
}

export interface TemplateDefaults {
  frame: FrameConfigSpec;
  captionSourceHint: TemplateCaptionSource;
}

export enum TemplateCaptionSource {
  NONE = 'none',
  DATE = 'date',
  LOCATION = 'location',
  REVIEWER = 'reviewer',
  CUSTOM = 'custom'
}

export interface TemplateDescriptor {
  id: TemplateId;
  level: TemplateLevel;
  displayName: string;
  displayNameEn: string;
  contentBinding: TemplateContentBinding;
  defaults: TemplateDefaults;
  allowedBackgroundColors: Array<string>;
}

const WHITE_EQUAL_DESCRIPTOR: TemplateDescriptor = {
  id: TemplateId.WHITE_EQUAL,
  level: TemplateLevel.L0_FRAME,
  displayName: '纯白画廊',
  displayNameEn: 'White Equal',
  contentBinding: {
    useTitle: false,
    useCaption: false,
    useExif: false,
    useReviewFields: false,
    useJudgement: false,
    useReviewer: false,
    useDate: false,
    useLogo: false
  },
  defaults: {
    frame: {
      outerPaddingRatio: 0.058,
      innerPaddingRatio: 0,
      cornerRadiusRatio: 0,
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
    },
    captionSourceHint: TemplateCaptionSource.NONE
  },
  allowedBackgroundColors: ['#FFFFFF']
};

const META_BOTTOM_DESCRIPTOR: TemplateDescriptor = {
  id: TemplateId.META_BOTTOM,
  level: TemplateLevel.L1_META,
  displayName: '参数底栏',
  displayNameEn: 'Meta Bottom',
  contentBinding: {
    useTitle: false,
    useCaption: false,
    useExif: true,
    useReviewFields: false,
    useJudgement: false,
    useReviewer: false,
    useDate: false,
    useLogo: false
  },
  defaults: {
    frame: {
      outerPaddingRatio: 0.032,
      innerPaddingRatio: 0.014,
      cornerRadiusRatio: 0,
      backgroundColorHex: '#FFFFFF',
      textColorHex: '#161616',
      secondaryTextColorHex: '#5F6368',
      titleFontRatio: 0.024,
      bodyFontRatio: 0.017,
      labelFontRatio: 0.012,
      lineSpacingRatio: 0.55,
      fieldSpacingRatio: 1.15,
      logoAssetId: '',
      watermarkText: ''
    },
    captionSourceHint: TemplateCaptionSource.NONE
  },
  allowedBackgroundColors: ['#FFFFFF', '#F6F1E8', '#F0F0F0']
};

const SIGNATURE_OVERLAY_DESCRIPTOR: TemplateDescriptor = {
  id: TemplateId.SIGNATURE_OVERLAY,
  level: TemplateLevel.L2_NOTE,
  displayName: '手写签名',
  displayNameEn: 'Signature Overlay',
  contentBinding: {
    useTitle: false,
    useCaption: true,
    useExif: false,
    useReviewFields: false,
    useJudgement: false,
    useReviewer: false,
    useDate: false,
    useLogo: false
  },
  defaults: {
    frame: {
      outerPaddingRatio: 0.038,
      innerPaddingRatio: 0.020,
      cornerRadiusRatio: 0,
      backgroundColorHex: '#F6F1E8',
      textColorHex: '#3A2E1F',
      secondaryTextColorHex: '#8A7A63',
      titleFontRatio: 0.024,
      bodyFontRatio: 0.020,
      labelFontRatio: 0.012,
      lineSpacingRatio: 0.55,
      fieldSpacingRatio: 1.15,
      logoAssetId: '',
      watermarkText: ''
    },
    captionSourceHint: TemplateCaptionSource.CUSTOM
  },
  allowedBackgroundColors: ['#F6F1E8', '#FFFFFF']
};

const ADAPTIVE_REVIEW_CARD_DESCRIPTOR: TemplateDescriptor = {
  id: TemplateId.ADAPTIVE_REVIEW_CARD,
  level: TemplateLevel.L3_REVIEW,
  displayName: '摄影复盘卡',
  displayNameEn: 'Adaptive Review Card',
  contentBinding: {
    useTitle: true,
    useCaption: false,
    useExif: false,
    useReviewFields: true,
    useJudgement: true,
    useReviewer: true,
    useDate: true,
    useLogo: false
  },
  defaults: {
    frame: {
      outerPaddingRatio: 0.032,
      innerPaddingRatio: 0.010,
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
    },
    captionSourceHint: TemplateCaptionSource.NONE
  },
  allowedBackgroundColors: ['#FFFFFF', '#F6F1E8', '#F0F0F0']
};

export const TEMPLATE_REGISTRY: Map<TemplateId, TemplateDescriptor> = new Map<TemplateId, TemplateDescriptor>();

TEMPLATE_REGISTRY.set(TemplateId.WHITE_EQUAL, WHITE_EQUAL_DESCRIPTOR);
TEMPLATE_REGISTRY.set(TemplateId.META_BOTTOM, META_BOTTOM_DESCRIPTOR);
TEMPLATE_REGISTRY.set(TemplateId.SIGNATURE_OVERLAY, SIGNATURE_OVERLAY_DESCRIPTOR);
TEMPLATE_REGISTRY.set(TemplateId.REVIEW_CARD, ADAPTIVE_REVIEW_CARD_DESCRIPTOR);
TEMPLATE_REGISTRY.set(TemplateId.ADAPTIVE_REVIEW_CARD, ADAPTIVE_REVIEW_CARD_DESCRIPTOR);

export function resolveTemplate(id: string): TemplateDescriptor {
  const known: TemplateDescriptor | undefined = TEMPLATE_REGISTRY.get(id as TemplateId);
  if (known !== undefined) {
    return known;
  }
  const fallback: TemplateDescriptor | undefined = TEMPLATE_REGISTRY.get(TemplateId.ADAPTIVE_REVIEW_CARD);
  if (fallback === undefined) {
    throw new Error('TEMPLATE_REGISTRY 缺失 ADAPTIVE_REVIEW_CARD descriptor，属于配置错误');
  }
  return fallback;
}
