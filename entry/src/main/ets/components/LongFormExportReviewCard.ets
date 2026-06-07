import {
  createDefaultReviewCardDocument,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { resolveReviewCardLayoutResolution } from '../model/ReviewCardLayout';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewPhotoArea } from './ReviewPhotoArea';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';

export class CompactReviewTextStyle {
  static readonly titleSize: number = 38;
  static readonly titleLineHeight: number = 52;
  static readonly labelSize: number = 16;
  static readonly labelLineHeight: number = 22;
  static readonly bodySize: number = 24;
  static readonly bodyLineHeight: number = 34;
  static readonly valueTopGap: number = 6;
  static readonly dividerBottomGap: number = 10;
  static readonly itemBottomGap: number = 12;
}

@Component
export struct LongFormExportReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  build() {
    Column() {
      ReviewPhotoArea({
        imageUri: this.document.imageUri,
        imageWidth: this.document.imageWidth,
        imageHeight: this.document.imageHeight,
        imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
        aspectRatioValue: resolveReviewCardLayoutResolution(this.document).aspectRatio,
        cornerRadius: 22
      })

      Column() {
        ReviewCardTitle({
          title: this.document.content.title,
          titleSize: CompactReviewTextStyle.titleSize,
          titleLineHeight: CompactReviewTextStyle.titleLineHeight
        })

        ReviewInfoGroup({
          visualFocus: this.document.content.visualFocus,
          focusReason: this.document.content.focusReason,
          visualPath: this.document.content.visualPath,
          visibleFacts: this.document.content.visibleFacts,
          coreRelation: this.document.content.coreRelation,
          extendedUnderstanding: this.document.content.extendedUnderstanding,
          currentBlocker: this.document.content.currentBlocker,
          labelSize: CompactReviewTextStyle.labelSize,
          labelLineHeight: CompactReviewTextStyle.labelLineHeight,
          bodySize: CompactReviewTextStyle.bodySize,
          bodyLineHeight: CompactReviewTextStyle.bodyLineHeight,
          labelColor: '#8D929A',
          bodyColor: ReviewCardStyleTokens.bodyColor,
          dividerColor: '#ECE5DA',
          valueTopGap: CompactReviewTextStyle.valueTopGap,
          dividerBottomGap: CompactReviewTextStyle.dividerBottomGap,
          itemBottomGap: CompactReviewTextStyle.itemBottomGap
        })
          .margin({ top: 18 })
      }
      .padding({ top: 24 })
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(58)
    .width('100%')
    .borderRadius(0)
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
  }
}
