import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { HOME_HERO_IMAGE_PAGE, REVIEWER_PROFILE_PAGE } from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  SettingsEntryTone,
  SettingsLinkRow,
  SettingsSectionHeader
} from '../components/AppDesign';
import {
  RdbDiagnosticsResult,
  RdbMigrationDiagnosticsResult,
  ReviewCardRdbDiagnosticsService
} from '../services/ReviewCardRdbDiagnosticsService';
import { ENABLE_RDB_DIAGNOSTICS_ENTRY } from '../services/ReviewFlowFeedback';
import { HomeHeroImageService } from '../services/HomeHeroImageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';

const APP_VERSION_TEXT: string = '0.2.0 Beta';
const APP_BUILD_TEXT: string = 'Harmony Beta 0.2';
const MY_PAGE_TITLE_CONTENT_GAP: number = AppMetrics.space10;
const MY_PAGE_BOTTOM_PADDING: number = AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding + AppMetrics.space16;

@Component
export struct MyPage {
  private loadRequestId: number = 0;
  @Prop @Watch('refreshPageData') refreshToken: number = 0;
  @State reviewerName: string = '';
  @State homeHeroImageCount: number = 0;
  @State isRdbDiagnosticsRunning: boolean = false;
  @State rdbDiagnosticsSummary: string = '未运行';
  @State rdbDiagnosticsStatus: string = '开发';

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

    this.reviewerName = await ReviewSettingsService.loadReviewerName(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.homeHeroImageCount = (await HomeHeroImageService.listImages(context)).length;
    if (requestId !== this.loadRequestId) {
      return;
    }
  }

  private resolveReviewerSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
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

  private openReviewerProfile(): void {
    router.pushUrl({ url: REVIEWER_PROFILE_PAGE });
  }

  private openHomeHeroImage(): void {
    router.pushUrl({ url: HOME_HERO_IMAGE_PAGE });
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
  SettingsSection() {
    Column({ space: AppMetrics.cardGap }) {
      SettingsSectionHeader({
        title: '设置'
      })

      SettingsLinkRow({
        title: '复盘人',
        value: this.resolveReviewerSummary() === '未设置' ? '新建复盘会使用默认空名称' : this.resolveReviewerSummary(),
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

    }
    .width('100%')
  }

  @Builder
  AboutSection() {
    Column({ space: AppMetrics.cardGap }) {
      SettingsSectionHeader({
        title: '应用'
      })

      SettingsLinkRow({
        title: '版本',
        value: `${APP_VERSION_TEXT} · ${APP_BUILD_TEXT}`,
        status: '',
        tone: SettingsEntryTone.MUTED,
        showChevron: false,
        dense: true,
        onTap: () => {
        }
      })

      if (ENABLE_RDB_DIAGNOSTICS_ENTRY) {
        SettingsLinkRow({
          title: '开发诊断',
          value: this.isRdbDiagnosticsRunning ? '正在运行，仅用于开发验证' : `RDB 验证 · ${this.rdbDiagnosticsSummary}`,
          status: this.rdbDiagnosticsStatus,
          tone: this.resolveDeveloperTone(),
          dense: true,
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
