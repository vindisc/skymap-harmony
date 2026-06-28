import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { HOME_STORAGE_PAGE } from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppTypography,
  PrimaryButton,
  SecondaryButton,
  SettingsEntryTone,
  SettingsLinkRow,
  SettingsPageHeader,
  SettingsSectionHeader
} from '../components/AppDesign';
import {
  HomeStorageConfigStatus,
  HomeStorageOperationResult,
  HomeStorageService,
  HomeStorageSettings
} from '../services/HomeStorageService';
import { SettingsRefreshService } from '../services/SettingsRefreshService';
import { formatReviewTime } from '../utils/ImageLayoutUtils';

@Entry
@Component
struct SyncCenterPage {
  private settingsRefreshToken: number = SettingsRefreshService.getRefreshToken();
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();
  @State isTesting: boolean = false;
  @State lastCheckedAt: number = 0;
  @State lastTestMessage: string = '';
  @State lastTestSucceeded: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.loadSettings();
  }

  onPageShow(): void {
    this.syncSettingsRefreshToken();
    this.loadSettings();
  }

  private syncSettingsRefreshToken(): void {
    const nextToken: number = SettingsRefreshService.getRefreshToken();
    if (nextToken !== this.settingsRefreshToken) {
      this.settingsRefreshToken = nextToken;
    }
  }

  private async loadSettings(): Promise<void> {
    this.homeStorageSettings = await HomeStorageService.loadSettings(this.getAbilityContext());
  }

  private resolveStatus(): HomeStorageConfigStatus {
    return HomeStorageService.getConfigurationStatus(this.homeStorageSettings);
  }

  private resolveStatusText(): string {
    return HomeStorageService.resolveConfigurationStatusLabel(this.resolveStatus());
  }

  private resolveStatusTone(): SettingsEntryTone {
    const status: HomeStorageConfigStatus = this.resolveStatus();
    if (status === HomeStorageConfigStatus.COMPLETE) {
      return SettingsEntryTone.SUCCESS;
    }
    if (status === HomeStorageConfigStatus.PARTIAL) {
      return SettingsEntryTone.WARNING;
    }
    return SettingsEntryTone.MUTED;
  }

  private resolveAvailabilityText(): string {
    return HomeStorageService.resolveAvailabilityLabel(this.resolveStatus());
  }

  private resolveHomeStorageAddress(): string {
    const host: string = this.homeStorageSettings.smbHost;
    const port: string = this.homeStorageSettings.smbPort;
    if (host.length === 0) {
      return '未配置';
    }
    return `${host}:${port}`;
  }

  private resolveShareName(): string {
    return this.homeStorageSettings.smbShareName.length > 0 ? this.homeStorageSettings.smbShareName : '未配置';
  }

  private resolveRemoteDirectory(): string {
    return this.homeStorageSettings.remoteDirectory.length > 0 ? this.homeStorageSettings.remoteDirectory : '共享根目录';
  }

  private openSettings(): void {
    router.pushUrl({ url: HOME_STORAGE_PAGE });
  }

  private async testConnection(): Promise<void> {
    if (this.isTesting) {
      return;
    }

    this.isTesting = true;
    try {
      const result: HomeStorageOperationResult = await HomeStorageService.testConnection(this.homeStorageSettings);
      this.lastCheckedAt = Date.now();
      this.lastTestMessage = result.message;
      this.lastTestSucceeded = result.success;
      promptAction.showToast({ message: result.message });
    } finally {
      this.isTesting = false;
    }
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row({ space: AppMetrics.space16 }) {
      Text(label)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.mutedText)
        .width(64)

      Text(value)
        .fontSize(AppTypography.body)
        .fontColor(AppColors.text)
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.sectionGap }) {
        SettingsPageHeader({
          title: '同步中心',
          subtitle: '家庭存储仍是 Beta 后实验能力。当前 Beta 请使用导出 review.json 完成手动交换。'
        })

        Column({ space: AppMetrics.space8 }) {
          SettingsSectionHeader({
            title: '家庭存储',
            description: '当前家庭存储需要在同一网络或 VPN 下使用。'
          })

          SettingsLinkRow({
            title: this.resolveAvailabilityText(),
            value: `${this.resolveHomeStorageAddress()} · ${this.resolveShareName()} · ${this.resolveRemoteDirectory()}`,
            status: this.resolveStatusText(),
            tone: this.resolveStatusTone(),
            showChevron: false,
            onTap: () => {
            }
          })
        }
        .width('100%')

        Column({ space: AppMetrics.cardGap }) {
          this.InfoRow('状态', this.resolveAvailabilityText())
          this.InfoRow('连接地址', this.resolveHomeStorageAddress())
          this.InfoRow('共享目录', this.resolveShareName())
          this.InfoRow('保存位置', this.resolveRemoteDirectory())

          if (this.lastCheckedAt > 0) {
            this.InfoRow('最近测试', formatReviewTime(this.lastCheckedAt))
          }

          if (this.lastTestMessage.length > 0) {
            Text(this.lastTestMessage)
              .fontSize(AppTypography.caption)
              .fontColor(this.lastTestSucceeded ? AppColors.tagGreenText : AppColors.danger)
              .lineHeight(AppTypography.captionLineHeight)
              .width('100%')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(12)
              .backgroundColor(this.lastTestSucceeded ? AppColors.tagGreen : AppColors.surfaceTint)
              .border({ width: 1, color: this.lastTestSucceeded ? AppColors.border : AppColors.danger })
          }
        }
        .padding(AppMetrics.cardPadding)
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surface)
        .border({ width: 1, color: AppColors.border })

        Row({ space: AppMetrics.cardGap }) {
          SecondaryButton({
            label: this.isTesting ? '检查中…' : '检查家庭存储',
            isDisabled: this.isTesting,
            onTap: () => {
              this.testConnection();
            }
          })
          .layoutWeight(1)

          PrimaryButton({
            label: this.resolveStatus() === HomeStorageConfigStatus.COMPLETE ? '修改配置' : '配置',
            onTap: () => {
              this.openSettings();
            }
          })
          .layoutWeight(1)
        }
        .width('100%')
      }
      .padding({
        left: AppMetrics.pagePadding,
        right: AppMetrics.pagePadding,
        top: AppMetrics.pageTopPadding,
        bottom: AppMetrics.pageBottomPadding + AppMetrics.space24
      })
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
