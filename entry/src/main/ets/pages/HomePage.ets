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
  REVIEW_FLOW_HOME_COPY_ISSUE_FAILED_TEXT,
  REVIEW_FLOW_HOME_COPY_ISSUE_SUCCESS_TEXT,
  REVIEW_FLOW_HOME_COPY_ISSUE_TEXT,
  REVIEW_FLOW_HOME_RELOAD_FAILED_TEXT,
  REVIEW_FLOW_IMPORT_PENDING_TEXT
} from '../services/ReviewFlowFeedback';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  SecondaryButton
} from '../components/AppDesign';

const HOME_HERO_ASPECT_RATIO: number = 0.75;
const HOME_SIDE_PADDING: number = 16;
const HOME_HERO_TEXT_PADDING: number = 20;
const HOME_HERO_RADIUS: number = 18;
const HOME_HERO_TEXT_BOTTOM: number = 20;
const HOME_METHOD_TAG_HEIGHT: number = 24;
const HOME_METHOD_TAG_RADIUS: number = 999;
const HOME_METHOD_TAG_GAP: number = 6;
const HOME_PRIMARY_BUTTON_HEIGHT: number = 44;
const HOME_FLOW_CARD_GAP: number = 10;
const HOME_FLOW_CARD_HEIGHT: number = 62;
const HOME_FLOW_CARD_RADIUS: number = 16;

interface ReviewFlowStep {
  title: string;
  description: string;
}

@Component
export struct HomePage {
  private dashboardReloadState: HomeDashboardReloadState = createHomeDashboardReloadState();
  private readonly heroFeatureTags: Array<string> = [
    '视觉落点',
    '视线路径',
    '画面关系',
    '是否成立'
  ];
  private readonly reviewFlowSteps: Array<ReviewFlowStep> = [
    { title: '导入照片', description: '选一张照片' },
    { title: '记录观看', description: '写落点路径' },
    { title: '判断成立', description: '留结论卡点' }
  ];
  @Prop @Watch('refreshHomeData') refreshToken: number = 0;
  @State isPickingPhoto: boolean = false;
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
      promptAction.showToast({ message: REVIEW_FLOW_HOME_COPY_ISSUE_SUCCESS_TEXT });
    } catch (error) {
      promptAction.showToast({ message: REVIEW_FLOW_HOME_COPY_ISSUE_FAILED_TEXT });
    }
  }

  @Builder
  HeroPanel() {
    Column() {
      AppPageHeader({
        title: '摄影复盘',
        subtitle: '从照片里练习观看与判断',
        subtitleTop: 4
      })

      Stack({ alignContent: Alignment.BottomStart }) {
        Image($r('app.media.home_review_hero'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        Column({ space: 5 }) {
          Text('从一张照片开始，练习判断')
            .fontSize(16)
            .fontWeight(600)
            .fontColor(AppColors.onPrimary)
            .lineHeight(21)
            .maxLines(2)
            .width('100%')

          Text('看见落点、路径和关系。')
            .fontSize(13)
            .fontColor('#D9FFFFFF')
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
          colors: [['#00000000', 0], ['#0F121B12', 0.55], ['#0F121B80', 1]]
        })
      }
      .width('100%')
      .aspectRatio(HOME_HERO_ASPECT_RATIO)
      .borderRadius(HOME_HERO_RADIUS)
      .clip(true)
      .border({ width: 1, color: AppColors.border })
      .margin({ top: 12 })

      Scroll() {
        Row({ space: HOME_METHOD_TAG_GAP }) {
          ForEach(this.heroFeatureTags, (item: string) => {
            this.MethodTag(item)
          }, (item: string) => item)
        }
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ top: 10 })

      Column() {
        this.StartReviewButton()
      }
      .width('100%')
      .margin({ top: 12 })

      this.ReviewFlowPanel()
    }
    .width('100%')
    .padding({ left: HOME_SIDE_PADDING, right: HOME_SIDE_PADDING, top: 0, bottom: 0 })
    .backgroundColor(AppColors.pageBackground)
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
  MethodTag(label: string) {
    Text(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.primary)
      .height(HOME_METHOD_TAG_HEIGHT)
      .padding({ left: 10, right: 10 })
      .borderRadius(HOME_METHOD_TAG_RADIUS)
      .backgroundColor('#EDF4F7')
      .border({ width: 1, color: '#DDE8EE' })
      .maxLines(1)
  }

  @Builder
  StartReviewButton() {
    Button(this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '导入照片，开始复盘')
      .height(HOME_PRIMARY_BUTTON_HEIGHT)
      .width('100%')
      .borderRadius(AppMetrics.buttonRadius)
      .fontSize(14)
      .fontWeight(600)
      .fontColor(AppColors.onPrimary)
      .backgroundColor(this.isPickingPhoto ? AppColors.primaryDisabled : AppColors.primary)
      .border({ width: 1, color: this.isPickingPhoto ? AppColors.primaryDisabled : AppColors.primaryPressed })
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

  @Builder
  ReviewFlowPanel() {
    Row({ space: HOME_FLOW_CARD_GAP }) {
      ForEach(this.reviewFlowSteps, (step: ReviewFlowStep) => {
        this.FlowStepCard(step)
      }, (step: ReviewFlowStep) => step.title)
    }
    .width('100%')
    .margin({ top: 14 })
  }

  @Builder
  FlowStepCard(step: ReviewFlowStep) {
    Column({ space: 4 }) {
      Text(step.title)
        .fontSize(12)
        .fontWeight(600)
        .fontColor(AppColors.text)
        .lineHeight(16)
        .maxLines(1)

      Text(step.description)
        .fontSize(10)
        .fontColor(AppColors.secondaryText)
        .lineHeight(14)
        .maxLines(2)
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(HOME_FLOW_CARD_HEIGHT)
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .borderRadius(HOME_FLOW_CARD_RADIUS)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  build() {
    Column({ space: AppMetrics.sectionGap }) {
      this.HeroPanel()

      if (this.shouldShowHistoryDiagnostics()) {
        this.DiagnosticsPanel()
      }
    }
    .width('100%')
    .height('100%')
    .padding({
      left: 0,
      right: 0,
      top: AppMetrics.pageTopPadding,
      bottom: AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(AppColors.pageBackground)
  }
}
