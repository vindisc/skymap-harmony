import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReadingReviewCard } from './ReadingReviewCard';

@Component
export struct ReviewCardPreview {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();

  build() {
    Column() {
      ReadingReviewCard({ document: this.document })
    }
    .width('100%')
    .constraintSize({ maxWidth: 480 })
  }
}
