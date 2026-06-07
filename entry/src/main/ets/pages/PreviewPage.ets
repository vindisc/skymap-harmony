import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE } from '../app/AppRouter';
import {
  createDefaultReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardRenderMode
} from '../model/ReviewCardModel';
import { resolveReviewCardLayoutType } from '../model/ReviewCardLayout';
import { ReviewCardPreview } from '../components/ReviewCardPreview';
import { ReadingReviewRecord } from '../components/ReadingReviewRecord';
import { ReviewCardStylePreset } from '../components/ReviewCardStylePreset';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardExportService, ReviewCardExportResult, REVIEW_CARD_EXPORT_ID } from '../services/ReviewCardExportService';
import { AppColors } from '../components/AppDesign';
import { DisplayImageSize, resolveDisplayImageSize } from '../services/PhotoPickerService';
import { hasDisplayableImageUri } from '../utils/ImageLayoutUtils';

enum PreviewSaveState {
  UNSAVED = '未保存',
  SAVED = '已保存',
  EXPORTED = '已导出'
}

@Entry
@Component
struct PreviewPage {
  @State document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State exportMessage: string = '';
  @State isExporting: boolean = false;
  @State isExportSnapshotMode: boolean = false;
  @State saveStateLabel: PreviewSaveState = PreviewSaveState.UNSAVED;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.document = ReviewCardStore.getCurrentDocument();
    this.recoverImageSizeIfNeeded();
    this.syncSaveState();
  }

  private async recoverImageSizeIfNeeded(): Promise<void> {
    if (!this.document.imageSizeFallbackUsed || !hasDisplayableImageUri(this.document.imageUri)) {
      return;
    }

    try {
      const size: DisplayImageSize = await resolveDisplayImageSize(this.document.imageUri);
      if (size.width <= 0 || size.height <= 0) {
        return;
      }

      const next: ReviewCardDocument = {
        version: this.document.version,
        projectId: this.document.projectId,
        imageUri: this.document.imageUri,
        imageWidth: size.width,
        imageHeight: size.height,
        imageSizeFallbackUsed: false,
        content: {
          title: this.document.content.title,
          firstLook: this.document.content.firstLook,
          judgement: this.document.content.judgement,
          blocker: this.document.content.blocker
        },
        config: {
          templateId: this.document.config.templateId,
          layoutMode: this.document.config.layoutMode,
          background: this.document.config.background,
          textSize: this.document.config.textSize
        },
        createdAt: this.document.createdAt,
        updatedAt: this.document.updatedAt
      };
      this.document = next;
      ReviewCardStore.setCurrentDocument(next);
      await ReviewCardHistoryService.updateDocument(this.getAbilityContext(), next);
    } catch (error) {
    }
  }

  private async syncSaveState(): Promise<void> {
    try {
      const items = await ReviewCardHistoryService.load(this.getAbilityContext());
      const currentKey = getReviewDocumentKey(this.document);
      const matchedItem = items.find((item) => getReviewDocumentKey(item.document) === currentKey);
      if (!matchedItem) {
        this.saveStateLabel = PreviewSaveState.UNSAVED;
        return;
      }

      this.saveStateLabel = matchedItem.exportedPath.length > 0 ? PreviewSaveState.EXPORTED : PreviewSaveState.SAVED;
    } catch (error) {
      this.saveStateLabel = PreviewSaveState.UNSAVED;
    }
  }

  private async saveDraft(): Promise<void> {
    try {
      this.document = ReviewCardStore.saveCurrentDocument(this.document);
      await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
      this.saveStateLabel = PreviewSaveState.SAVED;
      this.exportMessage = '已保存';
      promptAction.showToast({ message: '已保存复盘记录' });
    } catch (error) {
      this.exportMessage = '保存失败，请稍后重试';
      promptAction.showToast({ message: '保存失败，请稍后重试' });
    }
  }

  private async exportImage(): Promise<void> {
    if (this.isExporting) {
      return;
    }
    this.isExporting = true;
    this.isExportSnapshotMode = true;
    try {
      await this.waitForExportLayout();
      const result: ReviewCardExportResult = await ReviewCardExportService.exportSnapshot(
        this.getAbilityContext(),
        this.getExportComponentId()
      );
      this.exportMessage = result.message;
      if (result.savedToPhotoLibrary) {
        await ReviewCardHistoryService.markExported(this.getAbilityContext(), this.document, result.path);
        this.saveStateLabel = PreviewSaveState.EXPORTED;
      }
      promptAction.showToast({ message: result.message });
    } finally {
      this.isExportSnapshotMode = false;
      this.isExporting = false;
    }
  }

  private async waitForExportLayout(): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, 360);
    });
  }

  private getExportComponentId(): string {
    return `${REVIEW_CARD_EXPORT_ID}-${this.document.createdAt}-${this.document.updatedAt}`;
  }

  private getExportCanvasWidth(): number {
    return ReviewCardStylePreset.resolve(
      ReviewCardRenderMode.EXPORT_CARD,
      resolveReviewCardLayoutType(this.document)
    ).canvasWidth;
  }

  @Builder
  ActionButton(label: string, emphasized: boolean, onTap: () => void) {
    Button(label)
      .height(30)
      .padding({ left: emphasized ? 12 : 8, right: emphasized ? 12 : 8 })
      .borderRadius(15)
      .fontSize(13)
      .fontWeight(emphasized ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(emphasized ? AppColors.text : AppColors.secondaryText)
      .backgroundColor(emphasized ? '#ECE7DE' : '#00000000')
      .border(emphasized ? { width: 1, color: '#E2DCCD' } : { width: 0 })
      .stateEffect(true)
      .onClick(() => {
        onTap();
      })
  }

  @Builder
  ExportSnapshotCard() {
    Column() {
      ReviewCardPreview({
        document: this.document,
        renderMode: ReviewCardRenderMode.EXPORT_CARD
      })
    }
    .id(this.getExportComponentId())
    .width(this.getExportCanvasWidth())
    .padding(12)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ReadingPage() {
    Column() {
      Row() {
        Text('复盘记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)

        Blank()

        Row({ space: 8 }) {
          this.ActionButton('编辑', false, () => {
            router.replaceUrl({ url: EDITOR_PAGE });
          })
          this.ActionButton(this.isExporting ? '导出中' : '导出', true, () => {
            this.exportImage();
          })
        }
        .opacity(this.isExporting ? 0.8 : 1)
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 14, bottom: 6 })
      .width('100%')

      Scroll() {
        Column() {
          ReadingReviewRecord({
            document: this.document,
            saveStateLabel: this.saveStateLabel === PreviewSaveState.UNSAVED ? '' : this.saveStateLabel
          })

          if (this.exportMessage.length > 0) {
            Text(this.exportMessage)
              .fontSize(12)
              .fontColor(AppColors.secondaryText)
              .lineHeight(18)
              .maxLines(2)
              .width('100%')
              .margin({ top: 14 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, top: 6, bottom: 28 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  build() {
    if (this.isExportSnapshotMode) {
      Column() {
        this.ExportSnapshotCard()
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 24, bottom: 24 })
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.pageBackground)
    } else {
      Column() {
        this.ReadingPage()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.pageBackground)
    }
  }
}
