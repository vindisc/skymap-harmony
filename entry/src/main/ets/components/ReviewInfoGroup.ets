import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewInfoItem } from './ReviewInfoItem';

@Component
export struct ReviewInfoGroup {
  @Prop firstLook: string = '';
  @Prop judgement: string = '';
  @Prop blocker: string = '';
  @Prop labelSize: number = ReviewCardStyleTokens.labelSize;
  @Prop labelLineHeight: number = ReviewCardStyleTokens.labelLineHeight;
  @Prop bodySize: number = ReviewCardStyleTokens.bodySize;
  @Prop bodyLineHeight: number = ReviewCardStyleTokens.bodyLineHeight;
  @Prop labelColor: string = ReviewCardStyleTokens.labelColor;
  @Prop bodyColor: string = ReviewCardStyleTokens.bodyColor;
  @Prop dividerColor: string = ReviewCardStyleTokens.hairlineColor;
  @Prop valueTopGap: number = 7;
  @Prop dividerBottomGap: number = 16;
  @Prop itemBottomGap: number = 8;

  build() {
    Column() {
      ReviewInfoItem({
        label: '第一眼落点',
        value: this.firstLook,
        showDivider: false,
        labelSize: this.labelSize,
        labelLineHeight: this.labelLineHeight,
        bodySize: this.bodySize,
        bodyLineHeight: this.bodyLineHeight,
        labelColor: this.labelColor,
        bodyColor: this.bodyColor,
        dividerColor: this.dividerColor,
        valueTopGap: this.valueTopGap,
        dividerBottomGap: this.dividerBottomGap,
        itemBottomGap: this.itemBottomGap
      })
      ReviewInfoItem({
        label: '是否成立',
        value: this.judgement,
        showDivider: true,
        labelSize: this.labelSize,
        labelLineHeight: this.labelLineHeight,
        bodySize: this.bodySize,
        bodyLineHeight: this.bodyLineHeight,
        labelColor: this.labelColor,
        bodyColor: this.bodyColor,
        dividerColor: this.dividerColor,
        valueTopGap: this.valueTopGap,
        dividerBottomGap: this.dividerBottomGap,
        itemBottomGap: this.itemBottomGap
      })
      ReviewInfoItem({
        label: '卡点',
        value: this.blocker,
        showDivider: true,
        labelSize: this.labelSize,
        labelLineHeight: this.labelLineHeight,
        bodySize: this.bodySize,
        bodyLineHeight: this.bodyLineHeight,
        labelColor: this.labelColor,
        bodyColor: this.bodyColor,
        dividerColor: this.dividerColor,
        valueTopGap: this.valueTopGap,
        dividerBottomGap: this.dividerBottomGap,
        itemBottomGap: this.itemBottomGap
      })
    }
    .width('100%')
    .padding({
      top: 0,
      bottom: 0
    })
  }
}
