import common from '@ohos.app.ability.common';
import pasteboard from '@ohos.pasteboard';
import {
  EDITOR_PAGE
} from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import {
  pickMultiplePhotoDetails,
  pickSinglePhoto,
  PickedPhotoDetailListResult,
  PickedPhotoResult
} from '../services/PhotoPickerService';
import {
  PendingReviewPhotoBatchResult,
  PendingReviewPhotoInput,
  PendingReviewPhotoStore
} from '../services/PendingReviewPhotoStore';
import {
  HomeHeroDisplayImage,
  HomeHeroImageConfig,
  HomeHeroImageService
} from '../services/HomeHeroImageService';
import {
  ReviewCardHistoryLoadResult,
  ReviewCardHistoryService
} from '../services/ReviewCardHistoryService';
import { LearningProgressFormService } from '../services/LearningProgressFormService';
import {
  applyHomeDashboardReloadFailure,
  applyHomeDashboardReloadSuccess,
  beginHomeDashboardReload,
  createHomeDashboardReloadState,
  HomeDashboardReloadState
} from '../services/HomeDashboardPresenter';
import {
  REVIEW_FLOW_HOME_COPY_ISSUE_FAILED_TEXT,
  REVIEW_FLOW_HOME_COPY_ISSUE_SUCCESS_TEXT,
  REVIEW_FLOW_HOME_COPY_ISSUE_TEXT,
  REVIEW_FLOW_HOME_RELOAD_FAILED_TEXT,
  REVIEW_FLOW_IMPORT_PENDING_TEXT,
  REVIEW_FLOW_PENDING_IMPORT_FAILED_TEXT,
  REVIEW_FLOW_PENDING_IMPORT_SUCCESS_TEXT
} from '../services/ReviewFlowFeedback';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  PrimaryButton,
  SecondaryButton,
  SkeletonBlock
} from '../components/AppDesign';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';
import { ToastService } from '../services/ToastService';

const HOME_HERO_ASPECT_RATIO: number = 0.68;
const HOME_SIDE_PADDING: number = AppMetrics.pagePadding;
const HOME_HERO_TEXT_PADDING: number = 20;
const HOME_HERO_RADIUS: number = AppMetrics.cardRadius;
const HOME_HERO_TEXT_BOTTOM: number = 54;
const HOME_METHOD_TAG_HEIGHT: number = 28;
const HOME_METHOD_TAG_RADIUS: number = AppMetrics.capsuleRadius;
const HOME_METHOD_TAG_GAP: number = 6;
const HOME_HERO_INDICATOR_BOTTOM: number = 18;
const HOME_PENDING_IMPORT_MAX_SELECT_NUMBER: number = 30;

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
  @State isImportingPendingPhoto: boolean = false;
  @State historyLoadFailed: boolean = false;
  @State historyDiagnosticsText: string = '';
  @State heroImages: Array<HomeHeroDisplayImage> = [];
  @State heroAutoplayEnabled: boolean = true;
  @State heroAutoplayPaused: boolean = false;
  @State heroIntervalSeconds: number = 4;
  @State activeHeroIndex: number = 0;
  @State isHistoryLoading: boolean = false;

  aboutToAppear(): void {
    this.reloadHistory();
    this.reloadHeroImages();
  }

  onPageShow(): void {
    this.reloadHistory();
    this.reloadHeroImages();
  }

  refreshHomeData(): void {
    this.reloadHistory();
    this.reloadHeroImages();
  }

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  private async reloadHistory(): Promise<void> {
    const requestId: number = beginHomeDashboardReload(this.dashboardReloadState);
    const context = this.getAbilityContext();
    this.isHistoryLoading = true;

    try {
      const result: ReviewCardHistoryLoadResult = await ReviewCardHistoryService.loadWithDiagnostics(context);
      this.historyDiagnosticsText = ReviewCardHistoryService.formatDiagnostics(result.diagnostics);
      if (applyHomeDashboardReloadSuccess(this.dashboardReloadState, requestId, result.items)) {
        this.syncDashboardStateFromPresenter();
        this.isHistoryLoading = false;
      }
    } catch (error) {
      this.historyDiagnosticsText = `首页历史读取异常\nerror=${error}`;
      if (applyHomeDashboardReloadFailure(this.dashboardReloadState, requestId)) {
        this.syncDashboardStateFromPresenter();
        this.isHistoryLoading = false;
      }
      return;
    }
  }

  private async reloadHeroImages(): Promise<void> {
    try {
      const config: HomeHeroImageConfig = await HomeHeroImageService.loadConfig(this.getAbilityContext());
      const images: Array<HomeHeroDisplayImage> = await HomeHeroImageService.getDisplayImages(this.getAbilityContext());
      this.heroImages = images;
      this.heroAutoplayEnabled = config.autoplayEnabled;
      this.heroIntervalSeconds = config.intervalSeconds;
    } catch (error) {
      console.warn(`[HomePage] home hero reload failed: ${error}`);
      this.heroImages = [];
    }
  }

  private hasUserHeroImages(): boolean {
    return this.heroImages.length > 0;
  }

  private shouldShowHeroIndicator(): boolean {
    return this.heroImages.length > 1;
  }

  private resolveHeroIndicator(): DotIndicator | boolean {
    if (!this.shouldShowHeroIndicator()) {
      return false;
    }

    return new DotIndicator()
      .bottom(HOME_HERO_INDICATOR_BOTTOM)
      .color(AppColors.overlayLight)
      .selectedColor(AppColors.onPrimary);
  }

  private shouldAutoplayHero(): boolean {
    return this.heroAutoplayEnabled && this.shouldShowHeroIndicator();
  }

  private pauseHeroAutoplayBriefly(): void {
    this.heroAutoplayPaused = true;
    setTimeout(() => {
      this.heroAutoplayPaused = false;
    }, 5000);
  }

  private shouldRenderHeroImage(index: number): boolean {
    return index < 3 || index <= this.activeHeroIndex + 1;
  }

  private skipFailedHeroImage(failedId: string): void {
    if (this.heroImages.length <= 1) {
      this.heroImages = [];
      return;
    }

    this.heroImages = this.heroImages.filter((item: HomeHeroDisplayImage): boolean => {
      return item.id !== failedId;
    });
  }

  private syncDashboardStateFromPresenter(): void {
    this.historyLoadFailed = this.dashboardReloadState.historyLoadFailed;
  }

  private async startPhotoDraft(): Promise<void> {
    if (this.isPickingPhoto || this.isImportingPendingPhoto) {
      return;
    }

    this.isPickingPhoto = true;
    const result: PickedPhotoResult = await pickSinglePhoto();
    this.isPickingPhoto = false;

    if (!result.success) {
      if (!result.cancelled && result.message.length > 0) {
        ToastService.show(this.getUIContext(), result.message);
      }
      return;
    }

    ReviewCardStore.createPhotoDraft(
      result.imageUri,
      result.imageWidth,
      result.imageHeight,
      result.imageSizeFallbackUsed
    );
    this.getUIContext().getRouter().pushUrl({ url: EDITOR_PAGE }).catch((error: Error) => {
      console.error(`[HomePage] 进入编辑页失败：${error.message}`);
    });
  }

  private async importPendingPhoto(): Promise<void> {
    if (this.isPickingPhoto || this.isImportingPendingPhoto) {
      return;
    }

    this.isImportingPendingPhoto = true;
    try {
      const result: PickedPhotoDetailListResult = await pickMultiplePhotoDetails(HOME_PENDING_IMPORT_MAX_SELECT_NUMBER);
      if (!result.success) {
        if (!result.cancelled && result.message.length > 0) {
          ToastService.show(this.getUIContext(), result.message);
        }
        return;
      }

      let failedCount: number = 0;
      const photos: Array<PendingReviewPhotoInput> = [];
      for (let index = 0; index < result.photos.length; index += 1) {
        if (result.photos[index].imageSizeFallbackUsed) {
          failedCount += 1;
          continue;
        }
        photos.push({
          photoUri: result.photos[index].imageUri,
          width: result.photos[index].imageWidth,
          height: result.photos[index].imageHeight,
          imageSizeFallbackUsed: result.photos[index].imageSizeFallbackUsed
        });
      }

      const batchResult: PendingReviewPhotoBatchResult = await PendingReviewPhotoStore.addPhotos(
        this.getAbilityContext(),
        photos
      );
      const successCount: number = batchResult.photos.length;
      failedCount += batchResult.failedCount;

      if (successCount <= 0) {
        ToastService.show(this.getUIContext(), failedCount > 0
          ? `成功导入：0，失败：${failedCount}`
          : REVIEW_FLOW_PENDING_IMPORT_FAILED_TEXT);
        return;
      }

      await LearningProgressFormService.refreshAllForms(this.getAbilityContext());

      if (failedCount > 0) {
        ToastService.show(this.getUIContext(), `成功导入：${successCount}，失败：${failedCount}`);
        return;
      }

      ToastService.show(this.getUIContext(), successCount === 1
        ? REVIEW_FLOW_PENDING_IMPORT_SUCCESS_TEXT
        : `已加入待复盘（${successCount} 张）`);
    } finally {
      this.isImportingPendingPhoto = false;
    }
  }

  private shouldShowHistoryDiagnostics(): boolean {
    return this.historyLoadFailed;
  }

  private shouldShowHistorySkeleton(): boolean {
    return this.isHistoryLoading && !this.historyLoadFailed && this.dashboardReloadState.reviewCount === 0;
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
      ToastService.show(this.getUIContext(), REVIEW_FLOW_HOME_COPY_ISSUE_SUCCESS_TEXT);
    } catch (error) {
      ToastService.show(this.getUIContext(), REVIEW_FLOW_HOME_COPY_ISSUE_FAILED_TEXT);
    }
  }

  @Builder
  HeroPanel() {
    Column() {
      AppPageHeader({
        title: '摄影复盘'
      })

      Swiper() {
        if (this.hasUserHeroImages()) {
          ForEach(this.heroImages, (item: HomeHeroDisplayImage, index: number) => {
            this.HeroImageSlide(item, index)
          }, (item: HomeHeroDisplayImage) => item.id)
        } else {
          this.DefaultHeroImageSlide()
        }
      }
      .width('100%')
      .aspectRatio(HOME_HERO_ASPECT_RATIO)
      .autoPlay(this.shouldAutoplayHero() && !this.heroAutoplayPaused)
      .interval(this.heroIntervalSeconds * 1000)
      .indicator(this.resolveHeroIndicator())
      .loop(this.shouldShowHeroIndicator())
      .curve(MotionTokens.curveDecelerate)
      .onChange((index: number) => {
        this.activeHeroIndex = index;
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pauseHeroAutoplayBriefly();
        }
      })
      .borderRadius(HOME_HERO_RADIUS)
      .clip(true)
      .border({ width: 1, color: AppColors.border })
      .shadow(ElevationTokens.medium)
      .margin({ top: AppMetrics.space12 })

      Row({ space: HOME_METHOD_TAG_GAP }) {
        ForEach(this.heroFeatureTags, (item: string) => {
          this.MethodTag(item)
        }, (item: string) => item)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: AppMetrics.space16 })

      Column({ space: AppMetrics.space8 }) {
        this.StartReviewButton()
        this.ImportPendingButton()
      }
      .width('100%')
      .margin({ top: AppMetrics.space20 })
    }
    .width('100%')
    .padding({ left: HOME_SIDE_PADDING, right: HOME_SIDE_PADDING, top: 0, bottom: 0 })
    .backgroundColor(AppColors.pageBackground)
  }

  @Builder
  HeroImageSlide(item: HomeHeroDisplayImage, index: number) {
    Stack({ alignContent: Alignment.BottomStart }) {
      if (this.shouldRenderHeroImage(index)) {
        Image(item.uri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .backgroundColor(AppColors.surfaceMuted)
          .onError(() => {
            this.skipFailedHeroImage(item.id);
          })
      } else {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(AppColors.surfaceMuted)
      }

      this.HeroTextOverlay()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DefaultHeroImageSlide() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image($r('app.media.home_review_hero'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .backgroundColor(AppColors.surfaceMuted)

      this.HeroTextOverlay()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HeroTextOverlay() {
    Column({ space: 6 }) {
      Text('先看关系，再谈意义')
        .fontSize(17)
        .fontWeight(700)
        .fontColor(AppColors.onPrimary)
        .lineHeight(23)
        .maxLines(2)
        .width('100%')

      Text('摄影不是按下快门开始，而是从学会观看开始')
        .fontSize(13)
        .fontColor(AppColors.onPrimaryMuted)
        .lineHeight(17)
        .maxLines(2)
        .width('100%')
    }
    .padding({
      left: HOME_HERO_TEXT_PADDING,
      right: HOME_HERO_TEXT_PADDING,
      top: 40,
      bottom: HOME_HERO_TEXT_BOTTOM
    })
    .width('100%')
    .linearGradient({
      angle: 180,
      colors: [
        [AppColors.transparent, 0],
        [AppColors.heroGradientMiddle, 0.38],
        [AppColors.heroGradientBlue, 0.68],
        [AppColors.heroGradientDeep, 1]
      ]
    })
  }

  @Builder
  DiagnosticsPanel() {
    Column({ space: 6 }) {
      Text(REVIEW_FLOW_HOME_RELOAD_FAILED_TEXT)
        .fontSize(AppTypography.meta)
        .fontColor(AppColors.tagAmberText)
        .lineHeight(AppTypography.metaLineHeight)
        .width('100%')

      SecondaryButton({
        label: REVIEW_FLOW_HOME_COPY_ISSUE_TEXT,
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
  HomeHistorySkeleton() {
    Column({ space: AppMetrics.space12 }) {
      SkeletonBlock({ blockWidth: '38%', blockHeight: 16, blockRadius: 8 })
      Row({ space: AppMetrics.space8 }) {
        Column() {
          SkeletonBlock({ blockHeight: 44, blockRadius: AppMetrics.buttonRadius })
        }
        .layoutWeight(1)

        Column() {
          SkeletonBlock({ blockHeight: 44, blockRadius: AppMetrics.buttonRadius })
        }
        .layoutWeight(1)

        Column() {
          SkeletonBlock({ blockHeight: 44, blockRadius: AppMetrics.buttonRadius })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  MethodTag(label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.primary)
      .height(HOME_METHOD_TAG_HEIGHT)
      .padding({
        left: AppMetrics.compactBadgePaddingHorizontal,
        right: AppMetrics.compactBadgePaddingHorizontal
      })
      .borderRadius(HOME_METHOD_TAG_RADIUS)
      .backgroundColor(AppColors.primarySoft)
      .border({ width: 0.5, color: AppColors.border })
      .shadow(ElevationTokens.subtle)
      .maxLines(1)
  }

  @Builder
  StartReviewButton() {
    PrimaryButton({
      label: this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '导入照片，开始复盘',
      isDisabled: this.isPickingPhoto || this.isImportingPendingPhoto,
      onTap: () => {
        this.startPhotoDraft();
      }
    })
  }

  @Builder
  ImportPendingButton() {
    SecondaryButton({
      label: this.isImportingPendingPhoto ? '正在加入待复盘…' : '导入待复盘',
      isDisabled: this.isPickingPhoto || this.isImportingPendingPhoto,
      onTap: () => {
        this.importPendingPhoto();
      }
    })
  }

  build() {
    Column({ space: AppMetrics.sectionGap }) {
      this.HeroPanel()

      if (this.shouldShowHistoryDiagnostics()) {
        this.DiagnosticsPanel()
      }

      if (this.shouldShowHistorySkeleton()) {
        Column() {
          this.HomeHistorySkeleton()
        }
          .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding })
          .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding({
      left: 0,
      right: 0,
      top: AppMetrics.pageTopPadding,
      bottom: AppMetrics.tabContentBottomPadding
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(AppColors.pageBackground)
  }
}
