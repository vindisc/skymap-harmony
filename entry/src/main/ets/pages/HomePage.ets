import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { formatReviewTime, getImageRatioLabel, SampleImageKind } from '../utils/ImageLayoutUtils';
import { ReviewPhotoBlock } from '../components/ReviewPhotoBlock';

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
      .height(34)
      .borderRadius(6)
      .fontSize(13)
      .fontColor('#46505C')
      .backgroundColor('#F1F3F5')
      .onClick(() => {
        this.startDraft(kind);
      })
  }

  @Builder
  HistoryRow(item: ReviewCardHistoryItem) {
    Row({ space: 12 }) {
      ReviewPhotoBlock({
        imageUri: item.document.imageUri,
        imageWidth: item.document.imageWidth,
        imageHeight: item.document.imageHeight,
        aspectRatioValue: 1.35,
        compact: true
      })
        .width(86)

      Column() {
        Text(item.document.content.title.length > 0 ? item.document.content.title : '未命名复盘')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2329')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 6 }) {
          Text(getImageRatioLabel(item.document.imageWidth, item.document.imageHeight))
            .fontSize(11)
            .fontColor('#2563EB')
            .padding({ left: 7, right: 7, top: 3, bottom: 3 })
            .borderRadius(4)
            .backgroundColor('#EAF2FF')
          Text(formatReviewTime(item.document.updatedAt))
            .fontSize(12)
            .fontColor('#68707D')
          if (item.exportedPath.length > 0) {
            Text('已导出')
              .fontSize(11)
              .fontColor('#2E7D5B')
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .borderRadius(4)
              .backgroundColor('#E9F6F0')
          }
        }
        .margin({ top: 8 })
        .width('100%')

        Text('点击查看复盘卡')
          .fontSize(12)
          .fontColor('#8A919F')
          .margin({ top: 7 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .padding({ top: 12, bottom: 12, left: 12, right: 12 })
    .width('100%')
    .borderRadius(8)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.openHistory(item.document);
    })
  }

  build() {
    Scroll() {
      Column() {
        Text('摄影复盘卡')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')
          .width('100%')
        Text('选择一张照片，写下你的观察，生成一张复盘卡')
          .fontSize(15)
          .fontColor('#68707D')
          .lineHeight(22)
          .margin({ top: 10 })
          .width('100%')

        Button(this.isPickingPhoto ? '正在打开相册...' : '选择照片，开始复盘')
          .height(52)
          .width('100%')
          .borderRadius(6)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 28 })
          .onClick(() => {
            this.startPhotoDraft();
          })

        if (this.statusMessage.length > 0) {
          Text(this.statusMessage)
            .fontSize(13)
            .fontColor('#68707D')
            .margin({ top: 10 })
            .width('100%')
        }

        Column() {
          Row() {
            Text('示例体验')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2329')
            Blank()
            Text('快速看看不同版式')
              .fontSize(12)
              .fontColor('#8A919F')
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
        .padding(14)
        .width('100%')
        .borderRadius(8)
        .backgroundColor('#FFFFFF')
        .margin({ top: 18 })

        Column() {
          Row() {
            Text('最近记录')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F2329')
            Blank()
            if (this.historyItems.length > 0) {
              Text(`${this.historyItems.length} 条`)
                .fontSize(12)
                .fontColor('#8A919F')
            }
          }
          .width('100%')

          if (this.historyItems.length === 0) {
            Column() {
              Text('还没有复盘记录')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1F2329')
              Text('选择一张照片，写下第一眼、判断和卡点，保存后会出现在这里。')
                .fontSize(14)
                .fontColor('#68707D')
                .lineHeight(21)
                .margin({ top: 8 })
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(18)
            .width('100%')
            .borderRadius(8)
            .backgroundColor('#FFFFFF')
            .margin({ top: 12 })
          } else {
            Column({ space: 10 }) {
              ForEach(this.historyItems, (item: ReviewCardHistoryItem) => {
                this.HistoryRow(item)
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
    .backgroundColor('#F6F7F9')
  }
}
