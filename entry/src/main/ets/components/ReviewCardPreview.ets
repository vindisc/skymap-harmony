import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ReadingReviewCard } from './ReadingReviewCard';
import { ReviewCardRenderPreset } from './ReviewCardRenderPreset';

@Component
export struct ReviewCardPreview {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop displayMode: string = 'preview';

  build() {
    if (this.displayMode === 'export') {
      Column() {
        ReadingReviewCard({
          document: this.document,
          displayMode: this.displayMode
        })
      }
      .width(ReviewCardRenderPreset.exportCanvasWidth())
    } else {
      Column() {
        ReadingReviewCard({
          document: this.document,
          displayMode: this.displayMode
        })
      }
      .width('100%')
      .constraintSize({ maxWidth: 480 })
    }
  }
}
