import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { HOME_STORAGE_PAGE } from '../app/AppRouter';
import { AppColors, AppMetrics, AppPageHeader, AppTypography, PrimaryButton, SecondaryButton } from '../components/AppDesign';
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
    return this.homeStorageSettings.remoteDirectory.length > 0 ? this.homeStorageSettings.remoteDirectory : '未配置';
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
        AppPageHeader({
          title: '同步中心',
          subtitle: '管理家庭存储状态。'
        })

        Column({ space: AppMetrics.cardGap }) {
          Row() {
            Column({ space: AppMetrics.space8 }) {
              Text('家庭存储')
                .fontSize(AppTypography.cardTitle)
                .fontWeight(600)
                .fontColor(AppColors.text)
                .lineHeight(AppTypography.cardTitleLineHeight)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(this.resolveStatusText())
              .fontSize(AppTypography.caption)
              .fontColor(this.resolveStatus() === HomeStorageConfigStatus.COMPLETE ? AppColors.tagGreenText
                : this.resolveStatus() === HomeStorageConfigStatus.PARTIAL ? AppColors.tagAmberText : AppColors.secondaryText)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(10)
              .backgroundColor(this.resolveStatus() === HomeStorageConfigStatus.COMPLETE ? AppColors.tagGreen
                : this.resolveStatus() === HomeStorageConfigStatus.PARTIAL ? AppColors.tagAmber : AppColors.surfaceMuted)
          }
          .width('100%')

          this.InfoRow('状态', this.resolveAvailabilityText())
          this.InfoRow('SMB 地址', this.resolveHomeStorageAddress())
          this.InfoRow('共享目录', this.resolveShareName())
          this.InfoRow('保存位置', this.resolveRemoteDirectory())

          if (this.lastCheckedAt > 0) {
            this.InfoRow('最近测试', formatReviewTime(this.lastCheckedAt))
          }
        }
        .padding(AppMetrics.cardPadding)
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surface)
        .border({ width: 1, color: AppColors.border })

        Row({ space: AppMetrics.cardGap }) {
          SecondaryButton({
            label: this.isTesting ? '测试中...' : '测试连接',
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
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
