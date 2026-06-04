@Component
export struct ReviewInputForm {
  @Link title: string;
  @Link firstLook: string;
  @Link judgement: string;
  @Link blocker: string;

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor('#1F2329')
      .width('100%')
  }

  build() {
    Column({ space: 18 }) {
      Column({ space: 8 }) {
        this.FieldLabel('标题')
        TextInput({ text: this.title, placeholder: '这张照片是否成立' })
          .height(44)
          .borderRadius(6)
          .fontSize(16)
          .fontColor('#1F2329')
          .placeholderColor('#9AA1AB')
          .backgroundColor('#FFFFFF')
          .onChange((value: string) => {
            this.title = value;
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        this.FieldLabel('第一眼落点')
        TextArea({ text: this.firstLook, placeholder: '我第一眼看到了什么？为什么？' })
          .height(128)
          .borderRadius(6)
          .fontSize(15)
          .fontColor('#1F2329')
          .placeholderColor('#9AA1AB')
          .backgroundColor('#FFFFFF')
          .onChange((value: string) => {
            this.firstLook = value;
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        this.FieldLabel('是否成立')
        TextArea({ text: this.judgement, placeholder: '成立 / 不确定 / 不成立，并说明原因' })
          .height(128)
          .borderRadius(6)
          .fontSize(15)
          .fontColor('#1F2329')
          .placeholderColor('#9AA1AB')
          .backgroundColor('#FFFFFF')
          .onChange((value: string) => {
            this.judgement = value;
          })
      }
      .width('100%')

      Column({ space: 8 }) {
        this.FieldLabel('卡点')
        TextArea({ text: this.blocker, placeholder: '这张照片当前最大的问题是什么？' })
          .height(128)
          .borderRadius(6)
          .fontSize(15)
          .fontColor('#1F2329')
          .placeholderColor('#9AA1AB')
          .backgroundColor('#FFFFFF')
          .onChange((value: string) => {
            this.blocker = value;
          })
      }
      .width('100%')
    }
    .width('100%')
  }
}
