import {
  cloneReviewCardDocument,
  createDefaultReviewCardDocument,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { getSampleImage, SampleImageKind } from '../utils/ImageLayoutUtils';

export class ReviewCardStore {
  private static currentDocument: ReviewCardDocument = createDefaultReviewCardDocument();

  static createDraft(kind: SampleImageKind): ReviewCardDocument {
    const sample = getSampleImage(kind);
    const draft = createDefaultReviewCardDocument();
    draft.imageUri = sample.imageUri;
    draft.imageWidth = sample.imageWidth;
    draft.imageHeight = sample.imageHeight;
    draft.updatedAt = Date.now();
    ReviewCardStore.currentDocument = draft;
    return cloneReviewCardDocument(draft);
  }

  static getCurrentDocument(): ReviewCardDocument {
    return cloneReviewCardDocument(ReviewCardStore.currentDocument);
  }

  static saveCurrentDocument(document: ReviewCardDocument): void {
    const next = cloneReviewCardDocument(document);
    next.updatedAt = Date.now();
    ReviewCardStore.currentDocument = next;
  }
}

