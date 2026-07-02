import common from '@ohos.app.ability.common';
import pasteboard from '@ohos.pasteboard';
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
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';
import { DisplayImageSize, resolveDisplayImageSize } from '../services/PhotoPickerService';
import { hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import { ToastService } from '../services/ToastService';

enum PreviewSaveState {
  UNSAVED = '未保存',
  SAVED = '已保存',
  EXPORTED = '已导出'
}

enum ExportState {
  IDLE = 'idle',
  IMAGE = 'image',
  BUNDLE = 'bundle',
  ORIGINAL = 'original'
}

const EXPORT_ACTION_TIMEOUT_MS: number = 30000;

@Entry
@Component
struct PreviewPage {
  @State document: ReviewCardDocument = createDefaultReviewCardDocument();
  @State isSaving: boolean = false;
  @State exportState: ExportState = ExportState.IDLE;
  @State isExportSnapshotMode: boolean = false;
  @State isExportMenuVisible: boolean = false;
  @State saveStateLabel: PreviewSaveState = PreviewSaveState.UNSAVED;
  @State actionFeedbackText: string = '';
  @State reviewerText: string = '';
  @State pressedActionKey: string = '';

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
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
      ToastService.show(this.getUIContext(), REVIEW_FLOW_SAVE_SUCCESS_TEXT);
    } catch (error) {
      this.actionFeedbackText = REVIEW_FLOW_SAVE_FAILED_TEXT;
      ToastService.show(this.getUIContext(), REVIEW_FLOW_SAVE_FAILED_TEXT);
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

    this.startExportAction(ExportState.IMAGE, '准备导出图片…');
    this.isExportSnapshotMode = true;
    let timeoutId: number = this.startExportTimeout(ExportState.IMAGE);
    try {
      this.actionFeedbackText = '渲染导出图…';
      await this.waitForExportLayout();
      this.actionFeedbackText = '保存到相册…';
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
        ToastService.show(this.getUIContext(), REVIEW_FLOW_IMAGE_EXPORT_SUCCESS_TEXT);
      } else if (result.cancelled) {
        this.actionFeedbackText = '';
      } else {
        const failedText: string = result.message.length > 0 ? result.message : REVIEW_FLOW_EXPORT_FAILED_TEXT;
        this.actionFeedbackText = failedText;
        ToastService.show(this.getUIContext(), failedText);
      }
    } catch (error) {
      this.actionFeedbackText = REVIEW_FLOW_EXPORT_FAILED_TEXT;
      ToastService.show(this.getUIContext(), REVIEW_FLOW_EXPORT_FAILED_TEXT);
    } finally {
      clearTimeout(timeoutId);
      this.isExportSnapshotMode = false;
      this.finishExportAction(ExportState.IMAGE);
    }
  }

  private async copyReviewData(): Promise<void> {
    try {
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(this.getAbilityContext());
      const exchangeJson: string = stringifyReviewCardExchangeSchemaV1(this.document, reviewerName);
      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, exchangeJson);
      await pasteboard.getSystemPasteboard().setData(data);
      ToastService.show(this.getUIContext(), '已复制复盘数据');
    } catch (error) {
      ToastService.show(this.getUIContext(), '复制失败，请稍后重试');
    }
  }

  private async exportReviewBundleToHomeStorage(): Promise<void> {
    if (this.isActionBusy()) {
      return;
    }

    this.startExportAction(ExportState.BUNDLE, '准备导出复盘包…');
    this.isExportSnapshotMode = true;
    let timeoutId: number = this.startExportTimeout(ExportState.BUNDLE);
    try {
      this.actionFeedbackText = '渲染导出图…';
      await this.waitForExportLayout();
      this.actionFeedbackText = '写入家庭存储…';
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
        ToastService.show(this.getUIContext(), REVIEW_FLOW_BUNDLE_EXPORT_SUCCESS_TEXT);
        return;
      }
      console.error(`[PreviewPage] 复盘包导出失败：${result.message}`);
      const failedText: string = result.message.length > 0 ? result.message : REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT;
      this.actionFeedbackText = failedText;
      ToastService.show(this.getUIContext(), failedText);
    } catch (error) {
      console.error(`[PreviewPage] 复盘包导出异常：${error}`);
      this.actionFeedbackText = REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT;
      ToastService.show(this.getUIContext(), REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT);
    } finally {
      clearTimeout(timeoutId);
      this.isExportSnapshotMode = false;
      this.finishExportAction(ExportState.BUNDLE);
    }
  }

  private async exportOriginalPhotoReviewBundleToHomeStorage(): Promise<void> {
    if (this.isActionBusy()) {
      return;
    }

    this.startExportAction(ExportState.ORIGINAL, REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_PENDING_TEXT);
    let timeoutId: number = this.startExportTimeout(ExportState.ORIGINAL);
    try {
      this.actionFeedbackText = '整理原图和复盘数据…';
      const context = this.getAbilityContext();
      const reviewerName: string = await ReviewSettingsService.loadReviewerName(context);
      this.actionFeedbackText = '写入家庭存储…';
      const result: ReviewBundleOriginalPhotoExportResult = await ReviewBundleOriginalPhotoExportService.exportOriginalPhotoReviewBundleToHomeStorage(
        context,
        this.document,
        reviewerName
      );
      if (result.success) {
        await this.markExportedQuietly(result.remotePath);
        this.actionFeedbackText = REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT;
        ToastService.show(this.getUIContext(), REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_SUCCESS_TEXT);
        return;
      }
      console.error(`[PreviewPage] 含原图复盘包导出失败：${result.message}`);
      const failedText: string = result.message.length > 0 ? result.message : REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT;
      this.actionFeedbackText = failedText;
      ToastService.show(this.getUIContext(), failedText);
    } catch (error) {
      console.error(`[PreviewPage] 含原图复盘包导出异常：${error}`);
      this.actionFeedbackText = REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT;
      ToastService.show(this.getUIContext(), REVIEW_FLOW_ORIGINAL_BUNDLE_EXPORT_FAILED_TEXT);
    } finally {
      clearTimeout(timeoutId);
      this.finishExportAction(ExportState.ORIGINAL);
    }
  }

  private startExportAction(state: ExportState, message: string): void {
    this.exportState = state;
    this.actionFeedbackText = message;
  }

  private startExportTimeout(state: ExportState): number {
    return setTimeout(() => {
      if (this.exportState !== state) {
        return;
      }
      this.actionFeedbackText = '导出超时，请重试';
      this.isExportSnapshotMode = false;
      this.exportState = ExportState.IDLE;
      ToastService.show(this.getUIContext(), '导出超时，请重试');
    }, EXPORT_ACTION_TIMEOUT_MS);
  }

  private finishExportAction(state: ExportState): void {
    if (this.exportState === state) {
      this.exportState = ExportState.IDLE;
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
      this.exportState !== ExportState.IDLE;
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

  private isPressed(key: string): boolean {
    return this.pressedActionKey === key;
  }

  private updatePressedAction(event: TouchEvent, key: string, isDisabled: boolean): void {
    if (isDisabled) {
      this.pressedActionKey = '';
      return;
    }
    if (event.type === TouchType.Down) {
      this.pressedActionKey = key;
      return;
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.pressedActionKey = '';
    }
  }

  private getFloatingActionBarHeight(): number {
    const feedbackHeight: number = this.actionFeedbackText.length > 0
      ? AppTypography.captionLineHeight + AppMetrics.space8
      : 0;
    return AppMetrics.toolbarButtonHeight + AppMetrics.floatingDockPadding * 2 + feedbackHeight;
  }

  private getReadingContentBottomPadding(): number {
    return this.getFloatingActionBarHeight()
      + AppMetrics.floatingDockTopMaskHeight
      + AppMetrics.floatingDockBottomPadding
      + AppMetrics.floatingDockScrollClearance;
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
      .backgroundColor(emphasized
        ? (this.isPressed(label) ? AppColors.primaryPressed : AppColors.primary)
        : (this.isPressed(label) ? AppColors.surfaceMuted : AppColors.surfaceElevated))
      .border({ width: 1, color: emphasized ? AppColors.primaryPressed : AppColors.border })
      .shadow(isDisabled ? ElevationTokens.none : (this.isPressed(label) ? ElevationTokens.subtle : ElevationTokens.low))
      .scale({ x: this.isPressed(label) ? MotionTokens.scalePressed : 1, y: this.isPressed(label) ? MotionTokens.scalePressed : 1 })
      .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
      .opacity(isDisabled ? 0.52 : 1)
      .stateEffect(!isDisabled)
      .enabled(!isDisabled)
      .onTouch((event: TouchEvent) => {
        this.updatePressedAction(event, label, isDisabled);
      })
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
      .backgroundColor(this.isPressed('more') ? AppColors.surfaceMuted : AppColors.surfaceElevated)
      .border({ width: 1, color: AppColors.border })
      .shadow(isDisabled ? ElevationTokens.none : (this.isPressed('more') ? ElevationTokens.subtle : ElevationTokens.low))
      .scale({ x: this.isPressed('more') ? MotionTokens.scalePressed : 1, y: this.isPressed('more') ? MotionTokens.scalePressed : 1 })
      .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
      .opacity(isDisabled ? 0.52 : 1)
      .stateEffect(!isDisabled)
      .enabled(!isDisabled)
      .onTouch((event: TouchEvent) => {
        this.updatePressedAction(event, 'more', isDisabled);
      })
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
            this.getUIContext().getRouter().replaceUrl({ url: EDITOR_PAGE }).catch((error: Error) => {
              console.error(`[PreviewPage] 返回编辑页失败：${error.message}`);
            });
          })
        }
        .layoutWeight(1)

        Column() {
          this.ActionButton(this.exportState === ExportState.IMAGE ? REVIEW_FLOW_EXPORT_PENDING_TEXT : '导出图片', true, this.isActionBusy(), () => {
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
    .padding({
      left: AppMetrics.floatingDockPadding,
      right: AppMetrics.floatingDockPadding,
      top: AppMetrics.floatingDockPadding,
      bottom: AppMetrics.floatingDockPadding
    })
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.high)
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
      .backgroundColor(this.isPressed(label) ? AppColors.surfaceMuted : AppColors.surfaceElevated)
      .border({ width: 1, color: AppColors.border })
      .shadow(isDisabled ? ElevationTokens.none : (this.isPressed(label) ? ElevationTokens.medium : ElevationTokens.subtle))
      .scale({ x: this.isPressed(label) ? MotionTokens.scaleSubtle : 1, y: this.isPressed(label) ? MotionTokens.scaleSubtle : 1 })
      .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
      .opacity(isDisabled ? 0.56 : 1)
      .onTouch((event: TouchEvent) => {
        this.updatePressedAction(event, label, isDisabled);
      })
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
        top: AppMetrics.floatingDockTopMaskHeight,
        bottom: AppMetrics.floatingDockBottomPadding
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

          this.ExportSheetAction(this.exportState === ExportState.BUNDLE ? '导出中…' : '导出复盘包', '包含复盘数据和导出图，用于家庭存储和 Mac 接力。', this.isActionBusy(), () => {
            this.exportReviewBundleToHomeStorage();
          })

          this.ExportSheetAction(this.exportState === ExportState.ORIGINAL ? '导出中…' : '导出复盘包（含原图）', '包含原始照片和复盘数据，适合在 Mac 端继续处理。', this.isActionBusy(), () => {
            this.exportOriginalPhotoReviewBundleToHomeStorage();
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

        Button('取消')
          .height(AppMetrics.controlHeight)
          .width('100%')
          .borderRadius(AppMetrics.cardRadius)
          .fontSize(AppTypography.buttonText)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .backgroundColor(AppColors.surfaceElevated)
          .border({ width: 1, color: AppColors.border })
          .shadow(ElevationTokens.low)
          .stateEffect(true)
          .onClick(() => {
            this.closeExportMenu();
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
