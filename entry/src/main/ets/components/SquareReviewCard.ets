import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewPhotoArea } from './ReviewPhotoArea';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';
import { ReviewCardRenderPreset } from './ReviewCardRenderPreset';
import { resolveReviewImageLayout } from '../utils/ImageLayoutUtils';

@Component
export struct SquareReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop displayMode: string = 'preview';

  @Builder
  PhotoBlock() {
    ReviewPhotoArea({
      imageUri: this.document.imageUri,
      imageWidth: this.document.imageWidth,
      imageHeight: this.document.imageHeight,
      imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
      aspectRatioValue: resolveReviewImageLayout(
        this.document.imageWidth,
        this.document.imageHeight,
        this.document.imageSizeFallbackUsed
      ).aspectRatio
    })
  }

  build() {
    Column() {
      this.PhotoBlock()
      Column() {
        ReviewCardTitle({
          title: this.document.content.title,
          titleSize: ReviewCardRenderPreset.titleSize(this.displayMode),
          titleLineHeight: ReviewCardRenderPreset.titleLineHeight(this.displayMode)
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
          labelSize: ReviewCardRenderPreset.labelSize(this.displayMode),
          labelLineHeight: ReviewCardRenderPreset.labelLineHeight(this.displayMode),
          bodySize: ReviewCardRenderPreset.bodySize(this.displayMode),
          bodyLineHeight: ReviewCardRenderPreset.bodyLineHeight(this.displayMode),
          valueTopGap: ReviewCardRenderPreset.valueTopGap(this.displayMode),
          dividerBottomGap: ReviewCardRenderPreset.dividerBottomGap(this.displayMode),
          itemBottomGap: ReviewCardRenderPreset.itemBottomGap(this.displayMode)
        })
          .margin({ top: ReviewCardRenderPreset.infoTopGap(this.displayMode) })
      }
      .padding({
        left: 2,
        right: 2,
        top: ReviewCardRenderPreset.textTopGap(this.displayMode),
        bottom: 0
      })
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(ReviewCardRenderPreset.cardPadding(this.displayMode))
    .width('100%')
    .borderRadius(ReviewCardRenderPreset.cardRadius(this.displayMode))
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
    .border({ width: 1, color: ReviewCardStyleTokens.hairlineColor })
    .shadow(ReviewCardStyleTokens.resolveRenderShadow(this.displayMode))
  }
}
