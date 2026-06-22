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
  SecondaryButton
} from '../components/AppDesign';

const HOME_HERO_HEIGHT: number = 340;
const HOME_SIDE_PADDING: number = 20;
const HOME_HERO_TEXT_BOTTOM: number = 24;
const HOME_METHOD_TAG_HEIGHT: number = 28;
const HOME_METHOD_TAG_RADIUS: number = 14;
const HOME_PRIMARY_BUTTON_HEIGHT: number = 48;
const HOME_STATS_CARD_HEIGHT: number = 72;
const HOME_STATS_RADIUS: number = 12;

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
          .height(HOME_HERO_HEIGHT)
          .objectFit(ImageFit.Cover)

        Column({ space: AppMetrics.space8 }) {
          Text('从一张照片开始，练习你的判断')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.onPrimary)
            .lineHeight(24)
            .maxLines(2)
            .width('100%')

          Text('把视觉落点、视线路径和画面关系，沉淀成能回看的复盘卡。')
            .fontSize(14)
            .fontColor('#D9FFFFFF')
            .lineHeight(20)
            .maxLines(2)
            .width('100%')
        }
        .padding({ left: HOME_SIDE_PADDING, right: HOME_SIDE_PADDING, bottom: HOME_HERO_TEXT_BOTTOM })
        .width('100%')
        .linearGradient({
          angle: 180,
          colors: [['#00000000', 0], ['#120E0B55', 0.58], ['#120E0BD9', 1]]
        })
      }
      .width('100%')
      .height(HOME_HERO_HEIGHT)
      .borderRadius(0)
      .clip(true)

      Scroll() {
        Row({ space: AppMetrics.space8 }) {
          ForEach(this.heroFeatureTags, (item: string) => {
            this.MethodTag(item)
          }, (item: string) => item)
        }
        .padding({ left: HOME_SIDE_PADDING, right: HOME_SIDE_PADDING })
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      Column() {
        this.StartReviewButton()
      }
      .padding({ left: HOME_SIDE_PADDING, right: HOME_SIDE_PADDING })
      .width('100%')

      this.CompactStatsPanel()
    }
    .width('100%')
    .padding({ top: 0, bottom: AppMetrics.space16 })
    .backgroundColor(AppColors.pageBackground)
  }

  @Builder
  CompactStatsPanel() {
    Row({ space: 12 }) {
        this.StatTile('总复盘', `${this.reviewCount}`)
        this.StatTile('成立', `${this.validReviewCount}`)
    }
    .width('100%')
    .padding({ left: HOME_SIDE_PADDING, right: HOME_SIDE_PADDING })
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
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(24)
        .maxLines(1)

      Text(label)
        .fontSize(12)
        .fontColor(AppColors.secondaryText)
        .lineHeight(16)
        .maxLines(1)
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .height(HOME_STATS_CARD_HEIGHT)
    .borderRadius(HOME_STATS_RADIUS)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  MethodTag(label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.primary)
      .height(HOME_METHOD_TAG_HEIGHT)
      .padding({ left: 12, right: 12 })
      .borderRadius(HOME_METHOD_TAG_RADIUS)
      .backgroundColor(AppColors.primarySoft)
      .maxLines(1)
  }

  @Builder
  StartReviewButton() {
    Button(this.isPickingPhoto ? '打开相册中...' : '导入照片，开始复盘')
      .height(HOME_PRIMARY_BUTTON_HEIGHT)
      .width('100%')
      .borderRadius(9)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.onPrimary)
      .backgroundColor(this.isPickingPhoto ? AppColors.primaryDisabled : AppColors.primary)
      .opacity(this.isPickingPhoto ? 0.72 : 1)
      .enabled(!this.isPickingPhoto)
      .stateEffect(!this.isPickingPhoto)
      .onClick(() => {
        if (this.isPickingPhoto) {
          return;
        }
        this.startPhotoDraft();
      })
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
