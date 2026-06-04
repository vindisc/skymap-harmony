import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewInfoItem } from './ReviewInfoItem';

@Component
export struct ReviewInfoGroup {
  @Prop firstLook: string = '';
  @Prop judgement: string = '';
  @Prop blocker: string = '';
  @Prop compact: boolean = false;

  build() {
    Column() {
      Divider()
        .strokeWidth(1)
        .color(ReviewCardStyleTokens.hairlineColor)
        .width('100%')
      Row({ space: this.compact ? 12 : 18 }) {
        ReviewInfoItem({
          label: '第一眼落点',
          value: this.firstLook,
          maxLines: this.compact ? 3 : 4
        })
          .layoutWeight(1)
        ReviewInfoItem({
          label: '是否成立',
          value: this.judgement,
          maxLines: this.compact ? 3 : 4
        })
          .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')
      .margin({ top: this.compact ? 13 : 16 })
      ReviewInfoItem({
        label: '卡点',
        value: this.blocker,
        maxLines: this.compact ? 3 : 4,
        emphasized: true
      })
        .margin({ top: this.compact ? 11 : 14 })
    }
    .width('100%')
  }
}
