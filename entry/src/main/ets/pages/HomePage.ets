import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import {
  EDITOR_PAGE,
  PROJECT_DETAIL_PAGE,
  REVIEW_SETTINGS_PAGE,
  SYNC_CENTER_PAGE
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
  AppTypography,
  PrimaryButton
} from '../components/AppDesign';
import { formatReviewTime } from '../utils/ImageLayoutUtils';

@Entry
@Component
struct HomePage {
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

  private openSyncCenter(): void {
    router.pushUrl({ url: SYNC_CENTER_PAGE });
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
    return this.reviewerName.length > 0 ? `复盘人：${this.reviewerName}` : '复盘人未设置';
  }

  @Builder
  StartReviewPanel() {
    Column({ space: AppMetrics.space16 }) {
      Column({ space: AppMetrics.space8 }) {
        Text('摄影复盘卡')
          .fontSize(AppTypography.level1)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.level1LineHeight)
          .width('100%')

        Text('开始新的复盘，或从复盘库、同步中心和设置继续后续动作。')
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
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
  HomeEntryCard(title: string, summary: string, detail: string, onTap: () => void) {
    Row({ space: AppMetrics.space16 }) {
      Column({ space: AppMetrics.space4 }) {
        Text(title)
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .width('100%')

        Text(summary)
          .fontSize(AppTypography.auxiliary)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.auxiliaryLineHeight)
          .width('100%')

        Text(detail)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.mutedText)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(AppTypography.body)
        .fontColor(AppColors.mutedText)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.space16)
    .width('100%')
    .constraintSize({ minHeight: 92 })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
    .onClick(() => {
      onTap();
    })
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.space16 }) {
        this.StartReviewPanel()

        this.HomeEntryCard(
          '复盘库',
          this.projectSummary.recordCount > 0 ? `总复盘数 ${this.projectSummary.recordCount}` : '还没有复盘记录',
          `最近更新时间 ${this.resolveLastUpdatedText()}`,
          () => {
            this.openProject();
          }
        )

        this.HomeEntryCard(
          '同步中心',
          this.resolveSyncStatusText(),
          `${this.homeStorageSettings.smbShareName.length > 0 ? this.homeStorageSettings.smbShareName : '家庭存储'} · ${this.homeStorageSettings.remoteDirectory.length > 0 ? this.homeStorageSettings.remoteDirectory : '等待配置'}`,
          () => {
            this.openSyncCenter();
          }
        )

        this.HomeEntryCard(
          '设置',
          this.resolveSettingsSummary(),
          '复盘人设置与家庭存储配置',
          () => {
            this.openReviewSettings();
          }
        )
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
