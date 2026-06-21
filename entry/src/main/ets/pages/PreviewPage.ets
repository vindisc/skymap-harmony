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
import { ReviewJsonExportResult, ReviewJsonExportService } from '../services/ReviewJsonExportService';
import { stringifyReviewCardExchangeSchemaV1 } from '../services/ReviewCardExchangeSchema';
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
  @State isUploadingHomeStorage: boolean = false;
  @State isExportSnapshotMode: boolean = false;
  @State isExportMenuVisible: boolean = false;
  @State saveStateLabel: PreviewSaveState = PreviewSaveState.UNSAVED;
  @State lastReviewJsonExportMessage: string = '';

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
      promptAction.showToast({ message: '已复制' });
    } catch (error) {
      promptAction.showToast({ message: '复制失败，请稍后重试' });
    }
  }

  private async exportReviewJson(): Promise<void> {
    const context = this.getAbilityContext();
    const result: ReviewJsonExportResult = await ReviewJsonExportService.exportReviewJson(
      context,
      this.document
    );
    if (result.success) {
      try {
        await ReviewCardHistoryService.markExported(context, this.document, result.path);
        this.saveStateLabel = PreviewSaveState.EXPORTED;
      } catch (error) {
      }
    }
    this.lastReviewJsonExportMessage = result.success
      ? `已导出 ${result.fileName}`
      : result.message;
    promptAction.showToast({ message: result.message });
  }

  private async uploadReviewJsonToHomeStorage(): Promise<void> {
    if (this.isUploadingHomeStorage) {
      return;
    }

    this.isUploadingHomeStorage = true;
    try {
      const context = this.getAbilityContext();
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(context);
      const result: HomeStorageOperationResult = await HomeStorageService.uploadReviewJson(
        context,
        this.document,
        reviewerName
      );
      if (result.success) {
        try {
          await ReviewCardHistoryService.markExported(context, this.document, result.remotePath);
          this.saveStateLabel = PreviewSaveState.EXPORTED;
        } catch (error) {
        }
      }
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
    return this.isExporting || this.isUploadingHomeStorage;
  }

  private openExportMenu(): void {
    if (this.isActionBusy()) {
      return;
    }
    this.isExportMenuVisible = true;
  }

  private closeExportMenu(): void {
    this.isExportMenuVisible = false;
  }

  @Builder
  ActionButton(label: string, emphasized: boolean, isDisabled: boolean, onTap: () => void) {
    Button(label)
      .height(AppMetrics.toolbarButtonHeight)
      .width(AppMetrics.toolbarButtonWidth)
      .borderRadius(AppMetrics.capsuleRadius)
      .fontSize(AppTypography.smallButtonText)
      .fontWeight(emphasized ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(isDisabled ? AppColors.secondaryText : (emphasized ? AppColors.onPrimary : AppColors.text))
      .backgroundColor(emphasized ? AppColors.primary : AppColors.surfaceMuted)
      .border({ width: 1, color: emphasized ? AppColors.primaryPressed : AppColors.border })
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
    .backgroundColor(AppColors.onPrimary)
  }

  @Builder
  ExportSheetAction(label: string, onTap: () => void) {
    Button(label)
      .height(AppMetrics.controlHeight)
      .width('100%')
      .borderRadius(AppMetrics.cardRadius)
      .fontSize(AppTypography.body)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .backgroundColor(AppColors.surface)
      .border({ width: 1, color: AppColors.border })
      .onClick(() => {
        this.closeExportMenu();
        onTap();
      })
  }

  @Builder
  ReadingPage() {
    Column() {
      Row({ space: AppMetrics.space8 }) {
        Text('复盘记录')
          .fontSize(AppTypography.level1)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.level1LineHeight)

        Blank()

        Row({ space: AppMetrics.space8 }) {
          this.ActionButton('编辑', false, this.isActionBusy(), () => {
            router.replaceUrl({ url: EDITOR_PAGE });
          })
          this.ActionButton(this.isExporting ? '导出中' : '导出', true, this.isActionBusy(), () => {
            this.openExportMenu();
          })
        }
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: AppMetrics.space8 })
      .width('100%')

      if (this.lastReviewJsonExportMessage.length > 0) {
        Row() {
          Text(this.lastReviewJsonExportMessage)
            .fontSize(AppTypography.caption)
            .fontColor(AppColors.secondaryText)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, bottom: AppMetrics.space8 })
        .width('100%')
      }

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

  @Builder
  ExportMenuSheet() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(AppColors.scrim)
        .onClick(() => {
          this.closeExportMenu();
        })

      Column({ space: AppMetrics.space8 }) {
        Column({ space: AppMetrics.space8 }) {
          Text('导出')
            .fontSize(AppTypography.level2)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .width('100%')

          this.ExportSheetAction('导出 JSON', () => {
            this.exportReviewJson();
          })

          this.ExportSheetAction(this.isUploadingHomeStorage ? '上传中...' : '上传家庭存储', () => {
            this.uploadReviewJsonToHomeStorage();
          })

          this.ExportSheetAction(this.isExporting ? '导出中...' : '导出图片', () => {
            this.exportImage();
          })

          this.ExportSheetAction('复制数据', () => {
            this.copyReviewData();
          })
        }
        .padding(AppMetrics.space16)
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.pageBackground)

        this.ExportSheetAction('取消', () => {
        })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, bottom: AppMetrics.space24 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .zIndex(10)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isExportSnapshotMode) {
        this.HiddenExportSnapshotLayer()
      }

      this.ReadingPage()

      if (this.isExportMenuVisible) {
        this.ExportMenuSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
