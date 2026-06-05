import { AppColors } from './AppDesign';

@Component
export struct ReviewInputForm {
  @Link title: string;
  @Link firstLook: string;
  @Link judgement: string;
  @Link blocker: string;
  onFieldFocus: (field: string) => void = () => {};
  onFieldBlur: () => void = () => {};

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .width('100%')
  }

  build() {
    Column({ space: 18 }) {
      Column({ space: 9 }) {
        this.FieldLabel('标题')
        TextInput({ text: this.title, placeholder: '这张照片是否成立' })
          .height(50)
          .borderRadius(8)
          .fontSize(16)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surface)
          .padding({ left: 14, right: 14 })
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

      Column({ space: 9 }) {
        this.FieldLabel('第一眼落点')
        TextArea({ text: this.firstLook, placeholder: '我第一眼看到了什么？为什么？' })
          .height(150)
          .borderRadius(8)
          .fontSize(16)
          .lineHeight(24)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surface)
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .border({ width: 1, color: AppColors.border })
          .onFocus(() => {
            this.onFieldFocus('firstLook');
          })
          .onBlur(() => {
            this.onFieldBlur();
          })
          .onChange((value: string) => {
            this.firstLook = value;
          })
      }
      .width('100%')

      Column({ space: 9 }) {
        this.FieldLabel('是否成立')
        TextArea({ text: this.judgement, placeholder: '成立 / 不确定 / 不成立，并说明原因' })
          .height(150)
          .borderRadius(8)
          .fontSize(16)
          .lineHeight(24)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surface)
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .border({ width: 1, color: AppColors.border })
          .onFocus(() => {
            this.onFieldFocus('judgement');
          })
          .onBlur(() => {
            this.onFieldBlur();
          })
          .onChange((value: string) => {
            this.judgement = value;
          })
      }
      .width('100%')

      Column({ space: 9 }) {
        this.FieldLabel('卡点')
        TextArea({ text: this.blocker, placeholder: '这张照片当前最大的问题是什么？' })
          .height(210)
          .borderRadius(8)
          .fontSize(16)
          .lineHeight(24)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surface)
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .border({ width: 1, color: AppColors.border })
          .onFocus(() => {
            this.onFieldFocus('blocker');
          })
          .onBlur(() => {
            this.onFieldBlur();
          })
          .onChange((value: string) => {
            this.blocker = value;
          })
      }
      .width('100%')
    }
    .width('100%')
  }
}
