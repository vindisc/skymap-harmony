import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import { EDITOR_PAGE } from '../app/AppRouter';
import { AppColors, AppMetrics, AppPageHeader, AppTypography, EmptyState, SkeletonBlock } from '../components/AppDesign';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import {
  createEmptyReviewStatsFeedback,
  ReviewProjectService,
  ReviewStatsBlockerItem,
  ReviewStatsDistributionItem,
  ReviewStatsFeedback,
  ReviewStatsRecentReviewItem
} from '../services/ReviewProjectService';
import { formatReviewTime } from '../utils/ImageLayoutUtils';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { REVIEW_FLOW_IMPORT_PENDING_TEXT } from '../services/ReviewFlowFeedback';
import { ToastService } from '../services/ToastService';

const STATS_OVERVIEW_MIN_HEIGHT: number = 120;
const STATS_CARD_MIN_HEIGHT: number = 104;
const STATS_PROGRESS_HEIGHT: number = 10;
const STATS_PROGRESS_RADIUS: number = 5;
const STATS_CONTENT_TOP_GAP: number = AppMetrics.space10;
const STATS_RECENT_REVIEW_FADE_WINDOW: number = 14 * 24 * 60 * 60 * 1000;

@Component
export struct StatsPage {
  private loadRequestId: number = 0;
  @Prop @Watch('refreshStatsData') refreshToken: number = 0;
  @State feedback: ReviewStatsFeedback = createEmptyReviewStatsFeedback();
  @State statsLoadFailed: boolean = false;
  @State isStatsLoading: boolean = false;
  @State isPickingPhoto: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadStats();
  }

  onPageShow(): void {
    this.reloadStats();
  }

  refreshStatsData(): void {
    this.reloadStats();
  }

  private async reloadStats(): Promise<void> {
    const requestId: number = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    this.isStatsLoading = true;
    try {
      const items: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(this.getAbilityContext());
      if (requestId !== this.loadRequestId) {
        return;
      }
      this.feedback = ReviewProjectService.buildStatsFeedback(items);
      this.statsLoadFailed = false;
      this.isStatsLoading = false;
    } catch (error) {
      if (requestId !== this.loadRequestId) {
        return;
      }
      this.statsLoadFailed = true;
      this.isStatsLoading = false;
    }
  }

  private hasStatsData(): boolean {
    return this.feedback.totalCount > 0;
  }

  private shouldShowStatsSkeleton(): boolean {
    return this.isStatsLoading && !this.hasStatsData() && !this.statsLoadFailed;
  }

  private async openCreateFirstReview(): Promise<void> {
    if (this.isPickingPhoto) {
      return;
    }

    this.isPickingPhoto = true;
    const result: PickedPhotoResult = await pickSinglePhoto();
    this.isPickingPhoto = false;

    if (!result.success) {
      if (!result.cancelled && result.message.length > 0) {
        ToastService.show(result.message);
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

  private resolveLatestReviewDate(): string {
    if (this.feedback.latestReviewTime <= 0) {
      return '暂无';
    }
    return formatReviewTime(this.feedback.latestReviewTime).split(' ')[0];
  }

  private resolveUpdatedDate(timestamp: number): string {
    if (timestamp <= 0) {
      return '时间待确认';
    }
    return formatReviewTime(timestamp);
  }

  private resolveDistributionColor(key: string): string {
    if (key === 'works') {
      return AppColors.tagGreenText;
    }
    if (key === 'notWorks') {
      return AppColors.tagAmberText;
    }
    return AppColors.primary;
  }

  private resolveDistributionBackground(key: string): string {
    if (key === 'works') {
      return AppColors.tagGreen;
    }
    if (key === 'notWorks') {
      return AppColors.tagAmber;
    }
    return AppColors.primarySoft;
  }

  private resolveReviewDecisionColor(value: string): string {
    if (value === '成立') {
      return AppColors.tagGreenText;
    }
    if (value === '不成立') {
      return AppColors.tagAmberText;
    }
    return AppColors.primary;
  }

  private resolveDistributionProgressWidth(item: ReviewStatsDistributionItem): string {
    if (item.count <= 0) {
      return '0%';
    }
    return `${Math.max(item.rate, 4)}%`;
  }

  private resolveRecentReviewOpacity(updatedAt: number): number {
    if (updatedAt <= 0 || this.feedback.latestReviewTime <= 0) {
      return 0.8;
    }
    const ageFromLatest: number = Math.max(0, this.feedback.latestReviewTime - updatedAt);
    if (ageFromLatest <= STATS_RECENT_REVIEW_FADE_WINDOW / 3) {
      return 1;
    }
    if (ageFromLatest <= STATS_RECENT_REVIEW_FADE_WINDOW) {
      return 0.88;
    }
    return 0.74;
  }

  @Builder
  OverviewMetric(label: string, value: number, color: string, background: string) {
    Column({ space: 2 }) {
      Text(`${value}`)
        .fontSize(AppTypography.cardTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .lineHeight(AppTypography.cardTitleLineHeight)
        .maxLines(1)

      Text(label)
        .fontSize(AppTypography.meta)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.metaLineHeight)
        .maxLines(1)
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .padding({ top: AppMetrics.space8, bottom: AppMetrics.space8 })
    .borderRadius(AppMetrics.buttonRadius)
    .backgroundColor(background)
  }

  @Builder
  OverviewCard() {
    Column({ space: AppMetrics.space12 }) {
      Row({ space: AppMetrics.space12 }) {
        Column({ space: 2 }) {
          Text(`${this.feedback.totalCount}`)
            .fontSize(AppTypography.statNumber)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .lineHeight(AppTypography.statNumberLineHeight)
            .maxLines(1)

          Text('次复盘')
            .fontSize(AppTypography.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.bodyLineHeight)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(`成立率 ${this.feedback.worksRate}%`)
          .fontSize(AppTypography.meta)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.tagGreenText)
          .lineHeight(AppTypography.metaLineHeight)
          .padding({
            left: AppMetrics.comfortableBadgePaddingHorizontal,
            right: AppMetrics.comfortableBadgePaddingHorizontal,
            top: AppMetrics.comfortableBadgePaddingVertical,
            bottom: AppMetrics.comfortableBadgePaddingVertical
          })
          .borderRadius(AppMetrics.capsuleRadius)
          .backgroundColor(AppColors.tagGreen)
          .maxLines(1)
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')

      Row({ space: AppMetrics.space8 }) {
        this.OverviewMetric('成立', this.feedback.worksCount, AppColors.tagGreenText, AppColors.tagGreen)
        this.OverviewMetric('待判断', this.feedback.uncertainCount, AppColors.primary, AppColors.primarySoft)
        this.OverviewMetric('不成立', this.feedback.notWorksCount, AppColors.tagAmberText, AppColors.tagAmber)
      }
        .width('100%')

      Row({ space: AppMetrics.space8 }) {
        Text(`最近一次：${this.resolveLatestReviewDate()}`)
          .fontSize(AppTypography.meta)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.metaLineHeight)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .constraintSize({ minHeight: STATS_OVERVIEW_MIN_HEIGHT })
    .padding(AppMetrics.cardPadding)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.medium)
  }

  @Builder
  Recent30DaysCard() {
    Column({ space: AppMetrics.space10 }) {
      Row() {
        Text('最近 30 天')
          .fontSize(AppTypography.cardTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.cardTitleLineHeight)
          .layoutWeight(1)

        if (this.feedback.recent30DaysCount > 0) {
          Text(`${this.feedback.recent30DaysCount} 次`)
            .fontSize(AppTypography.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .lineHeight(AppTypography.metaLineHeight)
            .padding({
              left: AppMetrics.compactBadgePaddingHorizontal,
              right: AppMetrics.compactBadgePaddingHorizontal,
              top: AppMetrics.compactBadgePaddingVertical,
              bottom: AppMetrics.compactBadgePaddingVertical
            })
            .borderRadius(AppMetrics.capsuleRadius)
            .backgroundColor(AppColors.primarySoft)
        }
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')

      if (this.feedback.recent30DaysCount > 0) {
        Row({ space: AppMetrics.space8 }) {
          this.OverviewMetric('成立', this.feedback.recent30DaysWorksCount, AppColors.tagGreenText, AppColors.tagGreen)
          this.OverviewMetric('待判断', this.feedback.recent30DaysUncertainCount, AppColors.primary, AppColors.primarySoft)
          this.OverviewMetric('不成立', this.feedback.recent30DaysNotWorksCount, AppColors.tagAmberText, AppColors.tagAmber)
        }
        .width('100%')
      } else {
        Text('继续复盘后，这里会显示最近 30 天变化。')
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .constraintSize({ minHeight: STATS_CARD_MIN_HEIGHT })
    .padding(AppMetrics.cardPadding)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  DistributionRow(item: ReviewStatsDistributionItem) {
    Column({ space: AppMetrics.space8 }) {
      Row() {
        Text(`${item.label} ${item.count}`)
          .fontSize(AppTypography.meta)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.metaLineHeight)
          .layoutWeight(1)

        Text(`${item.rate}%`)
          .fontSize(AppTypography.meta)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.resolveDistributionColor(item.key))
          .lineHeight(AppTypography.metaLineHeight)
          .padding({
            left: AppMetrics.space8,
            right: AppMetrics.space8,
            top: AppMetrics.compactBadgePaddingVertical,
            bottom: AppMetrics.compactBadgePaddingVertical
          })
          .borderRadius(AppMetrics.capsuleRadius)
          .backgroundColor(this.resolveDistributionBackground(item.key))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .width('100%')
          .height(STATS_PROGRESS_HEIGHT)
          .borderRadius(STATS_PROGRESS_RADIUS)
          .backgroundColor(AppColors.surfaceMuted)

        Column()
          .width(this.resolveDistributionProgressWidth(item))
          .height(STATS_PROGRESS_HEIGHT)
          .borderRadius(STATS_PROGRESS_RADIUS)
          .backgroundColor(this.resolveDistributionColor(item.key))
          .animation({ duration: MotionTokens.durationStandard, curve: MotionTokens.curveDecelerate })
      }
      .width('100%')
      .height(STATS_PROGRESS_HEIGHT)
    }
    .width('100%')
  }

  @Builder
  DistributionCard() {
    Column({ space: 12 }) {
      Text('判断分布')
        .fontSize(AppTypography.cardTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.cardTitleLineHeight)
        .width('100%')

      ForEach(this.feedback.decisionDistribution, (item: ReviewStatsDistributionItem) => {
        this.DistributionRow(item)
      }, (item: ReviewStatsDistributionItem) => item.key)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(AppMetrics.cardPadding)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  BlockerRow(item: ReviewStatsBlockerItem) {
    Row({ space: 10 }) {
      Text(`${item.order}.`)
        .fontSize(AppTypography.meta)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.primary)
        .lineHeight(AppTypography.metaLineHeight)
        .width(20)

      Text(item.text)
        .fontSize(AppTypography.body)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.bodyLineHeight)
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .wordBreak(WordBreak.BREAK_WORD)
    }
    .alignItems(VerticalAlign.Top)
    .width('100%')
  }

  @Builder
  BlockersCard() {
    Column({ space: 10 }) {
      Text('最近卡点')
        .fontSize(AppTypography.cardTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.cardTitleLineHeight)
        .width('100%')

      if (this.feedback.recentBlockers.length > 0) {
        ForEach(this.feedback.recentBlockers, (item: ReviewStatsBlockerItem) => {
          this.BlockerRow(item)
        }, (item: ReviewStatsBlockerItem) => item.key)
      } else {
        Text('暂时还没有记录卡点。')
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(AppMetrics.cardPadding)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  RecentReviewRow(item: ReviewStatsRecentReviewItem) {
    Row({ space: AppMetrics.space8 }) {
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.resolveUpdatedDate(item.updatedAt))
          .fontSize(AppTypography.meta)
          .fontColor(AppColors.mutedText)
          .lineHeight(AppTypography.metaLineHeight)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(item.decision)
        .fontSize(AppTypography.meta)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.resolveReviewDecisionColor(item.decision))
        .lineHeight(AppTypography.metaLineHeight)
        .padding({
          left: AppMetrics.compactBadgePaddingHorizontal,
          right: AppMetrics.compactBadgePaddingHorizontal,
          top: AppMetrics.compactBadgePaddingVertical,
          bottom: AppMetrics.compactBadgePaddingVertical
        })
        .borderRadius(AppMetrics.badgeRadius)
        .backgroundColor(this.resolveDistributionBackground(item.decision === '成立' ? 'works' : item.decision === '不成立' ? 'notWorks' : 'uncertain'))
        .maxLines(1)
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .padding({ top: 2, bottom: 2 })
    .opacity(this.resolveRecentReviewOpacity(item.updatedAt))
  }

  @Builder
  RecentReviewsCard() {
    Column({ space: 10 }) {
      Text('最近复盘')
        .fontSize(AppTypography.cardTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.cardTitleLineHeight)
        .width('100%')

      ForEach(this.feedback.recentReviews, (item: ReviewStatsRecentReviewItem) => {
        this.RecentReviewRow(item)
      }, (item: ReviewStatsRecentReviewItem) => item.key)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(AppMetrics.cardPadding)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  StatsSkeletonCard(height: number, firstLineWidth: string, secondLineWidth: string) {
    Column({ space: AppMetrics.space12 }) {
      SkeletonBlock({ blockWidth: firstLineWidth, blockHeight: 18, blockRadius: 9 })
      SkeletonBlock({ blockWidth: secondLineWidth, blockHeight: 14, blockRadius: 7 })
      Row({ space: AppMetrics.space8 }) {
        Column() {
          SkeletonBlock({ blockHeight: 34, blockRadius: AppMetrics.buttonRadius })
        }
        .layoutWeight(1)

        Column() {
          SkeletonBlock({ blockHeight: 34, blockRadius: AppMetrics.buttonRadius })
        }
        .layoutWeight(1)

        Column() {
          SkeletonBlock({ blockHeight: 34, blockRadius: AppMetrics.buttonRadius })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height(height)
    .padding(AppMetrics.cardPadding)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  StatsSkeleton() {
    Column({ space: AppMetrics.cardGap }) {
      this.StatsSkeletonCard(STATS_OVERVIEW_MIN_HEIGHT, '44%', '64%')
      this.StatsSkeletonCard(STATS_CARD_MIN_HEIGHT, '36%', '82%')
      this.StatsSkeletonCard(STATS_CARD_MIN_HEIGHT, '40%', '74%')
    }
    .width('100%')
  }

  build() {
    Column() {
      Column() {
        AppPageHeader({
          title: '统计'
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
        Column({ space: AppMetrics.cardGap }) {
          if (this.shouldShowStatsSkeleton()) {
            this.StatsSkeleton()
          } else if (this.statsLoadFailed) {
            EmptyState({
              title: '统计暂时无法刷新',
              message: '稍后返回本页会自动重试，已保存的复盘不会受影响。'
            })
              .margin({ top: AppMetrics.space8 })
          } else if (!this.hasStatsData()) {
            EmptyState({
              title: '还没有复盘数据',
              message: '完成第一张照片复盘后，这里会显示你的判断变化。',
              actionLabel: this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '去创建第一条复盘',
              isActionDisabled: this.isPickingPhoto,
              onAction: () => {
                this.openCreateFirstReview();
              }
            })
              .margin({ top: AppMetrics.space8 })
          } else {
            Column({ space: AppMetrics.cardGap }) {
              this.OverviewCard()
              this.Recent30DaysCard()
              this.DistributionCard()
              this.BlockersCard()
              this.RecentReviewsCard()
            }
            .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: STATS_CONTENT_TOP_GAP,
          bottom: AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding
        })
        .width('100%')
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
