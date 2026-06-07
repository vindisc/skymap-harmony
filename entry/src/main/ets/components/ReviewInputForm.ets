import { AppColors } from './AppDesign';

const REVIEW_TEXTAREA_MIN_LINES: number = 3;
const REVIEW_TEXTAREA_MAX_LINES: number = 8;
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
  @Link firstLook: string;
  @Link reason: string;
  @Link visualPath: string;
  @Link strongestRelation: string;
  @Link judgement: string;
  @Link blocker: string;
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
    Column({ space: 22 }) {
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

      this.ReviewField('第一眼落点', '我第一眼看到了什么？', this.firstLook, 'firstLook', (value: string) => {
        this.firstLook = value;
      })
      this.ReviewField('原因', '为什么它会先进入视线？', this.reason, 'reason', (value: string) => {
        this.reason = value;
      })
      this.ReviewField('视线路径', '视线接着从哪里走到哪里？', this.visualPath, 'visualPath', (value: string) => {
        this.visualPath = value;
      })
      this.ReviewField('最强关系', '画面里最强的 A ↔ B 关系是什么？', this.strongestRelation, 'strongestRelation', (value: string) => {
        this.strongestRelation = value;
      })
      this.ReviewField('是否成立', '成立 / 不确定 / 不成立，并说明原因', this.judgement, 'judgement', (value: string) => {
        this.judgement = value;
      })
      this.ReviewField('卡点', '这张照片当前最大的问题是什么？', this.blocker, 'blocker', (value: string) => {
        this.blocker = value;
      })
    }
    .width('100%')
  }
}
