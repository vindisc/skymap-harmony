import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';
import { ReviewPhotoArea } from './ReviewPhotoArea';
import { getExportPhotoAspectRatio, getPreviewPhotoAspectRatio } from '../utils/ImageLayoutUtils';

@Component
export struct ReadingReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop displayMode: string = 'preview';

  private isExportMode(): boolean {
    return this.displayMode === 'export';
  }

  private getPhotoAspectRatio(): number {
    if (this.isExportMode()) {
      return getExportPhotoAspectRatio(
        this.document.imageWidth,
        this.document.imageHeight,
        this.document.imageSizeFallbackUsed
      );
    }

    return getPreviewPhotoAspectRatio(
      this.document.imageWidth,
      this.document.imageHeight,
      this.document.imageSizeFallbackUsed
    );
  }

  private getCardPadding(): number {
    return this.isExportMode() ? 22 : 16;
  }

  private getCardRadius(): number {
    return this.isExportMode() ? 12 : ReviewCardStyleTokens.cardRadius;
  }

  private getTextTopGap(): number {
    return this.isExportMode() ? 11 : 13;
  }

  private getInfoTopGap(): number {
    return this.isExportMode() ? 8 : 10;
  }

  private getTitleSize(): number {
    return this.isExportMode() ? 13 : 17;
  }

  private getTitleLineHeight(): number {
    return this.isExportMode() ? 18 : 24;
  }

  private getLabelSize(): number {
    return this.isExportMode() ? 7 : 10;
  }

  private getLabelLineHeight(): number {
    return this.isExportMode() ? 10 : 14;
  }

  private getBodySize(): number {
    return this.isExportMode() ? 10 : 14;
  }

  private getBodyLineHeight(): number {
    return this.isExportMode() ? 15 : 22;
  }

  private getValueTopGap(): number {
    return this.isExportMode() ? 3 : 4;
  }

  private getDividerBottomGap(): number {
    return this.isExportMode() ? 6 : 8;
  }

  private getItemBottomGap(): number {
    return this.isExportMode() ? 4 : 6;
  }

  build() {
    Column() {
      ReviewPhotoArea({
        imageUri: this.document.imageUri,
        imageWidth: this.document.imageWidth,
        imageHeight: this.document.imageHeight,
        imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
        aspectRatioValue: this.getPhotoAspectRatio(),
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
          valueTopGap: this.getValueTopGap(),
          dividerBottomGap: this.getDividerBottomGap(),
          itemBottomGap: this.getItemBottomGap()
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
    .borderRadius(this.getCardRadius())
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
    .border({ width: 1, color: ReviewCardStyleTokens.hairlineColor })
    .shadow({ radius: this.isExportMode() ? 8 : 14, color: ReviewCardStyleTokens.shadowColor, offsetX: 0, offsetY: 6 })
  }
}
