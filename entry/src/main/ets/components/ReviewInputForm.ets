@Component
export struct ReviewInputForm {
  @Link title: string;
  @Link firstLook: string;
  @Link judgement: string;
  @Link blocker: string;
  onFieldFocus: (field: string) => void = () => {};

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor('#1F2329')
      .width('100%')
  }

  @Builder
  FieldHint(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#8A919F')
      .lineHeight(18)
      .width('100%')
  }

  build() {
    Column({ space: 22 }) {
      Column({ space: 9 }) {
        this.FieldLabel('标题')
        TextInput({ text: this.title, placeholder: '这张照片是否成立' })
          .height(48)
          .borderRadius(8)
          .fontSize(16)
          .fontColor('#1F2329')
          .placeholderColor('#9AA1AB')
          .backgroundColor('#FFFFFF')
          .padding({ left: 14, right: 14 })
          .border({ width: 1, color: '#E6E9ED' })
          .onFocus(() => {
            this.onFieldFocus('title');
          })
          .onChange((value: string) => {
            this.title = value;
          })
      }
      .width('100%')

      Column({ space: 9 }) {
        this.FieldLabel('第一眼落点')
        TextArea({ text: this.firstLook, placeholder: '我第一眼看到了什么？为什么？' })
          .height(158)
          .borderRadius(8)
          .fontSize(16)
          .lineHeight(24)
          .fontColor('#1F2329')
          .placeholderColor('#9AA1AB')
          .backgroundColor('#FFFFFF')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .border({ width: 1, color: '#E6E9ED' })
          .onFocus(() => {
            this.onFieldFocus('firstLook');
          })
          .onChange((value: string) => {
            this.firstLook = value;
          })
        this.FieldHint('记录最先进入视线的主体、光线或关系。')
      }
      .width('100%')

      Column({ space: 9 }) {
        this.FieldLabel('是否成立')
        TextArea({ text: this.judgement, placeholder: '成立 / 不确定 / 不成立，并说明原因' })
          .height(150)
          .borderRadius(8)
          .fontSize(16)
          .lineHeight(24)
          .fontColor('#1F2329')
          .placeholderColor('#9AA1AB')
          .backgroundColor('#FFFFFF')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .border({ width: 1, color: '#E6E9ED' })
          .onFocus(() => {
            this.onFieldFocus('judgement');
          })
          .onChange((value: string) => {
            this.judgement = value;
          })
        this.FieldHint('用一句判断开头，再补充画面为什么有效或失效。')
      }
      .width('100%')

      Column({ space: 9 }) {
        this.FieldLabel('卡点')
        TextArea({ text: this.blocker, placeholder: '这张照片当前最大的问题是什么？' })
          .height(190)
          .borderRadius(8)
          .fontSize(16)
          .lineHeight(24)
          .fontColor('#1F2329')
          .placeholderColor('#9AA1AB')
          .backgroundColor('#FFFFFF')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .border({ width: 1, color: '#E6E9ED' })
          .onFocus(() => {
            this.onFieldFocus('blocker');
          })
          .onChange((value: string) => {
            this.blocker = value;
          })
        this.FieldHint('这里可以写得更完整，预览卡会自动处理长内容。')
      }
      .width('100%')
    }
    .width('100%')
  }
}
