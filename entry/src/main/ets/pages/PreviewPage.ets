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
import { AppColors, PrimaryButton, SecondaryButton, TagLabel } from '../components/AppDesign';

@Entry
@Component
struct PreviewPage {
  @State document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State exportMessage: string = '';
  @State isExporting: boolean = false;
  @State saveStateLabel: string = '已自动保存';

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.document = ReviewCardStore.getCurrentDocument();
  }

  private async saveDraft(): Promise<void> {
    this.document = ReviewCardStore.saveCurrentDocument(this.document);
    await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
    this.saveStateLabel = '刚刚保存';
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
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .lineHeight(30)
          Text('确认照片、判断和复盘说明是否形成一张完整作品卡。')
            .fontSize(14)
            .fontColor(AppColors.secondaryText)
            .lineHeight(21)
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        TagLabel({ label: this.saveStateLabel, color: AppColors.tagGreenText, tagBackground: AppColors.tagGreen })
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 18, bottom: 8 })
      .width('100%')

      Scroll() {
        Column() {
          ReviewCardPreview({ document: this.document })
            .id(REVIEW_CARD_EXPORT_ID)

          if (this.exportMessage.length > 0) {
            Text(this.exportMessage)
              .fontSize(12)
              .fontColor(AppColors.secondaryText)
              .lineHeight(18)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .padding(12)
              .width('100%')
              .borderRadius(8)
              .backgroundColor(AppColors.surface)
              .border({ width: 1, color: AppColors.border })
              .margin({ top: 18 })
          }
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 18, right: 18, top: 16, bottom: 32 })
        .width('100%')
        .constraintSize({ minHeight: 560 })
      }
      .layoutWeight(1)

      Row({ space: 10 }) {
        SecondaryButton({
          label: '编辑',
          onTap: () => {
            router.pushUrl({ url: EDITOR_PAGE });
          }
        })
          .layoutWeight(1)
        SecondaryButton({
          label: '保存',
          onTap: () => {
            this.saveDraft();
          }
        })
          .layoutWeight(1)
        PrimaryButton({
          label: this.isExporting ? '正在导出' : '导出图片',
          onTap: () => {
            this.exportImage();
          }
        })
          .layoutWeight(1)
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 14 })
      .width('100%')
      .backgroundColor(AppColors.surface)
      .shadow({ radius: 12, color: '#14000000', offsetX: 0, offsetY: -4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
