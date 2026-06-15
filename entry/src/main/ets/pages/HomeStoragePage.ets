import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import window from '@ohos.window';
import { KeyboardAvoidMode } from '@ohos.arkui.UIContext';
import { AppColors, AppMetrics, AppPageHeader, AppTypography, PrimaryButton, SecondaryButton } from '../components/AppDesign';
import {
  HomeStorageOperationResult,
  HomeStorageService,
  HomeStorageSettings
} from '../services/HomeStorageService';

const SETTINGS_INPUT_SCROLL_DELAY: number = 220;
const SETTINGS_INPUT_BLOCK_HEIGHT: number = 78;
const SETTINGS_INPUT_SAFE_TOP_GAP: number = 36;
const SETTINGS_FORM_BOTTOM_PADDING: number = 32;
const SETTINGS_KEYBOARD_BOTTOM_PADDING: number = 42;
const SETTINGS_ACTION_BAR_HEIGHT: number = 92;
const SETTINGS_ACTION_BAR_BOTTOM_GAP: number = 12;
const SETTINGS_ACTION_BUTTON_GAP: number = 12;
const SETTINGS_SUMMARY_LABEL_WIDTH: number = 72;

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
  @State keyboardHeight: number = 0;
  @State focusedInputIndex: number = -1;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
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
      this.keyboardHeight = Math.max(0, px2vp(height));
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
        promptAction.showToast({ message: '已保存，但回读结果与当前输入不一致' });
        return;
      }
      promptAction.showToast({ message: '已保存家庭存储设置' });
    } catch (error) {
      promptAction.showToast({ message: '保存失败，请稍后重试' });
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
      promptAction.showToast({ message: result.message });
    } finally {
      this.isTestingHomeStorage = false;
    }
  }

  private isKeyboardActive(): boolean {
    return this.keyboardHeight > 0;
  }

  private getSettingsBottomPadding(): number {
    const actionBarPadding: number = SETTINGS_ACTION_BAR_HEIGHT + SETTINGS_ACTION_BAR_BOTTOM_GAP;
    if (this.isKeyboardActive()) {
      return this.keyboardHeight + SETTINGS_KEYBOARD_BOTTOM_PADDING + actionBarPadding;
    }

    return SETTINGS_FORM_BOTTOM_PADDING + actionBarPadding;
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

  private hasRequiredHomeStorageSettings(): boolean {
    return this.homeStorageHost.trim().length > 0 && this.homeStorageShareName.trim().length > 0;
  }

  private resolveStatusTitle(): string {
    if (!this.isSettingsLoaded) {
      return '正在读取';
    }
    return this.hasRequiredHomeStorageSettings() ? '可以测试连接' : '还需要填写';
  }

  private resolveStatusDescription(): string {
    if (!this.isSettingsLoaded) {
      return '正在读取本机保存的家庭存储配置。';
    }
    if (this.hasRequiredHomeStorageSettings()) {
      return '保存后可在阅读页把 review.json 上传到家庭存储。';
    }
    return '至少填写 SMB 地址或 IP、共享目录，端口默认使用 445。';
  }

  private resolveDestinationText(): string {
    if (!this.isSettingsLoaded) {
      return '读取中';
    }
    if (!this.hasRequiredHomeStorageSettings()) {
      return '填写地址和共享目录后显示';
    }
    const remoteDirectory: string = this.homeStorageRemoteDirectory.trim();
    const basePath: string = `\\\\${this.homeStorageHost.trim()}\\${this.homeStorageShareName.trim()}`;
    return remoteDirectory.length > 0 ? `${basePath}\\${remoteDirectory.replace(/\//g, '\\')}` : `${basePath}\\共享根目录`;
  }

  private resolveAccountText(): string {
    if (!this.isSettingsLoaded) {
      return '读取中';
    }
    return this.homeStorageUsername.trim().length > 0 ? this.homeStorageUsername.trim() : '匿名或访客访问';
  }

  private isActionDisabled(): boolean {
    return !this.isSettingsLoaded || this.isSaving || this.isTestingHomeStorage;
  }

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(AppTypography.inputLabel)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .lineHeight(AppTypography.inputLabelLineHeight)
      .width('100%')
  }

  @Builder
  FieldHint(text: string) {
    Text(text)
      .fontSize(AppTypography.meta)
      .fontColor(AppColors.mutedText)
      .lineHeight(AppTypography.metaLineHeight)
      .width('100%')
  }

  @Builder
  SectionTitle(title: string, subtitle: string) {
    Column({ space: AppMetrics.space8 }) {
      Text(title)
        .fontSize(AppTypography.sectionTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.sectionTitleLineHeight)
        .width('100%')

      Text(subtitle)
        .fontSize(AppTypography.auxiliary)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.auxiliaryLineHeight)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  LoadingSettings() {
    Column({ space: AppMetrics.space8 }) {
      Text('正在读取家庭存储设置')
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
    hint: string = ''
  ) {
    Column({ space: AppMetrics.space8 }) {
      this.FieldLabel(label)

      TextInput({ text: text, placeholder: placeholder })
        .type(isPassword ? InputType.Password : InputType.Normal)
        .height(AppMetrics.controlHeight)
        .maxLines(1)
        .borderRadius(AppMetrics.cardRadius)
        .fontSize(AppTypography.inputText)
        .fontColor(AppColors.text)
        .placeholderColor(AppColors.placeholderText)
        .backgroundColor(AppColors.surfaceMuted)
        .padding({ left: AppMetrics.space16, right: isPassword ? AppMetrics.space32 : AppMetrics.space16 })
        .border({ width: 1, color: AppColors.border })
        .onChange((value: string) => {
          onChange(value);
        })
        .onFocus(() => {
          if (inputIndex >= 0) {
            this.focusInput(inputIndex);
          }
        })
        .onBlur(() => {
          if (this.focusedInputIndex === inputIndex) {
            this.focusedInputIndex = -1;
          }
        })

      if (hint.length > 0) {
        this.FieldHint(hint)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  SummaryRow(label: string, value: string) {
    Row({ space: AppMetrics.space16 }) {
      Text(label)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.mutedText)
        .lineHeight(AppTypography.captionLineHeight)
        .width(SETTINGS_SUMMARY_LABEL_WIDTH)

      Text(value)
        .fontSize(AppTypography.body)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.bodyLineHeight)
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
  }

  @Builder
  StatusSummary() {
    Column({ space: AppMetrics.cardGap }) {
      Row({ space: AppMetrics.space16 }) {
        Column({ space: AppMetrics.space8 }) {
          Text('配置状态')
            .fontSize(AppTypography.cardTitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.cardTitleLineHeight)
            .width('100%')

          Text(this.resolveStatusDescription())
            .fontSize(AppTypography.auxiliary)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.auxiliaryLineHeight)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.resolveStatusTitle())
          .fontSize(AppTypography.meta)
          .fontColor(this.hasRequiredHomeStorageSettings() ? AppColors.tagBlueText : AppColors.secondaryText)
          .lineHeight(AppTypography.metaLineHeight)
          .padding({ left: AppMetrics.space8, right: AppMetrics.space8, top: 5, bottom: 5 })
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(this.hasRequiredHomeStorageSettings() ? AppColors.tagBlue : AppColors.surfaceMuted)
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')

      this.SummaryRow('写入位置', this.resolveDestinationText())
      this.SummaryRow('登录账号', this.resolveAccountText())
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  ConfigurationForm() {
    Column({ space: AppMetrics.sectionGap }) {
      Column({ space: AppMetrics.cardGap }) {
        this.SectionTitle('连接目标', '填写家庭存储在局域网中的 SMB 地址。也可以把 smb://地址/共享目录/路径 粘贴到地址栏，保存时会自动拆分。')

        this.SettingsInput('SMB 地址或 IP', this.homeStorageHost, '例如 192.168.3.10', (value: string) => {
          this.homeStorageHost = value;
        }, false, 0, '必填。支持填写 smb://192.168.3.10/Photos/Reviews。')

        this.SettingsInput('SMB 端口', this.homeStoragePort, '默认 445', (value: string) => {
          this.homeStoragePort = value;
        }, false, 1, '大多数家庭 NAS 使用 445，除非你手动改过端口。')

        this.SettingsInput('共享目录', this.homeStorageShareName, '例如 Photos', (value: string) => {
          this.homeStorageShareName = value;
        }, false, 2, '必填。填写 SMB 共享名，不需要加斜杠。')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: AppMetrics.cardGap }) {
        this.SectionTitle('保存位置', '指定 review.json 上传后的目录。留空时会直接保存到共享目录根部。')

        this.SettingsInput('目标路径', this.homeStorageRemoteDirectory, '例如 Reviews/2026', (value: string) => {
          this.homeStorageRemoteDirectory = value;
        }, false, 3, '可选。路径不存在时请先在家庭存储中创建。')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Column({ space: AppMetrics.cardGap }) {
        this.SectionTitle('登录凭据', '根据家庭存储权限填写账号信息。密码会通过系统安全存储保存，失败时才回退到本地设置。')

        this.SettingsInput('用户名', this.homeStorageUsername, '家庭存储账号，可留空', (value: string) => {
          this.homeStorageUsername = value;
        }, false, 4, '可选。访客共享或匿名访问可以留空。')

        this.SettingsInput('密码或凭据', this.homeStoragePassword, '家庭存储密码，可留空', (value: string) => {
          this.homeStoragePassword = value;
        }, true, 5, '可选。保存后再次进入会回填已保存凭据。')

        this.SettingsInput('工作组或域', this.homeStorageDomain, '可留空', (value: string) => {
          this.homeStorageDomain = value;
        }, false, 6, '可选。普通家庭网络通常不需要填写。')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  ActionBar() {
    Column() {
      Row({ space: SETTINGS_ACTION_BUTTON_GAP }) {
        SecondaryButton({
          label: this.isTestingHomeStorage ? '测试中...' : '测试连接',
          isDisabled: this.isActionDisabled(),
          onTap: () => {
            this.testHomeStorage();
          }
        })
          .height(AppMetrics.controlHeight)
          .layoutWeight(1)

        PrimaryButton({
          label: this.isSaving ? '保存中...' : '保存',
          isDisabled: this.isActionDisabled(),
          onTap: () => {
            this.saveSettings();
          }
        })
          .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
    }
    .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space16, bottom: AppMetrics.space16 })
    .width('100%')
    .height(SETTINGS_ACTION_BAR_HEIGHT)
    .backgroundColor(AppColors.pageBackground)
    .shadow({ radius: 18, color: '#14000000', offsetX: 0, offsetY: -4 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        AppPageHeader({
          title: '家庭存储',
          subtitle: '配置 SMB 家庭存储，让 review.json 可以从阅读页直接上传。'
        })

        Scroll(this.settingsScroller) {
          Column({ space: AppMetrics.sectionGap }) {
            this.StatusSummary()

            if (this.isSettingsLoaded) {
              this.ConfigurationForm()
            } else {
              this.LoadingSettings()
            }
          }
          .alignItems(HorizontalAlign.Start)
          .padding({ top: AppMetrics.space24, bottom: this.getSettingsBottomPadding() + AppMetrics.pageBottomPadding })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: 0 })
      .width('100%')
      .height('100%')

      this.ActionBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
