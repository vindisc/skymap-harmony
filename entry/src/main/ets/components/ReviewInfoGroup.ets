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
  @Prop valueTopGap: number = 7;
  @Prop dividerBottomGap: number = 16;

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
        valueTopGap: this.valueTopGap,
        dividerBottomGap: this.dividerBottomGap
      })
      ReviewInfoItem({
        label: '是否成立',
        value: this.judgement,
        showDivider: true,
        labelSize: this.labelSize,
        labelLineHeight: this.labelLineHeight,
        bodySize: this.bodySize,
        bodyLineHeight: this.bodyLineHeight,
        valueTopGap: this.valueTopGap,
        dividerBottomGap: this.dividerBottomGap
      })
      ReviewInfoItem({
        label: '卡点',
        value: this.blocker,
        showDivider: true,
        labelSize: this.labelSize,
        labelLineHeight: this.labelLineHeight,
        bodySize: this.bodySize,
        bodyLineHeight: this.bodyLineHeight,
        valueTopGap: this.valueTopGap,
        dividerBottomGap: this.dividerBottomGap
      })
    }
    .width('100%')
    .padding({
      top: 0,
      bottom: 0
    })
  }
}
