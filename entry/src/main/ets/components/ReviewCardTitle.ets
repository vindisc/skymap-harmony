import { DEFAULT_REVIEW_TITLE } from '../model/ReviewCardModel';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';

@Component
export struct ReviewCardTitle {
  @Prop title: string = DEFAULT_REVIEW_TITLE;
  @Prop compact: boolean = false;

  build() {
    Text(this.title.length > 0 ? this.title : DEFAULT_REVIEW_TITLE)
      .fontSize(this.compact ? 19 : ReviewCardStyleTokens.titleSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(ReviewCardStyleTokens.inkColor)
      .lineHeight(this.compact ? 27 : ReviewCardStyleTokens.titleLineHeight)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
  }
}
