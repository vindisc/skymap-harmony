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
import { ReviewCardPreview } from '../components/ReviewCardPreview';
import { ReadingReviewRecord } from '../components/ReadingReviewRecord';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardExportService, ReviewCardExportResult, REVIEW_CARD_EXPORT_ID } from '../services/ReviewCardExportService';
import { AppColors, SecondaryButton } from '../components/AppDesign';
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

  private goBack(): void {
    router.back();
  }

  private getExportComponentId(): string {
    return `${REVIEW_CARD_EXPORT_ID}-${this.document.createdAt}-${this.document.updatedAt}`;
  }

  build() {
    Column() {
      Row() {
        Button('返回')
          .height(34)
          .width(64)
          .borderRadius(7)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.secondaryText)
          .backgroundColor('#00000000')
          .stateEffect(true)
          .onClick(() => {
            this.goBack();
          })

        Column() {
          Text('复盘记录')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.text)
            .lineHeight(30)
            .width('100%')
          Text(this.saveStateLabel)
            .fontSize(12)
            .fontColor(AppColors.mutedText)
            .margin({ top: 6 })
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })

        Row({ space: 8 }) {
          SecondaryButton({
            label: '编辑',
            onTap: () => {
              router.replaceUrl({ url: EDITOR_PAGE });
            }
          })
            .width(76)

          SecondaryButton({
            label: this.isExporting ? '导出中' : '导出',
            onTap: () => {
              this.exportImage();
            }
          })
            .width(76)
            .opacity(this.isExporting ? 0.72 : 1)
        }
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: 20, right: 20, top: 18, bottom: 12 })
      .width('100%')

      Scroll() {
        Column() {
          ReadingReviewRecord({
            document: this.document
          })

          if (this.exportMessage.length > 0) {
            Text(this.exportMessage)
              .fontSize(12)
              .fontColor(AppColors.secondaryText)
              .lineHeight(18)
              .maxLines(2)
              .width('100%')
              .margin({ top: 16 })
          }

          if (this.isExportSnapshotMode) {
            Column() {
              ReviewCardPreview({
                document: this.document,
                renderMode: ReviewCardRenderMode.EXPORT_CARD
              })
            }
            .id(this.getExportComponentId())
            .margin({ top: 24 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, top: 10, bottom: 32 })
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
