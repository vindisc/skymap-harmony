import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import { ProjectReviewCard, AppColors, EmptyState, PrimaryButton } from '../components/AppDesign';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { ReviewCardStore } from '../services/ReviewCardStore';

@Entry
@Component
struct ProjectDetailPage {
  @State isPickingPhoto: boolean = false;
  @State summary: ReviewProjectSummary = createDefaultProjectSummary();

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadData();
  }

  private async reloadData(): Promise<void> {
    const items = await ReviewCardHistoryService.load(this.getAbilityContext());
    this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
  }

  private goBack(): void {
    router.back();
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
    const items = await ReviewCardHistoryService.deleteDocument(this.getAbilityContext(), document);
    this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
    promptAction.showToast({ message: '已删除复盘记录' });
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
      .height(70)
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

  build() {
    Scroll() {
      Column() {
        Row() {
          Button('返回')
            .height(34)
            .width(64)
            .borderRadius(7)
            .fontSize(13)
            .fontColor(AppColors.secondaryText)
            .backgroundColor('#00000000')
            .onClick(() => {
              this.goBack();
            })

          Blank()
        }
        .width('100%')

        Text(this.summary.project.name)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(34)
          .width('100%')
          .margin({ top: 10 })

        Text(`${this.summary.recordCount} 条复盘记录`)
          .fontSize(14)
          .fontColor(AppColors.secondaryText)
          .lineHeight(22)
          .width('100%')
          .margin({ top: 8 })

        PrimaryButton({
          label: this.isPickingPhoto ? '正在打开相册...' : '添加照片复盘',
          onTap: () => {
            this.startPhotoDraft();
          }
        })
          .margin({ top: 20 })

        if (this.summary.recordCount === 0) {
          EmptyState({
            title: '还没有复盘记录',
            message: '添加一张照片开始'
          })
            .margin({ top: 22 })
        } else {
          List({ space: 12 }) {
            ForEach(this.summary.items, (item: ReviewCardHistoryItem) => {
              ListItem() {
                ProjectReviewCard({
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
          .height(this.summary.items.length * 112)
          .scrollBar(BarState.Off)
          .margin({ top: 22 })
        }
      }
      .padding({ left: 20, right: 20, top: 18, bottom: 32 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
