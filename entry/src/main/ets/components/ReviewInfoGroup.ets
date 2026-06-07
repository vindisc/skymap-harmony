import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewInfoItem } from './ReviewInfoItem';

@Component
export struct ReviewInfoGroup {
  @Prop firstLook: string = '';
  @Prop reason: string = '';
  @Prop visualPath: string = '';
  @Prop strongestRelation: string = '';
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

  private hasValue(value: string): boolean {
    return value.trim().length > 0;
  }

  build() {
    Column() {
      if (this.hasValue(this.firstLook)) {
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
      }
      if (this.hasValue(this.reason)) {
        ReviewInfoItem({
          label: '原因',
          value: this.reason,
          showDivider: this.hasValue(this.firstLook),
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
      if (this.hasValue(this.visualPath)) {
        ReviewInfoItem({
          label: '视线路径',
          value: this.visualPath,
          showDivider: this.hasValue(this.firstLook) || this.hasValue(this.reason),
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
      if (this.hasValue(this.strongestRelation)) {
        ReviewInfoItem({
          label: '最强关系',
          value: this.strongestRelation,
          showDivider: this.hasValue(this.firstLook) || this.hasValue(this.reason) || this.hasValue(this.visualPath),
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
      if (this.hasValue(this.judgement)) {
        ReviewInfoItem({
          label: '是否成立',
          value: this.judgement,
          showDivider: this.hasValue(this.firstLook)
            || this.hasValue(this.reason)
            || this.hasValue(this.visualPath)
            || this.hasValue(this.strongestRelation),
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
      if (this.hasValue(this.blocker)) {
        ReviewInfoItem({
          label: '卡点',
          value: this.blocker,
          showDivider: this.hasValue(this.firstLook)
            || this.hasValue(this.reason)
            || this.hasValue(this.visualPath)
            || this.hasValue(this.strongestRelation)
            || this.hasValue(this.judgement),
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
    }
    .width('100%')
    .padding({
      top: 0,
      bottom: 0
    })
  }
}
