import {
  createDefaultReviewCardDocument,
  ReviewCardDocument,
  ReviewCardRenderMode
} from '../model/ReviewCardModel';
import { resolveReviewCardLayoutResolution } from '../model/ReviewCardLayout';
import { ReviewCardRenderer } from './ReviewCardRenderer';
import { ReviewCardStylePreset } from './ReviewCardStylePreset';

@Component
export struct ReviewCardPreview {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop renderMode: ReviewCardRenderMode = ReviewCardRenderMode.MOBILE_READING;
  @Prop reviewerText: string = '';
  @Prop exportComponentId: string = '';
  @Prop exportCanvasHeight: number = 0;

  private getLayout() {
    return resolveReviewCardLayoutResolution(this.document);
  }

  build() {
    if (this.renderMode === ReviewCardRenderMode.EXPORT_CARD) {
      Column() {
        ReviewCardRenderer({
          document: this.document,
          renderMode: this.renderMode,
          layoutType: this.getLayout().layoutType,
          reviewerText: this.reviewerText,
          exportComponentId: this.exportComponentId,
          exportCanvasHeight: this.exportCanvasHeight
        })
      }
      .width(ReviewCardStylePreset.resolve(this.renderMode, this.getLayout().layoutType).canvasWidth)
      .height(this.exportCanvasHeight)
    } else {
      Column() {
        ReviewCardRenderer({
          document: this.document,
          renderMode: this.renderMode,
          layoutType: this.getLayout().layoutType
        })
      }
      .width('100%')
      .constraintSize({ maxWidth: ReviewCardStylePreset.previewMaxWidth() })
    }
  }
}
