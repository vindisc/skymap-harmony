import {
  cloneReviewCardDocument,
  createDefaultReviewCardDocument,
  DEFAULT_REVIEW_TITLE,
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

function normalizeExchangeSchema(source: ReviewCardExchangeSchemaV1 | undefined): ReviewCardExchangeSchemaV1 {
  const schema: ReviewCardExchangeSchemaV1 = source ? source : {} as ReviewCardExchangeSchemaV1;
  return {
    fileName: normalizeExchangeText(schema.fileName),
    titleText: normalizeExchangeText(schema.titleText),
    reviewTimeText: normalizeExchangeText(schema.reviewTimeText),
    reviewerText: normalizeExchangeText(schema.reviewerText),
    reviewStructure: normalizeExchangeText(schema.reviewStructure),
    decision: normalizeExchangeText(schema.decision),
    firstLookText: normalizeExchangeText(schema.firstLookText),
    attentionReasonText: normalizeExchangeText(schema.attentionReasonText),
    eyePathText: normalizeExchangeText(schema.eyePathText),
    visualFactText: normalizeExchangeText(schema.visualFactText),
    strongestRelationText: normalizeExchangeText(schema.strongestRelationText),
    extensionReasonText: normalizeExchangeText(schema.extensionReasonText),
    blockerText: normalizeExchangeText(schema.blockerText)
  };
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

function parseReviewTimeText(value: string | undefined): number {
  const text: string = normalizeExchangeText(value).trim();
  const sections: Array<string> = text.split(' ');
  if (sections.length !== 2) {
    return 0;
  }

  const dateParts: Array<string> = sections[0].split('-');
  const timeParts: Array<string> = sections[1].split(':');
  if (dateParts.length !== 3 || timeParts.length !== 2) {
    return 0;
  }

  const year: number = Number(dateParts[0]);
  const month: number = Number(dateParts[1]);
  const day: number = Number(dateParts[2]);
  const hour: number = Number(timeParts[0]);
  const minute: number = Number(timeParts[1]);
  if (year <= 0 || month < 1 || month > 12 || day < 1 || day > 31 || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return 0;
  }

  const timestamp: number = new Date(year, month - 1, day, hour, minute, 0, 0).getTime();
  return timestamp > 0 ? timestamp : 0;
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

export function mapExchangeDecisionToReviewJudgement(value: string | undefined): ReviewJudgementStatus {
  const decision: string = normalizeExchangeText(value).trim();
  if (decision === ReviewCardExchangeDecision.WORKS) {
    return ReviewJudgementStatus.VALID;
  }
  if (decision === ReviewCardExchangeDecision.NOT_WORKS) {
    return ReviewJudgementStatus.INVALID;
  }
  return ReviewJudgementStatus.UNSURE;
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

export function parseReviewCardExchangeSchemaV1(jsonText: string): ReviewCardExchangeSchemaV1 {
  const parsed: ReviewCardExchangeSchemaV1 = JSON.parse(jsonText) as ReviewCardExchangeSchemaV1;
  return normalizeExchangeSchema(parsed);
}

export function createReviewCardDocumentFromExchangeSchemaV1(
  schema: ReviewCardExchangeSchemaV1,
  baseDocument: ReviewCardDocument | undefined = undefined
): ReviewCardDocument {
  const normalizedSchema: ReviewCardExchangeSchemaV1 = normalizeExchangeSchema(schema);
  const next: ReviewCardDocument = baseDocument
    ? cloneReviewCardDocument(baseDocument)
    : createDefaultReviewCardDocument();
  const importedReviewTime: number = parseReviewTimeText(normalizedSchema.reviewTimeText);

  next.content.title = normalizedSchema.titleText.length > 0 ? normalizedSchema.titleText : DEFAULT_REVIEW_TITLE;
  next.content.visualFocus = normalizedSchema.firstLookText;
  next.content.focusReason = normalizedSchema.attentionReasonText;
  next.content.visualPath = normalizedSchema.eyePathText;
  next.content.visibleFacts = normalizedSchema.visualFactText;
  next.content.coreRelation = normalizedSchema.strongestRelationText;
  next.content.judgement = mapExchangeDecisionToReviewJudgement(normalizedSchema.decision);
  next.content.extendedUnderstanding = normalizedSchema.extensionReasonText;
  next.content.currentBlocker = normalizedSchema.blockerText;
  next.updatedAt = importedReviewTime > 0 ? importedReviewTime : Date.now();
  return cloneReviewCardDocument(next);
}
