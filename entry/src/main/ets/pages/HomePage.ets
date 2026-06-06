import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { SampleImageKind } from '../utils/ImageLayoutUtils';
import { AppColors, EmptyState, PrimaryButton, RecentReviewCard } from '../components/AppDesign';

@Entry
@Component
struct HomePage {
  @State isPickingPhoto: boolean = false;
  @State historyItems: Array<ReviewCardHistoryItem> = [];

  aboutToAppear(): void {
    this.reloadHistory();
  }

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private async reloadHistory(): Promise<void> {
    this.historyItems = await ReviewCardHistoryService.load(this.getAbilityContext());
  }

  private startDraft(kind: SampleImageKind): void {
    ReviewCardStore.createDraft(kind);
    router.pushUrl({ url: EDITOR_PAGE });
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
  SampleChip(label: string, kind: SampleImageKind) {
    Button(label)
      .height(34)
      .borderRadius(7)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .backgroundColor('#F0ECE4')
      .padding({ left: 13, right: 13 })
      .onClick(() => {
        this.startDraft(kind);
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
      Text('选择照片，写下观察，生成一张复盘卡')
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
            Text('示例')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.text)
            Blank()
          }
          .width('100%')

          Row({ space: 8 }) {
            this.SampleChip('横图', 'horizontal')
            this.SampleChip('竖图', 'vertical')
            this.SampleChip('方图', 'square')
          }
          .width('100%')
          .margin({ top: 10 })
        }
        .padding({ left: 2, right: 2, top: 0, bottom: 0 })
        .width('100%')
        .margin({ top: 22 })

        Column() {
          Row() {
            Text('最近记录')
              .fontSize(19)
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
            Column({ space: 10 }) {
              ForEach(this.historyItems, (item: ReviewCardHistoryItem) => {
                RecentReviewCard({
                  item: item,
                  onTap: () => {
                    this.openHistory(item.document);
                  },
                  onDelete: () => {
                    this.confirmDeleteHistory(item.document);
                  }
                })
              }, (item: ReviewCardHistoryItem) => `${item.document.createdAt}`)
            }
            .width('100%')
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
