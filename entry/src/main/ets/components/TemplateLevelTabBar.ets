import { TemplateLevel } from '../model/TemplateModel';
import { MotionTokens } from '../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../theme/MotionQualityContext';
import { AppColors, AppMetrics, AppTypography } from './AppDesign';

interface TemplateLevelTabItem {
  level: TemplateLevel;
  label: string;
  disabled: boolean;
}

const TEMPLATE_LEVEL_TAB_ITEMS: Array<TemplateLevelTabItem> = [
  { level: TemplateLevel.L0_FRAME, label: '相框', disabled: false },
  { level: TemplateLevel.L1_META, label: '参数', disabled: false },
  { level: TemplateLevel.L2_NOTE, label: '一句话', disabled: true },
  { level: TemplateLevel.L3_REVIEW, label: '复盘', disabled: false }
];

@Component
export struct TemplateLevelTabBar {
  @Prop currentLevel: TemplateLevel = TemplateLevel.L3_REVIEW;
  onLevelTap: (level: TemplateLevel) => void = () => {};

  build() {
    Row() {
      ForEach(TEMPLATE_LEVEL_TAB_ITEMS, (item: TemplateLevelTabItem) => {
        Column({ space: AppMetrics.space8 }) {
          Text(item.label)
            .fontFamily(this.currentLevel === item.level ? 'NotoSansSC-Bold' : 'NotoSansSC-Regular')
            .fontSize(AppTypography.tabLabel)
            .fontWeight(this.currentLevel === item.level ? FontWeight.Bold : FontWeight.Regular)
            .fontColor(item.disabled
              ? AppColors.placeholderText
              : (this.currentLevel === item.level ? AppColors.primary : AppColors.secondaryText))
            .animation({
              duration: MotionQualityContext.resolveDuration(MotionTokens.durationQuick),
              curve: MotionQualityContext.resolveCurve(MotionCurveRole.EMPHASIZED)
            })

          Column()
            .width(this.currentLevel === item.level ? 28 : 8)
            .height(2)
            .borderRadius(1)
            .backgroundColor(this.currentLevel === item.level ? AppColors.primary : AppColors.transparent)
            .animation({
              duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
              curve: MotionQualityContext.resolveCurve(MotionCurveRole.EMPHASIZED)
            })
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .height(44)
        .opacity(item.disabled ? 0.45 : 1)
        .onClick(() => {
          if (!item.disabled) {
            this.onLevelTap(item.level);
          }
        })
      }, (item: TemplateLevelTabItem) => item.level)
    }
    .width('100%')
    .height(44)
  }
}
