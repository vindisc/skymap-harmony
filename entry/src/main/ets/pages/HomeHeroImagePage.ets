import common from '@ohos.app.ability.common';
import {
  AppBottomSafeAreaFill,
  AppColors,
  AppMetrics,
  AppTypography,
  SettingsPageHeader
} from '../components/AppDesign';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';
import { pickMultiplePhotos, PickedPhotoListResult } from '../services/PhotoPickerService';
import {
  HomeHeroDisplayImage,
  HomeHeroImageService,
  HomeHeroImportResult
} from '../services/HomeHeroImageService';
import { ToastService } from '../services/ToastService';
import { DialogService } from '../services/DialogService';

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
  @State addRowPressed: boolean = false;
  @State clearActionPressed: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
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

  private async addImages(): Promise<void> {
    if (this.isAdding) {
      return;
    }

    this.isAdding = true;
    try {
      const pickResult: PickedPhotoListResult = await pickMultiplePhotos(HOME_HERO_MAX_PICK_COUNT);
      if (!pickResult.success) {
        if (!pickResult.cancelled && pickResult.message.length > 0) {
          ToastService.show(this.getUIContext(), '图片保存失败，请重试');
        }
        return;
      }

      const importResult: HomeHeroImportResult =
        await HomeHeroImageService.importImages(this.getAbilityContext(), pickResult.imageUris);
      await this.loadImages();
      if (importResult.failedCount > 0 && importResult.importedCount > 0) {
        ToastService.show(this.getUIContext(), '部分图片无法保存，请重试');
        return;
      }
      ToastService.show(this.getUIContext(), importResult.message);
    } catch (error) {
      console.warn(`[HomeHeroImagePage] add failed: ${error}`);
      ToastService.show(this.getUIContext(), '图片保存失败，请重试');
    } finally {
      this.isAdding = false;
    }
  }

  private confirmRemoveImage(image: HomeHeroDisplayImage): void {
    if (this.deletingImageId.length > 0) {
      return;
    }

    DialogService.confirm(this.getUIContext(), {
      title: '删除这张图片？',
      message: '删除后，首页将不再展示这张图片。',
      cancelText: '取消',
      confirmText: '删除',
      confirmColor: AppColors.danger,
      onConfirm: () => {
        this.removeImage(image.id);
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
        ToastService.show(this.getUIContext(), '删除失败，请重试');
        return;
      }
      await this.loadImages();
      ToastService.show(this.getUIContext(), this.images.length <= 0 ? '已恢复默认首页图片' : '首页图片已更新');
    } catch (error) {
      console.warn(`[HomeHeroImagePage] remove failed: ${error}`);
      ToastService.show(this.getUIContext(), '删除失败，请重试');
    } finally {
      this.deletingImageId = '';
    }
  }

  private confirmClearImages(): void {
    if (this.images.length <= 0 || this.isClearing) {
      return;
    }

    DialogService.confirm(this.getUIContext(), {
      title: '清空首页图片？',
      message: '清空后，首页会恢复默认图片。',
      cancelText: '取消',
      confirmText: '清空',
      confirmColor: AppColors.danger,
      onConfirm: () => {
        this.clearImages();
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
        ToastService.show(this.getUIContext(), '清空失败，请重试');
        return;
      }
      await this.loadImages();
      ToastService.show(this.getUIContext(), '已恢复默认首页图片');
    } catch (error) {
      console.warn(`[HomeHeroImagePage] clear failed: ${error}`);
      ToastService.show(this.getUIContext(), '清空失败，请重试');
    } finally {
      this.isClearing = false;
    }
  }

  @Builder
  ImageRow(item: HomeHeroDisplayImage) {
    Row({ space: AppMetrics.cardGap }) {
      Image(item.uri)
        .width(HOME_HERO_THUMBNAIL_SIZE)
        .height(HOME_HERO_THUMBNAIL_SIZE)
        .objectFit(ImageFit.Cover)
        .borderRadius(AppMetrics.thumbnailRadius)
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
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  DefaultImageRow() {
    Row({ space: AppMetrics.cardGap }) {
      Image($r('app.media.home_review_hero'))
        .width(HOME_HERO_THUMBNAIL_SIZE)
        .height(HOME_HERO_THUMBNAIL_SIZE)
        .objectFit(ImageFit.Cover)
        .borderRadius(AppMetrics.thumbnailRadius)
        .clip(true)
        .backgroundColor(AppColors.surfaceMuted)

      Column({ space: 4 }) {
        Text('默认首页图')
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')

        Text(this.images.length <= 0 ? '当前展示，固定保留' : '固定保留，自定义图片会优先轮播')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text(this.images.length <= 0 ? '展示中' : '默认')
        .fontSize(AppTypography.meta)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.images.length <= 0 ? AppColors.tagGreenText : AppColors.mutedText)
        .lineHeight(AppTypography.metaLineHeight)
        .padding({
          left: AppMetrics.compactBadgePaddingHorizontal,
          right: AppMetrics.compactBadgePaddingHorizontal,
          top: AppMetrics.compactBadgePaddingVertical,
          bottom: AppMetrics.compactBadgePaddingVertical
        })
        .borderRadius(AppMetrics.capsuleRadius)
        .backgroundColor(this.images.length <= 0 ? AppColors.tagGreen : AppColors.surfaceMuted)
        .maxLines(1)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.listCardPadding)
    .width('100%')
    .borderRadius(AppMetrics.panelRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
  }

  @Builder
  AddImageRow() {
    Row({ space: AppMetrics.cardGap }) {
      Stack() {
        Text('+')
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isAdding || this.isLoading ? AppColors.mutedText : AppColors.primary)
      }
      .width(HOME_HERO_THUMBNAIL_SIZE)
      .height(HOME_HERO_THUMBNAIL_SIZE)
      .borderRadius(AppMetrics.thumbnailRadius)
      .backgroundColor(AppColors.primarySoft)
      .border({ width: 1, color: AppColors.border })

      Column({ space: 4 }) {
        Text(this.isAdding ? '添加中…' : '添加图片')
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.isAdding || this.isLoading ? AppColors.mutedText : AppColors.primary)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')

        Text('可一次选择多张，加入首页轮播')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(20)
        .fontColor(this.isAdding || this.isLoading ? AppColors.mutedText : AppColors.primary)
        .opacity(this.isAdding || this.isLoading ? 0.5 : 0.8)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.listCardPadding)
    .width('100%')
    .borderRadius(AppMetrics.panelRadius)
    .backgroundColor(this.addRowPressed ? AppColors.surfaceMuted : AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(this.addRowPressed ? ElevationTokens.medium : ElevationTokens.subtle)
    .scale({ x: this.addRowPressed ? MotionTokens.scaleSubtle : 1, y: this.addRowPressed ? MotionTokens.scaleSubtle : 1 })
    .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
    .onTouch((event: TouchEvent) => {
      if (this.isAdding || this.isLoading) {
        this.addRowPressed = false;
        return;
      }
      if (event.type === TouchType.Down) {
        this.addRowPressed = true;
        return;
      }
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.addRowPressed = false;
      }
    })
    .onClick(() => {
      if (this.isAdding || this.isLoading) {
        return;
      }
      this.addImages();
    })
  }

  @Builder
  ClearImagesAction() {
    Button(this.isClearing ? '清空中…' : '清空自定义')
      .height(34)
      .constraintSize({ minWidth: 88 })
      .borderRadius(AppMetrics.capsuleRadius)
      .fontSize(AppTypography.meta)
      .fontWeight(600)
      .fontColor(this.isClearing ? AppColors.secondaryText : AppColors.danger)
      .backgroundColor(this.clearActionPressed ? AppColors.dangerSoft : AppColors.surfaceTint)
      .border({ width: 1, color: this.isClearing ? AppColors.border : AppColors.danger })
      .shadow(this.isClearing ? ElevationTokens.none : ElevationTokens.subtle)
      .scale({ x: this.clearActionPressed ? MotionTokens.scalePressed : 1, y: this.clearActionPressed ? MotionTokens.scalePressed : 1 })
      .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
      .enabled(!this.isClearing && this.images.length > 0)
      .stateEffect(!this.isClearing && this.images.length > 0)
      .onTouch((event: TouchEvent) => {
        if (this.isClearing || this.images.length <= 0) {
          this.clearActionPressed = false;
          return;
        }
        if (event.type === TouchType.Down) {
          this.clearActionPressed = true;
          return;
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.clearActionPressed = false;
        }
      })
      .onClick(() => {
        this.confirmClearImages();
      })
  }

  @Builder
  ImageList() {
    Column({ space: AppMetrics.space8 }) {
      this.DefaultImageRow()

      ForEach(this.images, (item: HomeHeroDisplayImage) => {
        this.ImageRow(item)
      }, (item: HomeHeroDisplayImage) => item.id)

      this.AddImageRow()

      if (this.images.length > 0) {
        Row() {
          this.ClearImagesAction()
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AppBottomSafeAreaFill()

      Scroll() {
        Column({ space: AppMetrics.cardGap }) {
          SettingsPageHeader({
            title: '首页图片'
          })

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
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
