import common from '@ohos.app.ability.common';
import {
  APPEARANCE_SETTINGS_PAGE,
  BACKUP_CENTER_PAGE,
  HOME_STORAGE_PAGE,
  REVIEWER_PROFILE_PAGE,
  SYNC_CENTER_PAGE
} from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  SettingsEntryTone,
  SettingsLinkRow
} from '../components/AppDesign';
import { RippleTouch } from '../components/motion/RippleTouch';
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
import { MotionQuality, ReviewSettingsService } from '../services/ReviewSettingsService';
import { ReviewLibraryBackupService } from '../services/ReviewLibraryBackupService';
import { ToastService, ToastTone } from '../services/ToastService';
import { DialogService, DialogTone } from '../services/DialogService';

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
  @State motionQuality: MotionQuality = MotionQuality.FULL;
  @State shatterAnimationEnabled: boolean = true;
  @State backupItemTotal: number = 0;
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
    const context: common.UIAbilityContext = this.getAbilityContext();

    this.reviewerName = await ReviewSettingsService.loadReviewerName(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.homeStorageSettings = await HomeStorageService.loadSettings(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.motionQuality = await ReviewSettingsService.loadMotionQuality(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.shatterAnimationEnabled = await ReviewSettingsService.loadShatterAnimationEnabled(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
    this.backupItemTotal = await ReviewLibraryBackupService.countBackupItems(context);
  }

  private resolveReviewerSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
  }

  private resolveAppearanceSummary(): string {
    const quality: string = ReviewSettingsService.resolveMotionQualityLabel(this.motionQuality);
    return `${quality} · ${this.shatterAnimationEnabled ? '星河开' : '星河关'}`;
  }

  private resolveHomeStorageBadge(): string {
    return HomeStorageService.resolveEntryStatusLabel(
      HomeStorageService.getConfigurationStatus(this.homeStorageSettings)
    );
  }

  private resolveStorageTone(): SettingsEntryTone {
    const status: HomeStorageConfigStatus = HomeStorageService.getConfigurationStatus(this.homeStorageSettings);
    if (status === HomeStorageConfigStatus.COMPLETE) {
      return SettingsEntryTone.SUCCESS;
    }
    if (status === HomeStorageConfigStatus.PARTIAL) {
      return SettingsEntryTone.WARNING;
    }
    return SettingsEntryTone.MUTED;
  }

  private openPage(url: string, failureMessage: string): void {
    this.getUIContext().getRouter().pushUrl({ url }).catch((error: Error) => {
      console.error(`[MyPage] ${failureMessage}：${error.message}`);
    });
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
      const context: common.UIAbilityContext = this.getAbilityContext();
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
      ToastService.byTone(
        this.getUIContext(),
        isSuccess ? FEEDBACK_RDB_DIAG_SUCCESS_TEXT : FEEDBACK_RDB_DIAG_FAILED_TEXT,
        isSuccess ? ToastTone.SUCCESS : ToastTone.ERROR
      );
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
  ReviewerCardContent() {
    Row({ space: AppMetrics.cardGap }) {
      Column({ space: AppMetrics.space4 }) {
        Text('复盘人')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')

        Text(this.resolveReviewerSummary())
          .fontSize(AppTypography.cardTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.cardTitleLineHeight)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(20)
        .fontColor(AppColors.primary)
        .opacity(0.7)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .constraintSize({ minHeight: 76 })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.primarySoft)
    .border({ width: 1, color: AppColors.primary })
    .shadow(ElevationTokens.low)
    .onClick(() => {
      this.openPage(REVIEWER_PROFILE_PAGE, '打开复盘人设置失败');
    })
  }

  @Builder
  ReviewerCard() {
    RippleTouch({
      clipRadius: AppMetrics.cardRadius,
      content: () => {
        this.ReviewerCardContent();
      }
    })
      .width('100%')
  }

  @Builder
  RippleSettingsLinkRow(options: RippleSettingsLinkOptions) {
    RippleTouch({
      clipRadius: AppMetrics.cardRadius,
      content: () => {
        SettingsLinkRow({
          title: options.title,
          status: options.status,
          tone: options.tone,
          dense: true,
          scaleOnPress: false,
          onTap: options.onTap
        })
      }
    })
      .width('100%')
  }

  @Builder
  SettingsSection() {
    Column({ space: AppMetrics.cardGap }) {
      this.ReviewerCard()

      this.RippleSettingsLinkRow({
        title: '外观与动效',
        status: this.resolveAppearanceSummary(),
        tone: SettingsEntryTone.DEFAULT,
        onTap: () => {
          this.openPage(APPEARANCE_SETTINGS_PAGE, '打开外观与动效失败');
        }
      })

      this.RippleSettingsLinkRow({
        title: '家庭存储',
        status: this.resolveHomeStorageBadge(),
        tone: this.resolveStorageTone(),
        onTap: () => {
          this.openPage(HOME_STORAGE_PAGE, '打开家庭存储设置失败');
        }
      })

      this.RippleSettingsLinkRow({
        title: '同步中心',
        status: this.resolveHomeStorageBadge(),
        tone: this.resolveStorageTone(),
        onTap: () => {
          this.openPage(SYNC_CENTER_PAGE, '打开同步中心失败');
        }
      })

      this.RippleSettingsLinkRow({
        title: '备份与恢复',
        status: `${this.backupItemTotal} 条`,
        tone: this.backupItemTotal > 0 ? SettingsEntryTone.SUCCESS : SettingsEntryTone.MUTED,
        onTap: () => {
          this.openPage(BACKUP_CENTER_PAGE, '打开备份与恢复失败');
        }
      })
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
      Column({ space: AppMetrics.space4 }) {
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

  build() {
    Column() {
      AppPageHeader({ title: '我的' })
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: AppMetrics.pageTopPadding,
          bottom: MY_PAGE_TITLE_CONTENT_GAP
        })

      Scroll() {
        Column({ space: AppMetrics.sectionGap }) {
          this.SettingsSection()
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
