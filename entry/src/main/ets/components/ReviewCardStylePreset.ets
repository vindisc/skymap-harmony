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

    return {
      canvasWidth: 1520,
      cardPadding: 58,
      cardRadius: 0,
      titleSize: 38,
      titleLineHeight: 52,
      labelSize: 16,
      labelLineHeight: 22,
      bodySize: 24,
      bodyLineHeight: 34,
      textTopGap: 24,
      infoTopGap: 18,
      valueTopGap: 6,
      dividerBottomGap: 10,
      itemBottomGap: 12,
      sectionGap: 0,
      dividerColor: '#ECE5DA',
      imageRadius: 22,
      photoWidthPercent: '100%',
      verticalPhotoWidth: 0,
      textColumnMinWidth: 0,
      photoMaxWidth: 0,
      shadowRadius: 18,
      shadowOffsetY: 12
    };
  }
}
