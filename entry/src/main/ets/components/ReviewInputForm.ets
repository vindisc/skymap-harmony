import { AppColors } from './AppDesign';

const REVIEW_TEXTAREA_MIN_LINES: number = 2;
const REVIEW_TEXTAREA_MAX_LINES: number = 10;
const REVIEW_TEXTAREA_LINE_HEIGHT: number = 28;
const REVIEW_TEXTAREA_VERTICAL_PADDING: number = 28;
const REVIEW_TEXTAREA_MIN_HEIGHT: number = REVIEW_TEXTAREA_MIN_LINES * REVIEW_TEXTAREA_LINE_HEIGHT
  + REVIEW_TEXTAREA_VERTICAL_PADDING;
const REVIEW_TEXTAREA_MAX_HEIGHT: number = REVIEW_TEXTAREA_MAX_LINES * REVIEW_TEXTAREA_LINE_HEIGHT
  + REVIEW_TEXTAREA_VERTICAL_PADDING;
const REVIEW_TEXTAREA_APPROX_CHARS_PER_LINE: number = 14;

function estimateVisualLineCount(value: string): number {
  if (value.length === 0) {
    return REVIEW_TEXTAREA_MIN_LINES;
  }

  const rows: Array<string> = value.split('\n');
  let lines: number = 0;
  for (let index = 0; index < rows.length; index += 1) {
    const rowLength: number = rows[index].length;
    const wrappedLines: number = Math.max(1, Math.ceil(rowLength / REVIEW_TEXTAREA_APPROX_CHARS_PER_LINE));
    lines += wrappedLines;
  }

  return lines;
}

function resolveReviewTextAreaHeight(value: string): number {
  const lineCount: number = Math.min(
    REVIEW_TEXTAREA_MAX_LINES,
    Math.max(REVIEW_TEXTAREA_MIN_LINES, estimateVisualLineCount(value))
  );
  return Math.min(
    REVIEW_TEXTAREA_MAX_HEIGHT,
    Math.max(REVIEW_TEXTAREA_MIN_HEIGHT, lineCount * REVIEW_TEXTAREA_LINE_HEIGHT + REVIEW_TEXTAREA_VERTICAL_PADDING)
  );
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
  onFieldBlur: () => void = () => {};

  @Builder
  FieldLabel(label: string) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  private getTextAreaHeight(value: string): number {
    return resolveReviewTextAreaHeight(value);
  }

  @Builder
  ReviewField(label: string, placeholder: string, value: string, fieldKey: string, onChange: (value: string) => void) {
    Column({ space: 10 }) {
      this.FieldLabel(label)
      TextArea({ text: value, placeholder: placeholder })
        .height(this.getTextAreaHeight(value))
        .borderRadius(10)
        .fontSize(17)
        .lineHeight(REVIEW_TEXTAREA_LINE_HEIGHT)
        .fontColor(AppColors.text)
        .placeholderColor('#9AA1AB')
        .backgroundColor(AppColors.surfaceMuted)
        .padding({ left: 16, right: 16, top: 14, bottom: 14 })
        .border({ width: 1, color: AppColors.border })
        .onFocus(() => {
          this.onFieldFocus(fieldKey);
        })
        .onBlur(() => {
          this.onFieldBlur();
        })
        .onChange((nextValue: string) => {
          onChange(nextValue);
        })
    }
    .width('100%')
  }

  build() {
    Column({ space: 18 }) {
      Column({ space: 10 }) {
        this.FieldLabel('标题')
        TextInput({ text: this.title, placeholder: '这张照片是否成立' })
          .height(56)
          .borderRadius(10)
          .fontSize(17)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surfaceMuted)
          .padding({ left: 16, right: 16 })
          .border({ width: 1, color: AppColors.border })
          .onFocus(() => {
            this.onFieldFocus('title');
          })
          .onBlur(() => {
            this.onFieldBlur();
          })
          .onChange((value: string) => {
            this.title = value;
          })
      }
      .width('100%')

      this.ReviewField('视觉落点', '第一眼先看到哪里？', this.visualFocus, 'visualFocus', (value: string) => {
        this.visualFocus = value;
      })
      this.ReviewField('落点原因', '为什么它会先被看到？', this.focusReason, 'focusReason', (value: string) => {
        this.focusReason = value;
      })
      this.ReviewField('视线路径', '视线接着从哪里走到哪里？', this.visualPath, 'visualPath', (value: string) => {
        this.visualPath = value;
      })
      this.ReviewField('画面事实', '画面里有哪些可见事实？', this.visibleFacts, 'visibleFacts', (value: string) => {
        this.visibleFacts = value;
      })
      this.ReviewField('核心关系', '最重要的 A ↔ B 关系是什么？', this.coreRelation, 'coreRelation', (value: string) => {
        this.coreRelation = value;
      })
      this.ReviewField('是否成立', '成立、不确定或不成立？', this.judgement, 'judgement', (value: string) => {
        this.judgement = value;
      })
      this.ReviewField('延伸理解', '这张照片为什么成立或不成立？', this.extendedUnderstanding, 'extendedUnderstanding', (value: string) => {
        this.extendedUnderstanding = value;
      })
      this.ReviewField('当前卡点', '当前最大问题是什么？', this.currentBlocker, 'currentBlocker', (value: string) => {
        this.currentBlocker = value;
      })
    }
    .width('100%')
  }
}
