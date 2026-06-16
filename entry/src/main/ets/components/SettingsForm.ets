import { AppColors, AppMetrics, AppTypography, PrimaryButton, SecondaryButton } from './AppDesign';

@Component
export struct SettingsTextInput {
  @Prop label: string = '';
  @Prop text: string = '';
  @Prop placeholder: string = '';
  @Prop isPassword: boolean = false;
  @Prop showsPasswordToggle: boolean = false;
  @Prop inputType: InputType = InputType.Normal;
  @State isPasswordVisible: boolean = false;
  onChange: (value: string) => void = () => {};
  onFocusInput: () => void = () => {};
  onBlurInput: () => void = () => {};

  private resolveInputType(): InputType {
    if (this.isPassword && !this.isPasswordVisible) {
      return InputType.Password;
    }
    return this.inputType;
  }

  build() {
    Column({ space: AppMetrics.space8 }) {
      Text(this.label)
        .fontSize(AppTypography.inputLabel)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.inputLabelLineHeight)
        .width('100%')

      Row({ space: AppMetrics.space8 }) {
        TextInput({ text: this.text, placeholder: this.placeholder })
          .type(this.resolveInputType())
          .height(AppMetrics.controlHeight)
          .maxLines(1)
          .borderRadius(AppMetrics.cardRadius)
          .fontSize(AppTypography.inputText)
          .fontColor(AppColors.text)
          .placeholderColor(AppColors.placeholderText)
          .backgroundColor(AppColors.surfaceMuted)
          .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
          .border({ width: 1, color: AppColors.border })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.onChange(value);
          })
          .onFocus(() => {
            this.onFocusInput();
          })
          .onBlur(() => {
            this.onBlurInput();
          })

        if (this.showsPasswordToggle) {
          Button(this.isPasswordVisible ? '隐藏' : '显示')
            .height(AppMetrics.controlHeight)
            .width(58)
            .borderRadius(AppMetrics.buttonRadius)
            .fontSize(AppTypography.smallButtonText)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .backgroundColor(AppColors.surfaceMuted)
            .border({ width: 1, color: AppColors.border })
            .stateEffect(true)
            .onClick(() => {
              this.isPasswordVisible = !this.isPasswordVisible;
            })
        }
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
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
