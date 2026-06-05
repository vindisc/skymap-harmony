import { DEFAULT_REVIEW_TITLE } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';

@Component
export struct ReviewCardTitle {
  @Prop title: string = DEFAULT_REVIEW_TITLE;

  build() {
    Text(this.title.length > 0 ? this.title : DEFAULT_REVIEW_TITLE)
      .fontSize(ReviewCardStyleTokens.titleSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(ReviewCardStyleTokens.inkColor)
      .lineHeight(ReviewCardStyleTokens.titleLineHeight)
      .width('100%')
  }
}
