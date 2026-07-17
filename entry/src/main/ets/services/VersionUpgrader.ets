import { cloneReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';

const REVIEW_CARD_DOCUMENT_VERSION: string = '0.2.0';

function parseVersionPart(version: string, index: number): number {
  const parts: Array<string> = version.split('.');
  if (index >= parts.length) {
    return 0;
  }
  const parsedValue: number = Number(parts[index]);
  return Number.isFinite(parsedValue) && parsedValue >= 0 ? parsedValue : 0;
}

function isVersionLowerThan(version: string, targetVersion: string): boolean {
  for (let index = 0; index < 3; index += 1) {
    const currentPart: number = parseVersionPart(version, index);
    const targetPart: number = parseVersionPart(targetVersion, index);
    if (currentPart < targetPart) {
      return true;
    }
    if (currentPart > targetPart) {
      return false;
    }
  }
  return false;
}

export function upgradeVersionOnPersist(document: ReviewCardDocument): ReviewCardDocument {
  const clonedDocument: ReviewCardDocument = cloneReviewCardDocument(document);
  if (!isVersionLowerThan(clonedDocument.version, REVIEW_CARD_DOCUMENT_VERSION)) {
    return clonedDocument;
  }
  clonedDocument.version = REVIEW_CARD_DOCUMENT_VERSION;
  return clonedDocument;
}
