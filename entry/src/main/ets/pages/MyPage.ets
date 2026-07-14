import common from '@ohos.app.ability.common';
import {
  HOME_HERO_IMAGE_PAGE,
  HOME_STORAGE_PAGE,
  MOTION_SETTINGS_PAGE,
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
import {
  ENABLE_RDB_DIAGNOSTICS_ENTRY,
  FEEDBACK_RDB_DIAG_EXCEPTION_TEXT,
  FEEDBACK_RDB_DIAG_FAILED_TEXT,
  FEEDBACK_RDB_DIAG_SUCCESS_TEXT
} from '../services/ReviewFlowFeedback';
import { HomeStorageConfigStatus, HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { HomeHeroImageService } from '../services/HomeHeroImageService';
import {
  MotionQuality,
  REVIEW_WIDGET_CARD_BACKGROUND_PLAIN,
  ReviewSettingsService
} from '../services/ReviewSettingsService';
import { ToastService, ToastTone } from '../services/ToastService';
import { DialogService, DialogTone } from '../services/DialogService';
import {
  ReviewLibraryBackupExportResult,
  ReviewLibraryBackupInspection,
  ReviewLibraryBackupRestoreResult,
  ReviewLibraryBackupService
} from '../services/ReviewLibraryBackupService';
import { RippleTouch } from '../components/motion/RippleTouch';

const APP_VERSION_TEXT: string = '0.1.0 Beta';
const APP_BUILD_TEXT: string = 'Harmony Beta V1';
const APP_AUTHOR_QQ_TEXT: string = '921086628';
const MY_PAGE_TITLE_CONTENT_GAP: number = AppMetrics.space10;
const MY_PAGE_BOTTOM_PADDING: number = AppMetrics.tabContentBottomPadding + AppMetrics.space16;
const ABOUT_INFO_CARD_HEIGHT: number = 108;

interface RippleSettingsLinkOptions {
  title: string;
  status: string;
  tone: SettingsEntryTone;
  onTap: () => void;
}

@Component
export struct MyPage {
  private loadRequestId: number = 0;
  @Prop @Watch('refreshPageData') refreshToken: number = 0;
  @State reviewerName: string = '';
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();
  @State homeHeroImageCount: number = 0;
  @State widgetCardBackgroundStyle: string = REVIEW_WIDGET_CARD_BACKGROUND_PLAIN;
  @State shatterAnimationEnabled: boolean = true;
  @State motionQuality: MotionQuality = MotionQuality.FULL;
  @State isRdbDiagnosticsRunning: boolean = false;
  @State rdbDiagnosticsSummary: string = '未运行';
  @State rdbDiagnosticsStatus: string = '开发';
  @State isDeveloperDiagnosticsPressed: boolean = false;
  @State backupItemTotal: number = 0;
  @State isBackupActionRunning: boolean = false;

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

    this.shatterAnimationEnabled = await ReviewSettingsService.loadShatterAnimationEnabled(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.motionQuality = await ReviewSettingsService.loadMotionQuality(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.backupItemTotal = await ReviewLibraryBackupService.countBackupItems(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
  }

  private formatBackupTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '未知时间';
    }
    const date = new Date(timestamp);
    const pad = (value: number): string => `${value}`.padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
  }

  private async exportLibraryBackup(): Promise<void> {
    if (this.isBackupActionRunning) {
      return;
    }
    this.isBackupActionRunning = true;
    try {
      const result: ReviewLibraryBackupExportResult =
        await ReviewLibraryBackupService.exportToUserFile(this.getAbilityContext());
      if (result.success) {
        ToastService.success(this.getUIContext(), result.message);
      } else if (!result.cancelled) {
        ToastService.error(this.getUIContext(), result.message);
      }
    } catch (error) {
      ToastService.error(this.getUIContext(), `备份失败：${error}`);
    } finally {
      this.isBackupActionRunning = false;
    }
  }

  private async selectLibraryBackup(): Promise<void> {
    if (this.isBackupActionRunning) {
      return;
    }
    this.isBackupActionRunning = true;
    try {
      const inspection: ReviewLibraryBackupInspection =
        await ReviewLibraryBackupService.selectAndInspectBackup(this.getAbilityContext());
      if (!inspection.success) {
        if (!inspection.cancelled) {
          ToastService.error(this.getUIContext(), inspection.message);
        }
        return;
      }
      const imageSummary: string = inspection.missingImageCount > 0
        ? `包含 ${inspection.imageCount} 张照片；旧版备份另有 ${inspection.missingImageCount} 张未包含。`
        : `包含 ${inspection.imageCount} 张照片。`;
      DialogService.confirm(this.getUIContext(), {
        title: `恢复 ${inspection.itemCount} 条复盘？`,
        message: `已选择 ${inspection.fileCount} 个备份，最新备份时间：${this.formatBackupTime(inspection.createdAt)}。${imageSummary}\n恢复后会替换当前 ${this.backupItemTotal} 条复盘，家庭存储密码不会恢复。`,
        cancelText: '取消',
        confirmText: '确认恢复',
        onConfirm: () => {
          this.restoreLibraryBackup(inspection);
        }
      });
    } catch (error) {
      ToastService.error(this.getUIContext(), `读取备份失败：${error}`);
    } finally {
      this.isBackupActionRunning = false;
    }
  }

  private async restoreLibraryBackup(inspection: ReviewLibraryBackupInspection): Promise<void> {
    if (this.isBackupActionRunning) {
      return;
    }
    this.isBackupActionRunning = true;
    try {
      const result: ReviewLibraryBackupRestoreResult =
        await ReviewLibraryBackupService.restoreInspectedBackup(this.getAbilityContext(), inspection);
      if (!result.success) {
        ToastService.error(this.getUIContext(), result.message);
        return;
      }
      ToastService.byTone(
        this.getUIContext(),
        result.message,
        result.settingsRestored ? ToastTone.SUCCESS : ToastTone.WARNING
      );
      await this.reloadData();
    } catch (error) {
      ToastService.error(this.getUIContext(), `恢复失败，当前数据未被替换：${error}`);
    } finally {
      this.isBackupActionRunning = false;
    }
  }

  private async toggleShatterAnimation(): Promise<void> {
    const next: boolean = !this.shatterAnimationEnabled;
    try {
      const saved: boolean = await ReviewSettingsService.saveShatterAnimationEnabled(this.getAbilityContext(), next);
      this.shatterAnimationEnabled = saved;
    } catch (error) {
      console.warn(`[MyPage] toggle shatter animation failed: ${error}`);
    }
  }

  private resolveShatterAnimationBadge(): string {
    return this.shatterAnimationEnabled ? '已开启' : '已关闭';
  }

  private resolveHomeStorageStatus(): HomeStorageConfigStatus {
    return HomeStorageService.getConfigurationStatus(this.homeStorageSettings);
  }

  private resolveReviewerSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
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

  private openMotionSettings(): void {
    this.getUIContext().getRouter().pushUrl({ url: MOTION_SETTINGS_PAGE }).catch((error: Error) => {
      console.error(`[MyPage] 打开显示与动效设置失败：${error.message}`);
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
      tone: DialogTone.PRIMARY,
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
      ToastService.byTone(this.getUIContext(),
        isSuccess ? FEEDBACK_RDB_DIAG_SUCCESS_TEXT : FEEDBACK_RDB_DIAG_FAILED_TEXT,
        isSuccess ? ToastTone.SUCCESS : ToastTone.ERROR);
    } catch (error) {
      this.rdbDiagnosticsStatus = '失败';
      this.rdbDiagnosticsSummary = `异常：${error}`;
      console.info(`[RDB开发诊断] exception=${error}`);
      ToastService.error(this.getUIContext(), FEEDBACK_RDB_DIAG_EXCEPTION_TEXT);
    } finally {
      this.isRdbDiagnosticsRunning = false;
    }
  }

  @Builder
  RippleSettingsLinkRowContent(options: RippleSettingsLinkOptions) {
    SettingsLinkRow({
      title: options.title,
      status: options.status,
      tone: options.tone,
      dense: true,
      scaleOnPress: false,
      onTap: options.onTap
    })
  }

  @Builder
  RippleSettingsLinkRow(options: RippleSettingsLinkOptions) {
    RippleTouch({
      content: () => {
        this.RippleSettingsLinkRowContent(options);
      }
    })
      .width('100%')
  }

  @Builder
  SettingsSection() {
    Column({ space: AppMetrics.cardGap }) {
      this.RippleSettingsLinkRow({
        title: '复盘人',
        status: this.resolveReviewerSummary(),
        tone: this.resolveReviewerSummary() === '未设置' ? SettingsEntryTone.MUTED : SettingsEntryTone.SUCCESS,
        onTap: () => {
          this.openReviewerProfile();
        }
      })

      this.RippleSettingsLinkRow({
        title: '首页图片',
        status: this.resolveHomeHeroBadge(),
        tone: this.homeHeroImageCount <= 0 ? SettingsEntryTone.MUTED : SettingsEntryTone.SUCCESS,
        onTap: () => {
          this.openHomeHeroImage();
        }
      })

      this.RippleSettingsLinkRow({
        title: '卡片背景',
        status: this.resolveWidgetCardBackgroundBadge(),
        tone: SettingsEntryTone.DEFAULT,
        onTap: () => {
          this.openWidgetCardBackground();
        }
      })

      this.RippleSettingsLinkRow({
        title: '显示与动效',
        status: ReviewSettingsService.resolveMotionQualityLabel(this.motionQuality),
        tone: SettingsEntryTone.DEFAULT,
        onTap: () => {
          this.openMotionSettings();
        }
      })

      this.RippleSettingsLinkRow({
        title: '删除星河效果',
        status: this.resolveShatterAnimationBadge(),
        tone: this.shatterAnimationEnabled ? SettingsEntryTone.SUCCESS : SettingsEntryTone.MUTED,
        onTap: () => {
          this.toggleShatterAnimation();
        }
      })

      this.RippleSettingsLinkRow({
        title: '家庭存储',
        status: this.resolveHomeStorageBadge(),
        tone: this.resolveStorageTone(),
        onTap: () => {
          this.openHomeStorage();
        }
      })

      this.RippleSettingsLinkRow({
        title: '同步中心',
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
  DataProtectionSection() {
    Column({ space: AppMetrics.cardGap }) {
      this.RippleSettingsLinkRow({
        title: '备份全部复盘',
        status: this.isBackupActionRunning ? '处理中' : `${this.backupItemTotal} 条`,
        tone: this.backupItemTotal > 0 ? SettingsEntryTone.SUCCESS : SettingsEntryTone.MUTED,
        onTap: () => {
          this.exportLibraryBackup();
        }
      })

      this.RippleSettingsLinkRow({
        title: '从备份恢复',
        status: this.isBackupActionRunning ? '处理中' : '选择文件',
        tone: SettingsEntryTone.DEFAULT,
        onTap: () => {
          this.selectLibraryBackup();
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  AboutSection() {
    Column({ space: AppMetrics.cardGap }) {
      this.AboutInfoCard()

      if (ENABLE_RDB_DIAGNOSTICS_ENTRY) {
        this.DeveloperDiagnosticsCard()
      }
    }
    .width('100%')
  }

  @Builder
  AboutInfoCard() {
    Column({ space: AppMetrics.space8 }) {
      Text('关于')
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.bodyLineHeight)
        .width('100%')

      this.AboutField('版本', `${APP_VERSION_TEXT} · ${APP_BUILD_TEXT}`)

      this.AboutField('作者 QQ', APP_AUTHOR_QQ_TEXT)
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: AppMetrics.cardPadding,
      right: AppMetrics.cardPadding,
      top: AppMetrics.space10,
      bottom: AppMetrics.space10
    })
    .width('100%')
    .height(ABOUT_INFO_CARD_HEIGHT)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  AboutField(label: string, value: string) {
    Row({ space: AppMetrics.space10 }) {
      Text(label)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.captionLineHeight)
        .maxLines(1)

      Text(value)
        .fontSize(AppTypography.caption)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.captionLineHeight)
        .textAlign(TextAlign.End)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
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

        Text(this.isRdbDiagnosticsRunning ? '正在运行' : this.rdbDiagnosticsSummary)
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
      AppPageHeader({
        title: '我的'
      })
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: AppMetrics.pageTopPadding,
          bottom: MY_PAGE_TITLE_CONTENT_GAP
        })

      Scroll() {
        Column({ space: AppMetrics.sectionGap }) {
          this.SettingsSection()

          this.DataProtectionSection()

          this.AboutSection()
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          bottom: MY_PAGE_BOTTOM_PADDING
        })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
