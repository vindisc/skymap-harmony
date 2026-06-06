import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewPhotoArea } from './ReviewPhotoArea';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';
import { ReviewCardRenderPreset } from './ReviewCardRenderPreset';
import { resolveReviewImageLayout } from '../utils/ImageLayoutUtils';

@Component
export struct VerticalReviewCard {
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
      ).aspectRatio,
      compact: true
    })
  }

  build() {
    Column() {
      Column() {
        this.PhotoBlock()
      }
      .width(ReviewCardRenderPreset.verticalInlinePhotoWidth(this.displayMode))
      .alignSelf(ItemAlign.Center)

      Column() {
        ReviewCardTitle({
          title: this.document.content.title,
          titleSize: ReviewCardRenderPreset.titleSize(this.displayMode),
          titleLineHeight: ReviewCardRenderPreset.titleLineHeight(this.displayMode)
        })
        ReviewInfoGroup({
          firstLook: this.document.content.firstLook,
          judgement: this.document.content.judgement,
          blocker: this.document.content.blocker,
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
    .shadow({
      radius: ReviewCardRenderPreset.shadowRadius(this.displayMode),
      color: ReviewCardStyleTokens.shadowColor,
      offsetX: 0,
      offsetY: ReviewCardRenderPreset.shadowOffsetY(this.displayMode)
    })
  }
}
