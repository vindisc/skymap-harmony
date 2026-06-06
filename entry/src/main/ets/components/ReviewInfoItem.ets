import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';

@Component
export struct ReviewInfoItem {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop emphasized: boolean = false;
  @Prop showDivider: boolean = false;
  @Prop labelSize: number = ReviewCardStyleTokens.labelSize;
  @Prop labelLineHeight: number = ReviewCardStyleTokens.labelLineHeight;
  @Prop bodySize: number = ReviewCardStyleTokens.bodySize;
  @Prop bodyLineHeight: number = ReviewCardStyleTokens.bodyLineHeight;
  @Prop valueTopGap: number = 7;
  @Prop dividerBottomGap: number = 16;

  build() {
    Column() {
      if (this.showDivider) {
        Divider()
          .strokeWidth(1)
          .color(ReviewCardStyleTokens.hairlineColor)
          .width('100%')
          .opacity(0.46)
          .margin({ bottom: this.dividerBottomGap })
      }
      Text(this.label)
        .fontSize(this.labelSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(ReviewCardStyleTokens.labelColor)
        .lineHeight(this.labelLineHeight)
        .width('100%')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
        .textOverflow({ overflow: TextOverflow.Clip })
      Text(this.value.length > 0 ? this.value : '待填写')
        .fontSize(this.bodySize)
        .fontWeight(FontWeight.Regular)
        .fontColor(ReviewCardStyleTokens.bodyColor)
        .lineHeight(this.bodyLineHeight)
        .margin({ top: this.valueTopGap })
        .width('100%')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
        .textOverflow({ overflow: TextOverflow.Clip })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 0, bottom: 8 })
    .width('100%')
  }
}
