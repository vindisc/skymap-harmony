import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import {
  EDITOR_PAGE,
  PREVIEW_PAGE
} from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import {
  ReviewCardHistoryLoadResult,
  ReviewCardHistoryService
} from '../services/ReviewCardHistoryService';
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
  SecondaryButton,
  TagLabel
} from '../components/AppDesign';

@Component
export struct HomePage {
  private dashboardReloadState: HomeDashboardReloadState = createHomeDashboardReloadState();
  private readonly heroFeatureTags: Array<string> = [
    '视觉落点',
    '视线路径',
    '画面关系',
    '是否成立'
  ];
  @Prop @Watch('refreshHomeData') refreshToken: number = 0;
  @State isPickingPhoto: boolean = false;
  @State latestItem: ReviewCardHistoryItem | undefined = undefined;
  @State reviewCount: number = 0;
  @State validReviewCount: number = 0;
  @State unsureReviewCount: number = 0;
  @State streakDays: number = 0;
  @State historyLoadFailed: boolean = false;
  @State historyDiagnosticsText: string = '';

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
      const result: ReviewCardHistoryLoadResult = await ReviewCardHistoryService.loadWithDiagnostics(context);
      this.historyDiagnosticsText = ReviewCardHistoryService.formatDiagnostics(result.diagnostics);
      if (applyHomeDashboardReloadSuccess(this.dashboardReloadState, requestId, result.items)) {
        this.syncDashboardStateFromPresenter();
      }
    } catch (error) {
      this.historyDiagnosticsText = `首页历史读取异常\nerror=${error}`;
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

  private shouldShowHistoryDiagnostics(): boolean {
    return this.historyLoadFailed;
  }

  private async copyHistoryDiagnostics(): Promise<void> {
    const context = this.getAbilityContext();
    let diagnosticsText: string = this.historyDiagnosticsText;
    try {
      const result: ReviewCardHistoryLoadResult = await ReviewCardHistoryService.loadWithDiagnostics(context);
      diagnosticsText = ReviewCardHistoryService.formatDiagnostics(result.diagnostics);
      this.historyDiagnosticsText = diagnosticsText;
    } catch (error) {
      diagnosticsText = `${diagnosticsText}\ncopyReloadError=${error}`;
    }

    try {
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, diagnosticsText);
      await pasteboard.getSystemPasteboard().setData(data);
      promptAction.showToast({ message: '已复制恢复诊断' });
    } catch (error) {
      promptAction.showToast({ message: '复制诊断失败' });
    }
  }

  @Builder
  HeroPanel() {
    Column({ space: AppMetrics.cardGap }) {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image($r('app.media.home_review_hero'))
          .width('100%')
          .height(360)
          .objectFit(ImageFit.Cover)

        Column({ space: AppMetrics.space8 }) {
          Text('从一张照片开始，练习你的判断')
            .fontSize(AppTypography.level2)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.onPrimary)
            .lineHeight(AppTypography.level2LineHeight)
            .maxLines(2)
            .width('100%')

          Text('把视觉落点、视线路径和画面关系，沉淀成能回看的复盘卡。')
            .fontSize(AppTypography.body)
            .fontColor('#F4F0EA')
            .lineHeight(AppTypography.bodyLineHeight)
            .maxLines(2)
            .width('100%')
        }
        .padding(AppMetrics.space16)
        .width('100%')
        .linearGradient({
          angle: 180,
          colors: [['#00000000', 0], ['#351E12', 0.62], ['#15110E', 1]]
        })
      }
      .width('100%')
      .height(360)
      .borderRadius(24)
      .clip(true)

      Row({ space: AppMetrics.space8 }) {
        ForEach(this.heroFeatureTags, (item: string) => {
          TagLabel({
            label: item,
            color: AppColors.primary,
            tagBackground: AppColors.primarySoft
          })
        }, (item: string) => item)
      }
      .width('100%')

      PrimaryButton({
        label: this.isPickingPhoto ? '打开相册中...' : '导入照片，开始复盘',
        isDisabled: this.isPickingPhoto,
        onTap: () => {
          this.startPhotoDraft();
        }
      })
    }
    .padding(AppMetrics.space16)
    .width('100%')
    .borderRadius(28)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  CompactStatsPanel() {
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

      Row({ space: AppMetrics.space16 }) {
        Column({ space: 4 }) {
          Text(`${this.reviewCount}`)
            .fontSize(AppTypography.statNumber)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .lineHeight(AppTypography.statNumberLineHeight)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('总复盘')
            .fontSize(AppTypography.statLabel)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.statLabelLineHeight)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text(`${this.validReviewCount}`)
            .fontSize(AppTypography.statNumber)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.statNumberLineHeight)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('成立')
            .fontSize(AppTypography.statLabel)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.statLabelLineHeight)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text(`${this.unsureReviewCount}`)
            .fontSize(AppTypography.statNumber)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.statNumberLineHeight)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('待判断')
            .fontSize(AppTypography.statLabel)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.statLabelLineHeight)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text(this.resolveStreakText())
            .fontSize(AppTypography.statNumber)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.statNumberLineHeight)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('连续')
            .fontSize(AppTypography.statLabel)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.statLabelLineHeight)
            .maxLines(1)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      if (this.shouldShowHistoryDiagnostics()) {
        Column({ space: 6 }) {
          Text('历史数据仍为空时，请复制诊断发给开发排查。')
            .fontSize(AppTypography.meta)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.metaLineHeight)
            .width('100%')

          SecondaryButton({
            label: '复制恢复诊断',
            onTap: () => {
              this.copyHistoryDiagnostics();
            }
          })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
    }
    .padding(AppMetrics.space16)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceTint)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  RecentReviewSection() {
    Column({ space: AppMetrics.cardGap }) {
      Column({ space: 4 }) {
        Text('最近一次')
          .fontSize(AppTypography.sectionTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.sectionTitleLineHeight)
          .width('100%')

        Text('继续刚刚停下来的那条复盘。')
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
            SecondaryButton({
              label: '查看',
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
          title: '暂无记录',
          message: '导入一张照片后，这里会保留你最近一次复盘。'
        })
      }
    }
    .width('100%')
  }

  @Builder
  DiagnosticsPanel() {
    Column({ space: 6 }) {
      Text('历史记录读取失败，可复制诊断信息继续排查。')
        .fontSize(AppTypography.meta)
        .fontColor(AppColors.tagAmberText)
        .lineHeight(AppTypography.metaLineHeight)
        .width('100%')

      SecondaryButton({
        label: '复制恢复诊断',
        onTap: () => {
          this.copyHistoryDiagnostics();
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.space16)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.tagAmber)
    .border({ width: 1, color: AppColors.tagAmberText })
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.sectionGap }) {
        AppPageHeader({
          title: '摄影复盘',
          subtitle: '先看到成品，再开始判断。'
        })

        this.HeroPanel()
        this.RecentReviewSection()
        this.CompactStatsPanel()

        if (this.shouldShowHistoryDiagnostics()) {
          this.DiagnosticsPanel()
        }
      }
      .padding({
        left: AppMetrics.pagePadding,
        right: AppMetrics.pagePadding,
        top: AppMetrics.pageTopPadding,
        bottom: AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding
      })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
