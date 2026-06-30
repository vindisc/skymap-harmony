import { AppColors, AppMetrics, AppTypography } from './AppDesign';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';
import {
  getReviewJudgementIndex,
  normalizeReviewJudgement,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { estimateReviewTextLineCount } from '../utils/ReviewTextMetrics';

const REVIEW_TEXTAREA_LINE_HEIGHT: number = AppTypography.inputTextLineHeight;
const REVIEW_TEXTAREA_VERTICAL_PADDING: number = 28;
const REVIEW_TEXTAREA_APPROX_CHARS_PER_LINE: number = 10;
const REVIEW_FIELD_LABEL_GAP: number = AppMetrics.space8;
const REVIEW_FORM_FIELD_GAP: number = AppMetrics.space16;
const PRIMARY_FIELD_LABEL_SIZE: number = AppTypography.inputLabel;
const PRIMARY_FIELD_INPUT_SIZE: number = AppTypography.inputText;
const SECONDARY_FIELD_LABEL_SIZE: number = AppTypography.inputLabel;
const SECONDARY_FIELD_INPUT_SIZE: number = AppTypography.inputText;

function resolveReviewTextAreaHeight(value: string, defaultLines: number): number {
  return estimateReviewTextLineCount(
    value,
    defaultLines,
    REVIEW_TEXTAREA_APPROX_CHARS_PER_LINE
  ) * REVIEW_TEXTAREA_LINE_HEIGHT + REVIEW_TEXTAREA_VERTICAL_PADDING;
}

@Component
export struct ReviewInputForm {
  @Link title: string;
  @Link visualFocus: string;
  @Link focusReason: string;
  @Link visualPath: string;
  @Link visibleFacts: string;
  @Link coreRelation: string;
  @Link judgement: string;
  @Link extendedUnderstanding: string;
  @Link currentBlocker: string;
  onFieldFocus: (field: string) => void = () => {};
  onFieldChange: (field: string) => void = () => {};
  onFieldBlur: () => void = () => {};
  @State focusedField: string = '';

  @Builder
  FieldLabel(label: string, labelSize: number = PRIMARY_FIELD_LABEL_SIZE) {
    Column({ space: AppMetrics.space8 }) {
      Text(label)
        .fontSize(labelSize)
        .fontWeight(600)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.inputLabelLineHeight)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  private getTextAreaHeight(value: string, defaultLines: number): number {
    return resolveReviewTextAreaHeight(value, defaultLines);
  }

  @Builder
  JudgementSelect() {
    Column({ space: REVIEW_FIELD_LABEL_GAP }) {
      this.FieldLabel('是否成立', SECONDARY_FIELD_LABEL_SIZE)
      Select([
        { value: ReviewJudgementStatus.VALID },
        { value: ReviewJudgementStatus.UNSURE },
        { value: ReviewJudgementStatus.INVALID }
      ])
        .selected(getReviewJudgementIndex(this.judgement))
        .value(normalizeReviewJudgement(this.judgement))
        .height(AppMetrics.controlHeight)
        .width('100%')
        .borderRadius(AppMetrics.inputRadius)
        .font({ size: SECONDARY_FIELD_INPUT_SIZE, weight: FontWeight.Medium })
        .fontColor(AppColors.text)
        .selectedOptionFont({ size: SECONDARY_FIELD_INPUT_SIZE, weight: FontWeight.Medium })
        .selectedOptionFontColor(AppColors.text)
        .optionFont({ size: SECONDARY_FIELD_INPUT_SIZE })
        .optionFontColor(AppColors.secondaryText)
        .backgroundColor(this.focusedField === 'judgement' ? AppColors.surface : AppColors.surfaceTint)
        .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
        .border({
          width: this.focusedField === 'judgement' ? 1.5 : 1,
          color: this.focusedField === 'judgement' ? AppColors.borderFocused : AppColors.border
        })
        .shadow(this.focusedField === 'judgement' ? ElevationTokens.focus : ElevationTokens.none)
        .animation({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate })
        .onFocus(() => {
          this.focusedField = 'judgement';
          this.onFieldFocus('judgement');
        })
        .onBlur(() => {
          this.focusedField = '';
          this.onFieldBlur();
        })
        .onSelect((index: number, value: string) => {
          this.judgement = normalizeReviewJudgement(value);
          this.onFieldChange('judgement');
        })
    }
    .width('100%')
  }

  @Builder
  ReviewField(
    label: string,
    placeholder: string,
    value: string,
    fieldKey: string,
    defaultLines: number,
    labelSize: number,
    inputSize: number,
    onChange: (value: string) => void
  ) {
    Column({ space: REVIEW_FIELD_LABEL_GAP }) {
      this.FieldLabel(label, labelSize)
      TextArea({ text: value, placeholder: placeholder })
        .height(this.getTextAreaHeight(value, defaultLines))
        .style(TextContentStyle.DEFAULT)
        .barState(BarState.Off)
        .enableKeyboardOnFocus(true)
        .borderRadius(AppMetrics.inputRadius)
        .fontSize(inputSize)
        .lineHeight(REVIEW_TEXTAREA_LINE_HEIGHT)
        .fontColor(AppColors.text)
        .placeholderColor(AppColors.placeholderText)
        .caretColor(AppColors.primary)
        .caretStyle({ width: 2, color: AppColors.primary })
        .backgroundColor(this.focusedField === fieldKey ? AppColors.surface : AppColors.surfaceTint)
        .padding({ left: AppMetrics.space16, right: AppMetrics.space16, top: 14, bottom: 14 })
        .border({
          width: this.focusedField === fieldKey ? 1.5 : 1,
          color: this.focusedField === fieldKey ? AppColors.borderFocused : AppColors.border
        })
        .shadow(this.focusedField === fieldKey ? ElevationTokens.focus : ElevationTokens.none)
        .animation({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate })
        .onFocus(() => {
          this.focusedField = fieldKey;
          this.onFieldFocus(fieldKey);
        })
        .onBlur(() => {
          this.focusedField = '';
          this.onFieldBlur();
        })
        .onChange((nextValue: string) => {
          onChange(nextValue);
          this.onFieldChange(fieldKey);
        })
    }
    .width('100%')
  }

  build() {
    Column({ space: REVIEW_FORM_FIELD_GAP }) {
      Column({ space: REVIEW_FIELD_LABEL_GAP }) {
        this.FieldLabel('标题', PRIMARY_FIELD_LABEL_SIZE)
        TextInput({ text: this.title, placeholder: '这张照片是否成立' })
          .height(AppMetrics.controlHeight)
          .enableKeyboardOnFocus(true)
          .borderRadius(AppMetrics.inputRadius)
          .fontSize(PRIMARY_FIELD_INPUT_SIZE)
          .fontColor(AppColors.text)
          .placeholderColor(AppColors.placeholderText)
          .caretColor(AppColors.primary)
          .backgroundColor(this.focusedField === 'title' ? AppColors.surface : AppColors.surfaceTint)
          .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
          .border({
            width: this.focusedField === 'title' ? 1.5 : 1,
            color: this.focusedField === 'title' ? AppColors.borderFocused : AppColors.border
          })
          .shadow(this.focusedField === 'title' ? ElevationTokens.focus : ElevationTokens.none)
          .animation({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate })
          .onFocus(() => {
            this.focusedField = 'title';
            this.onFieldFocus('title');
          })
          .onBlur(() => {
            this.focusedField = '';
            this.onFieldBlur();
          })
          .onChange((value: string) => {
            this.title = value;
            this.onFieldChange('title');
          })
      }
      .width('100%')

      this.ReviewField('视觉落点', '第一眼先看到哪里？', this.visualFocus, 'visualFocus', 2,
        PRIMARY_FIELD_LABEL_SIZE, PRIMARY_FIELD_INPUT_SIZE, (value: string) => {
        this.visualFocus = value;
      })
      this.ReviewField('落点原因', '为什么它会先被看到？', this.focusReason, 'focusReason', 2,
        PRIMARY_FIELD_LABEL_SIZE, PRIMARY_FIELD_INPUT_SIZE, (value: string) => {
        this.focusReason = value;
      })
      this.ReviewField('视线路径', '视线接着从哪里走到哪里？', this.visualPath, 'visualPath', 3,
        PRIMARY_FIELD_LABEL_SIZE, PRIMARY_FIELD_INPUT_SIZE, (value: string) => {
        this.visualPath = value;
      })
      this.ReviewField('画面事实', '画面里有哪些可见事实？', this.visibleFacts, 'visibleFacts', 3,
        PRIMARY_FIELD_LABEL_SIZE, PRIMARY_FIELD_INPUT_SIZE, (value: string) => {
        this.visibleFacts = value;
      })
      this.ReviewField('核心关系', '最重要的 A ↔ B 关系是什么？', this.coreRelation, 'coreRelation', 2,
        PRIMARY_FIELD_LABEL_SIZE, PRIMARY_FIELD_INPUT_SIZE, (value: string) => {
        this.coreRelation = value;
      })
      this.JudgementSelect()
      this.ReviewField('延伸理解', '这张照片为什么成立或不成立？', this.extendedUnderstanding, 'extendedUnderstanding', 2,
        SECONDARY_FIELD_LABEL_SIZE, SECONDARY_FIELD_INPUT_SIZE, (value: string) => {
        this.extendedUnderstanding = value;
      })
      this.ReviewField('当前卡点', '当前最大问题是什么？', this.currentBlocker, 'currentBlocker', 2,
        SECONDARY_FIELD_LABEL_SIZE, SECONDARY_FIELD_INPUT_SIZE, (value: string) => {
        this.currentBlocker = value;
      })
    }
    .width('100%')
  }
}
