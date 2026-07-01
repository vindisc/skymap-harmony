import {
  createDefaultReviewCardDocument,
  ReviewCardDocument,
  ReviewCardLayoutType,
  ReviewCardRenderMode
} from '../model/ReviewCardModel';
import { resolveReviewCardLayoutResolution } from '../model/ReviewCardLayout';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewCardStyleDefinition, ReviewCardStylePreset } from './ReviewCardStylePreset';
import { ReviewPhotoArea } from './ReviewPhotoArea';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';

@Component
export struct ExportSquareReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  private getPreset(): ReviewCardStyleDefinition {
    return ReviewCardStylePreset.resolve(ReviewCardRenderMode.EXPORT_CARD, ReviewCardLayoutType.SQUARE);
  }

  build() {
    Column() {
      Column() {
        ReviewPhotoArea({
          imageUri: this.document.imageUri,
          imageWidth: this.document.imageWidth,
          imageHeight: this.document.imageHeight,
          imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
          aspectRatioValue: resolveReviewCardLayoutResolution(this.document).aspectRatio,
          cornerRadius: this.getPreset().imageRadius
        })
      }
      .width(this.getPreset().photoWidthPercent)
      .constraintSize({ maxWidth: this.getPreset().photoMaxWidth })
      .alignSelf(ItemAlign.Center)

      Column() {
        ReviewCardTitle({
          title: this.document.content.title,
          titleSize: this.getPreset().titleSize,
          titleLineHeight: this.getPreset().titleLineHeight
        })

        ReviewInfoGroup({
          visualFocus: this.document.content.visualFocus,
          focusReason: this.document.content.focusReason,
          visualPath: this.document.content.visualPath,
          visibleFacts: this.document.content.visibleFacts,
          coreRelation: this.document.content.coreRelation,
          judgement: this.document.content.judgement,
          extendedUnderstanding: this.document.content.extendedUnderstanding,
          currentBlocker: this.document.content.currentBlocker,
          labelSize: this.getPreset().labelSize,
          labelLineHeight: this.getPreset().labelLineHeight,
          bodySize: this.getPreset().bodySize,
          bodyLineHeight: this.getPreset().bodyLineHeight,
          dividerColor: this.getPreset().dividerColor,
          valueTopGap: this.getPreset().valueTopGap,
          dividerBottomGap: this.getPreset().dividerBottomGap,
          itemBottomGap: this.getPreset().itemBottomGap
        })
          .margin({ top: this.getPreset().infoTopGap })
      }
      .padding({
        left: 0,
        right: 0,
        top: this.getPreset().textTopGap,
        bottom: 0
      })
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(this.getPreset().cardPadding)
    .width('100%')
    .borderRadius(this.getPreset().cardRadius)
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
    .border({ width: 1, color: ReviewCardStyleTokens.hairlineColor })
    .shadow(ReviewCardStyleTokens.exportCardShadow)
  }
}
