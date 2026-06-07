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
export struct ExportHorizontalReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  private getPreset(): ReviewCardStyleDefinition {
    return ReviewCardStylePreset.resolve(ReviewCardRenderMode.EXPORT_CARD, ReviewCardLayoutType.HORIZONTAL);
  }

  build() {
    Column() {
      ReviewPhotoArea({
        imageUri: this.document.imageUri,
        imageWidth: this.document.imageWidth,
        imageHeight: this.document.imageHeight,
        imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
        aspectRatioValue: resolveReviewCardLayoutResolution(this.document).aspectRatio,
        cornerRadius: this.getPreset().imageRadius
      })

      Column() {
        ReviewCardTitle({
          title: this.document.content.title,
          titleSize: this.getPreset().titleSize,
          titleLineHeight: this.getPreset().titleLineHeight
        })

        ReviewInfoGroup({
          firstLook: this.document.content.firstLook,
          judgement: this.document.content.judgement,
          blocker: this.document.content.blocker,
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
        left: 6,
        right: 6,
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
