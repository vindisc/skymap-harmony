import {
  createDefaultReviewCardDocument,
  ReviewCardDocument,
  ReviewCardLayoutMode
} from '../model/ReviewCardModel';
import { resolveLayoutMode } from '../model/ReviewCardLayout';
import { HorizontalReviewCard } from './HorizontalReviewCard';
import { VerticalReviewCard } from './VerticalReviewCard';
import { SquareReviewCard } from './SquareReviewCard';

@Component
export struct ReviewCardPreview {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  build() {
    Column() {
      if (resolveLayoutMode(this.document) === ReviewCardLayoutMode.VERTICAL_PHOTO_RIGHT_TEXT) {
        VerticalReviewCard({ document: this.document })
      } else if (resolveLayoutMode(this.document) === ReviewCardLayoutMode.SQUARE_PHOTO_BOTTOM_TEXT) {
        SquareReviewCard({ document: this.document })
      } else {
        HorizontalReviewCard({ document: this.document })
      }
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .constraintSize({ maxWidth: 720 })
  }
}
