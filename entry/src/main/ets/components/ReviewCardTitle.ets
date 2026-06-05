import { DEFAULT_REVIEW_TITLE } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';

@Component
export struct ReviewCardTitle {
  @Prop title: string = DEFAULT_REVIEW_TITLE;
  @Prop titleSize: number = ReviewCardStyleTokens.titleSize;
  @Prop titleLineHeight: number = ReviewCardStyleTokens.titleLineHeight;

  build() {
    Text(this.title.length > 0 ? this.title : DEFAULT_REVIEW_TITLE)
      .fontSize(this.titleSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(ReviewCardStyleTokens.inkColor)
      .lineHeight(this.titleLineHeight)
      .width('100%')
      .wordBreak(WordBreak.BREAK_WORD)
      .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
      .textOverflow({ overflow: TextOverflow.Clip })
  }
}
