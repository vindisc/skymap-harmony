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

      Column({ space: 10 }) {
        this.FieldLabel('第一眼落点')
        TextArea({ text: this.firstLook, placeholder: '我第一眼看到了什么？为什么？' })
          .height(190)
          .borderRadius(10)
          .fontSize(17)
          .lineHeight(28)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surfaceMuted)
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
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

      Column({ space: 10 }) {
        this.FieldLabel('是否成立')
        TextArea({ text: this.judgement, placeholder: '成立 / 不确定 / 不成立，并说明原因' })
          .height(190)
          .borderRadius(10)
          .fontSize(17)
          .lineHeight(28)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surfaceMuted)
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
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

      Column({ space: 10 }) {
        this.FieldLabel('卡点')
        TextArea({ text: this.blocker, placeholder: '这张照片当前最大的问题是什么？' })
          .height(240)
          .borderRadius(10)
          .fontSize(17)
          .lineHeight(28)
          .fontColor(AppColors.text)
          .placeholderColor('#9AA1AB')
          .backgroundColor(AppColors.surfaceMuted)
          .padding({ left: 16, right: 16, top: 14, bottom: 14 })
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
