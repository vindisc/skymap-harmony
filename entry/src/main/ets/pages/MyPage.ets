import common from '@ohos.app.ability.common';
import {
  HOME_HERO_IMAGE_PAGE,
  HOME_STORAGE_PAGE,
  REVIEWER_PROFILE_PAGE,
  SYNC_CENTER_PAGE,
  WIDGET_CARD_BACKGROUND_PAGE
} from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  SettingsEntryTone,
  SettingsLinkRow
} from '../components/AppDesign';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';
import {
  RdbDiagnosticsResult,
  RdbMigrationDiagnosticsResult,
  ReviewCardRdbDiagnosticsService
} from '../services/ReviewCardRdbDiagnosticsService';
import { ENABLE_RDB_DIAGNOSTICS_ENTRY } from '../services/ReviewFlowFeedback';
import { HomeStorageConfigStatus, HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { HomeHeroImageService } from '../services/HomeHeroImageService';
import { REVIEW_WIDGET_CARD_BACKGROUND_PLAIN, ReviewSettingsService } from '../services/ReviewSettingsService';
import { ToastService } from '../services/ToastService';
import { DialogService } from '../services/DialogService';

const APP_VERSION_TEXT: string = '0.1.0 Beta';
const APP_BUILD_TEXT: string = 'Harmony Beta V1';
const MY_PAGE_TITLE_CONTENT_GAP: number = AppMetrics.space10;
const MY_PAGE_BOTTOM_PADDING: number = AppMetrics.tabContentBottomPadding + AppMetrics.space16;

@Component
export struct MyPage {
  private loadRequestId: number = 0;
  @Prop @Watch('refreshPageData') refreshToken: number = 0;
  @State reviewerName: string = '';
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();
  @State homeHeroImageCount: number = 0;
  @State widgetCardBackgroundStyle: string = REVIEW_WIDGET_CARD_BACKGROUND_PLAIN;
  @State isRdbDiagnosticsRunning: boolean = false;
  @State rdbDiagnosticsSummary: string = '未运行';
  @State rdbDiagnosticsStatus: string = '开发';
  @State isDeveloperDiagnosticsPressed: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
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

    this.reviewerName = await ReviewSettingsService.loadReviewerName(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.widgetCardBackgroundStyle = await ReviewSettingsService.loadWidgetCardBackgroundStyle(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.homeStorageSettings = await HomeStorageService.loadSettings(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.homeHeroImageCount = (await HomeHeroImageService.listImages(context)).length;
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

  private resolveHomeHeroSummary(): string {
    if (this.homeHeroImageCount <= 0) {
      return '使用默认首页图';
    }
    if (this.homeHeroImageCount === 1) {
      return '已设置 1 张图片';
    }
    return `已设置 ${this.homeHeroImageCount} 张图片，会自动轮播`;
  }

  private resolveHomeHeroBadge(): string {
    return this.homeHeroImageCount <= 0 ? '默认' : `${this.homeHeroImageCount} 张`;
  }

  private resolveWidgetCardBackgroundBadge(): string {
    return ReviewSettingsService.resolveWidgetCardBackgroundLabel(this.widgetCardBackgroundStyle);
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

  private resolveDeveloperStatusTextColor(): string {
    if (this.rdbDiagnosticsStatus === '通过') {
      return AppColors.tagGreenText;
    }
    if (this.rdbDiagnosticsStatus === '失败') {
      return AppColors.danger;
    }
    if (this.rdbDiagnosticsStatus === '运行中') {
      return AppColors.tagAmberText;
    }
    return AppColors.secondaryText;
  }

  private resolveDeveloperStatusBackground(): string {
    if (this.rdbDiagnosticsStatus === '通过') {
      return AppColors.tagGreen;
    }
    if (this.rdbDiagnosticsStatus === '失败') {
      return AppColors.dangerSoft;
    }
    if (this.rdbDiagnosticsStatus === '运行中') {
      return AppColors.tagAmber;
    }
    return AppColors.surfaceMuted;
  }

  private updateDeveloperDiagnosticsPressed(event: TouchEvent): void {
    if (this.isRdbDiagnosticsRunning) {
      this.isDeveloperDiagnosticsPressed = false;
      return;
    }
    if (event.type === TouchType.Down) {
      this.isDeveloperDiagnosticsPressed = true;
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.isDeveloperDiagnosticsPressed = false;
    }
  }

  private openReviewerProfile(): void {
    this.getUIContext().getRouter().pushUrl({ url: REVIEWER_PROFILE_PAGE }).catch((error: Error) => {
      console.error(`[MyPage] 打开复盘人设置失败：${error.message}`);
    });
  }

  private openHomeHeroImage(): void {
    this.getUIContext().getRouter().pushUrl({ url: HOME_HERO_IMAGE_PAGE }).catch((error: Error) => {
      console.error(`[MyPage] 打开首页图片设置失败：${error.message}`);
    });
  }

  private openHomeStorage(): void {
    this.getUIContext().getRouter().pushUrl({ url: HOME_STORAGE_PAGE }).catch((error: Error) => {
      console.error(`[MyPage] 打开家庭存储设置失败：${error.message}`);
    });
  }

  private openWidgetCardBackground(): void {
    this.getUIContext().getRouter().pushUrl({ url: WIDGET_CARD_BACKGROUND_PAGE }).catch((error: Error) => {
      console.error(`[MyPage] 打开卡片背景设置失败：${error.message}`);
    });
  }

  private openSyncCenter(): void {
    this.getUIContext().getRouter().pushUrl({ url: SYNC_CENTER_PAGE }).catch((error: Error) => {
      console.error(`[MyPage] 打开同步中心失败：${error.message}`);
    });
  }

  private confirmRdbDeveloperDiagnostics(): void {
    if (this.isRdbDiagnosticsRunning) {
      return;
    }

    DialogService.confirm(this.getUIContext(), {
      title: '运行开发诊断？',
      message: '此入口仅用于开发期验证 RDB 与迁移链路，普通使用不需要运行。',
      cancelText: '取消',
      confirmText: '运行',
      onConfirm: () => {
        this.runRdbDeveloperDiagnostics();
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
      ToastService.show(this.getUIContext(), isSuccess ? 'RDB开发诊断通过' : 'RDB开发诊断失败，查看日志');
    } catch (error) {
      this.rdbDiagnosticsStatus = '失败';
      this.rdbDiagnosticsSummary = `异常：${error}`;
      console.info(`[RDB开发诊断] exception=${error}`);
      ToastService.show(this.getUIContext(), 'RDB开发诊断异常，查看日志');
    } finally {
      this.isRdbDiagnosticsRunning = false;
    }
  }

  @Builder
  SettingsSection() {
    Column({ space: AppMetrics.cardGap }) {
      SettingsLinkRow({
        title: '复盘人',
        value: this.resolveReviewerSummary(),
        status: this.resolveReviewerSummary() === '未设置' ? '未设置' : '已设置',
        tone: this.resolveReviewerSummary() === '未设置' ? SettingsEntryTone.MUTED : SettingsEntryTone.SUCCESS,
        dense: true,
        onTap: () => {
          this.openReviewerProfile();
        }
      })

      SettingsLinkRow({
        title: '首页图片',
        value: this.resolveHomeHeroSummary(),
        status: this.resolveHomeHeroBadge(),
        tone: this.homeHeroImageCount <= 0 ? SettingsEntryTone.MUTED : SettingsEntryTone.SUCCESS,
        dense: true,
        onTap: () => {
          this.openHomeHeroImage();
        }
      })

      SettingsLinkRow({
        title: '卡片背景',
        status: this.resolveWidgetCardBackgroundBadge(),
        tone: SettingsEntryTone.DEFAULT,
        dense: true,
        onTap: () => {
          this.openWidgetCardBackground();
        }
      })

      SettingsLinkRow({
        title: '家庭存储',
        value: this.resolveHomeStorageDetail(),
        status: this.resolveHomeStorageBadge(),
        tone: this.resolveStorageTone(),
        dense: true,
        onTap: () => {
          this.openHomeStorage();
        }
      })

      SettingsLinkRow({
        title: '同步中心',
        value: this.resolveSyncSummary(),
        status: this.resolveSyncBadge(),
        tone: this.resolveStorageTone(),
        dense: true,
        onTap: () => {
          this.openSyncCenter();
        }
      })
    }
    .width('100%')
  }

  @Builder
  AboutSection() {
    Column({ space: AppMetrics.cardGap }) {
      this.VersionInfoCard()

      if (ENABLE_RDB_DIAGNOSTICS_ENTRY) {
        this.DeveloperDiagnosticsCard()
      }
    }
    .width('100%')
  }

  @Builder
  VersionInfoCard() {
    Column({ space: 4 }) {
      Text('版本')
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.bodyLineHeight)
        .width('100%')

      Text(`${APP_VERSION_TEXT} · ${APP_BUILD_TEXT}`)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.captionLineHeight)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: AppMetrics.cardPadding,
      right: AppMetrics.cardPadding,
      top: AppMetrics.space10,
      bottom: AppMetrics.space10
    })
    .width('100%')
    .height(60)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  DeveloperDiagnosticsCard() {
    Row({ space: AppMetrics.cardGap }) {
      Column({ space: 4 }) {
        Text('开发诊断')
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.tagAmberText)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
          .maxLines(1)

        Text(this.isRdbDiagnosticsRunning ? '正在运行，仅用于开发验证' : `RDB 验证 · ${this.rdbDiagnosticsSummary}`)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.rdbDiagnosticsStatus)
        .fontSize(AppTypography.meta)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveDeveloperStatusTextColor())
        .lineHeight(AppTypography.metaLineHeight)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(AppMetrics.capsuleRadius)
        .backgroundColor(this.resolveDeveloperStatusBackground())
        .maxLines(1)

      Text('›')
        .fontSize(18)
        .fontColor(AppColors.tagAmberText)
        .opacity(0.5)
    }
    .alignItems(VerticalAlign.Center)
    .padding({
      left: AppMetrics.cardPadding,
      right: AppMetrics.cardPadding,
      top: AppMetrics.space10,
      bottom: AppMetrics.space10
    })
    .width('100%')
    .height(68)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(this.isDeveloperDiagnosticsPressed ? AppColors.surfaceMuted : AppColors.tagAmber)
    .border({ width: 1, color: AppColors.tagAmberText })
    .shadow(this.isDeveloperDiagnosticsPressed ? ElevationTokens.medium : ElevationTokens.subtle)
    .scale({
      x: this.isDeveloperDiagnosticsPressed ? MotionTokens.scaleSubtle : 1,
      y: this.isDeveloperDiagnosticsPressed ? MotionTokens.scaleSubtle : 1
    })
    .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
    .opacity(this.isRdbDiagnosticsRunning ? 0.72 : 1)
    .onTouch((event: TouchEvent) => {
      this.updateDeveloperDiagnosticsPressed(event);
    })
    .onClick(() => {
      this.confirmRdbDeveloperDiagnostics();
    })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          AppPageHeader({
            title: '我的'
          })

          Column({ space: AppMetrics.sectionGap }) {
            this.SettingsSection()

            this.AboutSection()
          }
          .width('100%')
          .margin({ top: MY_PAGE_TITLE_CONTENT_GAP })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: AppMetrics.pageTopPadding,
          bottom: MY_PAGE_BOTTOM_PADDING
        })
        .height('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
