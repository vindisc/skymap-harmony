import { cloneReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveLongFormExportCardHeight } from '../components/LongFormExportReviewCard';
import { ReviewCardStyleTokens } from '../components/ReviewCardStyleTokens';

export const L3_CANVAS_BASELINE_TOTAL_WIDTH: number = 1520;
export const L3_CANVAS_BASELINE_H_PADDING: number = 48;
export const L3_CANVAS_BASELINE_PHOTO_WIDTH: number = 1424;

const L3_CANVAS_BASELINE_TITLE_FONT: number = 32;
const L3_CANVAS_BASELINE_BODY_FONT: number = 22;
const L3_CANVAS_BASELINE_CORNER_RADIUS: number = 22;
const L3_CANVAS_BASELINE_PANEL_PADDING: number = 28;

export interface RotatedPixelMapSize {
  width: number;
  height: number;
}

export interface L3CanvasGeometry {
  canvasWidth: number;
  canvasHeight: number;
  photoOffsetX: number;
  photoOffsetY: number;
  photoWidth: number;
  photoHeight: number;
  scale: number;
  isHorizontal: boolean;
  titleFontPx: number;
  bodyFontPx: number;
  cornerRadiusPx: number;
  panelPaddingPx: number;
  bgColorHex: string;
  textAreaHeightPx: number;
}

export function resolveL3CanvasGeometry(
  document: ReviewCardDocument,
  rotatedSize: RotatedPixelMapSize
): L3CanvasGeometry {
  const safeWidth: number = Math.max(1, rotatedSize.width);
  const safeHeight: number = Math.max(1, rotatedSize.height);
  const scale: number = safeWidth / L3_CANVAS_BASELINE_PHOTO_WIDTH;
  const rotatedDocument: ReviewCardDocument = cloneReviewCardDocument(document);
  rotatedDocument.imageWidth = safeWidth;
  rotatedDocument.imageHeight = safeHeight;
  const cardHeightAtBaseline: number = resolveLongFormExportCardHeight(
    rotatedDocument,
    L3_CANVAS_BASELINE_TOTAL_WIDTH
  );
  const photoHeightAtBaseline: number = safeHeight / scale;
  const canvasWidth: number = Math.round(L3_CANVAS_BASELINE_TOTAL_WIDTH * scale);
  const canvasHeight: number = Math.round(cardHeightAtBaseline * scale);

  return {
    canvasWidth: canvasWidth,
    canvasHeight: canvasHeight,
    photoOffsetX: Math.round(L3_CANVAS_BASELINE_H_PADDING * scale),
    photoOffsetY: Math.round(L3_CANVAS_BASELINE_H_PADDING * scale),
    photoWidth: safeWidth,
    photoHeight: safeHeight,
    scale: scale,
    isHorizontal: safeWidth > safeHeight * 1.05,
    titleFontPx: L3_CANVAS_BASELINE_TITLE_FONT * scale,
    bodyFontPx: L3_CANVAS_BASELINE_BODY_FONT * scale,
    cornerRadiusPx: L3_CANVAS_BASELINE_CORNER_RADIUS * scale,
    panelPaddingPx: L3_CANVAS_BASELINE_PANEL_PADDING * scale,
    bgColorHex: ReviewCardStyleTokens.canvasColor,
    textAreaHeightPx: Math.round((cardHeightAtBaseline - photoHeightAtBaseline) * scale)
  };
}
