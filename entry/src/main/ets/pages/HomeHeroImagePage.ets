import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import {
  AppColors,
  AppMetrics,
  AppTypography,
  DangerButton,
  EmptyState,
  PrimaryButton,
  SecondaryButton,
  SettingsPageHeader,
  SettingsSectionHeader
} from '../components/AppDesign';
import { pickMultiplePhotos, PickedPhotoListResult } from '../services/PhotoPickerService';
import {
  HomeHeroDisplayImage,
  HomeHeroImageService,
  HomeHeroImportResult
} from '../services/HomeHeroImageService';

const HOME_HERO_MAX_PICK_COUNT: number = 9;
const HOME_HERO_THUMBNAIL_SIZE: number = 72;

@Entry
@Component
struct HomeHeroImagePage {
  private loadRequestId: number = 0;
  @State images: Array<HomeHeroDisplayImage> = [];
  @State isLoading: boolean = false;
  @State isAdding: boolean = false;
  @State isClearing: boolean = false;
  @State deletingImageId: string = '';

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.loadImages();
  }

  onPageShow(): void {
    this.loadImages();
  }

  private async loadImages(): Promise<void> {
    const requestId: number = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    this.isLoading = true;
    try {
      const displayImages: Array<HomeHeroDisplayImage> =
        await HomeHeroImageService.getDisplayImages(this.getAbilityContext());
      if (requestId !== this.loadRequestId) {
        return;
      }
      this.images = displayImages;
    } catch (error) {
      console.warn(`[HomeHeroImagePage] load failed: ${error}`);
      if (requestId === this.loadRequestId) {
        this.images = [];
      }
    } finally {
      if (requestId === this.loadRequestId) {
        this.isLoading = false;
      }
    }
  }

  private resolveStatusText(): string {
    if (this.images.length <= 0) {
      return '正在使用默认首页图';
    }
    if (this.images.length === 1) {
      return '已设置 1 张首页图';
    }
    return `已设置 ${this.images.length} 张首页图，会自动轮播`;
  }

  private async addImages(): Promise<void> {
    if (this.isAdding) {
      return;
    }

    this.isAdding = true;
    try {
      const pickResult: PickedPhotoListResult = await pickMultiplePhotos(HOME_HERO_MAX_PICK_COUNT);
      if (!pickResult.success) {
        if (!pickResult.cancelled && pickResult.message.length > 0) {
          promptAction.showToast({ message: '图片保存失败，请重试' });
        }
        return;
      }

      const importResult: HomeHeroImportResult =
        await HomeHeroImageService.importImages(this.getAbilityContext(), pickResult.imageUris);
      await this.loadImages();
      if (importResult.failedCount > 0 && importResult.importedCount > 0) {
        promptAction.showToast({ message: '部分图片无法保存，请重试' });
        return;
      }
      promptAction.showToast({ message: importResult.message });
    } catch (error) {
      console.warn(`[HomeHeroImagePage] add failed: ${error}`);
      promptAction.showToast({ message: '图片保存失败，请重试' });
    } finally {
      this.isAdding = false;
    }
  }

  private confirmRemoveImage(image: HomeHeroDisplayImage): void {
    if (this.deletingImageId.length > 0) {
      return;
    }

    AlertDialog.show({
      title: '删除这张图片？',
      message: '删除后，首页将不再展示这张图片。',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        action: () => {
          this.removeImage(image.id);
        }
      }
    });
  }

  private async removeImage(imageId: string): Promise<void> {
    if (this.deletingImageId.length > 0) {
      return;
    }

    this.deletingImageId = imageId;
    try {
      const success: boolean = await HomeHeroImageService.removeImage(this.getAbilityContext(), imageId);
      if (!success) {
        promptAction.showToast({ message: '删除失败，请重试' });
        return;
      }
      await this.loadImages();
      promptAction.showToast({ message: this.images.length <= 0 ? '已恢复默认首页图片' : '首页图片已更新' });
    } catch (error) {
      console.warn(`[HomeHeroImagePage] remove failed: ${error}`);
      promptAction.showToast({ message: '删除失败，请重试' });
    } finally {
      this.deletingImageId = '';
    }
  }

  private confirmClearImages(): void {
    if (this.images.length <= 0 || this.isClearing) {
      return;
    }

    AlertDialog.show({
      title: '清空首页图片？',
      message: '清空后，首页会恢复默认图片。',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清空',
        action: () => {
          this.clearImages();
        }
      }
    });
  }

  private async clearImages(): Promise<void> {
    if (this.isClearing) {
      return;
    }

    this.isClearing = true;
    try {
      const success: boolean = await HomeHeroImageService.clearImages(this.getAbilityContext());
      if (!success) {
        promptAction.showToast({ message: '清空失败，请重试' });
        return;
      }
      await this.loadImages();
      promptAction.showToast({ message: '已恢复默认首页图片' });
    } catch (error) {
      console.warn(`[HomeHeroImagePage] clear failed: ${error}`);
      promptAction.showToast({ message: '清空失败，请重试' });
    } finally {
      this.isClearing = false;
    }
  }

  @Builder
  SummaryCard() {
    Column({ space: AppMetrics.space8 }) {
      Text(this.resolveStatusText())
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.bodyLineHeight)
        .width('100%')

      Text('选择一张或多张图片作为首页展示图。多张图片会自动轮播。')
        .fontSize(AppTypography.caption)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.captionLineHeight)
        .width('100%')
        .maxLines(3)
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  ImageRow(item: HomeHeroDisplayImage) {
    Row({ space: AppMetrics.cardGap }) {
      Image(item.uri)
        .width(HOME_HERO_THUMBNAIL_SIZE)
        .height(HOME_HERO_THUMBNAIL_SIZE)
        .objectFit(ImageFit.Cover)
        .borderRadius(14)
        .clip(true)
        .backgroundColor(AppColors.surfaceMuted)

      Column({ space: 4 }) {
        Text(`第 ${item.sortOrder + 1} 张`)
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')

        Text(item.createdAt.length > 0 ? '已添加到首页图片' : '首页展示图')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button(this.deletingImageId === item.id ? '删除中…' : '删除')
        .height(AppMetrics.compactControlHeight)
        .constraintSize({ minWidth: 68 })
        .borderRadius(AppMetrics.buttonRadius)
        .fontSize(AppTypography.smallButtonText)
        .fontWeight(600)
        .fontColor(this.deletingImageId === item.id ? AppColors.secondaryText : AppColors.danger)
        .backgroundColor(AppColors.surfaceTint)
        .border({ width: 1, color: this.deletingImageId === item.id ? AppColors.border : AppColors.danger })
        .enabled(this.deletingImageId.length <= 0)
        .stateEffect(this.deletingImageId.length <= 0)
        .onClick(() => {
          this.confirmRemoveImage(item);
        })
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.listCardPadding)
    .width('100%')
    .borderRadius(AppMetrics.panelRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  ImageList() {
    Column({ space: AppMetrics.space8 }) {
      SettingsSectionHeader({
        title: '已配置图片',
        description: this.images.length > 1 ? '按添加顺序轮播。' : ''
      })

      if (this.images.length <= 0) {
        EmptyState({
          title: '还没有自定义首页图',
          message: '添加图片后，首页会优先展示你选择的图片。'
        })
      } else {
        ForEach(this.images, (item: HomeHeroDisplayImage) => {
          this.ImageRow(item)
        }, (item: HomeHeroDisplayImage) => item.id)
      }
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.sectionGap }) {
        SettingsPageHeader({
          title: '首页图片',
          subtitle: '管理首页展示图。'
        })

        this.SummaryCard()

        Column({ space: AppMetrics.cardGap }) {
          PrimaryButton({
            label: this.isAdding ? '添加中…' : '添加图片',
            isDisabled: this.isAdding || this.isLoading,
            onTap: () => {
              this.addImages();
            }
          })

          Row({ space: AppMetrics.cardGap }) {
            SecondaryButton({
              label: '使用默认图片',
              isDisabled: this.images.length <= 0 || this.isClearing,
              onTap: () => {
                this.confirmClearImages();
              }
            })
            .layoutWeight(1)

            DangerButton({
              label: this.isClearing ? '清空中…' : '清空图片',
              isDisabled: this.images.length <= 0 || this.isClearing,
              onTap: () => {
                this.confirmClearImages();
              }
            })
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')

        this.ImageList()
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({
        left: AppMetrics.pagePadding,
        right: AppMetrics.pagePadding,
        top: AppMetrics.pageTopPadding,
        bottom: AppMetrics.pageBottomPadding + AppMetrics.space24
      })
      .height('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
