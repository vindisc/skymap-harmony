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
        cardRadius: 16,
        titleSize: 20,
        titleLineHeight: 28,
        labelSize: 12,
        labelLineHeight: 17,
        bodySize: 15,
        bodyLineHeight: 23,
        textTopGap: 16,
        infoTopGap: 14,
        valueTopGap: 5,
        dividerBottomGap: 8,
        itemBottomGap: 12,
        sectionGap: 18,
        dividerColor: ReviewCardStyleTokens.hairlineColor,
        imageRadius: 16,
        photoWidthPercent: layoutType === ReviewCardLayoutType.VERTICAL ? '72%' : '100%',
        verticalPhotoWidth: 0,
        textColumnMinWidth: 0,
        photoMaxWidth: 0,
        shadowRadius: 18,
        shadowOffsetY: 12
      };
    }

    return {
      canvasWidth: 1520,
      cardPadding: 48,
      cardRadius: 12,
      titleSize: 32,
      titleLineHeight: 44,
      labelSize: 15,
      labelLineHeight: 20,
      bodySize: 22,
      bodyLineHeight: 31,
      textTopGap: 20,
      infoTopGap: 16,
      valueTopGap: 4,
      dividerBottomGap: 7,
      itemBottomGap: 9,
      sectionGap: 0,
      dividerColor: '#E6DED0',
      imageRadius: 24,
      photoWidthPercent: '100%',
      verticalPhotoWidth: 0,
      textColumnMinWidth: 0,
      photoMaxWidth: 0,
      shadowRadius: 20,
      shadowOffsetY: 14
    };
  }
}
