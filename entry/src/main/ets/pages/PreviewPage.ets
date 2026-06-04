import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
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
    ReviewCardStore.saveCurrentDocument(this.document);
    await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
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
        Button('返回编辑')
          .height(36)
          .borderRadius(6)
          .fontSize(14)
          .onClick(() => {
            router.back();
          })
        Blank()
      }
      .padding({ left: 16, right: 16, top: 16 })
      .width('100%')

      Scroll() {
        Column() {
          ReviewCardPreview({ document: this.document })
            .id(REVIEW_CARD_EXPORT_ID)
        }
        .padding(20)
        .width('100%')
      }
      .layoutWeight(1)

      Row({ space: 10 }) {
        Button('保存草稿')
          .height(46)
          .layoutWeight(1)
          .borderRadius(6)
          .fontSize(15)
          .onClick(() => {
            this.saveDraft();
          })
        Button(this.isExporting ? '正在导出' : '导出图片')
          .height(46)
          .layoutWeight(1)
          .borderRadius(6)
          .fontSize(15)
          .onClick(() => {
            this.exportImage();
          })
      }
      .padding(16)
      .width('100%')
      .backgroundColor('#FFFFFF')
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
