import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import window from '@ohos.window';
import { KeyboardAvoidMode } from '@ohos.arkui.UIContext';
import { AppColors, AppMetrics, AppPageHeader, AppTypography, PrimaryButton } from '../components/AppDesign';
import {
  HomeStorageOperationResult,
  HomeStorageService,
  HomeStorageSettings
} from '../services/HomeStorageService';
import { formatReviewTime } from '../utils/ImageLayoutUtils';

const SETTINGS_INPUT_SCROLL_DELAY: number = 220;
const SETTINGS_INPUT_BLOCK_HEIGHT: number = 78;
const SETTINGS_INPUT_SAFE_TOP_GAP: number = 36;
const SETTINGS_FORM_BOTTOM_PADDING: number = 32;
const SETTINGS_KEYBOARD_BOTTOM_PADDING: number = 42;

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
  @State isSaving: boolean = false;
  @State isTestingHomeStorage: boolean = false;
  @State keyboardHeight: number = 0;
  @State focusedInputIndex: number = -1;
  @State lastUploadedAt: number = 0;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.isPageAlive = true;
    this.disableSystemKeyboardAvoidance();
    this.registerKeyboardHeightObserver();
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
    const context = this.getAbilityContext();
    const results = await Promise.all([
      HomeStorageService.loadSettings(context),
      HomeStorageService.loadLastUploadedAt(context)
    ]);
    if (requestId !== this.loadRequestId) {
      return;
    }

    const homeStorageSettings = results[0] as HomeStorageSettings;
    this.homeStorageHost = homeStorageSettings.smbHost;
    this.homeStoragePort = homeStorageSettings.smbPort;
    this.homeStorageShareName = homeStorageSettings.smbShareName;
    this.homeStorageRemoteDirectory = homeStorageSettings.remoteDirectory;
    this.homeStorageUsername = homeStorageSettings.username;
    this.homeStoragePassword = homeStorageSettings.password;
    this.homeStorageDomain = homeStorageSettings.smbDomain;
    this.lastUploadedAt = results[1] as number;
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
    if (this.isSaving) {
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
      promptAction.showToast({ message: '已保存家庭存储设置' });
    } catch (error) {
      promptAction.showToast({ message: '保存失败，请稍后重试' });
    } finally {
      this.isSaving = false;
    }
  }

  private async testHomeStorage(): Promise<void> {
    if (this.isTestingHomeStorage) {
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
    if (this.isKeyboardActive()) {
      return this.keyboardHeight + SETTINGS_KEYBOARD_BOTTOM_PADDING;
    }

    return SETTINGS_FORM_BOTTOM_PADDING;
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

  private resolveConnectionStatusText(): string {
    return HomeStorageService.validateSettings(this.currentHomeStorageSettings()).length === 0 ? '已配置' : '未配置';
  }

  private resolveLastUploadedText(): string {
    return this.lastUploadedAt > 0 ? formatReviewTime(this.lastUploadedAt) : '暂无上传记录';
  }

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(AppTypography.cardTitle)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .lineHeight(AppTypography.cardTitleLineHeight)
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
    Column({ space: AppMetrics.space8 }) {
      this.FieldLabel(label)

      TextInput({ text: text, placeholder: placeholder })
        .type(isPassword ? InputType.Password : InputType.Normal)
        .height(AppMetrics.controlHeight)
        .borderRadius(AppMetrics.cardRadius)
        .fontSize(AppTypography.body)
        .fontColor(AppColors.text)
        .placeholderColor('#9AA1AB')
        .backgroundColor(AppColors.surfaceMuted)
        .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
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
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  SecondaryActionButton(label: string, isDisabled: boolean, onTap: () => void) {
    Button(label)
      .height(AppMetrics.compactControlHeight)
      .borderRadius(AppMetrics.cardRadius)
      .fontSize(AppTypography.buttonText)
      .fontWeight(FontWeight.Medium)
      .fontColor(isDisabled ? AppColors.secondaryText : AppColors.text)
      .backgroundColor(AppColors.surfaceMuted)
      .border({ width: 1, color: AppColors.border })
      .stateEffect(!isDisabled)
      .enabled(!isDisabled)
      .onClick(() => {
        onTap();
      })
  }

  @Builder
  StatusRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(AppTypography.auxiliary)
        .fontColor(AppColors.secondaryText)

      Blank()

      Text(value)
        .fontSize(AppTypography.auxiliary)
        .fontColor(AppColors.text)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  build() {
    Column() {
      AppPageHeader({
        title: '家庭存储',
        subtitle: '管理 SMB 设置、测试连接，并查看最近上传状态。'
      })

      Scroll(this.settingsScroller) {
        Column({ space: AppMetrics.sectionGap }) {
          Column({ space: AppMetrics.cardGap }) {
            this.StatusRow('连接状态', this.resolveConnectionStatusText())
            this.StatusRow('最近上传时间', this.resolveLastUploadedText())
          }
          .padding(AppMetrics.cardPadding)
          .width('100%')
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(AppColors.surface)
          .border({ width: 1, color: AppColors.border })

          Column({ space: AppMetrics.cardGap }) {
            Text('用于把复盘里的 review.json 上传到家庭存储，配置项与导出菜单保持一致。')
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.secondaryText)
              .lineHeight(AppTypography.auxiliaryLineHeight)
              .width('100%')

            this.SettingsInput('SMB 地址或 IP', this.homeStorageHost, '192.168.3.10', (value: string) => {
              this.homeStorageHost = value;
            }, false, 0)

            this.SettingsInput('SMB 端口', this.homeStoragePort, '445', (value: string) => {
              this.homeStoragePort = value;
            }, false, 1)

            this.SettingsInput('共享目录', this.homeStorageShareName, 'Photos', (value: string) => {
              this.homeStorageShareName = value;
            }, false, 2)

            this.SettingsInput('目标路径', this.homeStorageRemoteDirectory, '摄影资料库/Reviews', (value: string) => {
              this.homeStorageRemoteDirectory = value;
            }, false, 3)

            this.SettingsInput('用户名', this.homeStorageUsername, '家庭存储账号，可留空', (value: string) => {
              this.homeStorageUsername = value;
            }, false, 4)

            this.SettingsInput('密码', this.homeStoragePassword, '家庭存储密码，可留空', (value: string) => {
              this.homeStoragePassword = value;
            }, true, 5)

            this.SettingsInput('工作组或域', this.homeStorageDomain, '可留空', (value: string) => {
              this.homeStorageDomain = value;
            }, false, 6)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          Column({ space: AppMetrics.cardGap }) {
            this.SecondaryActionButton(this.isTestingHomeStorage ? '测试连接中...' : '测试连接', this.isTestingHomeStorage, () => {
              this.testHomeStorage();
            })

            PrimaryButton({
              label: this.isSaving ? '保存中...' : '保存',
              isDisabled: this.isSaving,
              onTap: () => {
                this.saveSettings();
              }
            })
          }
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ top: AppMetrics.space32, bottom: this.getSettingsBottomPadding() + AppMetrics.pageBottomPadding })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: AppMetrics.space32 })
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
