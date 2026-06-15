import { AppColors, AppMetrics, AppTypography, PrimaryButton, SecondaryButton } from './AppDesign';

@Component
export struct SettingsTextInput {
  @Prop label: string = '';
  @Prop text: string = '';
  @Prop placeholder: string = '';
  @Prop isPassword: boolean = false;
  onChange: (value: string) => void = () => {};
  onFocusInput: () => void = () => {};
  onBlurInput: () => void = () => {};

  build() {
    Column({ space: AppMetrics.space8 }) {
      Text(this.label)
        .fontSize(AppTypography.inputLabel)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.inputLabelLineHeight)
        .width('100%')

      TextInput({ text: this.text, placeholder: this.placeholder })
        .type(this.isPassword ? InputType.Password : InputType.Normal)
        .height(AppMetrics.controlHeight)
        .maxLines(1)
        .borderRadius(AppMetrics.cardRadius)
        .fontSize(AppTypography.inputText)
        .fontColor(AppColors.text)
        .placeholderColor(AppColors.placeholderText)
        .backgroundColor(AppColors.surfaceMuted)
        .padding({ left: AppMetrics.space16, right: this.isPassword ? AppMetrics.space32 : AppMetrics.space16 })
        .border({ width: 1, color: AppColors.border })
        .onChange((value: string) => {
          this.onChange(value);
        })
        .onFocus(() => {
          this.onFocusInput();
        })
        .onBlur(() => {
          this.onBlurInput();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}

@Component
export struct SettingsActionBar {
  @Prop primaryLabel: string = '';
  @Prop secondaryLabel: string = '';
  @Prop isPrimaryDisabled: boolean = false;
  @Prop isSecondaryDisabled: boolean = false;
  onPrimaryTap: () => void = () => {};
  onSecondaryTap: () => void = () => {};

  build() {
    Column() {
      Row({ space: AppMetrics.cardGap }) {
        if (this.secondaryLabel.length > 0) {
          SecondaryButton({
            label: this.secondaryLabel,
            isDisabled: this.isSecondaryDisabled,
            onTap: () => {
              this.onSecondaryTap();
            }
          })
            .height(AppMetrics.controlHeight)
            .layoutWeight(1)
        }

        PrimaryButton({
          label: this.primaryLabel,
          isDisabled: this.isPrimaryDisabled,
          onTap: () => {
            this.onPrimaryTap();
          }
        })
          .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
    }
    .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.cardGap, bottom: AppMetrics.cardGap })
    .width('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
