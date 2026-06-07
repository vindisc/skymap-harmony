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
export struct ExportVerticalReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  private getPreset(): ReviewCardStyleDefinition {
    return ReviewCardStylePreset.resolve(ReviewCardRenderMode.EXPORT_CARD, ReviewCardLayoutType.VERTICAL);
  }

  build() {
    Row({ space: this.getPreset().sectionGap }) {
      Column() {
        ReviewPhotoArea({
          imageUri: this.document.imageUri,
          imageWidth: this.document.imageWidth,
          imageHeight: this.document.imageHeight,
          imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
          aspectRatioValue: resolveReviewCardLayoutResolution(this.document).aspectRatio,
          compact: true,
          cornerRadius: this.getPreset().imageRadius
        })
      }
      .width(this.getPreset().verticalPhotoWidth)
      .margin({ top: 6, bottom: 6 })
      .alignItems(HorizontalAlign.Start)

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
      .layoutWeight(1)
      .constraintSize({ minWidth: this.getPreset().textColumnMinWidth })
      .padding({ top: this.getPreset().textTopGap })
      .alignItems(HorizontalAlign.Start)
    }
    .alignItems(VerticalAlign.Top)
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
