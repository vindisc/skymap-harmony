import { ReviewCardLayoutType, ReviewCardRenderMode } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';

export interface ReviewCardStyleDefinition {
  canvasWidth: number;
  cardPadding: number;
  cardRadius: number;
  titleSize: number;
  titleLineHeight: number;
  labelSize: number;
  labelLineHeight: number;
  bodySize: number;
  bodyLineHeight: number;
  textTopGap: number;
  infoTopGap: number;
  valueTopGap: number;
  dividerBottomGap: number;
  itemBottomGap: number;
  sectionGap: number;
  dividerColor: string;
  imageRadius: number;
  photoWidthPercent: string;
  verticalPhotoWidth: number;
  textColumnMinWidth: number;
  photoMaxWidth: number;
  shadowRadius: number;
  shadowOffsetY: number;
}

export class ReviewCardStylePreset {
  static previewMaxWidth(): number {
    return 480;
  }

  static resolve(renderMode: ReviewCardRenderMode, layoutType: ReviewCardLayoutType): ReviewCardStyleDefinition {
    if (renderMode === ReviewCardRenderMode.MOBILE_READING) {
      return {
        canvasWidth: ReviewCardStylePreset.previewMaxWidth(),
        cardPadding: 18,
        cardRadius: 12,
        titleSize: 22,
        titleLineHeight: 32,
        labelSize: 12,
        labelLineHeight: 18,
        bodySize: 16,
        bodyLineHeight: 26,
        textTopGap: 18,
        infoTopGap: 16,
        valueTopGap: 6,
        dividerBottomGap: 14,
        itemBottomGap: 14,
        sectionGap: 20,
        dividerColor: ReviewCardStyleTokens.hairlineColor,
        imageRadius: 14,
        photoWidthPercent: layoutType === ReviewCardLayoutType.VERTICAL ? '72%' : '100%',
        verticalPhotoWidth: 0,
        textColumnMinWidth: 0,
        photoMaxWidth: 0,
        shadowRadius: 16,
        shadowOffsetY: 10
      };
    }

    if (layoutType === ReviewCardLayoutType.VERTICAL) {
      return {
        canvasWidth: 1680,
        cardPadding: 72,
        cardRadius: 28,
        titleSize: 44,
        titleLineHeight: 62,
        labelSize: 18,
        labelLineHeight: 26,
        bodySize: 26,
        bodyLineHeight: 40,
        textTopGap: 18,
        infoTopGap: 24,
        valueTopGap: 8,
        dividerBottomGap: 14,
        itemBottomGap: 16,
        sectionGap: 54,
        dividerColor: '#ECE5DA',
        imageRadius: 24,
        photoWidthPercent: '100%',
        verticalPhotoWidth: 640,
        textColumnMinWidth: 620,
        photoMaxWidth: 0,
        shadowRadius: 18,
        shadowOffsetY: 12
      };
    }

    if (layoutType === ReviewCardLayoutType.SQUARE) {
      return {
        canvasWidth: 1520,
        cardPadding: 66,
        cardRadius: 28,
        titleSize: 40,
        titleLineHeight: 56,
        labelSize: 17,
        labelLineHeight: 24,
        bodySize: 25,
        bodyLineHeight: 38,
        textTopGap: 28,
        infoTopGap: 20,
        valueTopGap: 8,
        dividerBottomGap: 14,
        itemBottomGap: 16,
        sectionGap: 46,
        dividerColor: '#ECE5DA',
        imageRadius: 24,
        photoWidthPercent: '74%',
        verticalPhotoWidth: 0,
        textColumnMinWidth: 0,
        photoMaxWidth: 920,
        shadowRadius: 18,
        shadowOffsetY: 12
      };
    }

    return {
      canvasWidth: 1520,
      cardPadding: 66,
      cardRadius: 28,
      titleSize: 42,
      titleLineHeight: 58,
      labelSize: 17,
      labelLineHeight: 24,
      bodySize: 25,
      bodyLineHeight: 38,
      textTopGap: 28,
      infoTopGap: 20,
      valueTopGap: 8,
      dividerBottomGap: 14,
      itemBottomGap: 16,
      sectionGap: 44,
      dividerColor: '#ECE5DA',
      imageRadius: 24,
      photoWidthPercent: '100%',
      verticalPhotoWidth: 0,
      textColumnMinWidth: 0,
      photoMaxWidth: 0,
      shadowRadius: 18,
      shadowOffsetY: 12
    };
  }
}
