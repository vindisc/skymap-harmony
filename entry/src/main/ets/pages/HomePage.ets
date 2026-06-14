import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import {
  EDITOR_PAGE,
  PREVIEW_PAGE
} from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import {
  ReviewProjectSummary,
  createDefaultProjectSummary
} from '../model/ProjectModel';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { ReviewDashboardStats } from '../services/ReviewProjectService';
import { HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  EmptyState,
  PrimaryButton,
  RecentReviewCard,
  SecondaryButton
} from '../components/AppDesign';

@Component
export struct HomePage {
  private reloadRequestId: number = 0;
  @Prop @Watch('refreshHomeData') refreshToken: number = 0;
  @State isPickingPhoto: boolean = false;
  @State projectSummary: ReviewProjectSummary = createDefaultProjectSummary();
  @State dashboardStats: ReviewDashboardStats = {
    streakDays: 0
  };
  @State reviewerName: string = '';
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();
  @State historyLoadFailed: boolean = false;

  aboutToAppear(): void {
    this.reloadHistory();
  }

  onPageShow(): void {
    this.reloadHistory();
  }

  refreshHomeData(): void {
    this.reloadHistory();
  }

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private hasMeaningfulCurrentDocument(document: ReviewCardDocument): boolean {
    return document.imageUri.length > 0 ||
      document.content.visualFocus.length > 0 ||
      document.content.focusReason.length > 0 ||
      document.content.visualPath.length > 0 ||
      document.content.visibleFacts.length > 0 ||
      document.content.coreRelation.length > 0 ||
      document.content.extendedUnderstanding.length > 0 ||
      document.content.currentBlocker.length > 0;
  }

  private async reloadHistory(): Promise<void> {
    const requestId: number = this.reloadRequestId + 1;
    this.reloadRequestId = requestId;
    const context = this.getAbilityContext();

    const currentDocument = ReviewCardStore.getCurrentDocument();
    if (this.hasMeaningfulCurrentDocument(currentDocument)) {
      this.applyHomeData([
        {
          document: currentDocument,
          exportedPath: ''
        }
      ]);
    }

    try {
      const items: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
      if (requestId !== this.reloadRequestId) {
        return;
      }
      this.historyLoadFailed = false;
      this.applyHomeData(items);
    } catch (error) {
      if (requestId === this.reloadRequestId) {
        this.historyLoadFailed = true;
      }
      return;
    }

    const reviewerName: string = await ReviewSettingsService.loadReviewerName(context);
    if (requestId !== this.reloadRequestId) {
      return;
    }
    this.reviewerName = reviewerName;

    const homeStorageSettings: HomeStorageSettings = await HomeStorageService.loadSettings(context);
    if (requestId !== this.reloadRequestId) {
      return;
    }
    this.homeStorageSettings = homeStorageSettings;
  }

  private applyHomeData(items: Array<ReviewCardHistoryItem>): void {
    this.projectSummary = ReviewProjectService.buildHomeSummary(items);
    this.dashboardStats = ReviewProjectService.buildDashboardStats(items);
  }

  private openLatestReview(): void {
    if (!this.projectSummary.latestItem) {
      return;
    }
    ReviewCardStore.setCurrentDocument(this.projectSummary.latestItem.document);
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  private continueLatestReview(): void {
    if (!this.projectSummary.latestItem) {
      return;
    }
    ReviewCardStore.setCurrentDocument(this.projectSummary.latestItem.document);
    router.pushUrl({ url: EDITOR_PAGE });
  }

  private async startPhotoDraft(): Promise<void> {
    if (this.isPickingPhoto) {
      return;
    }

    this.isPickingPhoto = true;
    const result: PickedPhotoResult = await pickSinglePhoto();
    this.isPickingPhoto = false;

    if (!result.success) {
      if (!result.cancelled && result.message.length > 0) {
        promptAction.showToast({ message: result.message });
      }
      return;
    }

    ReviewCardStore.createPhotoDraft(
      result.imageUri,
      result.imageWidth,
      result.imageHeight,
      result.imageSizeFallbackUsed
    );
    router.pushUrl({ url: EDITOR_PAGE });
  }

  private isHomeStorageConfigured(): boolean {
    return HomeStorageService.validateSettings(this.homeStorageSettings).length === 0;
  }

  private resolveSyncStatusText(): string {
    return this.isHomeStorageConfigured() ? '已配置' : '未配置';
  }

  private resolveSettingsSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
  }

  private resolveStreakText(): string {
    if (this.projectSummary.recordCount === 0 || this.dashboardStats.streakDays <= 0) {
      return '—';
    }
    return `${this.dashboardStats.streakDays}天`;
  }

  private resolveStatsHintText(): string {
    if (this.historyLoadFailed) {
      return '历史记录暂时读取失败，请重新进入首页或重启应用再试。';
    }
    return this.projectSummary.recordCount > 0 ? '每一次判断都会留下可回看的线索。' : '还没有记录，第一条复盘会从这里开始。';
  }

  @Builder
  StatItem(value: string, label: string, emphasized: boolean = false) {
    Column({ space: AppMetrics.space8 }) {
      Text(value)
        .fontSize((emphasized || label === '总复盘') ? AppTypography.statNumber + 4 : AppTypography.statNumber)
        .fontWeight(FontWeight.Bold)
        .fontColor((emphasized || label === '总复盘') ? AppColors.primary : AppColors.text)
        .lineHeight((emphasized || label === '总复盘') ? AppTypography.statNumberLineHeight + 4 : AppTypography.statNumberLineHeight)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(label)
        .fontSize(AppTypography.statLabel)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.statLabelLineHeight)
        .maxLines(1)
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  GrowthStatsPanel() {
    Column({ space: AppMetrics.cardGap }) {
      Row() {
        Text('复盘概览')
          .fontSize(AppTypography.sectionTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.sectionTitleLineHeight)

        Blank()

        Text(this.resolveStatsHintText())
          .fontSize(AppTypography.meta)
          .fontColor(this.historyLoadFailed ? AppColors.tagAmberText : AppColors.secondaryText)
          .lineHeight(AppTypography.metaLineHeight)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Row({ space: AppMetrics.space8 }) {
        this.StatItem(`${this.projectSummary.recordCount}`, '总复盘')
        this.StatItem(`${this.projectSummary.stats.validCount}`, '成立')
        this.StatItem(`${this.projectSummary.stats.unsureCount}`, '待判断')
        this.StatItem(this.resolveStreakText(), '连续')
      }
      .width('100%')
    }
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(this.historyLoadFailed ? AppColors.tagAmber : AppColors.surface)
    .border({ width: 1, color: this.historyLoadFailed ? AppColors.tagAmberText : AppColors.border })
  }

  @Builder
  StartReviewPanel() {
    Column({ space: AppMetrics.cardGap }) {
      Column({ space: AppMetrics.space8 }) {
        Text('开始新的复盘')
          .fontSize(AppTypography.cardTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.cardTitleLineHeight)
          .width('100%')

        Text('继续训练你的摄影判断。')
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      PrimaryButton({
        label: this.isPickingPhoto ? '打开相册中...' : '开始复盘',
        isDisabled: this.isPickingPhoto,
        onTap: () => {
          this.startPhotoDraft();
        }
      })
    }
    .padding(AppMetrics.space16)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.sectionGap }) {
        AppPageHeader({
          title: '摄影复盘',
          subtitle: '看见积累，继续下一次复盘。'
        })

        this.StartReviewPanel()

        this.GrowthStatsPanel()

        Column({ space: AppMetrics.cardGap }) {
          Text('最近一次')
            .fontSize(AppTypography.sectionTitle)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.sectionTitleLineHeight)
            .width('100%')

          if (this.projectSummary.latestItem) {
            Column({ space: AppMetrics.cardGap }) {
              RecentReviewCard({
                item: this.projectSummary.latestItem,
                onTap: () => {
                  this.openLatestReview();
                }
              })

              Row({ space: AppMetrics.space8 }) {
                SecondaryButton({
                  label: '查看详情',
                  onTap: () => {
                    this.openLatestReview();
                  }
                })
                  .layoutWeight(1)

                PrimaryButton({
                  label: '继续编辑',
                  onTap: () => {
                    this.continueLatestReview();
                  }
                })
                  .layoutWeight(1)
              }
              .width('100%')
            }
          } else {
            EmptyState({
              title: '还没有复盘记录',
              message: '开始第一条复盘后，这里会展示你最近一次的内容。'
            })
          }
        }

        Column({ space: AppMetrics.cardGap }) {
          Text('当前状态')
            .fontSize(AppTypography.sectionTitle)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.sectionTitleLineHeight)
            .width('100%')

          Column({ space: AppMetrics.space8 }) {
            Text(`家庭存储：${this.resolveSyncStatusText()}`)
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.text)
              .width('100%')

            Text(`复盘人：${this.resolveSettingsSummary()}`)
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.text)
              .width('100%')
          }
          .padding(AppMetrics.space16)
          .width('100%')
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(AppColors.surface)
          .border({ width: 1, color: AppColors.border })
        }
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
