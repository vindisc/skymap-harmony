import { ReviewCardDocument, ReviewCardLayoutMode } from './ReviewCardModel';

export function resolveLayoutMode(document: ReviewCardDocument): ReviewCardLayoutMode {
  if (document.config.layoutMode !== ReviewCardLayoutMode.AUTO) {
    return document.config.layoutMode;
  }

  if (document.imageHeight <= 0) {
    return ReviewCardLayoutMode.SQUARE_PHOTO_BOTTOM_TEXT;
  }

  const ratio: number = document.imageWidth / document.imageHeight;
  if (ratio >= 1.15) {
    return ReviewCardLayoutMode.HORIZONTAL_PHOTO_BOTTOM_TEXT;
  }

  if (ratio <= 0.85) {
    return ReviewCardLayoutMode.VERTICAL_PHOTO_RIGHT_TEXT;
  }

  return ReviewCardLayoutMode.SQUARE_PHOTO_BOTTOM_TEXT;
}

