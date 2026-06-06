import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveReviewImageLayout } from '../utils/ImageLayoutUtils';
import { HorizontalReviewCard } from './HorizontalReviewCard';
import { SquareReviewCard } from './SquareReviewCard';
import { VerticalReviewCard } from './VerticalReviewCard';

@Component
export struct ReadingReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop displayMode: string = 'preview';

  private getLayoutType(): string {
    return resolveReviewImageLayout(
      this.document.imageWidth,
      this.document.imageHeight,
      this.document.imageSizeFallbackUsed
    ).layoutType;
  }

  build() {
    if (this.getLayoutType() === 'vertical') {
      VerticalReviewCard({
        document: this.document,
        displayMode: this.displayMode
      })
    } else if (this.getLayoutType() === 'horizontal') {
      HorizontalReviewCard({
        document: this.document,
        displayMode: this.displayMode
      })
    } else {
      SquareReviewCard({
        document: this.document,
        displayMode: this.displayMode
      })
    }
  }
}
