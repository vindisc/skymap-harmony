import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';

export class ReviewCardRenderPreset {
  static isExportMode(displayMode: string): boolean {
    return displayMode === 'export';
  }

  static cardPadding(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 22 : 16;
  }

  static cardRadius(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 12 : ReviewCardStyleTokens.cardRadius;
  }

  static textTopGap(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 11 : 13;
  }

  static infoTopGap(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 8 : 10;
  }

  static titleSize(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 13 : 17;
  }

  static titleLineHeight(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 18 : 24;
  }

  static labelSize(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 7 : 10;
  }

  static labelLineHeight(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 10 : 14;
  }

  static bodySize(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 10 : 14;
  }

  static bodyLineHeight(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 15 : 22;
  }

  static valueTopGap(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 3 : 4;
  }

  static dividerBottomGap(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 6 : 8;
  }

  static itemBottomGap(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 4 : 6;
  }

  static shadowRadius(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 8 : 14;
  }

  static shadowOffsetY(displayMode: string): number {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? 6 : 10;
  }

  static verticalInlinePhotoWidth(displayMode: string): string {
    return ReviewCardRenderPreset.isExportMode(displayMode) ? '72%' : '74%';
  }

  static exportCanvasWidth(): number {
    return 560;
  }
}
