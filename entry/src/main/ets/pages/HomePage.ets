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
  ReviewProjectSummary,
  createDefaultProjectSummary
} from '../model/ProjectModel';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  EmptyState,
  PrimaryButton,
  RecentReviewCard
} from '../components/AppDesign';
import { formatReviewTime } from '../utils/ImageLayoutUtils';

@Component
export struct HomePage {
  private reloadRequestId: number = 0;
  @State isPickingPhoto: boolean = false;
  @State projectSummary: ReviewProjectSummary = createDefaultProjectSummary();
  @State reviewerName: string = '';
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();

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
    const context = this.getAbilityContext();
    const results = await Promise.all([
      ReviewCardHistoryService.load(context),
      ReviewSettingsService.loadReviewerName(context),
      HomeStorageService.loadSettings(context)
    ]);
    if (requestId !== this.reloadRequestId) {
      return;
    }

    const items: Array<ReviewCardHistoryItem> = results[0] as Array<ReviewCardHistoryItem>;
    const reviewerName: string = results[1] as string;
    const homeStorageSettings: HomeStorageSettings = results[2] as HomeStorageSettings;
    this.reviewerName = reviewerName;
    this.homeStorageSettings = homeStorageSettings;
    this.applyHomeData(items);
  }

  private applyHomeData(items: Array<ReviewCardHistoryItem>): void {
    this.projectSummary = ReviewProjectService.buildDefaultProjectSummary(items);
  }

  private openLatestReview(): void {
    if (!this.projectSummary.latestItem) {
      return;
    }
    ReviewCardStore.setCurrentDocument(this.projectSummary.latestItem.document);
    router.pushUrl({ url: PREVIEW_PAGE });
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

  private isHomeStorageConfigured(): boolean {
    return HomeStorageService.validateSettings(this.homeStorageSettings).length === 0;
  }

  private resolveLastUpdatedText(): string {
    if (this.projectSummary.recordCount === 0 || this.projectSummary.latestUpdatedAt <= 0) {
      return '还没有复盘记录';
    }

    return formatReviewTime(this.projectSummary.latestUpdatedAt);
  }

  private resolveSyncStatusText(): string {
    return this.isHomeStorageConfigured() ? 'SMB 已连接' : '未配置家庭存储';
  }

  private resolveSettingsSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
  }

  @Builder
  StartReviewPanel() {
    Column({ space: AppMetrics.space16 }) {
      Column({ space: AppMetrics.space8 }) {
        Text('摄影复盘卡')
          .fontSize(AppTypography.level2)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.level2LineHeight)
          .width('100%')

        Text('通过持续复盘提升摄影判断力')
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
      }

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
      Column({ space: AppMetrics.space24 }) {
        AppPageHeader({
          title: '首页',
          subtitle: '开始新复盘，或继续查看最近一次记录。'
        })

        this.StartReviewPanel()

        Column({ space: AppMetrics.space12 }) {
          Text('最近一次')
            .fontSize(AppTypography.auxiliary)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .width('100%')

          if (this.projectSummary.latestItem) {
            RecentReviewCard({
              item: this.projectSummary.latestItem,
              onTap: () => {
                this.openLatestReview();
              }
            })
          } else {
            EmptyState({
              title: '还没有复盘记录',
              message: '开始第一条复盘后，这里会展示你最近一次的内容。'
            })
          }
        }

        Column({ space: AppMetrics.space12 }) {
          Text('当前状态')
            .fontSize(AppTypography.auxiliary)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .width('100%')

          Column({ space: AppMetrics.space12 }) {
            Text(`复盘库：${this.projectSummary.recordCount} 条记录`)
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.text)
              .width('100%')

            Text(`最近更新：${this.resolveLastUpdatedText()}`)
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.text)
              .width('100%')

            Text(`同步：${this.resolveSyncStatusText()}`)
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.text)
              .width('100%')

            Text(`复盘人：${this.resolveSettingsSummary()}`)
              .fontSize(AppTypography.auxiliary)
              .fontColor(AppColors.text)
              .width('100%')
          }
          .padding(AppMetrics.space16)
          .width('100%')
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(AppColors.surface)
          .border({ width: 1, color: AppColors.border })
        }
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space24 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
