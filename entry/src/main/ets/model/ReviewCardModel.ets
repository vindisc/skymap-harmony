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

export interface ReviewContent {
  title: string;
  firstLook: string;
  reason: string;
  visualPath: string;
  strongestRelation: string;
  judgement: string;
  blocker: string;
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
}

export const DEFAULT_REVIEW_TITLE: string = '这张照片是否成立';
export const DEFAULT_PROJECT_ID: string = 'default';

function normalizeReviewText(value: string | undefined, fallback: string = ''): string {
  if (typeof value === 'string') {
    return value;
  }
  return fallback;
}

export function createDefaultReviewContent(): ReviewContent {
  return {
    title: DEFAULT_REVIEW_TITLE,
    firstLook: '',
    reason: '',
    visualPath: '',
    strongestRelation: '',
    judgement: '',
    blocker: ''
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
  const sourceContent = document.content ? document.content : createDefaultReviewContent();
  return {
    version: document.version,
    projectId: document.projectId && document.projectId.length > 0 ? document.projectId : DEFAULT_PROJECT_ID,
    imageUri: document.imageUri,
    imageWidth: document.imageWidth,
    imageHeight: document.imageHeight,
    imageSizeFallbackUsed: document.imageSizeFallbackUsed === true,
    content: {
      title: normalizeReviewText(sourceContent.title, DEFAULT_REVIEW_TITLE),
      firstLook: normalizeReviewText(sourceContent.firstLook),
      reason: normalizeReviewText(sourceContent.reason),
      visualPath: normalizeReviewText(sourceContent.visualPath),
      strongestRelation: normalizeReviewText(sourceContent.strongestRelation),
      judgement: normalizeReviewText(sourceContent.judgement),
      blocker: normalizeReviewText(sourceContent.blocker)
    },
    config: {
      templateId: document.config.templateId,
      layoutMode: document.config.layoutMode,
      background: document.config.background,
      textSize: document.config.textSize
    },
    createdAt: document.createdAt,
    updatedAt: document.updatedAt
  };
}

export function getReviewDocumentKey(document: ReviewCardDocument): string {
  return `${document.createdAt}`;
}
