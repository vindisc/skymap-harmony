import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE } from '../app/AppRouter';
import {
  cloneReviewCardDocument,
  createDefaultReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardRenderMode
} from '../model/ReviewCardModel';
import { resolveReviewCardLayoutType } from '../model/ReviewCardLayout';
import { ReviewCardPreview } from '../components/ReviewCardPreview';
import { ReadingReviewRecord } from '../components/ReadingReviewRecord';
import { ReviewCardStylePreset } from '../components/ReviewCardStylePreset';
import { resolveLongFormExportCardHeight } from '../components/LongFormExportReviewCard';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardExportService, ReviewCardExportResult, REVIEW_CARD_EXPORT_ID } from '../services/ReviewCardExportService';
import { stringifyReviewCardExchangeSchemaV1 } from '../services/ReviewCardExchangeSchema';
import { ReviewCardReviewFileService, ReviewCardReviewFileExportResult } from '../services/ReviewCardReviewFileService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';
import { HomeStorageOperationResult, HomeStorageService } from '../services/HomeStorageService';
import { AppColors, AppMetrics, AppTypography } from '../components/AppDesign';
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
  @State isExporting: boolean = false;
  @State isExportingReviewFile: boolean = false;
  @State isUploadingHomeStorage: boolean = false;
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

      const next: ReviewCardDocument = cloneReviewCardDocument(this.document);
      next.imageWidth = size.width;
      next.imageHeight = size.height;
      next.imageSizeFallbackUsed = false;
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
      promptAction.showToast({ message: '已保存复盘记录' });
    } catch (error) {
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
        this.getExportComponentId(),
        () => {
          this.isExportSnapshotMode = false;
        }
      );
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

  private async copyReviewData(): Promise<void> {
    try {
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
      const exchangeJson: string = stringifyReviewCardExchangeSchemaV1(this.document, reviewerName);
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, exchangeJson);
      await pasteboard.getSystemPasteboard().setData(data);
      promptAction.showToast({ message: '已复制复盘数据' });
    } catch (error) {
      promptAction.showToast({ message: '复制失败，请稍后重试' });
    }
  }

  private async exportReviewFile(): Promise<void> {
    if (this.isExportingReviewFile) {
      return;
    }

    this.isExportingReviewFile = true;
    try {
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
      const result: ReviewCardReviewFileExportResult = await ReviewCardReviewFileService.exportReviewJson(
        this.getAbilityContext(),
        this.document,
        reviewerName
      );
      promptAction.showToast({ message: result.message });
    } finally {
      this.isExportingReviewFile = false;
    }
  }

  private async uploadReviewFileToHomeStorage(): Promise<void> {
    if (this.isUploadingHomeStorage) {
      return;
    }

    this.isUploadingHomeStorage = true;
    try {
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
      const result: HomeStorageOperationResult = await HomeStorageService.uploadReviewJson(
        this.getAbilityContext(),
        this.document,
        reviewerName
      );
      promptAction.showToast({ message: result.message });
    } finally {
      this.isUploadingHomeStorage = false;
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

  private getExportCanvasHeight(): number {
    return resolveLongFormExportCardHeight(this.document, this.getExportCanvasWidth());
  }

  private isActionBusy(): boolean {
    return this.isExporting || this.isExportingReviewFile || this.isUploadingHomeStorage;
  }

  @Builder
  ActionButton(label: string, emphasized: boolean, isDisabled: boolean, onTap: () => void) {
    Button(label)
      .height(28)
      .padding({ left: emphasized ? AppMetrics.space12 : AppMetrics.space8, right: emphasized ? AppMetrics.space12 : AppMetrics.space8 })
      .borderRadius(AppMetrics.capsuleRadius)
      .fontSize(AppTypography.caption)
      .fontWeight(emphasized ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(isDisabled ? AppColors.secondaryText : (emphasized ? AppColors.text : AppColors.secondaryText))
      .backgroundColor('#00000000')
      .border(emphasized ? { width: 1, color: isDisabled ? '#E4E7EC' : AppColors.border } : { width: 0 })
      .opacity(isDisabled ? 0.52 : 1)
      .stateEffect(!isDisabled)
      .enabled(!isDisabled)
      .onClick(() => {
        onTap();
      })
  }

  @Builder
  ExportSnapshotCard() {
    Column() {
      ReviewCardPreview({
        document: this.document,
        renderMode: ReviewCardRenderMode.EXPORT_CARD,
        exportComponentId: this.getExportComponentId(),
        exportCanvasHeight: this.getExportCanvasHeight()
      })
    }
    .width(this.getExportCanvasWidth())
    .height(this.getExportCanvasHeight())
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ReadingPage() {
    Column() {
      Column() {
        Text('复盘记录')
          .fontSize(AppTypography.level2)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.level2LineHeight)
          .width('100%')

        Column({ space: AppMetrics.space8 }) {
          Row({ space: AppMetrics.space8 }) {
            this.ActionButton('编辑', false, this.isActionBusy(), () => {
              router.replaceUrl({ url: EDITOR_PAGE });
            })
            this.ActionButton('复制复盘数据', false, this.isActionBusy(), () => {
              this.copyReviewData();
            })
            this.ActionButton(this.isExporting ? '导出中' : '导出图片', true, this.isActionBusy(), () => {
              this.exportImage();
            })
          }
          .height(32)
          .width('100%')

          Row({ space: AppMetrics.space8 }) {
            this.ActionButton(
              this.isExportingReviewFile ? '导出中' : '导出复盘文件',
              false,
              this.isActionBusy(),
              () => {
                this.exportReviewFile();
              })
            this.ActionButton(
              this.isUploadingHomeStorage ? '上传中' : '上传家庭存储',
              false,
              this.isActionBusy(),
              () => {
                this.uploadReviewFileToHomeStorage();
              })
          }
          .height(32)
        }
        .width('100%')
        .margin({ top: AppMetrics.space8 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space12, bottom: AppMetrics.space4 })
      .width('100%')

      Scroll() {
        Column() {
          ReadingReviewRecord({ document: this.document })
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space8, bottom: AppMetrics.space32 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
    .zIndex(1)
  }

  @Builder
  HiddenExportSnapshotLayer() {
    Column() {
      this.ExportSnapshotCard()
    }
    .width(this.getExportCanvasWidth())
    .height(this.getExportCanvasHeight())
    .position({ x: -20000, y: -20000 })
    .hitTestBehavior(HitTestMode.None)
    .zIndex(-1)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isExportSnapshotMode) {
        this.HiddenExportSnapshotLayer()
      }

      this.ReadingPage()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
