export enum ReviewCardLayoutMode {
  AUTO = 'auto',
  HORIZONTAL_PHOTO_BOTTOM_TEXT = 'horizontalPhotoBottomText',
  VERTICAL_PHOTO_RIGHT_TEXT = 'verticalPhotoRightText',
  SQUARE_PHOTO_BOTTOM_TEXT = 'squarePhotoBottomText'
}

export enum ReviewCardRenderMode {
  MOBILE_READING = 'mobileReading',
  EXPORT_CARD = 'exportCard'
}

export enum ReviewCardLayoutType {
  HORIZONTAL = 'horizontal',
  VERTICAL = 'vertical',
  SQUARE = 'square'
}

export interface ReviewCardLayoutResolution {
  layoutType: ReviewCardLayoutType;
  aspectRatio: number;
  usedFallbackSize: boolean;
  hasExactSize: boolean;
}

export enum ReviewCardBackground {
  WHITE = 'white',
  LIGHT_GRAY = 'lightGray'
}

export enum ReviewCardTextSize {
  SMALL = 'small',
  STANDARD = 'standard',
  LARGE = 'large'
}

export enum ReviewJudgementStatus {
  VALID = '成立',
  UNSURE = '不确定',
  INVALID = '不成立'
}

export interface ReviewJudgementOption {
  label: string;
  value: ReviewJudgementStatus;
}

export interface ReviewContent {
  title: string;
  visualFocus: string;
  focusReason: string;
  visualPath: string;
  visibleFacts: string;
  coreRelation: string;
  judgement: string;
  extendedUnderstanding: string;
  currentBlocker: string;
  firstLook?: string;
  reason?: string;
  strongestRelation?: string;
  blocker?: string;
}

export interface ReviewCardConfig {
  templateId: string;
  layoutMode: ReviewCardLayoutMode;
  background: ReviewCardBackground;
  textSize: ReviewCardTextSize;
}

export interface ReviewCardDocument {
  version: string;
  projectId: string;
  imageUri: string;
  imageWidth: number;
  imageHeight: number;
  imageSizeFallbackUsed: boolean;
  content: ReviewContent;
  config: ReviewCardConfig;
  createdAt: number;
  updatedAt: number;
}

export interface ReviewCardHistoryItem {
  document: ReviewCardDocument;
  exportedPath: string;
  reviewerText?: string;
}

export const DEFAULT_REVIEW_TITLE: string = '这张照片是否成立';
export const DEFAULT_PROJECT_ID: string = 'default';
export const DEFAULT_REVIEW_JUDGEMENT: ReviewJudgementStatus = ReviewJudgementStatus.UNSURE;
export const REVIEW_JUDGEMENT_OPTIONS: Array<ReviewJudgementOption> = [
  { label: ReviewJudgementStatus.VALID, value: ReviewJudgementStatus.VALID },
  { label: ReviewJudgementStatus.UNSURE, value: ReviewJudgementStatus.UNSURE },
  { label: ReviewJudgementStatus.INVALID, value: ReviewJudgementStatus.INVALID }
];

function normalizeReviewText(value: string | undefined, fallback: string = ''): string {
  if (typeof value === 'string') {
    return value;
  }
  return fallback;
}

function normalizeReviewNumber(value: number | undefined, fallback: number): number {
  if (typeof value === 'number' && value > 0) {
    return value;
  }
  return fallback;
}

export function normalizeReviewJudgement(value: string | undefined): ReviewJudgementStatus {
  const trimmedValue: string = normalizeReviewText(value).trim();
  if (trimmedValue === ReviewJudgementStatus.VALID) {
    return ReviewJudgementStatus.VALID;
  }
  if (trimmedValue === ReviewJudgementStatus.INVALID) {
    return ReviewJudgementStatus.INVALID;
  }
  if (trimmedValue === ReviewJudgementStatus.UNSURE) {
    return ReviewJudgementStatus.UNSURE;
  }
  if (trimmedValue === '待判断') {
    return ReviewJudgementStatus.UNSURE;
  }
  if (trimmedValue.includes(ReviewJudgementStatus.INVALID)) {
    return ReviewJudgementStatus.INVALID;
  }
  if (trimmedValue.includes('待判断')) {
    return ReviewJudgementStatus.UNSURE;
  }
  if (trimmedValue.includes(ReviewJudgementStatus.UNSURE)) {
    return ReviewJudgementStatus.UNSURE;
  }
  if (trimmedValue.includes(ReviewJudgementStatus.VALID)) {
    return ReviewJudgementStatus.VALID;
  }
  return DEFAULT_REVIEW_JUDGEMENT;
}

export function getReviewJudgementIndex(value: string | undefined): number {
  const status: ReviewJudgementStatus = normalizeReviewJudgement(value);
  for (let index = 0; index < REVIEW_JUDGEMENT_OPTIONS.length; index += 1) {
    if (REVIEW_JUDGEMENT_OPTIONS[index].value === status) {
      return index;
    }
  }
  return 1;
}

export function createDefaultReviewContent(): ReviewContent {
  return {
    title: DEFAULT_REVIEW_TITLE,
    visualFocus: '',
    focusReason: '',
    visualPath: '',
    visibleFacts: '',
    coreRelation: '',
    judgement: DEFAULT_REVIEW_JUDGEMENT,
    extendedUnderstanding: '',
    currentBlocker: ''
  };
}

export function createDefaultReviewCardDocument(): ReviewCardDocument {
  const now: number = Date.now();
  return {
    version: '0.1.0',
    projectId: DEFAULT_PROJECT_ID,
    imageUri: '',
    imageWidth: 1600,
    imageHeight: 1000,
    imageSizeFallbackUsed: false,
    content: createDefaultReviewContent(),
    config: {
      templateId: 'review_card',
      layoutMode: ReviewCardLayoutMode.AUTO,
      background: ReviewCardBackground.WHITE,
      textSize: ReviewCardTextSize.STANDARD
    },
    createdAt: now,
    updatedAt: now
  };
}

export function cloneReviewCardDocument(document: ReviewCardDocument): ReviewCardDocument {
  const fallbackDocument = createDefaultReviewCardDocument();
  const sourceContent = document.content ? document.content : createDefaultReviewContent();
  const sourceConfig = document.config ? document.config : fallbackDocument.config;
  const extendedUnderstanding = normalizeReviewText(sourceContent.extendedUnderstanding);
  const judgement = normalizeReviewJudgement(normalizeReviewText(sourceContent.judgement, extendedUnderstanding));
  return {
    version: normalizeReviewText(document.version, fallbackDocument.version),
    projectId: document.projectId && document.projectId.length > 0 ? document.projectId : DEFAULT_PROJECT_ID,
    imageUri: normalizeReviewText(document.imageUri),
    imageWidth: normalizeReviewNumber(document.imageWidth, fallbackDocument.imageWidth),
    imageHeight: normalizeReviewNumber(document.imageHeight, fallbackDocument.imageHeight),
    imageSizeFallbackUsed: document.imageSizeFallbackUsed === true,
    content: {
      title: normalizeReviewText(sourceContent.title, DEFAULT_REVIEW_TITLE),
      visualFocus: normalizeReviewText(sourceContent.visualFocus, normalizeReviewText(sourceContent.firstLook)),
      focusReason: normalizeReviewText(sourceContent.focusReason, normalizeReviewText(sourceContent.reason)),
      visualPath: normalizeReviewText(sourceContent.visualPath),
      visibleFacts: normalizeReviewText(sourceContent.visibleFacts),
      coreRelation: normalizeReviewText(sourceContent.coreRelation, normalizeReviewText(sourceContent.strongestRelation)),
      judgement: judgement,
      extendedUnderstanding: extendedUnderstanding,
      currentBlocker: normalizeReviewText(sourceContent.currentBlocker, normalizeReviewText(sourceContent.blocker))
    },
    config: {
      templateId: normalizeReviewText(sourceConfig.templateId, fallbackDocument.config.templateId),
      layoutMode: sourceConfig.layoutMode ? sourceConfig.layoutMode : fallbackDocument.config.layoutMode,
      background: sourceConfig.background ? sourceConfig.background : fallbackDocument.config.background,
      textSize: sourceConfig.textSize ? sourceConfig.textSize : fallbackDocument.config.textSize
    },
    createdAt: normalizeReviewNumber(document.createdAt, fallbackDocument.createdAt),
    updatedAt: normalizeReviewNumber(document.updatedAt, fallbackDocument.updatedAt)
  };
}

export function getReviewDocumentKey(document: ReviewCardDocument): string {
  return `${document.createdAt}`;
}
