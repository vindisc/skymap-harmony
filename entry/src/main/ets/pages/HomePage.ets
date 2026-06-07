import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PROJECT_DETAIL_PAGE } from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { ReviewProjectService } from '../services/ReviewProjectService';
import {
  AppColors,
  PrimaryButton,
  ProjectHomeCard
} from '../components/AppDesign';

@Entry
@Component
struct HomePage {
  @State isPickingPhoto: boolean = false;
  @State historyItems: Array<ReviewCardHistoryItem> = [];
  @State projectSummary: ReviewProjectSummary = createDefaultProjectSummary();

  aboutToAppear(): void {
    this.reloadHistory();
  }

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private async reloadHistory(): Promise<void> {
    this.historyItems = await ReviewCardHistoryService.load(this.getAbilityContext());
    this.projectSummary = ReviewProjectService.buildDefaultProjectSummary(this.historyItems);
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
    Column() {
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

  build() {
    Scroll() {
      Column() {
        this.StartReviewPanel()

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
