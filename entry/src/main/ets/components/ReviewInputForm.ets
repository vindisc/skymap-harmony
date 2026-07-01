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
const REVIEW_TEXTAREA_HORIZONTAL_PADDING: number = AppMetrics.space16;
const REVIEW_TEXTAREA_VERTICAL_INSET: number = 14;

function resolveReviewTextAreaHeight(value: string, defaultLines: number): number {
  return estimateReviewTextLineCount(
    value,
    defaultLines,
    REVIEW_TEXTAREA_APPROX_CHARS_PER_LINE
  ) * REVIEW_TEXTAREA_LINE_HEIGHT + REVIEW_TEXTAREA_VERTICAL_PADDING;
}

@Component
struct ReviewTextAreaField {
  @Link value: string;
  @Prop label: string = '';
  @Prop placeholder: string = '';
  @Prop fieldKey: string = '';
  @Prop defaultLines: number = 2;
  @Prop labelSize: number = PRIMARY_FIELD_LABEL_SIZE;
  @Prop inputSize: number = PRIMARY_FIELD_INPUT_SIZE;
  @Prop isFocused: boolean = false;
  onFocusField: () => void = () => {};
  onBlurField: () => void = () => {};
  onFieldChange: () => void = () => {};

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

  build() {
    Column({ space: REVIEW_FIELD_LABEL_GAP }) {
      this.FieldLabel(this.label, this.labelSize)
      TextArea({ text: $$this.value, placeholder: this.placeholder })
        .height(resolveReviewTextAreaHeight(this.value, this.defaultLines))
        .style(TextContentStyle.DEFAULT)
        .barState(BarState.Off)
        .enableKeyboardOnFocus(true)
        .borderRadius(AppMetrics.inputRadius)
        .fontSize(this.inputSize)
        .lineHeight(REVIEW_TEXTAREA_LINE_HEIGHT)
        .fontColor(AppColors.text)
        .placeholderColor(AppColors.placeholderText)
        .caretColor(AppColors.primary)
        .caretStyle({ width: 2, color: AppColors.primary })
        .backgroundColor(this.isFocused ? AppColors.surface : AppColors.surfaceTint)
        .padding({
          left: REVIEW_TEXTAREA_HORIZONTAL_PADDING,
          right: REVIEW_TEXTAREA_HORIZONTAL_PADDING,
          top: REVIEW_TEXTAREA_VERTICAL_INSET,
          bottom: REVIEW_TEXTAREA_VERTICAL_INSET
        })
        .border({
          width: this.isFocused ? 1.5 : 1,
          color: this.isFocused ? AppColors.borderFocused : AppColors.border
        })
        .shadow(this.isFocused ? ElevationTokens.focus : ElevationTokens.none)
        .onFocus(() => {
          animateTo({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate }, () => {
            this.onFocusField();
          });
        })
        .onBlur(() => {
          animateTo({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate }, () => {
            this.onBlurField();
          });
        })
        .onChange((nextValue: string) => {
          this.value = nextValue;
          this.onFieldChange();
        })
    }
    .width('100%')
  }
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
          .onFocus(() => {
            animateTo({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate }, () => {
              this.focusedField = 'title';
              this.onFieldFocus('title');
            });
          })
          .onBlur(() => {
            animateTo({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate }, () => {
              this.focusedField = '';
              this.onFieldBlur();
            });
          })
          .onChange((value: string) => {
            this.title = value;
            this.onFieldChange('title');
          })
      }
      .width('100%')

      ReviewTextAreaField({
        value: $visualFocus,
        label: '视觉落点',
        placeholder: '第一眼先看到哪里？',
        fieldKey: 'visualFocus',
        defaultLines: 2,
        labelSize: PRIMARY_FIELD_LABEL_SIZE,
        inputSize: PRIMARY_FIELD_INPUT_SIZE,
        isFocused: this.focusedField === 'visualFocus',
        onFocusField: () => {
          this.focusedField = 'visualFocus';
          this.onFieldFocus('visualFocus');
        },
        onBlurField: () => {
          this.focusedField = '';
          this.onFieldBlur();
        },
        onFieldChange: () => {
          this.onFieldChange('visualFocus');
        }
      })
      ReviewTextAreaField({
        value: $focusReason,
        label: '落点原因',
        placeholder: '为什么它会先被看到？',
        fieldKey: 'focusReason',
        defaultLines: 2,
        labelSize: PRIMARY_FIELD_LABEL_SIZE,
        inputSize: PRIMARY_FIELD_INPUT_SIZE,
        isFocused: this.focusedField === 'focusReason',
        onFocusField: () => {
          this.focusedField = 'focusReason';
          this.onFieldFocus('focusReason');
        },
        onBlurField: () => {
          this.focusedField = '';
          this.onFieldBlur();
        },
        onFieldChange: () => {
          this.onFieldChange('focusReason');
        }
      })
      ReviewTextAreaField({
        value: $visualPath,
        label: '视线路径',
        placeholder: '视线接着从哪里走到哪里？',
        fieldKey: 'visualPath',
        defaultLines: 3,
        labelSize: PRIMARY_FIELD_LABEL_SIZE,
        inputSize: PRIMARY_FIELD_INPUT_SIZE,
        isFocused: this.focusedField === 'visualPath',
        onFocusField: () => {
          this.focusedField = 'visualPath';
          this.onFieldFocus('visualPath');
        },
        onBlurField: () => {
          this.focusedField = '';
          this.onFieldBlur();
        },
        onFieldChange: () => {
          this.onFieldChange('visualPath');
        }
      })
      ReviewTextAreaField({
        value: $visibleFacts,
        label: '画面事实',
        placeholder: '画面里有哪些可见事实？',
        fieldKey: 'visibleFacts',
        defaultLines: 3,
        labelSize: PRIMARY_FIELD_LABEL_SIZE,
        inputSize: PRIMARY_FIELD_INPUT_SIZE,
        isFocused: this.focusedField === 'visibleFacts',
        onFocusField: () => {
          this.focusedField = 'visibleFacts';
          this.onFieldFocus('visibleFacts');
        },
        onBlurField: () => {
          this.focusedField = '';
          this.onFieldBlur();
        },
        onFieldChange: () => {
          this.onFieldChange('visibleFacts');
        }
      })
      ReviewTextAreaField({
        value: $coreRelation,
        label: '核心关系',
        placeholder: '最重要的 A ↔ B 关系是什么？',
        fieldKey: 'coreRelation',
        defaultLines: 2,
        labelSize: PRIMARY_FIELD_LABEL_SIZE,
        inputSize: PRIMARY_FIELD_INPUT_SIZE,
        isFocused: this.focusedField === 'coreRelation',
        onFocusField: () => {
          this.focusedField = 'coreRelation';
          this.onFieldFocus('coreRelation');
        },
        onBlurField: () => {
          this.focusedField = '';
          this.onFieldBlur();
        },
        onFieldChange: () => {
          this.onFieldChange('coreRelation');
        }
      })
      this.JudgementSelect()
      ReviewTextAreaField({
        value: $extendedUnderstanding,
        label: '延伸理解',
        placeholder: '这张照片为什么成立或不成立？',
        fieldKey: 'extendedUnderstanding',
        defaultLines: 2,
        labelSize: SECONDARY_FIELD_LABEL_SIZE,
        inputSize: SECONDARY_FIELD_INPUT_SIZE,
        isFocused: this.focusedField === 'extendedUnderstanding',
        onFocusField: () => {
          this.focusedField = 'extendedUnderstanding';
          this.onFieldFocus('extendedUnderstanding');
        },
        onBlurField: () => {
          this.focusedField = '';
          this.onFieldBlur();
        },
        onFieldChange: () => {
          this.onFieldChange('extendedUnderstanding');
        }
      })
      ReviewTextAreaField({
        value: $currentBlocker,
        label: '当前卡点',
        placeholder: '当前最大问题是什么？',
        fieldKey: 'currentBlocker',
        defaultLines: 2,
        labelSize: SECONDARY_FIELD_LABEL_SIZE,
        inputSize: SECONDARY_FIELD_INPUT_SIZE,
        isFocused: this.focusedField === 'currentBlocker',
        onFocusField: () => {
          this.focusedField = 'currentBlocker';
          this.onFieldFocus('currentBlocker');
        },
        onBlurField: () => {
          this.focusedField = '';
          this.onFieldBlur();
        },
        onFieldChange: () => {
          this.onFieldChange('currentBlocker');
        }
      })
    }
    .width('100%')
  }
}
