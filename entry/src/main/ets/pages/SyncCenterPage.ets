import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { REVIEW_SETTINGS_PAGE } from '../app/AppRouter';
import { AppColors, AppMetrics, AppPageHeader, AppTypography, PrimaryButton } from '../components/AppDesign';
import {
  HomeStorageOperationResult,
  HomeStorageService,
  HomeStorageSettings
} from '../services/HomeStorageService';
import { formatReviewTime } from '../utils/ImageLayoutUtils';

@Entry
@Component
struct SyncCenterPage {
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();
  @State isTesting: boolean = false;
  @State lastCheckedAt: number = 0;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    this.homeStorageSettings = await HomeStorageService.loadSettings(this.getAbilityContext());
  }

  private isConfigured(): boolean {
    return HomeStorageService.validateSettings(this.homeStorageSettings).length === 0;
  }

  private resolveStatusText(): string {
    return this.isConfigured() ? '已连接' : '未连接';
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
    router.pushUrl({ url: REVIEW_SETTINGS_PAGE });
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
    Column({ space: AppMetrics.space4 }) {
      Text(label)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.mutedText)
        .width('100%')

      Text(value)
        .fontSize(AppTypography.body)
        .fontColor(AppColors.text)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Column() {
      Column({ space: AppMetrics.space16 }) {
        AppPageHeader({
          title: '同步中心',
          subtitle: '查看家庭存储状态，测试连接并进入同步配置。'
        })

        Column({ space: AppMetrics.space16 }) {
          Row() {
            Column({ space: AppMetrics.space4 }) {
              Text('家庭存储')
                .fontSize(AppTypography.body)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.text)
                .width('100%')

              Text(this.resolveStatusText())
                .fontSize(AppTypography.auxiliary)
                .fontColor(this.isConfigured() ? '#496A52' : AppColors.secondaryText)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(this.isConfigured() ? 'SMB 已连接' : '未配置家庭存储')
              .fontSize(AppTypography.caption)
              .fontColor(AppColors.mutedText)
          }
          .width('100%')

          this.InfoRow('SMB 地址', this.resolveHomeStorageAddress())
          this.InfoRow('共享目录', this.resolveShareName())
          this.InfoRow('目标路径', this.resolveRemoteDirectory())

          if (this.lastCheckedAt > 0) {
            this.InfoRow('最近测试', formatReviewTime(this.lastCheckedAt))
          }
        }
        .padding(AppMetrics.space16)
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surface)
        .border({ width: 1, color: AppColors.border })

        Button(this.isTesting ? '测试中...' : '测试连接')
          .height(44)
          .width('100%')
          .borderRadius(AppMetrics.buttonRadius)
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .backgroundColor(AppColors.surfaceMuted)
          .border({ width: 1, color: AppColors.border })
          .enabled(!this.isTesting)
          .opacity(this.isTesting ? 0.72 : 1)
          .onClick(() => {
            this.testConnection();
          })

        PrimaryButton({
          label: '进入配置',
          onTap: () => {
            this.openSettings();
          }
        })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space24 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
