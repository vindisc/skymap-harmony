import { AppColors, AppMetrics, AppTypography } from './AppDesign';

@Component
export struct ColorSwatchRow {
  @Prop colors: Array<string> = [];
  @Prop currentColor: string = '#FFFFFF';
  @Prop disabled: boolean = false;
  onChange: (color: string) => void = () => {};

  build() {
    Row({ space: AppMetrics.space12 }) {
      Text('背景色')
        .fontFamily('NotoSansSC-Regular')
        .fontSize(AppTypography.inputLabel)
        .fontColor(this.disabled ? AppColors.placeholderText : AppColors.secondaryText)
        .layoutWeight(1)

      ForEach(this.colors, (color: string) => {
        Stack({ alignContent: Alignment.Center }) {
          Column()
            .width(28)
            .height(28)
            .borderRadius(14)
            .backgroundColor(color)
            .border({ width: 1, color: AppColors.border })

          if (this.currentColor.toUpperCase() === color.toUpperCase()) {
            Text('✓')
              .fontFamily('NotoSansSC-Bold')
              .fontSize(AppTypography.meta)
              .fontWeight(FontWeight.Bold)
              .fontColor(color.toUpperCase() === '#FFFFFF' ? AppColors.text : AppColors.primary)
          }
        }
        .width(40)
        .height(40)
        .opacity(this.disabled ? 0.4 : 1)
        .onClick(() => {
          if (!this.disabled) {
            this.onChange(color);
          }
        })
      }, (color: string) => color)
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
  }
}
