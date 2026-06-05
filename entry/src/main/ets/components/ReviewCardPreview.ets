import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReadingReviewCard } from './ReadingReviewCard';

@Component
export struct ReviewCardPreview {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop displayMode: string = 'preview';

  build() {
    Column() {
      ReadingReviewCard({
        document: this.document,
        displayMode: this.displayMode
      })
    }
    .width('100%')
    .constraintSize({ maxWidth: this.displayMode === 'export' ? 420 : 480 })
  }
}
