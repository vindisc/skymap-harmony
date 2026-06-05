import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';
import { ReviewPhotoArea } from './ReviewPhotoArea';

@Component
export struct ReadingReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop displayMode: string = 'preview';

  private isExportMode(): boolean {
    return this.displayMode === 'export';
  }

  private getPhotoRatio(): number {
    if (this.document.imageWidth <= 0 || this.document.imageHeight <= 0) {
      return 1.35;
    }

    const ratio: number = this.document.imageWidth / this.document.imageHeight;
    if (ratio >= 1.15) {
      return 1.45;
    }

    if (ratio <= 0.85) {
      return 0.82;
    }

    return 1;
  }

  private getCardPadding(): number {
    return this.isExportMode() ? 18 : ReviewCardStyleTokens.cardPadding;
  }

  private getTextTopGap(): number {
    return this.isExportMode() ? 16 : 20;
  }

  private getInfoTopGap(): number {
    return this.isExportMode() ? 15 : 20;
  }

  private getTitleSize(): number {
    return this.isExportMode() ? 17 : ReviewCardStyleTokens.titleSize;
  }

  private getTitleLineHeight(): number {
    return this.isExportMode() ? 23 : ReviewCardStyleTokens.titleLineHeight;
  }

  private getLabelSize(): number {
    return this.isExportMode() ? 9 : ReviewCardStyleTokens.labelSize;
  }

  private getLabelLineHeight(): number {
    return this.isExportMode() ? 13 : ReviewCardStyleTokens.labelLineHeight;
  }

  private getBodySize(): number {
    return this.isExportMode() ? 12 : ReviewCardStyleTokens.bodySize;
  }

  private getBodyLineHeight(): number {
    return this.isExportMode() ? 18 : ReviewCardStyleTokens.bodyLineHeight;
  }

  build() {
    Column() {
      ReviewPhotoArea({
        imageUri: this.document.imageUri,
        imageWidth: this.document.imageWidth,
        imageHeight: this.document.imageHeight,
        aspectRatioValue: this.getPhotoRatio(),
        compact: true
      })

      Column() {
        ReviewCardTitle({
          title: this.document.content.title,
          titleSize: this.getTitleSize(),
          titleLineHeight: this.getTitleLineHeight()
        })

        ReviewInfoGroup({
          firstLook: this.document.content.firstLook,
          judgement: this.document.content.judgement,
          blocker: this.document.content.blocker,
          labelSize: this.getLabelSize(),
          labelLineHeight: this.getLabelLineHeight(),
          bodySize: this.getBodySize(),
          bodyLineHeight: this.getBodyLineHeight(),
          valueTopGap: this.isExportMode() ? 5 : 7,
          dividerBottomGap: this.isExportMode() ? 12 : 16
        })
          .margin({ top: this.getInfoTopGap() })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 2, right: 2, top: this.getTextTopGap() })
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(this.getCardPadding())
    .width('100%')
    .borderRadius(ReviewCardStyleTokens.cardRadius)
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
    .border({ width: 1, color: ReviewCardStyleTokens.hairlineColor })
    .shadow({ radius: 16, color: ReviewCardStyleTokens.shadowColor, offsetX: 0, offsetY: 8 })
  }
}
