import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PREVIEW_PAGE, PROJECT_DETAIL_PAGE } from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { ReviewProjectService } from '../services/ReviewProjectService';
import {
  AppColors,
  EmptyState,
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

  private openHistory(document: ReviewCardDocument): void {
    ReviewCardStore.setCurrentDocument(document);
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  private confirmDeleteHistory(document: ReviewCardDocument): void {
    AlertDialog.show({
      title: '删除这条复盘记录？',
      message: '删除后无法恢复',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#9A3328',
        action: () => {
          this.deleteHistory(document);
        }
      }
    });
  }

  private async deleteHistory(document: ReviewCardDocument): Promise<void> {
    this.historyItems = await ReviewCardHistoryService.deleteDocument(this.getAbilityContext(), document);
    this.projectSummary = ReviewProjectService.buildDefaultProjectSummary(this.historyItems);
    promptAction.showToast({ message: '已删除复盘记录' });
  }

  private openProject(): void {
    router.pushUrl({ url: PROJECT_DETAIL_PAGE });
  }

  private getRecentItems(): Array<ReviewCardHistoryItem> {
    return this.historyItems.slice(0, 3);
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
  DeleteSwipeAction(document: ReviewCardDocument) {
    Button('删除')
      .height(66)
      .width(76)
      .borderRadius(8)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .backgroundColor('#B73A31')
      .onClick(() => {
        this.confirmDeleteHistory(document);
      })
  }

  @Builder
  HeroPanel() {
    Column() {
      Text('摄影复盘卡')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(34)
        .width('100%')
      Text('选择照片，写下观察，把每次拍摄沉淀成可回看的复盘记录')
        .fontSize(15)
        .fontColor(AppColors.secondaryText)
        .lineHeight(23)
        .margin({ top: 8 })
        .width('100%')

      PrimaryButton({
        label: this.isPickingPhoto ? '正在打开相册...' : '选择照片，开始复盘',
        onTap: () => {
          this.startPhotoDraft();
        }
      })
        .margin({ top: 24 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Scroll() {
      Column() {
        this.HeroPanel()

        Column() {
          Row() {
            Text('我的复盘')
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
        .margin({ top: 28 })

        Column() {
          Row() {
            Text('最近记录')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
          }
          .width('100%')

          if (this.historyItems.length === 0) {
            EmptyState({
              title: '暂无复盘记录',
              message: ''
            })
              .margin({ top: 12 })
          } else {
            List({ space: 10 }) {
              ForEach(this.getRecentItems(), (item: ReviewCardHistoryItem) => {
                ListItem() {
                  RecentReviewCard({
                    item: item,
                    onTap: () => {
                      this.openHistory(item.document);
                    }
                  })
                }
                .swipeAction({
                  end: () => {
                    this.DeleteSwipeAction(item.document);
                  },
                  edgeEffect: SwipeEdgeEffect.Spring
                })
              }, (item: ReviewCardHistoryItem) => `${item.document.createdAt}`)
            }
            .width('100%')
            .height(this.getRecentItems().length * 98)
            .scrollBar(BarState.Off)
            .margin({ top: 12 })
          }
        }
        .width('100%')
        .margin({ top: 30 })
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
