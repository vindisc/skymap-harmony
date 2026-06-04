import { ReviewCardBackground, ReviewCardTextSize } from './ReviewCardModel';

export interface ReviewCardTheme {
  canvasColor: string;
  panelColor: string;
  textColor: string;
  mutedTextColor: string;
  accentColor: string;
  titleSize: number;
  bodySize: number;
  captionSize: number;
}

export function resolveReviewCardTheme(background: ReviewCardBackground, textSize: ReviewCardTextSize): ReviewCardTheme {
  let titleSize: number = 20;
  let bodySize: number = 14;
  let captionSize: number = 11;

  if (textSize === ReviewCardTextSize.SMALL) {
    titleSize = 18;
    bodySize = 13;
    captionSize = 10;
  } else if (textSize === ReviewCardTextSize.LARGE) {
    titleSize = 22;
    bodySize = 16;
    captionSize = 12;
  }

  return {
    canvasColor: background === ReviewCardBackground.LIGHT_GRAY ? '#F1F3F5' : '#FFFFFF',
    panelColor: '#F8F9FB',
    textColor: '#1F2329',
    mutedTextColor: '#68707D',
    accentColor: '#8CB6A8',
    titleSize: titleSize,
    bodySize: bodySize,
    captionSize: captionSize
  };
}

