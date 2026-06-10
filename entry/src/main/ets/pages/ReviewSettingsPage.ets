import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { AppColors, AppMetrics, AppTypography, PrimaryButton } from '../components/AppDesign';
import {
  HomeStorageOperationResult,
  HomeStorageProtocol,
  HomeStorageService,
  HomeStorageSettings
} from '../services/HomeStorageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';

@Entry
@Component
struct ReviewSettingsPage {
  private loadRequestId: number = 0;
  @State reviewerName: string = '';
  @State homeStorageProtocol: string = HomeStorageProtocol.WEBDAV;
  @State homeStorageEndpointUrl: string = '';
  @State homeStorageUsername: string = '';
  @State homeStoragePassword: string = '';
  @State homeStorageRemoteDirectory: string = '';
  @State isSaving: boolean = false;
  @State isTestingHomeStorage: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    const requestId = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    const reviewerName = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
    const homeStorageSettings = await HomeStorageService.loadSettings(this.getAbilityContext());
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.reviewerName = reviewerName;
    this.homeStorageProtocol = homeStorageSettings.protocol;
    this.homeStorageEndpointUrl = homeStorageSettings.endpointUrl;
    this.homeStorageUsername = homeStorageSettings.username;
    this.homeStoragePassword = homeStorageSettings.password;
    this.homeStorageRemoteDirectory = homeStorageSettings.remoteDirectory;
  }

  private currentHomeStorageSettings(): HomeStorageSettings {
    return {
      protocol: this.homeStorageProtocol,
      endpointUrl: this.homeStorageEndpointUrl,
      username: this.homeStorageUsername,
      password: this.homeStoragePassword,
      remoteDirectory: this.homeStorageRemoteDirectory
    };
  }

  private async saveSettings(): Promise<void> {
    if (this.isSaving) {
      return;
    }

    this.isSaving = true;
    try {
      this.reviewerName = await ReviewSettingsService.saveReviewerName(this.getAbilityContext(), this.reviewerName);
      const homeStorageSettings = await HomeStorageService.saveSettings(
        this.getAbilityContext(),
        this.currentHomeStorageSettings()
      );
      this.homeStorageProtocol = homeStorageSettings.protocol;
      this.homeStorageEndpointUrl = homeStorageSettings.endpointUrl;
      this.homeStorageUsername = homeStorageSettings.username;
      this.homeStoragePassword = homeStorageSettings.password;
      this.homeStorageRemoteDirectory = homeStorageSettings.remoteDirectory;
      promptAction.showToast({ message: '已保存复盘设置' });
    } catch (error) {
      promptAction.showToast({ message: '保存失败，请稍后重试' });
    } finally {
      this.isSaving = false;
    }
  }

  private isHomeStorageProtocol(protocol: HomeStorageProtocol): boolean {
    return this.homeStorageProtocol === protocol;
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

  @Builder
  Header() {
    Row() {
      Blank()

      Text('复盘设置')
        .fontSize(AppTypography.level2)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.level2LineHeight)

      Blank()
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height(AppTypography.level2LineHeight)
  }

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(AppTypography.body)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .width('100%')
  }

  @Builder
  SettingsInput(
    label: string,
    text: string,
    placeholder: string,
    onChange: (value: string) => void,
    isPassword: boolean = false
  ) {
    Column({ space: AppMetrics.space8 }) {
      this.FieldLabel(label)

      TextInput({ text: text, placeholder: placeholder })
        .type(isPassword ? InputType.Password : InputType.Normal)
        .height(48)
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
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  SecondaryButton(label: string, isDisabled: boolean, onTap: () => void) {
    Button(label)
      .height(48)
      .borderRadius(AppMetrics.cardRadius)
      .fontSize(AppTypography.body)
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
  ProtocolButton(label: string, protocol: HomeStorageProtocol) {
    Button(label)
      .height(40)
      .layoutWeight(1)
      .borderRadius(AppMetrics.cardRadius)
      .fontSize(AppTypography.auxiliary)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.isHomeStorageProtocol(protocol) ? '#FFFFFF' : AppColors.text)
      .backgroundColor(this.isHomeStorageProtocol(protocol) ? AppColors.primary : AppColors.surfaceMuted)
      .border({ width: 1, color: this.isHomeStorageProtocol(protocol) ? AppColors.primary : AppColors.border })
      .stateEffect(true)
      .onClick(() => {
        this.homeStorageProtocol = protocol;
      })
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: AppMetrics.space24 }) {
          this.SettingsInput('复盘人', this.reviewerName, '可留空', (value: string) => {
            this.reviewerName = value;
          })

          Column({ space: AppMetrics.space12 }) {
            Text('家庭存储')
              .fontSize(AppTypography.body)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .width('100%')

            Row({ space: AppMetrics.space8 }) {
              this.ProtocolButton('WebDAV', HomeStorageProtocol.WEBDAV)
              this.ProtocolButton('SMB', HomeStorageProtocol.SMB_SYSTEM_PICKER)
            }
            .width('100%')

            if (this.isHomeStorageProtocol(HomeStorageProtocol.WEBDAV)) {
              this.SettingsInput('WebDAV 地址', this.homeStorageEndpointUrl, 'https://nas.example.com/webdav', (value: string) => {
                this.homeStorageEndpointUrl = value;
              })

              this.SettingsInput('用户名', this.homeStorageUsername, '可留空', (value: string) => {
                this.homeStorageUsername = value;
              })

              this.SettingsInput('密码或 Token', this.homeStoragePassword, '建议使用专用应用密码', (value: string) => {
                this.homeStoragePassword = value;
              }, true)

              this.SettingsInput('远程目录', this.homeStorageRemoteDirectory, '摄影资料库/Reviews', (value: string) => {
                this.homeStorageRemoteDirectory = value;
              })
            }

            if (this.isHomeStorageProtocol(HomeStorageProtocol.SMB_SYSTEM_PICKER)) {
              Text('上传时选择系统文件中的 SMB 共享目录')
                .fontSize(AppTypography.auxiliary)
                .fontColor(AppColors.secondaryText)
                .lineHeight(AppTypography.auxiliaryLineHeight)
                .width('100%')
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: AppMetrics.space32, bottom: AppMetrics.space24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .width('100%')

      Column({ space: AppMetrics.space12 }) {
        this.SecondaryButton(this.isTestingHomeStorage ? '测试中...' : '测试连接', this.isTestingHomeStorage, () => {
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
    .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
