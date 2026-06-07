import {
  createDefaultReviewCardDocument,
  ReviewCardDocument,
  ReviewCardLayoutType,
  ReviewCardRenderMode
} from '../model/ReviewCardModel';
import { MobileReadingReviewCard } from './MobileReadingReviewCard';
import { ExportHorizontalReviewCard } from './ExportHorizontalReviewCard';
import { ExportVerticalReviewCard } from './ExportVerticalReviewCard';
import { ExportSquareReviewCard } from './ExportSquareReviewCard';

@Component
export struct ReviewCardRenderer {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop renderMode: ReviewCardRenderMode = ReviewCardRenderMode.MOBILE_READING;
  @Prop layoutType: ReviewCardLayoutType = ReviewCardLayoutType.HORIZONTAL;

  build() {
    if (this.renderMode === ReviewCardRenderMode.MOBILE_READING) {
      MobileReadingReviewCard({
        document: this.document,
        layoutType: this.layoutType
      })
    } else if (this.layoutType === ReviewCardLayoutType.VERTICAL) {
      ExportVerticalReviewCard({
        document: this.document
      })
    } else if (this.layoutType === ReviewCardLayoutType.SQUARE) {
      ExportSquareReviewCard({
        document: this.document
      })
    } else {
      ExportHorizontalReviewCard({
        document: this.document
      })
    }
  }
}
