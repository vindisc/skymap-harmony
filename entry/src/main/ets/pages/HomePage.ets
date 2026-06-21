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
  applyHomeDashboardReloadFailure,
  applyHomeDashboardReloadSuccess,
  beginHomeDashboardReload,
  createHomeDashboardReloadState,
  HomeDashboardReloadState
} from '../services/HomeDashboardPresenter';
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
  private dashboardReloadState: HomeDashboardReloadState = createHomeDashboardReloadState();
  @Prop @Watch('refreshHomeData') refreshToken: number = 0;
  @State isPickingPhoto: boolean = false;
  @State latestItem: ReviewCardHistoryItem | undefined = undefined;
  @State reviewCount: number = 0;
  @State validReviewCount: number = 0;
  @State unsureReviewCount: number = 0;
  @State streakDays: number = 0;
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

  private async reloadHistory(): Promise<void> {
    const requestId: number = beginHomeDashboardReload(this.dashboardReloadState);
    const context = this.getAbilityContext();

    try {
      const items: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
      if (applyHomeDashboardReloadSuccess(this.dashboardReloadState, requestId, items)) {
        this.syncDashboardStateFromPresenter();
      }
    } catch (error) {
      if (applyHomeDashboardReloadFailure(this.dashboardReloadState, requestId)) {
        this.syncDashboardStateFromPresenter();
      }
      return;
    }
  }

  private syncDashboardStateFromPresenter(): void {
    this.latestItem = this.dashboardReloadState.latestItem;
    this.reviewCount = this.dashboardReloadState.reviewCount;
    this.validReviewCount = this.dashboardReloadState.validReviewCount;
    this.unsureReviewCount = this.dashboardReloadState.unsureReviewCount;
    this.streakDays = this.dashboardReloadState.streakDays;
    this.historyLoadFailed = this.dashboardReloadState.historyLoadFailed;
  }

  private openLatestReview(): void {
    if (!this.latestItem) {
      return;
    }
    ReviewCardStore.setCurrentDocument(this.latestItem.document);
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  private continueLatestReview(): void {
    if (!this.latestItem) {
      return;
    }
    ReviewCardStore.setCurrentDocument(this.latestItem.document);
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

  private resolveStreakText(): string {
    if (this.reviewCount === 0 || this.streakDays <= 0) {
      return '—';
    }
    return `${this.streakDays}天`;
  }

  private resolveStatsHintText(): string {
    if (this.historyLoadFailed) {
      return '历史读取失败';
    }
    return this.reviewCount > 0 ? '已更新' : '暂无记录';
  }

  @Builder
  DashboardStat(label: string, value: string, isEmphasized: boolean = false) {
    Column({ space: 6 }) {
      Text(value)
        .fontSize(isEmphasized ? AppTypography.statNumber + 6 : AppTypography.statNumber)
        .fontWeight(FontWeight.Bold)
        .fontColor(isEmphasized ? AppColors.primary : AppColors.text)
        .lineHeight(isEmphasized ? AppTypography.statNumberLineHeight + 6 : AppTypography.statNumberLineHeight)
        .maxLines(1)

      Text(label)
        .fontSize(AppTypography.statLabel)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.statLabelLineHeight)
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.cardPadding)
    .layoutWeight(1)
    .borderRadius(AppMetrics.panelRadius)
    .backgroundColor(isEmphasized ? AppColors.primarySoft : AppColors.surfaceMuted)
  }

  @Builder
  GrowthStatsPanel() {
    Column({ space: AppMetrics.cardGap }) {
      Column({ space: 6 }) {
        Text('复盘概览')
          .fontSize(AppTypography.sectionTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.sectionTitleLineHeight)

        Text(this.resolveStatsHintText())
          .fontSize(AppTypography.caption)
          .fontColor(this.historyLoadFailed ? AppColors.tagAmberText : AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row({ space: AppMetrics.space8 }) {
        this.DashboardStat('总复盘', `${this.reviewCount}`, true)
        this.DashboardStat('成立', `${this.validReviewCount}`)
      }
      .width('100%')

      Row({ space: AppMetrics.space8 }) {
        this.DashboardStat('待判断', `${this.unsureReviewCount}`)
        this.DashboardStat('连续', this.resolveStreakText())
      }
      .width('100%')
    }
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(this.historyLoadFailed ? AppColors.tagAmber : AppColors.surfaceRaised)
    .border({ width: 1, color: this.historyLoadFailed ? AppColors.tagAmberText : AppColors.border })
  }

  @Builder
  StartReviewPanel() {
    Column({ space: AppMetrics.cardGap }) {
      Column({ space: AppMetrics.space8 }) {
        Text('开始新的复盘')
          .fontSize(AppTypography.cardTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.cardTitleLineHeight)
          .width('100%')

        Text('从一张真实照片开始，把判断、关系和卡点沉淀成可回看的记录。')
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
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceRaised)
    .border({ width: 1, color: AppColors.border })
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.sectionGap }) {
        AppPageHeader({
          title: '摄影复盘',
          subtitle: '让每一次判断都能被安静地保存、回看和继续推进。'
        })

        this.StartReviewPanel()

        this.GrowthStatsPanel()

        Column({ space: AppMetrics.cardGap }) {
          Column({ space: 6 }) {
            Text('最近一次')
              .fontSize(AppTypography.sectionTitle)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .lineHeight(AppTypography.sectionTitleLineHeight)
              .width('100%')

            Text('回到刚刚停下来的那条复盘，继续补完它。')
              .fontSize(AppTypography.caption)
              .fontColor(AppColors.secondaryText)
              .lineHeight(AppTypography.captionLineHeight)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          if (this.latestItem) {
            Column({ space: AppMetrics.cardGap }) {
              RecentReviewCard({
                item: this.latestItem,
                onTap: () => {
                  this.openLatestReview();
                }
              })

              Row({ space: AppMetrics.space8 }) {
                PrimaryButton({
                  label: '继续编辑',
                  onTap: () => {
                    this.continueLatestReview();
                  }
                })
                  .layoutWeight(1)

                SecondaryButton({
                  label: '查看',
                  onTap: () => {
                    this.openLatestReview();
                  }
                })
                  .layoutWeight(1)
              }
              .width('100%')
            }
          } else {
            EmptyState({
              title: '暂无记录',
              message: '从相册选择一张照片，开始你的第一条复盘。'
            })
          }
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
