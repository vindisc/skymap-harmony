import { ReviewCardDocument, ReviewCardLayoutMode } from './ReviewCardModel';
import { getImageRatioKind, ImageRatioKind } from '../utils/ImageLayoutUtils';

export function resolveLayoutMode(document: ReviewCardDocument): ReviewCardLayoutMode {
  if (document.config.layoutMode !== ReviewCardLayoutMode.AUTO) {
    return document.config.layoutMode;
  }

  const kind: ImageRatioKind = getImageRatioKind(
    document.imageWidth,
    document.imageHeight,
    document.imageSizeFallbackUsed
  );

  if (kind === 'horizontal') {
    return ReviewCardLayoutMode.HORIZONTAL_PHOTO_BOTTOM_TEXT;
  }

  if (kind === 'vertical') {
    return ReviewCardLayoutMode.VERTICAL_PHOTO_RIGHT_TEXT;
  }

  if (kind === 'unknown') {
    return ReviewCardLayoutMode.SQUARE_PHOTO_BOTTOM_TEXT;
  }

  return ReviewCardLayoutMode.SQUARE_PHOTO_BOTTOM_TEXT;
}
