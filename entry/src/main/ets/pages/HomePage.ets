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
import { ReviewProjectSummary } from '../model/ProjectModel';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { formatReviewTime } from '../utils/ImageLayoutUtils';
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
  @State latestItem: ReviewCardHistoryItem | undefined = undefined;
  @State reviewCount: number = 0;
  @State validReviewCount: number = 0;
  @State unsureReviewCount: number = 0;
  @State streakDays: number = 0;
  @State historyLoadFailed: boolean = false;
  @State debugLoadedItemCount: number = -1;
  @State debugSummaryCount: number = -1;
  @State debugLatestTitle: string = '未加载';
  @State debugLatestUpdatedAt: string = '未加载';
  @State debugLastError: string = '';
  @State debugReloadStamp: string = '未加载';

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
    const requestId: number = this.reloadRequestId + 1;
    this.reloadRequestId = requestId;
    const context = this.getAbilityContext();

    try {
      const items: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
      if (requestId !== this.reloadRequestId) {
        return;
      }
      this.debugLoadedItemCount = items.length;
      this.debugLastError = '';
      this.debugReloadStamp = formatReviewTime(Date.now());
      this.historyLoadFailed = false;
      this.applyHomeData(items);
    } catch (error) {
      if (requestId === this.reloadRequestId) {
        this.historyLoadFailed = true;
        this.debugLastError = `${error}`;
        this.debugReloadStamp = formatReviewTime(Date.now());
      }
      return;
    }
  }

  private applyHomeData(items: Array<ReviewCardHistoryItem>): void {
    const summary: ReviewProjectSummary = ReviewProjectService.buildHomeSummary(items);
    this.latestItem = summary.latestItem;
    this.reviewCount = summary.recordCount;
    this.validReviewCount = summary.stats.validCount;
    this.unsureReviewCount = summary.stats.unsureCount;
    this.streakDays = this.resolveStreakDays(items);
    this.debugSummaryCount = summary.recordCount;
    this.debugLatestTitle = summary.latestItem ? summary.latestItem.document.content.title : '无最近记录';
    this.debugLatestUpdatedAt = summary.latestItem ? formatReviewTime(summary.latestItem.document.updatedAt) : '无最近记录';
  }

  private resolveStreakDays(items: Array<ReviewCardHistoryItem>): number {
    try {
      return ReviewProjectService.buildDashboardStats(items).streakDays;
    } catch (error) {
      return 0;
    }
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
      return '历史记录暂时读取失败，请重新进入首页或重启应用再试。';
    }
    return this.reviewCount > 0 ? '每一次判断都会留下可回看的线索。' : '还没有记录，第一条复盘会从这里开始。';
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
        this.StatItem(`${this.reviewCount}`, '总复盘')
        this.StatItem(`${this.validReviewCount}`, '成立')
        this.StatItem(`${this.unsureReviewCount}`, '待判断')
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
  DebugStatsPanel() {
    Column({ space: AppMetrics.space8 }) {
      Text('诊断信息')
        .fontSize(AppTypography.caption)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.tagAmberText)
        .width('100%')

      Text(`load=${this.debugLoadedItemCount} · summary=${this.debugSummaryCount} · UI=${this.reviewCount}/${this.validReviewCount}/${this.unsureReviewCount} · 连续=${this.resolveStreakText()}`)
        .fontSize(AppTypography.meta)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.metaLineHeight)
        .width('100%')

      Text(`最近：${this.debugLatestTitle} · ${this.debugLatestUpdatedAt}`)
        .fontSize(AppTypography.meta)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.metaLineHeight)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.debugLastError.length > 0 ? `错误：${this.debugLastError}` : `刷新：${this.debugReloadStamp}`)
        .fontSize(AppTypography.meta)
        .fontColor(this.debugLastError.length > 0 ? AppColors.danger : AppColors.secondaryText)
        .lineHeight(AppTypography.metaLineHeight)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.tagAmber)
    .border({ width: 1, color: AppColors.tagAmberText })
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

        this.DebugStatsPanel()

        Column({ space: AppMetrics.cardGap }) {
          Text('最近一次')
            .fontSize(AppTypography.sectionTitle)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.sectionTitleLineHeight)
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
