import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';

@Component
export struct ReviewInfoItem {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop emphasized: boolean = false;
  @Prop showDivider: boolean = false;

  build() {
    Column() {
      if (this.showDivider) {
        Divider()
          .strokeWidth(1)
          .color(ReviewCardStyleTokens.hairlineColor)
          .width('100%')
          .opacity(0.72)
        .margin({ bottom: 16 })
      }
      Text(this.label)
        .fontSize(ReviewCardStyleTokens.labelSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(ReviewCardStyleTokens.labelColor)
        .lineHeight(ReviewCardStyleTokens.labelLineHeight)
        .width('100%')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
        .textOverflow({ overflow: TextOverflow.Clip })
      Text(this.value.length > 0 ? this.value : '待填写')
        .fontSize(ReviewCardStyleTokens.bodySize)
        .fontWeight(FontWeight.Regular)
        .fontColor(ReviewCardStyleTokens.bodyColor)
        .lineHeight(ReviewCardStyleTokens.bodyLineHeight)
        .margin({ top: 7 })
        .width('100%')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
        .textOverflow({ overflow: TextOverflow.Clip })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 0, bottom: 4 })
    .width('100%')
  }
}
