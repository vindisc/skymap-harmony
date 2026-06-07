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
        cardRadius: 10,
        titleSize: 20,
        titleLineHeight: 30,
        labelSize: 11,
        labelLineHeight: 16,
        bodySize: 15,
        bodyLineHeight: 24,
        textTopGap: 16,
        infoTopGap: 12,
        valueTopGap: 5,
        dividerBottomGap: 10,
        itemBottomGap: 10,
        sectionGap: 20,
        dividerColor: ReviewCardStyleTokens.hairlineColor,
        imageRadius: 10,
        photoWidthPercent: layoutType === ReviewCardLayoutType.VERTICAL ? '72%' : '100%',
        verticalPhotoWidth: 0,
        textColumnMinWidth: 0,
        photoMaxWidth: 0,
        shadowRadius: 14,
        shadowOffsetY: 10
      };
    }

    if (layoutType === ReviewCardLayoutType.VERTICAL) {
      return {
        canvasWidth: 1920,
        cardPadding: 96,
        cardRadius: 34,
        titleSize: 58,
        titleLineHeight: 82,
        labelSize: 24,
        labelLineHeight: 34,
        bodySize: 34,
        bodyLineHeight: 50,
        textTopGap: 0,
        infoTopGap: 26,
        valueTopGap: 10,
        dividerBottomGap: 18,
        itemBottomGap: 22,
        sectionGap: 68,
        dividerColor: '#E7E0D5',
        imageRadius: 30,
        photoWidthPercent: '100%',
        verticalPhotoWidth: 640,
        textColumnMinWidth: 760,
        photoMaxWidth: 0,
        shadowRadius: 28,
        shadowOffsetY: 16
      };
    }

    if (layoutType === ReviewCardLayoutType.SQUARE) {
      return {
        canvasWidth: 1600,
        cardPadding: 74,
        cardRadius: 30,
        titleSize: 50,
        titleLineHeight: 72,
        labelSize: 22,
        labelLineHeight: 30,
        bodySize: 32,
        bodyLineHeight: 46,
        textTopGap: 34,
        infoTopGap: 22,
        valueTopGap: 10,
        dividerBottomGap: 18,
        itemBottomGap: 18,
        sectionGap: 52,
        dividerColor: '#E8E2D8',
        imageRadius: 28,
        photoWidthPercent: '72%',
        verticalPhotoWidth: 0,
        textColumnMinWidth: 0,
        photoMaxWidth: 980,
        shadowRadius: 24,
        shadowOffsetY: 14
      };
    }

    return {
      canvasWidth: 1600,
      cardPadding: 72,
      cardRadius: 30,
      titleSize: 52,
      titleLineHeight: 74,
      labelSize: 22,
      labelLineHeight: 30,
      bodySize: 32,
      bodyLineHeight: 46,
      textTopGap: 34,
      infoTopGap: 22,
      valueTopGap: 10,
      dividerBottomGap: 18,
      itemBottomGap: 18,
      sectionGap: 48,
      dividerColor: '#E8E2D8',
      imageRadius: 28,
      photoWidthPercent: '100%',
      verticalPhotoWidth: 0,
      textColumnMinWidth: 0,
      photoMaxWidth: 0,
      shadowRadius: 24,
      shadowOffsetY: 14
    };
  }
}
