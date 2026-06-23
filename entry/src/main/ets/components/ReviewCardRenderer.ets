import {
  createDefaultReviewCardDocument,
  ReviewCardDocument,
  ReviewCardLayoutType,
  ReviewCardRenderMode
} from '../model/ReviewCardModel';
import { MobileReadingReviewCard } from './MobileReadingReviewCard';
import { LongFormExportReviewCard } from './LongFormExportReviewCard';

@Component
export struct ReviewCardRenderer {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop renderMode: ReviewCardRenderMode = ReviewCardRenderMode.MOBILE_READING;
  @Prop layoutType: ReviewCardLayoutType = ReviewCardLayoutType.HORIZONTAL;
  @Prop exportComponentId: string = '';
  @Prop exportCanvasHeight: number = 0;
  @Prop reviewerName: string = '';

  build() {
    if (this.renderMode === ReviewCardRenderMode.MOBILE_READING) {
      MobileReadingReviewCard({
        document: this.document,
        layoutType: this.layoutType
      })
    } else {
      LongFormExportReviewCard({
        document: this.document,
        exportComponentId: this.exportComponentId,
        canvasHeight: this.exportCanvasHeight,
        reviewerName: this.reviewerName
      })
    }
  }
}
