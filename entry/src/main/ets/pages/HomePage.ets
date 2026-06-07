import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PREVIEW_PAGE, PROJECT_DETAIL_PAGE } from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewProjectStats, ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { ReviewProjectService } from '../services/ReviewProjectService';
import {
  AppColors,
  PrimaryButton,
  ProjectHomeCard,
  RecentReviewCard
} from '../components/AppDesign';

@Entry
@Component
struct HomePage {
  @State isPickingPhoto: boolean = false;
  @State historyItems: Array<ReviewCardHistoryItem> = [];
  @State projectSummary: ReviewProjectSummary = createDefaultProjectSummary();
  @State globalStats: ReviewProjectStats = {
    totalCount: 0,
    validCount: 0,
    unsureCount: 0,
    invalidCount: 0
  };

  aboutToAppear(): void {
    this.reloadHistory();
  }

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private async reloadHistory(): Promise<void> {
    this.historyItems = await ReviewCardHistoryService.load(this.getAbilityContext());
    this.globalStats = ReviewProjectService.buildGlobalStats(this.historyItems);
    this.projectSummary = ReviewProjectService.buildDefaultProjectSummary(this.historyItems);
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
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Text('摄影复盘卡')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(32)
          .width('100%')

        Text('选择照片，写下观察，把每次拍摄沉淀成可回看的复盘记录')
          .fontSize(15)
          .fontColor(AppColors.secondaryText)
          .lineHeight(23)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      PrimaryButton({
        label: this.isPickingPhoto ? '正在打开相册...' : '开始复盘',
        onTap: () => {
          this.startPhotoDraft();
        }
      })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  OverviewStat(label: string, value: number) {
    Column({ space: 6 }) {
      Text(`${value}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .maxLines(1)

      Text(label)
        .fontSize(12)
        .fontColor(AppColors.secondaryText)
        .maxLines(1)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(64)
    .borderRadius(8)
    .backgroundColor(AppColors.surfaceMuted)
  }

  @Builder
  ReviewOverviewPanel() {
    Column() {
      Text('复盘概览')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .width('100%')

      Row({ space: 8 }) {
        this.OverviewStat('总复盘', this.globalStats.totalCount)
        this.OverviewStat('成立', this.globalStats.validCount)
        this.OverviewStat('待判断', this.globalStats.unsureCount)
        this.OverviewStat('不成立', this.globalStats.invalidCount)
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ top: 22 })
  }

  @Builder
  LatestReviewPanel() {
    Column() {
      Text('最近一次复盘')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
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
          .margin({ top: 12 })
      } else {
        Row({ space: 10 }) {
          Column() {
            Text('照片')
              .fontSize(12)
              .fontColor(AppColors.mutedText)
          }
          .justifyContent(FlexAlign.Center)
          .width(72)
          .height(72)
          .borderRadius(9)
          .backgroundColor(AppColors.surfaceMuted)

          Column({ space: 5 }) {
            Text('还没有复盘记录')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.text)
              .width('100%')
            Text('开始第一次复盘后会出现在这里')
              .fontSize(13)
              .fontColor(AppColors.secondaryText)
              .lineHeight(18)
              .width('100%')
            Text('等待开始')
              .fontSize(12)
              .fontColor(AppColors.mutedText)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .alignItems(VerticalAlign.Center)
        .padding({ left: 10, right: 10, top: 10, bottom: 10 })
        .width('100%')
        .constraintSize({ minHeight: 92 })
        .borderRadius(11)
        .backgroundColor(AppColors.surface)
        .border({ width: 1, color: AppColors.border })
        .margin({ top: 12 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ top: 22 })
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
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
          }
          .width('100%')

          ProjectHomeCard({
            summary: this.projectSummary,
            onTap: () => {
              this.openProject();
            }
          })
            .margin({ top: 12 })
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .padding({ left: 22, right: 22, top: 28, bottom: 36 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
