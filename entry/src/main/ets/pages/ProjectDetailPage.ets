import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppTypography,
  EmptyState,
  PrimaryButton,
  ProjectReviewCard,
  SecondaryButton
} from '../components/AppDesign';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { ReviewCardDocument, ReviewCardHistoryItem, ReviewJudgementStatus } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';

@Component
export struct ProjectDetailPage {
  @State summary: ReviewProjectSummary = createDefaultProjectSummary();
  @State filteredItems: Array<ReviewCardHistoryItem> = [];
  @State searchText: string = '';
  @State decisionFilter: string = 'all';
  @State isPickingPhoto: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadData();
  }

  onPageShow(): void {
    this.reloadData();
  }

  private async reloadData(): Promise<void> {
    const items = await ReviewCardHistoryService.load(this.getAbilityContext());
    this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
    this.applyFilters();
  }

  private applyFilters(): void {
    this.filteredItems = ReviewProjectService.filterItems(this.summary.items, this.searchText, this.decisionFilter);
  }

  private clearFilters(): void {
    this.searchText = '';
    this.decisionFilter = 'all';
    this.applyFilters();
  }

  private resolveResultCountText(): string {
    if (this.summary.recordCount === 0) {
      return '0';
    }
    return `${this.filteredItems.length}/${this.summary.recordCount}`;
  }

  private hasActiveFilters(): boolean {
    return this.searchText.length > 0 || this.decisionFilter !== 'all';
  }

  private async openCreateFirstReview(): Promise<void> {
    if (this.isPickingPhoto) {
      return;
    }

    this.isPickingPhoto = true;
    const result: PickedPhotoResult = await pickSinglePhoto();
    this.isPickingPhoto = false;

    if (!result.success) {
      if (!result.cancelled && result.message.length > 0) {
        promptAction.showToast({ message: result.message });
      }
      return;
    }

    ReviewCardStore.createPhotoDraft(
      result.imageUri,
      result.imageWidth,
      result.imageHeight,
      result.imageSizeFallbackUsed
    );
    router.pushUrl({ url: EDITOR_PAGE });
  }

  private isFilterSelected(value: string): boolean {
    return this.decisionFilter === value;
  }

  private resolveFilterChipTextColor(value: string): string {
    return this.isFilterSelected(value) ? AppColors.text : AppColors.secondaryText;
  }

  private resolveFilterChipBackgroundColor(value: string): string {
    return this.isFilterSelected(value) ? AppColors.primarySoft : AppColors.surfaceRaised;
  }

  private openHistory(document: ReviewCardDocument): void {
    ReviewCardStore.setCurrentDocument(document);
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  private confirmDeleteHistory(document: ReviewCardDocument): void {
    AlertDialog.show({
      title: '删除这条复盘记录？',
      message: '删除后无法恢复',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: AppColors.danger,
        action: () => {
          this.deleteHistory(document);
        }
      }
    });
  }

  private async deleteHistory(document: ReviewCardDocument): Promise<void> {
    const items = await ReviewCardHistoryService.deleteDocument(this.getAbilityContext(), document);
    this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
    promptAction.showToast({ message: '已删除复盘记录' });
  }

  @Builder
  DeleteSwipeAction(document: ReviewCardDocument) {
    Button('删除')
      .height(AppMetrics.compactControlHeight)
      .width(72)
      .borderRadius(AppMetrics.cardRadius)
      .fontSize(AppTypography.smallButtonText)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.danger)
      .backgroundColor(AppColors.surfaceRaised)
      .border({ width: 1, color: AppColors.danger })
      .onClick(() => {
        this.confirmDeleteHistory(document);
      })
  }

  @Builder
  FilterChip(label: string, value: string) {
    Button(label)
      .height(AppMetrics.filterChipHeight)
      .constraintSize({ minWidth: value === 'all' ? 60 : 72 })
      .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
      .borderRadius(AppMetrics.capsuleRadius)
      .fontSize(AppTypography.meta)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.resolveFilterChipTextColor(value))
      .backgroundColor(this.resolveFilterChipBackgroundColor(value))
      .border({ width: 1, color: this.isFilterSelected(value) ? AppColors.primary : AppColors.border })
      .onClick(() => {
        this.decisionFilter = value;
        this.applyFilters();
      })
  }

  @Builder
  HeaderRow() {
    Column({ space: 10 }) {
      Row() {
        Text('复盘库')
          .fontSize(AppTypography.pageTitle)
          .fontWeight(700)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.pageTitleLineHeight)

        Blank()

        Text(this.resolveResultCountText())
          .fontSize(AppTypography.meta)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.metaLineHeight)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(AppMetrics.capsuleRadius)
          .backgroundColor(AppColors.surfaceMuted)
      }
      .alignItems(VerticalAlign.Center)

      Text('按标题、关系、卡点和状态，把你过去的判断重新找回来。')
        .fontSize(AppTypography.pageSubtitle)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.pageSubtitleLineHeight)
        .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      Column() {
        this.HeaderRow()

        Column({ space: AppMetrics.cardGap }) {
          TextInput({ text: this.searchText, placeholder: '标题、关系、卡点、文件名' })
            .height(AppMetrics.searchHeight)
            .borderRadius(AppMetrics.cardRadius)
            .fontSize(AppTypography.inputText)
            .fontColor(AppColors.text)
            .placeholderColor(AppColors.placeholderText)
            .backgroundColor(AppColors.surfaceRaised)
            .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
            .border({ width: 1, color: AppColors.border })
            .onChange((value: string) => {
              this.searchText = value;
              this.applyFilters();
            })

          Row({ space: AppMetrics.space8 }) {
            this.FilterChip('全部', 'all')
            this.FilterChip('成立', ReviewJudgementStatus.VALID)
            this.FilterChip('待判断', ReviewJudgementStatus.UNSURE)
            this.FilterChip('不成立', ReviewJudgementStatus.INVALID)
          }
          .width('100%')
          .height(AppMetrics.filterChipHeight)

          if (this.hasActiveFilters()) {
            SecondaryButton({
              label: '清空筛选',
              onTap: () => {
                this.clearFilters();
              }
            })
              .width(112)
          }
        }
        .margin({ top: AppMetrics.sectionGap })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: 0 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.summary.recordCount === 0) {
        Column() {
          EmptyState({
            title: '暂无复盘记录',
            message: '从相册开始第一条记录，之后就可以在这里筛选和回看。'
          })

          Row() {
            PrimaryButton({
              label: this.isPickingPhoto ? '打开相册中...' : '创建第一条复盘',
              isDisabled: this.isPickingPhoto,
              onTap: () => {
                this.openCreateFirstReview();
              }
            })
          }
          .width('100%')
          .margin({ top: AppMetrics.space16 })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else if (this.filteredItems.length === 0) {
        Column() {
          EmptyState({
            title: '没有找到匹配的复盘',
            message: '换个关键词，或者清空当前筛选条件。'
          })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else {
        List({ space: AppMetrics.space8 }) {
          ForEach(this.filteredItems, (item: ReviewCardHistoryItem) => {
            ListItem() {
              ProjectReviewCard({
                item: item,
                onTap: () => {
                  this.openHistory(item.document);
                }
              })
            }
            .swipeAction({
              end: () => {
                this.DeleteSwipeAction(item.document);
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: ReviewCardHistoryItem) => `${item.document.createdAt}`)
          ListItem() {
            Column()
              .height(AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding)
              .width('100%')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.cardGap })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
