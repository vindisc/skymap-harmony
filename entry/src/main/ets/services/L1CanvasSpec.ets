import { normalizeFrameConfig } from '../model/FrameConfigModel';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveTemplate, TemplateId } from '../model/TemplateModel';
import { CanvasRotatedImageSize } from './CanvasPhotoStripHelpers';

export interface L1CanvasGeometry {
  canvasWidth: number;
  canvasHeight: number;
  outerPaddingPx: number;
  innerPaddingPx: number;
  imageOffsetX: number;
  imageOffsetY: number;
  imageWidth: number;
  imageHeight: number;
  titleFontPx: number;
  bodyFontPx: number;
  bottomBarHeightPx: number;
  bottomBarTopY: number;
  backgroundColorHex: string;
  titleColorHex: string;
  secondaryColorHex: string;
}

export function resolveL1CanvasGeometry(
  document: ReviewCardDocument,
  rotatedSize: CanvasRotatedImageSize
): L1CanvasGeometry {
  const defaults = resolveTemplate(TemplateId.META_BOTTOM).defaults.frame;
  const frame = normalizeFrameConfig(document.config.frame, defaults);
  const longEdge: number = Math.max(rotatedSize.width, rotatedSize.height);
  const shortEdge: number = Math.min(rotatedSize.width, rotatedSize.height);
  const outerPaddingPx: number = Math.round(longEdge * frame.outerPaddingRatio);
  const innerPaddingPx: number = Math.round(longEdge * frame.innerPaddingRatio);
  const titleFontPx: number = Math.max(1, Math.round(shortEdge * frame.titleFontRatio));
  const bodyFontPx: number = Math.max(1, Math.round(shortEdge * frame.bodyFontRatio));
  const bottomBarHeightPx: number = Math.round(titleFontPx * 2.4);
  const bottomBarTopY: number = outerPaddingPx + rotatedSize.height + innerPaddingPx;
  return {
    canvasWidth: rotatedSize.width + outerPaddingPx * 2,
    canvasHeight: rotatedSize.height + outerPaddingPx * 2 + innerPaddingPx + bottomBarHeightPx,
    outerPaddingPx: outerPaddingPx,
    innerPaddingPx: innerPaddingPx,
    imageOffsetX: outerPaddingPx,
    imageOffsetY: outerPaddingPx,
    imageWidth: rotatedSize.width,
    imageHeight: rotatedSize.height,
    titleFontPx: titleFontPx,
    bodyFontPx: bodyFontPx,
    bottomBarHeightPx: bottomBarHeightPx,
    bottomBarTopY: bottomBarTopY,
    backgroundColorHex: frame.backgroundColorHex,
    titleColorHex: frame.textColorHex,
    secondaryColorHex: frame.secondaryTextColorHex
  };
}
