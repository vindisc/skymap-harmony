import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { SampleImageKind } from '../utils/ImageLayoutUtils';
import { AppColors, EmptyState, PrimaryButton, RecentReviewCard, SecondaryButton, TagLabel } from '../components/AppDesign';

@Entry
@Component
struct HomePage {
  @State statusMessage: string = '';
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

  private async startPhotoDraft(): Promise<void> {
    if (this.isPickingPhoto) {
      return;
    }

    this.isPickingPhoto = true;
    this.statusMessage = '';
    const result: PickedPhotoResult = await pickSinglePhoto();
    this.isPickingPhoto = false;

    if (!result.success) {
      this.statusMessage = result.cancelled ? '' : result.message;
      return;
    }

    ReviewCardStore.createPhotoDraft(result.imageUri, result.imageWidth, result.imageHeight);
    this.statusMessage = result.message;
    router.pushUrl({ url: EDITOR_PAGE });
  }

  @Builder
  SampleChip(label: string, kind: SampleImageKind) {
    Button(label)
      .height(36)
      .borderRadius(7)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .backgroundColor('#EEF1F4')
      .padding({ left: 14, right: 14 })
      .onClick(() => {
        this.startDraft(kind);
      })
  }

  @Builder
  HeroPanel() {
    Column() {
      TagLabel({ label: '摄影复盘卡' })
      Text('把一张照片整理成一次清晰复盘')
        .fontSize(31)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(38)
        .margin({ top: 14 })
        .width('100%')
      Text('选择真实照片，写下第一眼、判断和卡点，生成一张干净的作品卡。')
        .fontSize(15)
        .fontColor(AppColors.secondaryText)
        .lineHeight(23)
        .margin({ top: 10 })
        .width('100%')

      PrimaryButton({
        label: this.isPickingPhoto ? '正在打开相册...' : '选择照片，开始复盘',
        onTap: () => {
          this.startPhotoDraft();
        }
      })
        .margin({ top: 24 })

      Row({ space: 8 }) {
        TagLabel({ label: '真实照片' })
        TagLabel({ label: '自动版式', color: AppColors.secondaryText, tagBackground: '#F1F3F5' })
        TagLabel({ label: '可导出', color: AppColors.secondaryText, tagBackground: '#F1F3F5' })
      }
      .margin({ top: 14 })
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(20)
    .width('100%')
    .borderRadius(8)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
    .shadow({ radius: 16, color: '#12000000', offsetX: 0, offsetY: 6 })
  }

  build() {
    Scroll() {
      Column() {
        this.HeroPanel()

        if (this.statusMessage.length > 0) {
          Text(this.statusMessage)
            .fontSize(13)
            .fontColor(AppColors.secondaryText)
            .lineHeight(19)
            .margin({ top: 12 })
            .width('100%')
        }

        Column() {
          Row() {
            Text('示例体验')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.text)
            Blank()
            Text('不选照片也能试')
              .fontSize(12)
              .fontColor(AppColors.mutedText)
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
        .padding(16)
        .width('100%')
        .borderRadius(8)
        .backgroundColor(AppColors.surface)
        .border({ width: 1, color: AppColors.border })
        .margin({ top: 16 })

        Column() {
          Row() {
            Text('最近记录')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
            Blank()
            if (this.historyItems.length > 0) {
              Text(`${this.historyItems.length} 条`)
                .fontSize(12)
                .fontColor(AppColors.mutedText)
            }
          }
          .width('100%')

          if (this.historyItems.length === 0) {
            EmptyState({
              title: '还没有复盘记录',
              message: '选择一张照片完成第一张复盘后，这里会展示缩略图、方向、保存时间和导出状态。'
            })
              .margin({ top: 12 })
          } else {
            Column({ space: 10 }) {
              ForEach(this.historyItems, (item: ReviewCardHistoryItem) => {
                RecentReviewCard({
                  item: item,
                  onTap: () => {
                    this.openHistory(item.document);
                  }
                })
              }, (item: ReviewCardHistoryItem) => `${item.document.createdAt}`)
            }
            .width('100%')
            .margin({ top: 12 })
          }
        }
        .width('100%')
        .margin({ top: 28 })
      }
      .padding(24)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
