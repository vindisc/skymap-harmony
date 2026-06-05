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
          .margin({ bottom: 16 })
      }
      Text(this.label)
        .fontSize(ReviewCardStyleTokens.labelSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(ReviewCardStyleTokens.labelColor)
        .lineHeight(ReviewCardStyleTokens.labelLineHeight)
        .width('100%')
      Text(this.value.length > 0 ? this.value : '待填写')
        .fontSize(this.emphasized ? ReviewCardStyleTokens.bodySize + 1 : ReviewCardStyleTokens.bodySize)
        .fontWeight(this.emphasized ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(ReviewCardStyleTokens.bodyColor)
        .lineHeight(ReviewCardStyleTokens.bodyLineHeight)
        .margin({ top: 5 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ top: this.emphasized ? 2 : 0, bottom: this.emphasized ? 2 : 0 })
    .width('100%')
  }
}
