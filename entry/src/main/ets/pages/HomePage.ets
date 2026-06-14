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
  RecentReviewCard
} from '../components/AppDesign';
import { formatReviewTime } from '../utils/ImageLayoutUtils';

@Component
export struct HomePage {
  private reloadRequestId: number = 0;
  @State isPickingPhoto: boolean = false;
  @State projectSummary: ReviewProjectSummary = createDefaultProjectSummary();
  @State dashboardStats: ReviewDashboardStats = {
    totalCount: 0,
    validCount: 0,
    unsureCount: 0,
    streakDays: 0
  };
  @State reviewerName: string = '';
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();

  aboutToAppear(): void {
    this.reloadHistory();
  }

  onPageShow(): void {
    this.reloadHistory();
  }

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private async reloadHistory(): Promise<void> {
    const requestId: number = this.reloadRequestId + 1;
    this.reloadRequestId = requestId;
    const context = this.getAbilityContext();
    const results = await Promise.all([
      ReviewCardHistoryService.load(context),
      ReviewSettingsService.loadReviewerName(context),
      HomeStorageService.loadSettings(context)
    ]);
    if (requestId !== this.reloadRequestId) {
      return;
    }

    const items: Array<ReviewCardHistoryItem> = results[0] as Array<ReviewCardHistoryItem>;
    const reviewerName: string = results[1] as string;
    const homeStorageSettings: HomeStorageSettings = results[2] as HomeStorageSettings;
    this.reviewerName = reviewerName;
    this.homeStorageSettings = homeStorageSettings;
    this.applyHomeData(items);
  }

  private applyHomeData(items: Array<ReviewCardHistoryItem>): void {
    this.projectSummary = ReviewProjectService.buildDefaultProjectSummary(items);
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

  private resolveLastUpdatedText(): string {
    if (this.projectSummary.recordCount === 0 || this.projectSummary.latestUpdatedAt <= 0) {
      return '还没有复盘记录';
    }

    return formatReviewTime(this.projectSummary.latestUpdatedAt);
  }

  private resolveSyncStatusText(): string {
    return this.isHomeStorageConfigured() ? '已配置' : '未配置';
  }

  private resolveSettingsSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
  }

  private resolveStreakText(): string {
    return this.dashboardStats.streakDays > 0 ? `${this.dashboardStats.streakDays}天` : '0天';
  }

  @Builder
  StatItem(value: string, label: string) {
    Column({ space: AppMetrics.space4 }) {
      Text(value)
        .fontSize(AppTypography.level2)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)

      Text(label)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.secondaryText)
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  GrowthStatsPanel() {
    Column({ space: AppMetrics.space16 }) {
      Text('成长统计')
        .fontSize(AppTypography.auxiliary)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .width('100%')

      Row({ space: AppMetrics.space12 }) {
        this.StatItem(`${this.dashboardStats.totalCount}`, '总复盘')
        this.StatItem(`${this.dashboardStats.validCount}`, '成立')
      }
      .width('100%')

      Row({ space: AppMetrics.space12 }) {
        this.StatItem(`${this.dashboardStats.unsureCount}`, '待判断')
        this.StatItem(this.resolveStreakText(), '连续复盘')
      }
      .width('100%')
    }
    .padding(AppMetrics.space16)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  StartReviewPanel() {
    Column({ space: AppMetrics.space12 }) {
      Column({ space: AppMetrics.space4 }) {
        Text('摄影复盘')
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .width('100%')
      }

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
      Column({ space: AppMetrics.space24 }) {
        AppPageHeader({
          title: '首页',
          subtitle: '先看成长反馈，再从最近一次继续，或直接开始新复盘。'
        })

        this.GrowthStatsPanel()

        this.StartReviewPanel()

        Column({ space: AppMetrics.space12 }) {
          Text('最近一次')
            .fontSize(AppTypography.auxiliary)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .width('100%')

          if (this.projectSummary.latestItem) {
            Column({ space: AppMetrics.space12 }) {
              RecentReviewCard({
                item: this.projectSummary.latestItem,
                onTap: () => {
                  this.openLatestReview();
                }
              })

              Row({ space: AppMetrics.space8 }) {
                Button('查看详情')
                  .height(36)
                  .layoutWeight(1)
                  .borderRadius(AppMetrics.capsuleRadius)
                  .fontSize(AppTypography.auxiliary)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.text)
                  .backgroundColor(AppColors.surfaceMuted)
                  .onClick(() => {
                    this.openLatestReview();
                  })

                Button('继续编辑')
                  .height(36)
                  .layoutWeight(1)
                  .borderRadius(AppMetrics.capsuleRadius)
                  .fontSize(AppTypography.auxiliary)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                  .backgroundColor(AppColors.primary)
                  .onClick(() => {
                    this.continueLatestReview();
                  })
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

        Column({ space: AppMetrics.space12 }) {
          Text('当前状态')
            .fontSize(AppTypography.auxiliary)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .width('100%')

          Column({ space: AppMetrics.space12 }) {
            Text(`复盘库：${this.projectSummary.recordCount} 条记录`)
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.text)
              .width('100%')

            Text(`最近更新：${this.resolveLastUpdatedText()}`)
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.text)
              .width('100%')

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
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space24 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
