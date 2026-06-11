import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PREVIEW_PAGE, PROJECT_DETAIL_PAGE, REVIEW_SETTINGS_PAGE } from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import {
  ReviewProjectSummary,
  createDefaultProjectSummary
} from '../model/ProjectModel';
import { ReviewProjectService } from '../services/ReviewProjectService';
import {
  AppColors,
  AppMetrics,
  AppTypography,
  CompactPrimaryButton,
  ProjectHomeCard,
  RecentReviewCard
} from '../components/AppDesign';

@Component
struct HomeOverviewStatCard {
  @Prop label: string = '';
  @Prop value: number = 0;

  build() {
    Column({ space: AppMetrics.space4 }) {
      Text(`${this.value}`)
        .fontSize(AppTypography.auxiliary)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .maxLines(1)

      Text(this.label)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.secondaryText)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(52)
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceMuted)
  }
}

@Entry
@Component
struct HomePage {
  private reloadRequestId: number = 0;
  @State isPickingPhoto: boolean = false;
  @State projectSummary: ReviewProjectSummary = createDefaultProjectSummary();
  @State totalReviewCount: number = 0;
  @State validReviewCount: number = 0;
  @State unsureReviewCount: number = 0;
  @State invalidReviewCount: number = 0;

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
    const items: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(this.getAbilityContext());
    if (requestId !== this.reloadRequestId) {
      return;
    }

    this.applyHomeData(items);
  }

  private applyHomeData(items: Array<ReviewCardHistoryItem>): void {
    const nextProjectSummary: ReviewProjectSummary = ReviewProjectService.buildDefaultProjectSummary(items);
    const nextOverviewStats = ReviewProjectService.buildGlobalStats(items);
    this.totalReviewCount = nextOverviewStats.totalCount;
    this.validReviewCount = nextOverviewStats.validCount;
    this.unsureReviewCount = nextOverviewStats.unsureCount;
    this.invalidReviewCount = nextOverviewStats.invalidCount;
    this.projectSummary = nextProjectSummary;
  }

  private openHistory(document: ReviewCardDocument): void {
    ReviewCardStore.setCurrentDocument(document);
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  private openProject(): void {
    router.pushUrl({
      url: PROJECT_DETAIL_PAGE,
      params: {
        projectId: 'default'
      }
    });
  }

  private openReviewSettings(): void {
    router.pushUrl({ url: REVIEW_SETTINGS_PAGE });
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

  @Builder
  StartReviewPanel() {
    Column({ space: AppMetrics.space16 }) {
      Row() {
        Column() {
          Text('摄影复盘卡')
            .fontSize(AppTypography.level1)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .lineHeight(AppTypography.level1LineHeight)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('复盘设置')
          .height(32)
          .padding({ left: AppMetrics.space12, right: AppMetrics.space12 })
          .borderRadius(AppMetrics.capsuleRadius)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .backgroundColor(AppColors.surfaceMuted)
          .onClick(() => {
            this.openReviewSettings();
          })
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')

      CompactPrimaryButton({
        label: this.isPickingPhoto ? '打开相册中' : '开始复盘',
        isDisabled: this.isPickingPhoto,
        buttonWidth: 168,
        onTap: () => {
          this.startPhotoDraft();
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  ReviewOverviewPanel() {
    Column() {
      Text('复盘概览')
        .fontSize(AppTypography.level2)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.level2LineHeight)
        .width('100%')

      Row({ space: AppMetrics.space8 }) {
        HomeOverviewStatCard({ label: '总复盘', value: this.totalReviewCount })
        HomeOverviewStatCard({ label: '成立', value: this.validReviewCount })
        HomeOverviewStatCard({ label: '待判断', value: this.unsureReviewCount })
        HomeOverviewStatCard({ label: '不成立', value: this.invalidReviewCount })
      }
      .width('100%')
      .margin({ top: AppMetrics.space12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ top: AppMetrics.space24 })
  }

  @Builder
  LatestReviewPanel() {
    Column() {
      Text('最近一次')
        .fontSize(AppTypography.level2)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.level2LineHeight)
        .width('100%')

      if (this.projectSummary.latestItem) {
        RecentReviewCard({
          item: this.projectSummary.latestItem,
          onTap: () => {
            if (this.projectSummary.latestItem) {
              this.openHistory(this.projectSummary.latestItem.document);
            }
          }
        })
          .margin({ top: AppMetrics.space12 })
      } else {
        Row({ space: AppMetrics.space12 }) {
          Column() {
            Text('照片')
              .fontSize(AppTypography.caption)
              .fontColor(AppColors.mutedText)
          }
          .justifyContent(FlexAlign.Center)
          .width(72)
          .height(72)
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(AppColors.surfaceMuted)

          Column({ space: AppMetrics.space4 }) {
            Text('还没有复盘记录')
              .fontSize(AppTypography.body)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.text)
              .width('100%')
            Text('开始第一次复盘后会出现在这里')
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.secondaryText)
              .lineHeight(AppTypography.auxiliaryLineHeight)
              .width('100%')
            Text('等待开始')
              .fontSize(AppTypography.caption)
              .fontColor(AppColors.mutedText)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .alignItems(VerticalAlign.Center)
        .padding(AppMetrics.space12)
        .width('100%')
        .constraintSize({ minHeight: 96 })
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surface)
        .border({ width: 1, color: AppColors.border })
        .margin({ top: AppMetrics.space12 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ top: AppMetrics.space24 })
  }

  build() {
    Scroll() {
      Column() {
        this.StartReviewPanel()

        this.ReviewOverviewPanel()

        this.LatestReviewPanel()

        Column() {
          Row() {
            Text('我的项目')
              .fontSize(AppTypography.level2)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .lineHeight(AppTypography.level2LineHeight)
          }
          .width('100%')

          ProjectHomeCard({
            summary: this.projectSummary,
            onTap: () => {
              this.openProject();
            }
          })
            .margin({ top: AppMetrics.space12 })
        }
        .width('100%')
        .margin({ top: AppMetrics.space24 })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space24 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
