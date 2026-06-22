import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import {
  EDITOR_PAGE
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
  AppTypography,
  PrimaryButton,
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
    this.reviewCount = this.dashboardReloadState.reviewCount;
    this.validReviewCount = this.dashboardReloadState.validReviewCount;
    this.unsureReviewCount = this.dashboardReloadState.unsureReviewCount;
    this.streakDays = this.dashboardReloadState.streakDays;
    this.historyLoadFailed = this.dashboardReloadState.historyLoadFailed;
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
    Column({ space: AppMetrics.space16 }) {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image($r('app.media.home_review_hero'))
          .width('100%')
          .height(500)
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
      .height(500)
      .borderRadius(0)
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
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding })

      PrimaryButton({
        label: this.isPickingPhoto ? '打开相册中...' : '导入照片，开始复盘',
        isDisabled: this.isPickingPhoto,
        onTap: () => {
          this.startPhotoDraft();
        }
      })
      .margin({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding })

      this.CompactStatsPanel()
    }
    .width('100%')
    .padding({ top: 0, bottom: AppMetrics.space16 })
    .backgroundColor(AppColors.pageBackground)
  }

  @Builder
  CompactStatsPanel() {
    Column({ space: AppMetrics.space8 }) {
      Row({ space: AppMetrics.space8 }) {
        this.StatTile('总复盘', `${this.reviewCount}`)
        this.StatTile('成立', `${this.validReviewCount}`)
      }
      .width('100%')

      Row({ space: AppMetrics.space8 }) {
        this.StatTile('待判断', `${this.unsureReviewCount}`)
        this.StatTile('连续', this.resolveStreakText())
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding })
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

  @Builder
  StatTile(label: string, value: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(AppTypography.cardTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.cardTitleLineHeight)
        .maxLines(1)

      Text(label)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.captionLineHeight)
        .maxLines(1)
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .borderRadius(18)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.sectionGap }) {
        this.HeroPanel()

        if (this.shouldShowHistoryDiagnostics()) {
          this.DiagnosticsPanel()
        }
      }
      .padding({
        left: 0,
        right: 0,
        top: 0,
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
