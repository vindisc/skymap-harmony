export enum ReviewCardLayoutMode {
  AUTO = 'auto',
  HORIZONTAL_PHOTO_BOTTOM_TEXT = 'horizontalPhotoBottomText',
  VERTICAL_PHOTO_RIGHT_TEXT = 'verticalPhotoRightText',
  SQUARE_PHOTO_BOTTOM_TEXT = 'squarePhotoBottomText'
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
  imageUri: string;
  imageWidth: number;
  imageHeight: number;
  content: ReviewContent;
  config: ReviewCardConfig;
  createdAt: number;
  updatedAt: number;
}

export const DEFAULT_REVIEW_TITLE: string = '这张照片是否成立';

export function createDefaultReviewContent(): ReviewContent {
  return {
    title: DEFAULT_REVIEW_TITLE,
    firstLook: '',
    judgement: '',
    blocker: ''
  };
}

export function createDefaultReviewCardDocument(): ReviewCardDocument {
  const now: number = Date.now();
  return {
    version: '0.1.0',
    imageUri: '',
    imageWidth: 1600,
    imageHeight: 1000,
    content: createDefaultReviewContent(),
    config: {
      templateId: 'review-card-basic',
      layoutMode: ReviewCardLayoutMode.AUTO,
      background: ReviewCardBackground.WHITE,
      textSize: ReviewCardTextSize.STANDARD
    },
    createdAt: now,
    updatedAt: now
  };
}

export function cloneReviewCardDocument(document: ReviewCardDocument): ReviewCardDocument {
  return {
    version: document.version,
    imageUri: document.imageUri,
    imageWidth: document.imageWidth,
    imageHeight: document.imageHeight,
    content: {
      title: document.content.title,
      firstLook: document.content.firstLook,
      judgement: document.content.judgement,
      blocker: document.content.blocker
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

