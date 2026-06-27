import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { HOME_STORAGE_PAGE, REVIEWER_PROFILE_PAGE, SYNC_CENTER_PAGE } from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  SettingsEntryTone,
  SettingsLinkRow,
  SettingsSectionHeader
} from '../components/AppDesign';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import {
  RdbDiagnosticsResult,
  RdbMigrationDiagnosticsResult,
  ReviewCardRdbDiagnosticsService
} from '../services/ReviewCardRdbDiagnosticsService';
import { ENABLE_RDB_DIAGNOSTICS_ENTRY } from '../services/ReviewFlowFeedback';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { HomeStorageConfigStatus, HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';

const APP_VERSION_TEXT: string = '0.1.0 Beta';
const APP_BUILD_TEXT: string = 'Harmony Beta V1';
const MY_PAGE_BOTTOM_PADDING: number = AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding + AppMetrics.space16;

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

  private resolveStorageTone(): SettingsEntryTone {
    const status: HomeStorageConfigStatus = this.resolveHomeStorageStatus();
    if (status === HomeStorageConfigStatus.COMPLETE) {
      return SettingsEntryTone.SUCCESS;
    }
    if (status === HomeStorageConfigStatus.PARTIAL) {
      return SettingsEntryTone.WARNING;
    }
    return SettingsEntryTone.MUTED;
  }

  private resolveDeveloperTone(): SettingsEntryTone {
    if (this.rdbDiagnosticsStatus === '通过') {
      return SettingsEntryTone.SUCCESS;
    }
    if (this.rdbDiagnosticsStatus === '失败') {
      return SettingsEntryTone.DANGER;
    }
    if (this.rdbDiagnosticsStatus === '运行中') {
      return SettingsEntryTone.WARNING;
    }
    return SettingsEntryTone.MUTED;
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
  IdentityCard() {
    Column({ space: AppMetrics.space16 }) {
      Column({ space: 4 }) {
        Text('当前复盘人')
          .fontSize(AppTypography.meta)
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
        Column({ space: 4 }) {
          Text(`${this.reviewCount}`)
            .fontSize(AppTypography.sectionTitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .lineHeight(AppTypography.sectionTitleLineHeight)

          Text('累计复盘')
            .fontSize(AppTypography.meta)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.metaLineHeight)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text(`${this.validReviewCount}`)
            .fontSize(AppTypography.sectionTitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .lineHeight(AppTypography.sectionTitleLineHeight)

          Text('成立记录')
            .fontSize(AppTypography.meta)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.metaLineHeight)
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

  @Builder
  SettingsSection() {
    Column({ space: AppMetrics.space8 }) {
      SettingsSectionHeader({
        title: '设置',
        description: '影响新建复盘、导出和家庭存储连接。'
      })

      SettingsLinkRow({
        title: '复盘人',
        value: this.resolveReviewerSummary() === '未设置' ? '新建复盘会使用默认空名称' : this.resolveReviewerSummary(),
        status: this.resolveReviewerSummary() === '未设置' ? '未设置' : '已设置',
        tone: this.resolveReviewerSummary() === '未设置' ? SettingsEntryTone.MUTED : SettingsEntryTone.SUCCESS,
        onTap: () => {
          this.openReviewerProfile();
        }
      })

      SettingsLinkRow({
        title: '家庭存储',
        value: this.resolveHomeStorageDetail(),
        status: this.resolveHomeStorageBadge(),
        tone: this.resolveStorageTone(),
        onTap: () => {
          this.openHomeStorage();
        }
      })

      SettingsLinkRow({
        title: '同步中心',
        value: '管理家庭存储连接，后续承接批量同步。',
        status: this.resolveSyncBadge(),
        tone: this.resolveStorageTone(),
        onTap: () => {
          this.openSyncCenter();
        }
      })
    }
    .width('100%')
  }

  @Builder
  AboutSection() {
    Column({ space: AppMetrics.space8 }) {
      SettingsSectionHeader({
        title: '应用',
        description: ''
      })

      SettingsLinkRow({
        title: '版本',
        value: `${APP_VERSION_TEXT} · ${APP_BUILD_TEXT}`,
        status: '',
        tone: SettingsEntryTone.MUTED,
        showChevron: false,
        onTap: () => {
        }
      })

      if (ENABLE_RDB_DIAGNOSTICS_ENTRY) {
        SettingsLinkRow({
          title: '开发诊断',
          value: this.isRdbDiagnosticsRunning ? '正在运行，仅用于开发验证' : `RDB 验证 · ${this.rdbDiagnosticsSummary}`,
          status: this.rdbDiagnosticsStatus,
          tone: this.resolveDeveloperTone(),
          onTap: () => {
            this.confirmRdbDeveloperDiagnostics();
          }
        })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      Column() {
        AppPageHeader({
          title: '我的',
          subtitle: '复盘身份、存储同步和应用状态。'
        })
      }
      .padding({
        left: AppMetrics.pagePadding,
        right: AppMetrics.pagePadding,
        top: AppMetrics.pageTopPadding,
        bottom: 0
      })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(AppColors.pageBackground)

      Scroll() {
        Column({ space: AppMetrics.sectionGap }) {
          this.IdentityCard()

          this.SettingsSection()

          this.AboutSection()
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: AppMetrics.sectionGap,
          bottom: MY_PAGE_BOTTOM_PADDING
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
