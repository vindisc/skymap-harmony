import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import { KeyboardAvoidMode } from '@ohos.arkui.UIContext';
import {
  AppBottomSafeAreaFill,
  AppColors,
  AppMetrics,
  AppTypography,
  SettingsPageHeader
} from '../components/AppDesign';
import { SettingsActionBar, SettingsTextInput } from '../components/SettingsForm';
import { ElevationTokens } from '../theme/DesignTokens';
import {
  HomeStorageOperationResult,
  HomeStorageService,
  HomeStorageSettings
} from '../services/HomeStorageService';

const SETTINGS_INPUT_SCROLL_DELAY: number = 220;
const SETTINGS_INPUT_BLOCK_HEIGHT: number = 78;
const SETTINGS_INPUT_SAFE_TOP_GAP: number = 36;
const SETTINGS_TITLE_FORM_GAP: number = AppMetrics.space8;
const HOME_STORAGE_PAGE_TOP_PADDING: number = AppMetrics.pageTopPadding;
const HOME_STORAGE_ROUTE_TOP_COMPENSATION: number = 0 - AppMetrics.space24;
const SETTINGS_KEYBOARD_BOTTOM_PADDING: number = AppMetrics.systemNavigationBarHeight + AppMetrics.space8;
const SETTINGS_FEEDBACK_DISMISS_MS: number = 2200;

@Entry
@Component
struct HomeStoragePage {
  private settingsScroller: Scroller = new Scroller();
  private hostWindow: window.Window | null = null;
  private keyboardHeightChangeCallback: ((height: number) => void) | null = null;
  private previousKeyboardAvoidMode: KeyboardAvoidMode = KeyboardAvoidMode.OFFSET;
  private scrollRequestId: number = 0;
  private isPageAlive: boolean = false;
  private loadRequestId: number = 0;
  private feedbackDismissTimer: number = -1;
  @State homeStorageHost: string = '';
  @State homeStoragePort: string = '';
  @State homeStorageShareName: string = '';
  @State homeStorageRemoteDirectory: string = '';
  @State homeStorageUsername: string = '';
  @State homeStoragePassword: string = '';
  @State homeStorageDomain: string = '';
  @State isSettingsLoaded: boolean = false;
  @State isSaving: boolean = false;
  @State isTestingHomeStorage: boolean = false;
  @State actionFeedbackText: string = '';
  @State actionFeedbackLevel: string = 'neutral';
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
    this.clearFeedbackTimer();
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
    const context = this.getAbilityContext();
    const homeStorageSettings = await HomeStorageService.loadSettings(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.homeStorageHost = homeStorageSettings.smbHost;
    this.homeStoragePort = homeStorageSettings.smbPort;
    this.homeStorageShareName = homeStorageSettings.smbShareName;
    this.homeStorageRemoteDirectory = homeStorageSettings.remoteDirectory;
    this.homeStorageUsername = homeStorageSettings.username;
    this.homeStoragePassword = homeStorageSettings.password;
    this.homeStorageDomain = homeStorageSettings.smbDomain;
    this.isSettingsLoaded = true;
  }

  private currentHomeStorageSettings(): HomeStorageSettings {
    return {
      username: this.homeStorageUsername,
      password: this.homeStoragePassword,
      remoteDirectory: this.homeStorageRemoteDirectory,
      smbHost: this.homeStorageHost,
      smbPort: this.homeStoragePort,
      smbShareName: this.homeStorageShareName,
      smbDomain: this.homeStorageDomain
    };
  }

  private async saveSettings(): Promise<void> {
    if (this.isSaving || !this.isSettingsLoaded) {
      return;
    }

    this.isSaving = true;
    try {
      const homeStorageSettings = await HomeStorageService.saveSettings(
        this.getAbilityContext(),
        this.currentHomeStorageSettings()
      );
      this.homeStorageHost = homeStorageSettings.smbHost;
      this.homeStoragePort = homeStorageSettings.smbPort;
      this.homeStorageShareName = homeStorageSettings.smbShareName;
      this.homeStorageRemoteDirectory = homeStorageSettings.remoteDirectory;
      this.homeStorageUsername = homeStorageSettings.username;
      this.homeStoragePassword = homeStorageSettings.password;
      this.homeStorageDomain = homeStorageSettings.smbDomain;
      const verifiedSettings = await HomeStorageService.verifySavedSettings(this.getAbilityContext());
      if (verifiedSettings.smbHost !== this.homeStorageHost ||
        verifiedSettings.smbShareName !== this.homeStorageShareName ||
        verifiedSettings.remoteDirectory !== this.homeStorageRemoteDirectory ||
        verifiedSettings.username !== this.homeStorageUsername ||
        verifiedSettings.smbDomain !== this.homeStorageDomain) {
        this.setActionFeedback('已保存，但回读不一致', 'warning');
        return;
      }
      this.setActionFeedback('已保存家庭存储设置', 'success');
    } catch (error) {
      this.setActionFeedback('保存失败，请稍后重试', 'error');
    } finally {
      this.isSaving = false;
    }
  }

  private async testHomeStorage(): Promise<void> {
    if (this.isTestingHomeStorage || !this.isSettingsLoaded) {
      return;
    }

    this.isTestingHomeStorage = true;
    try {
      const result: HomeStorageOperationResult = await HomeStorageService.testConnection(this.currentHomeStorageSettings());
      this.setActionFeedback(result.message, result.success ? 'success' : 'error');
    } finally {
      this.isTestingHomeStorage = false;
    }
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

  private clearActionFeedback(): void {
    this.clearFeedbackTimer();
    this.actionFeedbackText = '';
    this.actionFeedbackLevel = 'neutral';
  }

  private setActionFeedback(message: string, level: string): void {
    this.clearFeedbackTimer();
    this.actionFeedbackText = message;
    this.actionFeedbackLevel = level;
    this.feedbackDismissTimer = setTimeout(() => {
      this.clearActionFeedback();
    }, SETTINGS_FEEDBACK_DISMISS_MS);
  }

  private clearFeedbackTimer(): void {
    if (this.feedbackDismissTimer < 0) {
      return;
    }
    clearTimeout(this.feedbackDismissTimer);
    this.feedbackDismissTimer = -1;
  }

  private sanitizePort(value: string): string {
    return value.replace(/[^0-9]/g, '');
  }

  private isActionDisabled(): boolean {
    return !this.isSettingsLoaded || this.isSaving || this.isTestingHomeStorage;
  }

  private resolveFeedbackColor(): string {
    if (this.actionFeedbackLevel === 'success') {
      return AppColors.tagGreenText;
    }
    if (this.actionFeedbackLevel === 'error') {
      return AppColors.danger;
    }
    if (this.actionFeedbackLevel === 'warning') {
      return AppColors.tagAmberText;
    }
    return AppColors.secondaryText;
  }

  private resolveFeedbackBackground(): string {
    if (this.actionFeedbackLevel === 'success') {
      return AppColors.tagGreen;
    }
    if (this.actionFeedbackLevel === 'error') {
      return AppColors.surface;
    }
    if (this.actionFeedbackLevel === 'warning') {
      return AppColors.tagAmber;
    }
    return AppColors.surfaceMuted;
  }

  @Builder
  Header() {
    SettingsPageHeader({
      title: '家庭存储'
    })
  }

  @Builder
  LoadingSettings() {
    Column({ space: AppMetrics.space8 }) {
      Text('读取中')
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
    inputIndex: number = -1,
    inputType: InputType = InputType.Normal,
    showsPasswordToggle: boolean = false
  ) {
    SettingsTextInput({
      label: label,
      text: text,
      placeholder: placeholder,
      isPassword: isPassword,
      inputType: inputType,
      showsPasswordToggle: showsPasswordToggle,
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
  CenterFeedbackOverlay() {
    if (this.actionFeedbackText.length > 0) {
      Text(this.actionFeedbackText)
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveFeedbackColor())
        .lineHeight(AppTypography.bodyLineHeight)
        .textAlign(TextAlign.Center)
        .padding({ left: AppMetrics.space20, right: AppMetrics.space20, top: AppMetrics.space12, bottom: AppMetrics.space12 })
        .constraintSize({ minWidth: 168, maxWidth: 300 })
        .borderRadius(AppMetrics.capsuleRadius)
        .backgroundColor(this.resolveFeedbackBackground())
        .border({ width: 1, color: this.actionFeedbackLevel === 'error' ? AppColors.danger : AppColors.border })
        .shadow(ElevationTokens.medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .zIndex(8)
    }
  }

  @Builder
  ConfigurationForm() {
    Column({ space: AppMetrics.cardGap }) {
      this.SettingsInput('家庭存储地址', this.homeStorageHost, '192.168.3.10', (value: string) => {
        this.homeStorageHost = value;
        this.clearActionFeedback();
      }, false, 0)

      this.SettingsInput('连接端口', this.homeStoragePort, '445', (value: string) => {
        this.homeStoragePort = this.sanitizePort(value);
        this.clearActionFeedback();
      }, false, 1, InputType.Number)

      this.SettingsInput('共享目录', this.homeStorageShareName, 'Photos', (value: string) => {
        this.homeStorageShareName = value;
        this.clearActionFeedback();
      }, false, 2)

      this.SettingsInput('目标路径', this.homeStorageRemoteDirectory, 'Reviews/2026', (value: string) => {
        this.homeStorageRemoteDirectory = value;
        this.clearActionFeedback();
      }, false, 3)

      this.SettingsInput('用户名', this.homeStorageUsername, '账号', (value: string) => {
        this.homeStorageUsername = value;
        this.clearActionFeedback();
      }, false, 4)

      this.SettingsInput('密码', this.homeStoragePassword, '密码', (value: string) => {
        this.homeStoragePassword = value;
        this.clearActionFeedback();
      }, true, 5, InputType.Normal, true)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AppBottomSafeAreaFill()

      Column() {
        this.Header()

        Scroll(this.settingsScroller) {
          Column({ space: AppMetrics.cardGap }) {
            if (this.isSettingsLoaded) {
              this.ConfigurationForm()
            } else {
              this.LoadingSettings()
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ top: SETTINGS_TITLE_FORM_GAP, bottom: this.getSettingsBottomPadding() })
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .height('100%')
      .padding({
        left: AppMetrics.pagePadding,
        right: AppMetrics.pagePadding,
        top: HOME_STORAGE_PAGE_TOP_PADDING,
        bottom: 0
      })
      .backgroundColor(AppColors.pageBackground)
      .translate({ y: HOME_STORAGE_ROUTE_TOP_COMPENSATION })

      Stack({ alignContent: Alignment.Center }) {
        this.CenterFeedbackOverlay()
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.None)

      if (!this.isKeyboardActive()) {
        SettingsActionBar({
          primaryLabel: this.isSaving ? '保存中…' : '保存',
          secondaryLabel: this.isTestingHomeStorage ? '检查中…' : '检查',
          isPrimaryDisabled: this.isActionDisabled(),
          isSecondaryDisabled: this.isActionDisabled(),
          onPrimaryTap: () => {
            this.saveSettings();
          },
          onSecondaryTap: () => {
            this.testHomeStorage();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
