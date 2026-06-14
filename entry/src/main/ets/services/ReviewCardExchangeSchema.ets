import {
  normalizeReviewJudgement,
  ReviewCardDocument,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { formatReviewTime, isSampleImageUri } from '../utils/ImageLayoutUtils';

export const REVIEW_CARD_EXCHANGE_SCHEMA_NAME: string = 'ReviewCardExchangeSchema';
export const REVIEW_CARD_EXCHANGE_SCHEMA_VERSION: string = 'v1';
export const REVIEW_CARD_EXCHANGE_STRUCTURE_QUICK_REVIEW: string = 'quickReview';

export enum ReviewCardExchangeDecision {
  WORKS = 'works',
  UNCERTAIN = 'uncertain',
  NOT_WORKS = 'notWorks'
}

export interface ReviewCardExchangeSchemaV1 {
  fileName: string;
  titleText: string;
  reviewTimeText: string;
  reviewerText: string;
  reviewStructure: string;
  decision: string;
  firstLookText: string;
  attentionReasonText: string;
  eyePathText: string;
  visualFactText: string;
  strongestRelationText: string;
  extensionReasonText: string;
  blockerText: string;
}

function normalizeExchangeText(value: string | undefined): string {
  if (typeof value === 'string') {
    return value;
  }
  return '';
}

export function mapReviewJudgementToExchangeDecision(value: string | undefined): ReviewCardExchangeDecision {
  const judgement: ReviewJudgementStatus = normalizeReviewJudgement(value);
  if (judgement === ReviewJudgementStatus.VALID) {
    return ReviewCardExchangeDecision.WORKS;
  }
  if (judgement === ReviewJudgementStatus.INVALID) {
    return ReviewCardExchangeDecision.NOT_WORKS;
  }
  return ReviewCardExchangeDecision.UNCERTAIN;
}

export function resolveReviewCardExchangeFileName(document: ReviewCardDocument): string {
  const imageUri: string = normalizeExchangeText(document.imageUri).trim();
  if (imageUri.length === 0 || isSampleImageUri(imageUri)) {
    return '';
  }

  const withoutQuery: string = imageUri.split('?')[0].split('#')[0];
  const pathParts: Array<string> = withoutQuery.split('/');
  const rawFileName: string = pathParts.length > 0 ? pathParts[pathParts.length - 1] : '';
  if (rawFileName.length === 0) {
    return '';
  }

  try {
    return decodeURIComponent(rawFileName);
  } catch (error) {
    return rawFileName;
  }
}

function removeLastFileExtension(fileName: string): string {
  const dotIndex: number = fileName.lastIndexOf('.');
  if (dotIndex > 0) {
    return fileName.slice(0, dotIndex);
  }
  return fileName;
}

function sanitizeReviewJsonBaseName(fileName: string): string {
  const baseName: string = removeLastFileExtension(fileName).trim();
  return baseName.replace(/[\\/:*?"<>|\r\n\t]+/g, '-').trim();
}

export function resolveReviewCardExchangeReviewJsonFileName(document: ReviewCardDocument): string {
  const sourceFileName: string = sanitizeReviewJsonBaseName(resolveReviewCardExchangeFileName(document));
  if (sourceFileName.length > 0) {
    return `${sourceFileName}.review.json`;
  }

  const timestamp: number = document.updatedAt > 0 ? document.updatedAt : Date.now();
  return `review-${timestamp}.json`;
}

export function createReviewCardExchangeSchemaV1(
  document: ReviewCardDocument,
  reviewerText: string = ''
): ReviewCardExchangeSchemaV1 {
  return {
    fileName: resolveReviewCardExchangeFileName(document),
    titleText: normalizeExchangeText(document.content.title),
    reviewTimeText: formatReviewTime(document.updatedAt),
    reviewerText: normalizeExchangeText(reviewerText).trim(),
    reviewStructure: REVIEW_CARD_EXCHANGE_STRUCTURE_QUICK_REVIEW,
    decision: mapReviewJudgementToExchangeDecision(document.content.judgement),
    firstLookText: normalizeExchangeText(document.content.visualFocus),
    attentionReasonText: normalizeExchangeText(document.content.focusReason),
    eyePathText: normalizeExchangeText(document.content.visualPath),
    visualFactText: normalizeExchangeText(document.content.visibleFacts),
    strongestRelationText: normalizeExchangeText(document.content.coreRelation),
    extensionReasonText: normalizeExchangeText(document.content.extendedUnderstanding),
    blockerText: normalizeExchangeText(document.content.currentBlocker)
  };
}

export function stringifyReviewCardExchangeSchemaV1(document: ReviewCardDocument, reviewerText: string = ''): string {
  return JSON.stringify(createReviewCardExchangeSchemaV1(document, reviewerText), null, 2);
}
