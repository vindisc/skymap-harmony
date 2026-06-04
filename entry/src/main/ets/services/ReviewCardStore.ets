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
    return ReviewCardStore.createPhotoDraft(sample.imageUri, sample.imageWidth, sample.imageHeight);
  }

  static createPhotoDraft(imageUri: string, imageWidth: number, imageHeight: number): ReviewCardDocument {
    const draft = createDefaultReviewCardDocument();
    draft.imageUri = imageUri;
    draft.imageWidth = imageWidth;
    draft.imageHeight = imageHeight;
    draft.updatedAt = Date.now();
    ReviewCardStore.currentDocument = draft;
    return cloneReviewCardDocument(draft);
  }

  static getCurrentDocument(): ReviewCardDocument {
    return cloneReviewCardDocument(ReviewCardStore.currentDocument);
  }

  static setCurrentDocument(document: ReviewCardDocument): void {
    ReviewCardStore.currentDocument = cloneReviewCardDocument(document);
  }

  static saveCurrentDocument(document: ReviewCardDocument): void {
    const next = cloneReviewCardDocument(document);
    next.updatedAt = Date.now();
    ReviewCardStore.currentDocument = next;
  }
}
