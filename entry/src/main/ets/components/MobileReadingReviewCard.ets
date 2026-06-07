import {
  createDefaultReviewCardDocument,
  ReviewCardDocument,
  ReviewCardLayoutResolution,
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
export struct MobileReadingReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop layoutType: ReviewCardLayoutType = ReviewCardLayoutType.HORIZONTAL;

  private getPreset(): ReviewCardStyleDefinition {
    return ReviewCardStylePreset.resolve(ReviewCardRenderMode.MOBILE_READING, this.layoutType);
  }

  private getLayoutResolution(): ReviewCardLayoutResolution {
    return resolveReviewCardLayoutResolution(this.document);
  }

  @Builder
  PhotoBlock() {
    Column() {
      ReviewPhotoArea({
        imageUri: this.document.imageUri,
        imageWidth: this.document.imageWidth,
        imageHeight: this.document.imageHeight,
        imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
        aspectRatioValue: this.getLayoutResolution().aspectRatio,
        compact: this.layoutType === ReviewCardLayoutType.VERTICAL,
        cornerRadius: this.getPreset().imageRadius
      })
    }
    .width(this.getPreset().photoWidthPercent)
    .alignSelf(ItemAlign.Center)
  }

  build() {
    Column() {
      this.PhotoBlock()

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
        left: 2,
        right: 2,
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
    .shadow({
      radius: this.getPreset().shadowRadius,
      color: ReviewCardStyleTokens.shadowColor,
      offsetX: 0,
      offsetY: this.getPreset().shadowOffsetY
    })
  }
}
