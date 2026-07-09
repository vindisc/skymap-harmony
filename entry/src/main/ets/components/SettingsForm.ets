import { AppColors, AppMetrics, AppTypography, PrimaryButton, SecondaryButton } from './AppDesign';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';

@Component
export struct SettingsTextInput {
  @Prop label: string = '';
  @Prop text: string = '';
  @Prop placeholder: string = '';
  @Prop isPassword: boolean = false;
  @Prop showsPasswordToggle: boolean = false;
  @Prop inputType: InputType = InputType.Normal;
  @State isFocused: boolean = false;
  onChange: (value: string) => void = () => {};
  onFocusInput: () => void = () => {};
  onBlurInput: () => void = () => {};

  private resolveInputType(): InputType {
    if (this.isPassword) {
      return InputType.Password;
    }
    return this.inputType;
  }

  build() {
    Column({ space: AppMetrics.space8 }) {
      Text(this.label)
        .fontSize(AppTypography.inputLabel)
        .fontWeight(600)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.inputLabelLineHeight)
        .width('100%')

      Row({ space: AppMetrics.space8 }) {
        TextInput({ text: this.text, placeholder: this.placeholder })
          .type(this.resolveInputType())
          .showPasswordIcon(this.showsPasswordToggle)
          .height(AppMetrics.controlHeight)
          .maxLines(1)
          .borderRadius(AppMetrics.buttonRadius)
          .fontSize(AppTypography.inputText)
          .fontColor(AppColors.text)
          .placeholderColor(AppColors.placeholderText)
          .backgroundColor(AppColors.transparent)
          .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.onChange(value);
          })
          .onFocus(() => {
            this.getUIContext().animateTo({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate }, () => {
              this.isFocused = true;
              this.onFocusInput();
            });
          })
          .onBlur(() => {
            this.getUIContext().animateTo({ duration: MotionTokens.durationQuick, curve: MotionTokens.curveDecelerate }, () => {
              this.isFocused = false;
              this.onBlurInput();
            });
          })
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .height(AppMetrics.controlHeight)
      .borderRadius(AppMetrics.inputRadius)
      .backgroundColor(this.isFocused ? AppColors.surface : AppColors.surfaceTint)
      .border({
        width: this.isFocused ? 1.5 : 1,
        color: this.isFocused ? AppColors.borderFocused : AppColors.border
      })
      .shadow(this.isFocused ? ElevationTokens.focus : ElevationTokens.none)
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
    .padding({
      left: AppMetrics.pagePadding,
      right: AppMetrics.pagePadding,
      top: AppMetrics.floatingDockTopMaskHeight,
      bottom: AppMetrics.floatingDockBottomPadding
    })
    .width('100%')
    .hitTestBehavior(HitTestMode.Transparent)
  }
}
