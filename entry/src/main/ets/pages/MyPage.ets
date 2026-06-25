import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { HOME_STORAGE_PAGE, REVIEWER_PROFILE_PAGE, SYNC_CENTER_PAGE } from '../app/AppRouter';
import { AppColors, AppMetrics, AppPageHeader, AppTypography } from '../components/AppDesign';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import {
  RdbDiagnosticsResult,
  RdbMigrationDiagnosticsResult,
  ReviewCardRdbDiagnosticsService
} from '../services/ReviewCardRdbDiagnosticsService';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { HomeStorageConfigStatus, HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';

const APP_VERSION_TEXT: string = '0.1.0 Beta';
const APP_BUILD_TEXT: string = 'Harmony Beta V1';

@Component
export struct MyPage {
  private loadRequestId: number = 0;
  @Prop @Watch('refreshPageData') refreshToken: number = 0;
  @State reviewerName: string = '';
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();
  @State reviewCount: number = 0;
  @State validReviewCount: number = 0;
  @State isRdbDiagnosticsRunning: boolean = false;
  @State rdbDiagnosticsSummary: string = '未运行';
  @State rdbDiagnosticsStatus: string = '开发';
  @State dataLoadFailed: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadData();
  }

  onPageShow(): void {
    this.reloadData();
  }

  refreshPageData(): void {
    this.reloadData();
  }

  private async reloadData(): Promise<void> {
    const requestId: number = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    const context = this.getAbilityContext();

    try {
      const historyItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
      if (requestId !== this.loadRequestId) {
        return;
      }
      const summary = ReviewProjectService.buildHomeSummary(historyItems);
      this.reviewCount = summary.recordCount;
      this.validReviewCount = summary.stats.validCount;
      this.dataLoadFailed = false;
    } catch (error) {
      if (requestId !== this.loadRequestId) {
        return;
      }
      this.dataLoadFailed = true;
    }

    this.reviewerName = await ReviewSettingsService.loadReviewerName(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.homeStorageSettings = await HomeStorageService.loadSettings(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
  }

  private resolveHomeStorageStatus(): HomeStorageConfigStatus {
    return HomeStorageService.getConfigurationStatus(this.homeStorageSettings);
  }

  private resolveReviewerSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
  }

  private resolveHomeStorageDetail(): string {
    if (this.resolveHomeStorageStatus() === HomeStorageConfigStatus.EMPTY) {
      return '未配置';
    }
    return `${this.homeStorageSettings.smbHost} · ${this.homeStorageSettings.smbShareName || '共享目录未填'}`;
  }

  private resolveSyncSummary(): string {
    return HomeStorageService.resolveEntryStatusLabel(this.resolveHomeStorageStatus());
  }

  private resolveHomeStorageBadge(): string {
    return HomeStorageService.resolveEntryStatusLabel(this.resolveHomeStorageStatus());
  }

  private resolveSyncBadge(): string {
    return HomeStorageService.resolveEntryStatusLabel(this.resolveHomeStorageStatus());
  }

  private resolveProfileName(): string {
    return this.resolveReviewerSummary();
  }

  private resolveReviewCountSummary(): string {
    if (this.dataLoadFailed) {
      return '复盘统计暂时无法刷新';
    }
    return `${this.reviewCount} 次复盘 · ${this.validReviewCount} 次成立`;
  }

  private openReviewerProfile(): void {
    router.pushUrl({ url: REVIEWER_PROFILE_PAGE });
  }

  private openHomeStorage(): void {
    router.pushUrl({ url: HOME_STORAGE_PAGE });
  }

  private openSyncCenter(): void {
    router.pushUrl({ url: SYNC_CENTER_PAGE });
  }

  private confirmRdbDeveloperDiagnostics(): void {
    if (this.isRdbDiagnosticsRunning) {
      return;
    }

    AlertDialog.show({
      title: '运行开发诊断？',
      message: '此入口仅用于开发期验证 RDB 与迁移链路，普通使用不需要运行。',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '运行',
        action: () => {
          this.runRdbDeveloperDiagnostics();
        }
      }
    });
  }

  private async runRdbDeveloperDiagnostics(): Promise<void> {
    if (this.isRdbDiagnosticsRunning) {
      return;
    }

    this.isRdbDiagnosticsRunning = true;
    this.rdbDiagnosticsSummary = '正在运行 RDB 旁路诊断';
    this.rdbDiagnosticsStatus = '运行中';
    try {
      const context = this.getAbilityContext();
      const rdbResult: RdbDiagnosticsResult = await ReviewCardRdbDiagnosticsService.runRdbDiagnostics(context);
      const migrationResult: RdbMigrationDiagnosticsResult =
        await ReviewCardRdbDiagnosticsService.runMigrationDiagnostics(context);
      const formattedRdbResult: string = ReviewCardRdbDiagnosticsService.formatDiagnosticsResult(rdbResult);
      const formattedMigrationResult: string = ReviewCardRdbDiagnosticsService.formatDiagnosticsResult(migrationResult);
      console.info(`[RDB开发诊断]\n${formattedRdbResult}\n\n[Preferences迁移诊断]\n${formattedMigrationResult}`);

      const isSuccess: boolean = rdbResult.success && migrationResult.success;
      const errorCount: number = rdbResult.errors.length + migrationResult.errors.length;
      this.rdbDiagnosticsStatus = isSuccess ? '通过' : '失败';
      this.rdbDiagnosticsSummary =
        `${isSuccess ? '通过' : '失败'} · RDB ${rdbResult.steps.length} 步 · 迁移 ${migrationResult.steps.length} 步 · 错误 ${errorCount}`;
      promptAction.showToast({ message: isSuccess ? 'RDB开发诊断通过' : 'RDB开发诊断失败，查看日志' });
    } catch (error) {
      this.rdbDiagnosticsStatus = '失败';
      this.rdbDiagnosticsSummary = `异常：${error}`;
      console.info(`[RDB开发诊断] exception=${error}`);
      promptAction.showToast({ message: 'RDB开发诊断异常，查看日志' });
    } finally {
      this.isRdbDiagnosticsRunning = false;
    }
  }

  @Builder
  LinkRow(title: string, value: string, onTap: () => void, status: string = '') {
    Row({ space: AppMetrics.cardGap }) {
      Column({ space: AppMetrics.space8 }) {
        Text(title)
          .fontSize(16)
          .fontWeight(600)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.cardTitleLineHeight)
          .width('100%')

        Text(value)
          .fontSize(13)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (status.length > 0) {
        Text(status)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(status === '已配置' || status === '可用' ? AppColors.tagGreenText
            : status === '待完善' ? AppColors.tagAmberText : AppColors.secondaryText)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor(status === '已配置' || status === '可用' ? AppColors.tagGreen
            : status === '待完善' ? AppColors.tagAmber : AppColors.surfaceMuted)
      }

      Text('›')
        .fontSize(18)
        .fontColor(AppColors.mutedText)
        .opacity(0.42)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .constraintSize({ minHeight: 74, maxHeight: 82 })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })

    .onClick(() => {
      onTap();
    })
  }

  @Builder
  IdentityCard() {
    Column({ space: AppMetrics.cardGap }) {
      Column({ space: 4 }) {
        Text('个人复盘资料')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.metaLineHeight)
          .width('100%')

        Text(this.resolveProfileName())
          .fontSize(AppTypography.profileName)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.profileNameLineHeight)
          .width('100%')

        Text(this.resolveReviewCountSummary())
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)

      Row({ space: AppMetrics.space16 }) {
        Column({ space: 2 }) {
          Text(`${this.reviewCount}`)
            .fontSize(AppTypography.statNumber)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .lineHeight(AppTypography.statNumberLineHeight)

          Text('累计复盘')
            .fontSize(12)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.statLabelLineHeight)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text(`${this.validReviewCount}`)
            .fontSize(AppTypography.statNumber)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .lineHeight(AppTypography.statNumberLineHeight)

          Text('成立记录')
            .fontSize(12)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.statLabelLineHeight)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .constraintSize({ minHeight: 148 })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.cardGap }) {
        AppPageHeader({
          title: '我的',
          subtitle: '管理复盘身份、同步方式和应用信息。'
        })

        this.IdentityCard()

        this.LinkRow('复盘人', this.resolveReviewerSummary(), () => {
          this.openReviewerProfile();
        })

        this.LinkRow(
          '家庭存储',
          this.resolveHomeStorageDetail(),
          () => {
            this.openHomeStorage();
          },
          this.resolveHomeStorageBadge()
        )

        this.LinkRow('同步中心', this.resolveSyncSummary(), () => {
          this.openSyncCenter();
        }, this.resolveSyncBadge())

        this.LinkRow('关于', `${APP_VERSION_TEXT} · ${APP_BUILD_TEXT}`, () => {
        })

        this.LinkRow(
          '开发诊断',
          this.isRdbDiagnosticsRunning ? '正在运行，仅用于开发验证' : `RDB 验证 · ${this.rdbDiagnosticsSummary}`,
          () => {
            this.confirmRdbDeveloperDiagnostics();
          },
          this.rdbDiagnosticsStatus
        )
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({
        left: AppMetrics.pagePadding,
        right: AppMetrics.pagePadding,
        top: AppMetrics.pageTopPadding,
        bottom: AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding + AppMetrics.space16
      })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
