import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import pasteboard from '@ohos.pasteboard';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE } from '../app/AppRouter';
import {
  cloneReviewCardDocument,
  createDefaultReviewCardDocument,
  DEFAULT_REVIEW_JUDGEMENT,
  DEFAULT_REVIEW_TITLE,
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
import { ReviewBundleExportResult, ReviewBundleExportService } from '../services/ReviewBundleExportService';
import {
  ReviewBundleOriginalPhotoExportResult,
  ReviewBundleOriginalPhotoExportService
} from '../services/ReviewBundleOriginalPhotoExportService';
import { stringifyReviewCardExchangeSchemaV1 } from '../services/ReviewCardExchangeSchema';
import { ReviewSettingsService } from '../services/ReviewSettingsService';
import {
  REVIEW_FLOW_EXPORT_FAILED_TEXT,
  REVIEW_FLOW_EXPORT_PENDING_TEXT,
  REVIEW_FLOW_EXPORT_SUCCESS_TEXT,
  REVIEW_FLOW_IMAGE_EXPORT_SUCCESS_TEXT,
  REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT,
  REVIEW_FLOW_BUNDLE_EXPORT_SUCCESS_TEXT,
  REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT,
  REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_PENDING_TEXT,
  REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT,
  REVIEW_FLOW_SAVE_FAILED_TEXT,
  REVIEW_FLOW_SAVE_SUCCESS_TEXT
} from '../services/ReviewFlowFeedback';
import { AppColors, AppMetrics, AppTypography } from '../components/AppDesign';
import { DisplayImageSize, resolveDisplayImageSize } from '../services/PhotoPickerService';
import { hasDisplayableImageUri } from '../utils/ImageLayoutUtils';

enum PreviewSaveState {
  UNSAVED = '未保存',
  SAVED = '已保存',
  EXPORTED = '已导出'
}

const FLOATING_DOCK_TOP_MASK_HEIGHT: number = 8;
const FLOATING_DOCK_SCROLL_CLEARANCE: number = 24;

@Entry
@Component
struct PreviewPage {
  @State document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State isSaving: boolean = false;
  @State isExporting: boolean = false;
  @State isExportingReviewJson: boolean = false;
  @State isExportingReviewBundle: boolean = false;
  @State isExportingOriginalPhotoBundle: boolean = false;
  @State isExportSnapshotMode: boolean = false;
  @State isExportMenuVisible: boolean = false;
  @State saveStateLabel: PreviewSaveState = PreviewSaveState.UNSAVED;
  @State actionFeedbackText: string = '';
  @State reviewerText: string = '';

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.document = ReviewCardStore.getCurrentDocument();
    this.refreshPersistedState();
  }

  private async refreshPersistedState(): Promise<void> {
    await this.loadReviewerText();
    await this.recoverImageSizeIfNeeded();
    await this.ensureCurrentDocumentPersisted();
    await this.syncSaveState();
  }

  private async loadReviewerText(): Promise<void> {
    this.reviewerText = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
  }

  private hasMeaningfulDocument(document: ReviewCardDocument): boolean {
    if (hasDisplayableImageUri(document.imageUri)) {
      return true;
    }

    const content = document.content;
    return (content.title.trim().length > 0 && content.title !== DEFAULT_REVIEW_TITLE) ||
      content.visualFocus.trim().length > 0 ||
      content.focusReason.trim().length > 0 ||
      content.visualPath.trim().length > 0 ||
      content.visibleFacts.trim().length > 0 ||
      content.coreRelation.trim().length > 0 ||
      content.extendedUnderstanding.trim().length > 0 ||
      content.currentBlocker.trim().length > 0 ||
      (content.judgement.trim().length > 0 && content.judgement !== DEFAULT_REVIEW_JUDGEMENT);
  }

  private async ensureCurrentDocumentPersisted(): Promise<void> {
    if (!this.hasMeaningfulDocument(this.document)) {
      return;
    }

    try {
      const items = await ReviewCardHistoryService.load(this.getAbilityContext());
      const currentKey = getReviewDocumentKey(this.document);
      const matchedItem = items.find((item) => getReviewDocumentKey(item.document) === currentKey);
      if (matchedItem) {
        return;
      }

      this.document = ReviewCardStore.saveCurrentDocument(this.document);
      await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
      this.saveStateLabel = PreviewSaveState.SAVED;
    } catch (error) {
    }
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
    if (this.isSaving) {
      return;
    }

    this.isSaving = true;
    try {
      this.document = ReviewCardStore.saveCurrentDocument(this.document);
      await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);
      this.saveStateLabel = PreviewSaveState.SAVED;
      this.actionFeedbackText = REVIEW_FLOW_SAVE_SUCCESS_TEXT;
      promptAction.showToast({ message: REVIEW_FLOW_SAVE_SUCCESS_TEXT });
    } catch (error) {
      this.actionFeedbackText = REVIEW_FLOW_SAVE_FAILED_TEXT;
      promptAction.showToast({ message: REVIEW_FLOW_SAVE_FAILED_TEXT });
    } finally {
      this.isSaving = false;
    }
  }

  private async markExportedQuietly(exportedPath: string): Promise<void> {
    try {
      await ReviewCardHistoryService.markExported(this.getAbilityContext(), this.document, exportedPath);
      this.saveStateLabel = PreviewSaveState.EXPORTED;
    } catch (error) {
      console.warn(`[PreviewPage] 导出成功但导出状态写回失败：${error}`);
    }
  }

  private async exportImage(): Promise<void> {
    if (this.isActionBusy()) {
      return;
    }

    this.isExporting = true;
    this.isExportSnapshotMode = true;
    this.actionFeedbackText = REVIEW_FLOW_EXPORT_PENDING_TEXT;
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
        await this.markExportedQuietly(result.path);
        this.actionFeedbackText = REVIEW_FLOW_IMAGE_EXPORT_SUCCESS_TEXT;
        promptAction.showToast({ message: REVIEW_FLOW_IMAGE_EXPORT_SUCCESS_TEXT });
      } else if (result.cancelled) {
        this.actionFeedbackText = '';
      } else {
        const failedText: string = result.message.length > 0 ? result.message : REVIEW_FLOW_EXPORT_FAILED_TEXT;
        this.actionFeedbackText = failedText;
        promptAction.showToast({ message: failedText });
      }
    } catch (error) {
      this.actionFeedbackText = REVIEW_FLOW_EXPORT_FAILED_TEXT;
      promptAction.showToast({ message: REVIEW_FLOW_EXPORT_FAILED_TEXT });
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

  private async exportReviewJson(): Promise<void> {
    if (this.isExportingReviewJson) {
      return;
    }

    this.isExportingReviewJson = true;
    this.actionFeedbackText = REVIEW_FLOW_EXPORT_PENDING_TEXT;
    const context = this.getAbilityContext();
    try {
      const result: ReviewJsonExportResult = await ReviewJsonExportService.exportReviewJson(
        context,
        this.document
      );
      if (result.success) {
        await this.markExportedQuietly(result.path);
        this.actionFeedbackText = REVIEW_FLOW_EXPORT_SUCCESS_TEXT;
        promptAction.showToast({ message: REVIEW_FLOW_EXPORT_SUCCESS_TEXT });
        return;
      }

      if (result.cancelled) {
        this.actionFeedbackText = '';
        return;
      }

      this.actionFeedbackText = REVIEW_FLOW_EXPORT_FAILED_TEXT;
      promptAction.showToast({ message: REVIEW_FLOW_EXPORT_FAILED_TEXT });
    } catch (error) {
      this.actionFeedbackText = REVIEW_FLOW_EXPORT_FAILED_TEXT;
      promptAction.showToast({ message: REVIEW_FLOW_EXPORT_FAILED_TEXT });
    } finally {
      this.isExportingReviewJson = false;
    }
  }

  private async exportReviewBundleToHomeStorage(): Promise<void> {
    if (this.isExportingReviewBundle) {
      return;
    }

    this.isExportingReviewBundle = true;
    this.isExportSnapshotMode = true;
    this.actionFeedbackText = '复盘包导出中…';
    try {
      await this.waitForExportLayout();
      const context = this.getAbilityContext();
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(context);
      const result: ReviewBundleExportResult = await ReviewBundleExportService.exportReviewBundleToHomeStorage(
        context,
        this.document,
        reviewerName,
        this.getExportComponentId(),
        this.getExportCanvasWidth(),
        this.getExportCanvasHeight(),
        () => {
          this.isExportSnapshotMode = false;
        }
      );
      if (result.success) {
        await this.markExportedQuietly(result.remotePath);
        this.actionFeedbackText = REVIEW_FLOW_BUNDLE_EXPORT_SUCCESS_TEXT;
        promptAction.showToast({ message: REVIEW_FLOW_BUNDLE_EXPORT_SUCCESS_TEXT });
        return;
      }
      console.error(`[PreviewPage] 复盘包导出失败：${result.message}`);
      const failedText: string = result.message.length > 0 ? result.message : REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT;
      this.actionFeedbackText = failedText;
      promptAction.showToast({ message: failedText });
    } catch (error) {
      console.error(`[PreviewPage] 复盘包导出异常：${error}`);
      this.actionFeedbackText = REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT;
      promptAction.showToast({ message: REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT });
    } finally {
      this.isExportSnapshotMode = false;
      this.isExportingReviewBundle = false;
    }
  }

  private async exportOriginalPhotoReviewBundleToHomeStorage(): Promise<void> {
    if (this.isExportingOriginalPhotoBundle) {
      return;
    }

    this.isExportingOriginalPhotoBundle = true;
    this.actionFeedbackText = REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_PENDING_TEXT;
    try {
      const context = this.getAbilityContext();
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(context);
      const result: ReviewBundleOriginalPhotoExportResult = await ReviewBundleOriginalPhotoExportService.exportOriginalPhotoReviewBundleToHomeStorage(
        context,
        this.document,
        reviewerName
      );
      if (result.success) {
        await this.markExportedQuietly(result.remotePath);
        this.actionFeedbackText = REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT;
        promptAction.showToast({ message: REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT });
        return;
      }
      console.error(`[PreviewPage] 含原图复盘包导出失败：${result.message}`);
      const failedText: string = result.message.length > 0 ? result.message : REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT;
      this.actionFeedbackText = failedText;
      promptAction.showToast({ message: failedText });
    } catch (error) {
      console.error(`[PreviewPage] 含原图复盘包导出异常：${error}`);
      this.actionFeedbackText = REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT;
      promptAction.showToast({ message: REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT });
    } finally {
      this.isExportingOriginalPhotoBundle = false;
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
    return this.isSaving ||
      this.isExporting ||
      this.isExportingReviewJson ||
      this.isExportingReviewBundle ||
      this.isExportingOriginalPhotoBundle;
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

  private getFloatingActionBarHeight(): number {
    const feedbackHeight: number = this.actionFeedbackText.length > 0
      ? AppTypography.captionLineHeight + AppMetrics.space8
      : 0;
    return AppMetrics.toolbarButtonHeight + AppMetrics.space10 + AppMetrics.space10 + feedbackHeight;
  }

  private getReadingContentBottomPadding(): number {
    return this.getFloatingActionBarHeight()
      + FLOATING_DOCK_TOP_MASK_HEIGHT
      + AppMetrics.pageBottomPadding
      + FLOATING_DOCK_SCROLL_CLEARANCE;
  }

  @Builder
  ActionButton(label: string, emphasized: boolean, isDisabled: boolean, onTap: () => void) {
    Button(label)
      .height(AppMetrics.toolbarButtonHeight)
      .width('100%')
      .borderRadius(AppMetrics.buttonRadius)
      .fontSize(AppTypography.smallButtonText)
      .fontWeight(emphasized ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(isDisabled ? AppColors.secondaryText : (emphasized ? AppColors.onPrimary : AppColors.text))
      .backgroundColor(emphasized ? AppColors.primary : AppColors.surface)
      .border({ width: 1, color: emphasized ? AppColors.primaryPressed : AppColors.border })
      .opacity(isDisabled ? 0.52 : 1)
      .stateEffect(!isDisabled)
      .enabled(!isDisabled)
      .onClick(() => {
        onTap();
      })
  }

  @Builder
  MoreActionButton(isDisabled: boolean, onTap: () => void) {
    Button('更多')
      .height(AppMetrics.toolbarButtonHeight)
      .width(AppMetrics.toolbarButtonHeight)
      .borderRadius(AppMetrics.buttonRadius)
      .fontSize(AppTypography.smallButtonText)
      .fontWeight(FontWeight.Medium)
      .fontColor(isDisabled ? AppColors.secondaryText : AppColors.text)
      .backgroundColor(AppColors.surface)
      .border({ width: 1, color: AppColors.border })
      .opacity(isDisabled ? 0.52 : 1)
      .stateEffect(!isDisabled)
      .enabled(!isDisabled)
      .onClick(() => {
        onTap();
      })
  }

  @Builder
  FloatingActionBar() {
    Column({ space: AppMetrics.space8 }) {
      if (this.actionFeedbackText.length > 0) {
        Text(this.actionFeedbackText)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      Row({ space: AppMetrics.space8 }) {
        Column() {
          this.ActionButton('编辑', false, this.isActionBusy(), () => {
            router.replaceUrl({ url: EDITOR_PAGE });
          })
        }
        .layoutWeight(1)

        Column() {
          this.ActionButton(this.isExporting ? REVIEW_FLOW_EXPORT_PENDING_TEXT : '导出图片', true, this.isActionBusy(), () => {
            this.exportImage();
          })
        }
        .layoutWeight(2)

        Column() {
          this.MoreActionButton(this.isActionBusy(), () => {
            this.openExportMenu();
          })
        }
        .width(AppMetrics.toolbarButtonHeight)
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
    }
    .padding({ left: AppMetrics.space10, right: AppMetrics.space10, top: AppMetrics.space10, bottom: AppMetrics.space10 })
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .shadow({
      radius: 18,
      color: AppColors.floatingShadow,
      offsetX: 0,
      offsetY: 8
    })
  }

  @Builder
  ExportSnapshotCard() {
    Column() {
      ReviewCardPreview({
        document: this.document,
        renderMode: ReviewCardRenderMode.EXPORT_CARD,
        reviewerText: this.reviewerText,
        exportComponentId: this.getExportComponentId(),
        exportCanvasHeight: this.getExportCanvasHeight()
      })
    }
    .width(this.getExportCanvasWidth())
    .height(this.getExportCanvasHeight())
    .backgroundColor(AppColors.onPrimary)
  }

  @Builder
  ExportSheetSectionTitle(label: string) {
    Text(label)
      .fontSize(AppTypography.caption)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.secondaryText)
      .width('100%')
  }

  @Builder
  ExportSheetAction(label: string, description: string, isDisabled: boolean, onTap: () => void) {
    Column({ space: 3 }) {
      Text(label)
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(isDisabled ? AppColors.secondaryText : AppColors.text)
        .width('100%')

      Text(description)
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.captionLineHeight)
        .width('100%')
    }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .constraintSize({ minHeight: AppMetrics.controlHeight })
      .padding({ left: AppMetrics.space16, right: AppMetrics.space16, top: AppMetrics.space8, bottom: AppMetrics.space8 })
      .width('100%')
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(AppColors.surface)
      .border({ width: 1, color: AppColors.border })
      .opacity(isDisabled ? 0.56 : 1)
      .onClick(() => {
        if (isDisabled) {
          return;
        }
        this.closeExportMenu();
        onTap();
      })
  }

  @Builder
  ReadingPage() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Column({ space: AppMetrics.space8 }) {
          Column() {
            Text('复盘记录')
              .fontSize(AppTypography.level1)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.text)
              .lineHeight(AppTypography.level1LineHeight)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: AppMetrics.space10 })
        .width('100%')

        Scroll() {
          Column() {
            ReadingReviewRecord({
              document: this.document,
              saveStateLabel: this.saveStateLabel
            })
          }
          .alignItems(HorizontalAlign.Start)
          .padding({
            left: AppMetrics.pagePadding,
            right: AppMetrics.pagePadding,
            top: AppMetrics.space10,
            bottom: this.getReadingContentBottomPadding()
          })
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .alignItems(HorizontalAlign.Start)
      .height('100%')
      .width('100%')

      Column() {
        this.FloatingActionBar()
      }
      .padding({
        left: AppMetrics.pagePadding,
        right: AppMetrics.pagePadding,
        top: FLOATING_DOCK_TOP_MASK_HEIGHT,
        bottom: AppMetrics.pageBottomPadding
      })
      .width('100%')
      .backgroundColor(AppColors.pageBackground)
      .hitTestBehavior(HitTestMode.Transparent)
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
        .backgroundColor(AppColors.modalScrim)
        .onClick(() => {
          this.closeExportMenu();
        })

      Column({ space: AppMetrics.space8 }) {
        Column({ space: AppMetrics.space8 }) {
          Text('导出当前复盘')
            .fontSize(AppTypography.level2)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .width('100%')

          this.ExportSheetSectionTitle('常用')

          this.ExportSheetAction(this.isExportingReviewBundle ? '导出中…' : '导出复盘包', '包含复盘数据和导出图，用于家庭存储和 Mac 接力。', this.isActionBusy(), () => {
            this.exportReviewBundleToHomeStorage();
          })

          this.ExportSheetSectionTitle('高级')

          this.ExportSheetAction(this.isExportingOriginalPhotoBundle ? '导出中…' : '导出复盘包（含原图）', '包含原始照片和复盘数据，适合在 Mac 端继续处理。', this.isActionBusy(), () => {
            this.exportOriginalPhotoReviewBundleToHomeStorage();
          })

          this.ExportSheetAction(this.isExportingReviewJson ? REVIEW_FLOW_EXPORT_PENDING_TEXT : '导出 review.json', '只导出复盘数据文件，不包含图片。', this.isActionBusy(), () => {
            this.exportReviewJson();
          })

          this.ExportSheetAction('复制复盘数据', '复制当前复盘的文本数据。', this.isActionBusy(), () => {
            this.copyReviewData();
          })
        }
        .padding(AppMetrics.space16)
        .width('100%')
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.pageBackground)
        .border({ width: 1, color: AppColors.border })

        this.ExportSheetAction('取消', '返回当前复盘。', false, () => {
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
