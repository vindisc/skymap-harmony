import {
  ReviewCardDocument,
  ReviewCardLayoutMode,
  ReviewCardLayoutResolution,
  ReviewCardLayoutType
} from './ReviewCardModel';
import { resolveReviewImageLayout } from '../utils/ImageLayoutUtils';

export function resolveLayoutMode(document: ReviewCardDocument): ReviewCardLayoutMode {
  if (document.config.layoutMode !== ReviewCardLayoutMode.AUTO) {
    return document.config.layoutMode;
  }

  const resolution = resolveReviewCardLayoutResolution(document);
  if (resolution.layoutType === ReviewCardLayoutType.HORIZONTAL) {
    return ReviewCardLayoutMode.HORIZONTAL_PHOTO_BOTTOM_TEXT;
  }

  if (resolution.layoutType === ReviewCardLayoutType.VERTICAL) {
    return ReviewCardLayoutMode.VERTICAL_PHOTO_RIGHT_TEXT;
  }

  return ReviewCardLayoutMode.SQUARE_PHOTO_BOTTOM_TEXT;
}

function layoutTypeFromLayoutMode(layoutMode: ReviewCardLayoutMode): ReviewCardLayoutType {
  if (layoutMode === ReviewCardLayoutMode.HORIZONTAL_PHOTO_BOTTOM_TEXT) {
    return ReviewCardLayoutType.HORIZONTAL;
  }

  if (layoutMode === ReviewCardLayoutMode.VERTICAL_PHOTO_RIGHT_TEXT) {
    return ReviewCardLayoutType.VERTICAL;
  }

  return ReviewCardLayoutType.SQUARE;
}

export function resolveReviewCardLayoutResolution(document: ReviewCardDocument): ReviewCardLayoutResolution {
  const detected = resolveReviewImageLayout(
    document.imageWidth,
    document.imageHeight,
    document.imageSizeFallbackUsed
  );

  if (document.config.layoutMode === ReviewCardLayoutMode.AUTO) {
    return detected;
  }

  return {
    layoutType: layoutTypeFromLayoutMode(document.config.layoutMode),
    aspectRatio: detected.aspectRatio,
    usedFallbackSize: detected.usedFallbackSize,
    hasExactSize: detected.hasExactSize
  };
}

export function resolveReviewCardLayoutType(document: ReviewCardDocument): ReviewCardLayoutType {
  return resolveReviewCardLayoutResolution(document).layoutType;
}
