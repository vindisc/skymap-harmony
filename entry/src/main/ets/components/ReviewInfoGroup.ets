import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewInfoItem } from './ReviewInfoItem';

@Component
export struct ReviewInfoGroup {
  @Prop visualFocus: string = '';
  @Prop focusReason: string = '';
  @Prop visualPath: string = '';
  @Prop visibleFacts: string = '';
  @Prop coreRelation: string = '';
  @Prop extendedUnderstanding: string = '';
  @Prop currentBlocker: string = '';
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
      if (this.hasValue(this.visualFocus)) {
        ReviewInfoItem({
          label: '视觉落点',
          value: this.visualFocus,
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
      if (this.hasValue(this.focusReason)) {
        ReviewInfoItem({
          label: '落点原因',
          value: this.focusReason,
          showDivider: this.hasValue(this.visualFocus),
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
          showDivider: this.hasValue(this.visualFocus) || this.hasValue(this.focusReason),
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
      if (this.hasValue(this.visibleFacts)) {
        ReviewInfoItem({
          label: '画面事实',
          value: this.visibleFacts,
          showDivider: this.hasValue(this.visualFocus) || this.hasValue(this.focusReason) || this.hasValue(this.visualPath),
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
      if (this.hasValue(this.coreRelation)) {
        ReviewInfoItem({
          label: '核心关系',
          value: this.coreRelation,
          showDivider: this.hasValue(this.visualFocus)
            || this.hasValue(this.focusReason)
            || this.hasValue(this.visualPath)
            || this.hasValue(this.visibleFacts),
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
      if (this.hasValue(this.extendedUnderstanding)) {
        ReviewInfoItem({
          label: '延伸理解',
          value: this.extendedUnderstanding,
          showDivider: this.hasValue(this.visualFocus)
            || this.hasValue(this.focusReason)
            || this.hasValue(this.visualPath)
            || this.hasValue(this.visibleFacts)
            || this.hasValue(this.coreRelation),
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
      if (this.hasValue(this.currentBlocker)) {
        ReviewInfoItem({
          label: '当前卡点',
          value: this.currentBlocker,
          showDivider: this.hasValue(this.visualFocus)
            || this.hasValue(this.focusReason)
            || this.hasValue(this.visualPath)
            || this.hasValue(this.visibleFacts)
            || this.hasValue(this.coreRelation)
            || this.hasValue(this.extendedUnderstanding),
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
