import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE } from '../app/AppRouter';
import {
  createDefaultReviewCardDocument,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { ReviewCardPreview } from '../components/ReviewCardPreview';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardExportService, ReviewCardExportResult, REVIEW_CARD_EXPORT_ID } from '../services/ReviewCardExportService';

@Entry
@Component
struct PreviewPage {
  @State document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State exportMessage: string = '';
  @State isExporting: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.document = ReviewCardStore.getCurrentDocument();
  }

  private async saveDraft(): Promise<void> {
    this.document = ReviewCardStore.saveCurrentDocument(this.document);
    await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
    this.exportMessage = '复盘记录已保存，首页最近记录会同步更新。';
    promptAction.showToast({ message: '已保存复盘记录' });
  }

  private async exportImage(): Promise<void> {
    if (this.isExporting) {
      return;
    }
    this.isExporting = true;
    const result: ReviewCardExportResult = await ReviewCardExportService.exportSnapshot(this.getAbilityContext());
    this.isExporting = false;
    this.exportMessage = result.success ? `${result.message}：${result.path}` : result.message;
    if (result.success) {
      await ReviewCardHistoryService.markExported(this.getAbilityContext(), this.document, result.path);
    }
    promptAction.showToast({ message: result.success ? '导出完成' : '导出失败' });
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text('复盘卡预览')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F2329')
          Text('确认版式后保存记录或导出图片')
            .fontSize(13)
            .fontColor('#68707D')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('编辑')
          .height(36)
          .borderRadius(6)
          .fontSize(14)
          .fontColor('#1F2329')
          .backgroundColor('#FFFFFF')
          .onClick(() => {
            router.pushUrl({ url: EDITOR_PAGE });
          })
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 18, bottom: 8 })
      .width('100%')

      Scroll() {
        Column() {
          ReviewCardPreview({ document: this.document })
            .id(REVIEW_CARD_EXPORT_ID)
        }
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 18, right: 18, top: 14, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)

      Row({ space: 10 }) {
        Button('编辑')
          .height(46)
          .layoutWeight(1)
          .borderRadius(6)
          .fontSize(14)
          .fontColor('#1F2329')
          .backgroundColor('#EEF2F5')
          .onClick(() => {
            router.pushUrl({ url: EDITOR_PAGE });
          })
        Button('保存')
          .height(46)
          .layoutWeight(1)
          .borderRadius(6)
          .fontSize(14)
          .onClick(() => {
            this.saveDraft();
          })
        Button(this.isExporting ? '正在导出' : '导出图片')
          .height(46)
          .layoutWeight(1)
          .borderRadius(6)
          .fontSize(14)
          .onClick(() => {
            this.exportImage();
          })
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 14 })
      .width('100%')
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 12, color: '#14000000', offsetX: 0, offsetY: -4 })
      if (this.exportMessage.length > 0) {
        Text(this.exportMessage)
          .fontSize(12)
          .fontColor('#68707D')
          .padding({ left: 16, right: 16, bottom: 12 })
          .width('100%')
          .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7F9')
  }
}
