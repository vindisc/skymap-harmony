import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';

@Component
export struct ReviewInfoItem {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop maxLines: number = 3;
  @Prop emphasized: boolean = false;

  build() {
    Column() {
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
        .maxLines(this.maxLines)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 5 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ top: this.emphasized ? 12 : 0, bottom: this.emphasized ? 2 : 0 })
    .width('100%')
  }
}
