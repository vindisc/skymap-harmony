import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import { KeyboardAvoidMode } from '@ohos.arkui.UIContext';
import { HOME_STORAGE_PAGE } from '../app/AppRouter';
import { AppBottomSafeAreaFill, AppColors, AppMetrics, AppTypography } from '../components/AppDesign';
import { SettingsActionBar, SettingsTextInput } from '../components/SettingsForm';
import { ReviewSettingsService } from '../services/ReviewSettingsService';
import { ToastService } from '../services/ToastService';

const SETTINGS_INPUT_SCROLL_DELAY: number = 220;
const SETTINGS_INPUT_BLOCK_HEIGHT: number = 78;
const SETTINGS_INPUT_SAFE_TOP_GAP: number = 36;
const SETTINGS_KEYBOARD_BOTTOM_PADDING: number = AppMetrics.systemNavigationBarHeight + AppMetrics.space8;

@Entry
@Component
struct ReviewSettingsPage {
  private settingsScroller: Scroller = new Scroller();
  private hostWindow: window.Window | null = null;
  private keyboardHeightChangeCallback: ((height: number) => void) | null = null;
  private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;
  private scrollRequestId: number = 0;
  private isPageAlive: boolean = false;
  private loadRequestId: number = 0;
  @State reviewerName: string = '';
  @State isSettingsLoaded: boolean = false;
  @State isSaving: boolean = false;
  @State keyboardHeight: number = 0;
  @State focusedInputIndex: number = -1;

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.isPageAlive = true;
    this.disableSystemKeyboardAvoidance();
    this.registerKeyboardHeightObserver();
    this.loadSettings();
  }

  onPageShow(): void {
    this.loadSettings();
  }

  aboutToDisappear(): void {
    this.isPageAlive = false;
    this.unregisterKeyboardHeightObserver();
    this.restoreSystemKeyboardAvoidance();
  }

  private disableSystemKeyboardAvoidance(): void {
    try {
      this.previousKeyboardAvoidMode = this.getUIContext().getKeyboardAvoidMode();
      this.getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
    } catch (error) {
      this.previousKeyboardAvoidMode = KeyboardAvoidMode.OFFSET;
    }
  }

  private restoreSystemKeyboardAvoidance(): void {
    try {
      this.getUIContext().setKeyboardAvoidMode(this.previousKeyboardAvoidMode);
    } catch (error) {
    }
  }

  private registerKeyboardHeightObserver(): void {
    this.keyboardHeightChangeCallback = (height: number): void => {
      this.keyboardHeight = Math.max(0, this.getUIContext().px2vp(height));
      if (this.keyboardHeight > 0 && this.focusedInputIndex >= 0) {
        this.scheduleInputIntoView(this.focusedInputIndex);
      }
    };

    window.getLastWindow(this.getAbilityContext()).then((targetWindow: window.Window) => {
      if (!this.isPageAlive || this.keyboardHeightChangeCallback === null) {
        return;
      }

      this.hostWindow = targetWindow;
      targetWindow.on('keyboardHeightChange', this.keyboardHeightChangeCallback);
    });
  }

  private unregisterKeyboardHeightObserver(): void {
    if (this.hostWindow === null || this.keyboardHeightChangeCallback === null) {
      return;
    }

    try {
      this.hostWindow.off('keyboardHeightChange', this.keyboardHeightChangeCallback);
    } catch (error) {
    }

    this.hostWindow = null;
    this.keyboardHeightChangeCallback = null;
  }

  private async loadSettings(): Promise<void> {
    const requestId = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    this.isSettingsLoaded = false;
    const reviewerName = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.reviewerName = reviewerName;
    this.isSettingsLoaded = true;
  }

  private async saveSettings(): Promise<void> {
    if (this.isSaving || !this.isSettingsLoaded) {
      return;
    }

    this.isSaving = true;
    try {
      this.reviewerName = await ReviewSettingsService.saveReviewerName(this.getAbilityContext(), this.reviewerName);
      ToastService.show(this.getUIContext(), '已保存复盘人');
    } catch (error) {
      ToastService.show(this.getUIContext(), '保存失败，请稍后重试');
    } finally {
      this.isSaving = false;
    }
  }

  private openHomeStorageSettings(): void {
    this.getUIContext().getRouter().pushUrl({ url: HOME_STORAGE_PAGE }).catch((error: Error) => {
      console.error(`[ReviewSettingsPage] 打开家庭存储设置失败：${error.message}`);
    });
  }

  private isKeyboardActive(): boolean {
    return this.keyboardHeight > 0;
  }

  private getSettingsBottomPadding(): number {
    if (this.isKeyboardActive()) {
      return this.keyboardHeight + SETTINGS_KEYBOARD_BOTTOM_PADDING;
    }

    return AppMetrics.floatingDockReservedHeight + AppMetrics.floatingDockScrollClearance;
  }

  private focusInput(index: number): void {
    this.focusedInputIndex = index;
    this.scheduleInputIntoView(index);
  }

  private scheduleInputIntoView(index: number): void {
    this.scrollRequestId += 1;
    const requestId: number = this.scrollRequestId;
    setTimeout(() => {
      if (requestId !== this.scrollRequestId || this.focusedInputIndex !== index) {
        return;
      }

      this.settingsScroller.scrollTo({
        xOffset: 0,
        yOffset: Math.max(0, index * SETTINGS_INPUT_BLOCK_HEIGHT - SETTINGS_INPUT_SAFE_TOP_GAP),
        animation: {
          duration: 240,
          curve: Curve.EaseOut
        }
      });
    }, SETTINGS_INPUT_SCROLL_DELAY);
  }

  @Builder
  Header() {
    Row() {
      Blank()

      Text('设置')
        .fontSize(AppTypography.pageTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.pageTitleLineHeight)

      Blank()
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height(AppTypography.pageTitleLineHeight)
  }

  @Builder
  LoadingSettings() {
    Column({ space: AppMetrics.space8 }) {
      Text('正在读取设置')
        .fontSize(AppTypography.body)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.bodyLineHeight)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  SettingsInput(
    label: string,
    text: string,
    placeholder: string,
    onChange: (value: string) => void,
    isPassword: boolean = false,
    inputIndex: number = -1
  ) {
    SettingsTextInput({
      label: label,
      text: text,
      placeholder: placeholder,
      isPassword: isPassword,
      onChange: onChange,
      onFocusInput: () => {
        if (inputIndex >= 0) {
          this.focusInput(inputIndex);
        }
      },
      onBlurInput: () => {
        if (this.focusedInputIndex === inputIndex) {
          this.focusedInputIndex = -1;
        }
      }
    })
  }

  @Builder
  ActionBar() {
    SettingsActionBar({
      primaryLabel: this.isSaving ? '保存中...' : '保存',
      isPrimaryDisabled: this.isSaving || !this.isSettingsLoaded,
      onPrimaryTap: () => {
        this.saveSettings();
      }
    })
  }

  @Builder
  HomeStorageLink() {
    Row({ space: AppMetrics.cardGap }) {
      Column({ space: AppMetrics.space8 }) {
        Text('家庭存储')
          .fontSize(AppTypography.cardTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.cardTitleLineHeight)
          .width('100%')

        Text('连接与凭据')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(AppTypography.cardTitle)
        .fontColor(AppColors.mutedText)
        .opacity(0.56)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .constraintSize({ minHeight: 68, maxHeight: 76 })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
    .onClick(() => {
      this.openHomeStorageSettings();
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AppBottomSafeAreaFill()

      Column() {
        this.Header()

        Scroll(this.settingsScroller) {
          Column({ space: AppMetrics.sectionGap }) {
            if (this.isSettingsLoaded) {
              this.SettingsInput('复盘人', this.reviewerName, '可留空', (value: string) => {
                this.reviewerName = value;
              }, false, 0)
            } else {
              this.LoadingSettings()
            }

            this.HomeStorageLink()
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: AppMetrics.space32, bottom: this.getSettingsBottomPadding() })
        }
        .edgeEffect(EdgeEffect.Spring)
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: 0 })
      .width('100%')
      .height('100%')

      if (!this.isKeyboardActive()) {
        this.ActionBar()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
