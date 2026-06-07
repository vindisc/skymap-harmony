import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, HOME_PAGE } from '../app/AppRouter';
import {
  createDefaultReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardLayoutType,
  ReviewCardRenderMode
} from '../model/ReviewCardModel';
import { resolveReviewCardLayoutResolution } from '../model/ReviewCardLayout';
import { ReviewCardPreview } from '../components/ReviewCardPreview';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardExportService, ReviewCardExportResult, REVIEW_CARD_EXPORT_ID } from '../services/ReviewCardExportService';
import { AppColors, PrimaryButton, SecondaryButton } from '../components/AppDesign';
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

  private goHome(): void {
    router.pushUrl({ url: HOME_PAGE });
  }

  private getExportComponentId(): string {
    return `${REVIEW_CARD_EXPORT_ID}-${this.document.createdAt}-${this.document.updatedAt}`;
  }

  private getExportHint(): string {
    const layout = resolveReviewCardLayoutResolution(this.document);
    if (layout.usedFallbackSize) {
      return '未读取到真实尺寸，当前先按兜底比例阅读预览；导出前会继续尝试恢复。';
    }

    if (layout.layoutType === ReviewCardLayoutType.VERTICAL) {
      return '导出时会按竖图成品卡排版：左图右文。';
    }

    if (layout.layoutType === ReviewCardLayoutType.HORIZONTAL) {
      return '导出时会按横图成品卡排版：上图下文。';
    }

    return '导出时会按方图成品卡排版：上图下文。';
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
          Text('确认后可以保存或导出')
            .fontSize(14)
            .fontColor(AppColors.secondaryText)
            .lineHeight(21)
            .margin({ top: 5 })
          Text(this.saveStateLabel)
            .fontSize(12)
            .fontColor(AppColors.mutedText)
            .margin({ top: 8 })
          Text(this.getExportHint())
            .fontSize(12)
            .fontColor(AppColors.secondaryText)
            .lineHeight(18)
            .margin({ top: 8 })
            .width('100%')
            .wordBreak(WordBreak.BREAK_WORD)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('回首页')
          .height(34)
          .width(72)
          .borderRadius(7)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.secondaryText)
          .backgroundColor('#00000000')
          .stateEffect(true)
          .onClick(() => {
            this.goHome();
          })
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 18, bottom: 8 })
      .width('100%')

      Scroll() {
        Column() {
          ReviewCardPreview({
            document: this.document,
            renderMode: this.isExportSnapshotMode
              ? ReviewCardRenderMode.EXPORT_CARD
              : ReviewCardRenderMode.MOBILE_READING
          })
            .id(this.getExportComponentId())

          if (this.exportMessage.length > 0) {
            Text(this.exportMessage)
              .fontSize(12)
              .fontColor(AppColors.secondaryText)
              .lineHeight(18)
              .maxLines(2)
              .width('100%')
              .margin({ top: 12 })
          }
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 18, right: 18, top: 16, bottom: 32 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Row({ space: 10 }) {
        SecondaryButton({
          label: '编辑',
          onTap: () => {
            router.replaceUrl({ url: EDITOR_PAGE });
          }
        })
          .layoutWeight(0.86)
        SecondaryButton({
          label: '保存',
          onTap: () => {
            this.saveDraft();
          }
        })
          .layoutWeight(0.86)
        PrimaryButton({
          label: this.isExporting ? '导出中' : '导出',
          isDisabled: this.isExporting,
          onTap: () => {
            this.exportImage();
          }
        })
          .layoutWeight(1.18)
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 12 })
      .width('100%')
      .backgroundColor(AppColors.surface)
      .shadow({ radius: 12, color: '#14000000', offsetX: 0, offsetY: -4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
