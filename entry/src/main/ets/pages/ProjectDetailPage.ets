import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import { AppColors, AppMetrics, AppPageHeader, AppTypography, CompactPrimaryButton, EmptyState, ReviewLibraryListCard } from '../components/AppDesign';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewLibraryFilterOptions, ReviewLibraryFilters, ReviewLibraryService } from '../services/ReviewLibraryService';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';

interface ProjectDetailSelectOption {
  value: string;
}

@Entry
@Component
struct ProjectDetailPage {
  @State summary: ReviewProjectSummary = createDefaultProjectSummary();
  @State allItems: Array<ReviewCardHistoryItem> = [];
  @State visibleItems: Array<ReviewCardHistoryItem> = [];
  @State filters: ReviewLibraryFilters = ReviewLibraryService.createEmptyFilters();
  @State filterOptions: ReviewLibraryFilterOptions = { blockers: [], reviewers: [] };
  @State isCreatingReview: boolean = false;

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
    this.allItems = items;
    this.filterOptions = ReviewLibraryService.buildFilterOptions(items);
    this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
    this.applyFilters();
  }

  private applyFilters(): void {
    this.visibleItems = ReviewLibraryService.filter(this.allItems, this.filters);
  }

  private resetFilters(): void {
    this.filters = ReviewLibraryService.createEmptyFilters();
    this.applyFilters();
  }

  private buildBlockerSelectOptions(): Array<ProjectDetailSelectOption> {
    const options: Array<ProjectDetailSelectOption> = [{ value: '全部卡点' }];
    this.filterOptions.blockers.forEach((blocker: string): void => {
      options.push({ value: blocker });
    });
    return options;
  }

  private buildReviewerSelectOptions(): Array<ProjectDetailSelectOption> {
    const options: Array<ProjectDetailSelectOption> = [{ value: '全部复盘人' }];
    this.filterOptions.reviewers.forEach((reviewer: string): void => {
      options.push({ value: reviewer });
    });
    return options;
  }

  private openHistory(document: ReviewCardDocument): void {
    ReviewCardStore.setCurrentDocument(document);
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  private async createFirstReview(): Promise<void> {
    if (this.isCreatingReview) {
      return;
    }

    this.isCreatingReview = true;
    const result: PickedPhotoResult = await pickSinglePhoto();
    this.isCreatingReview = false;

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

  private confirmDeleteHistory(document: ReviewCardDocument): void {
    AlertDialog.show({
      title: '删除这条复盘记录？',
      message: '只会删除复盘库记录，不会删除原照片或已导出的文件。',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#9A3328',
        action: () => {
          this.deleteHistory(document);
        }
      }
    });
  }

  private async deleteHistory(document: ReviewCardDocument): Promise<void> {
    const items = await ReviewCardHistoryService.deleteDocument(this.getAbilityContext(), document);
    this.allItems = items;
    this.filterOptions = ReviewLibraryService.buildFilterOptions(items);
    this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
    this.applyFilters();
    promptAction.showToast({ message: '已删除复盘记录' });
  }

  @Builder
  SearchAndFilterPanel() {
    Column({ space: AppMetrics.space12 }) {
      TextInput({ placeholder: '搜索标题、画面事实、核心关系、延伸理解、卡点', text: this.filters.query })
        .height(42)
        .fontSize(AppTypography.auxiliary)
        .fontColor(AppColors.text)
        .placeholderColor(AppColors.mutedText)
        .backgroundColor(AppColors.surface)
        .borderRadius(AppMetrics.cardRadius)
        .border({ width: 1, color: AppColors.border })
        .padding({ left: AppMetrics.space12, right: AppMetrics.space12 })
        .onChange((value: string) => {
          this.filters.query = value;
          this.applyFilters();
        })

      Row({ space: AppMetrics.space8 }) {
        Select([
          { value: '全部判断' },
          { value: '成立' },
          { value: '不确定' },
          { value: '不成立' }
        ])
          .selected(['全部判断', '成立', '不确定', '不成立'].indexOf(this.filters.judgement))
          .value(this.filters.judgement)
          .height(34)
          .font({ size: AppTypography.caption })
          .fontColor(AppColors.secondaryText)
          .backgroundColor(AppColors.surface)
          .borderRadius(AppMetrics.cardRadius)
          .border({ width: 1, color: AppColors.border })
          .layoutWeight(1)
          .onSelect((_index: number, value: string) => {
            this.filters.judgement = value;
            this.applyFilters();
          })

        Select(this.buildBlockerSelectOptions())
          .value(this.filters.blocker)
          .height(34)
          .font({ size: AppTypography.caption })
          .fontColor(AppColors.secondaryText)
          .backgroundColor(AppColors.surface)
          .borderRadius(AppMetrics.cardRadius)
          .border({ width: 1, color: AppColors.border })
          .layoutWeight(1)
          .onSelect((_index: number, value: string) => {
            this.filters.blocker = value;
            this.applyFilters();
          })

        Select(this.buildReviewerSelectOptions())
          .value(this.filters.reviewer)
          .height(34)
          .font({ size: AppTypography.caption })
          .fontColor(AppColors.secondaryText)
          .backgroundColor(AppColors.surface)
          .borderRadius(AppMetrics.cardRadius)
          .border({ width: 1, color: AppColors.border })
          .layoutWeight(1)
          .onSelect((_index: number, value: string) => {
            this.filters.reviewer = value;
            this.applyFilters();
          })
      }
      .width('100%')

      Row() {
        Text(`${this.visibleItems.length} / ${this.allItems.length} 条记录`)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .layoutWeight(1)

        Button('清除筛选')
          .height(30)
          .padding({ left: AppMetrics.space12, right: AppMetrics.space12 })
          .borderRadius(AppMetrics.capsuleRadius)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .backgroundColor(AppColors.surfaceMuted)
          .onClick(() => {
            this.resetFilters();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.space12)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceMuted)
  }

  @Builder
  DeleteSwipeAction(document: ReviewCardDocument) {
    Button('删除')
      .height(64)
      .width(72)
      .borderRadius(AppMetrics.cardRadius)
      .fontSize(AppTypography.auxiliary)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .backgroundColor('#B73A31')
      .onClick(() => {
        this.confirmDeleteHistory(document);
      })
  }

  build() {
    Column() {
      Column() {
        AppPageHeader({
          title: '复盘库',
          subtitle: '查看、搜索和筛选所有摄影复盘记录'
        })

        Text(`${this.summary.recordCount} 条复盘记录`)
          .fontSize(AppTypography.auxiliary)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.auxiliaryLineHeight)
          .width('100%')
          .margin({ top: AppMetrics.space12 })

        Column() {
          this.SearchAndFilterPanel()
        }
        .width('100%')
        .margin({ top: AppMetrics.space16 })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: 0 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.allItems.length === 0) {
        Column({ space: AppMetrics.space12 }) {
          EmptyState({
            title: '当前还没有复盘记录',
            message: '可从摄影复盘入口创建第一条复盘'
          })

          CompactPrimaryButton({
            label: this.isCreatingReview ? '选择中...' : '创建第一条复盘',
            isDisabled: this.isCreatingReview,
            buttonWidth: 168,
            onTap: () => {
              this.createFirstReview();
            }
          })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else if (this.visibleItems.length === 0) {
        Column() {
          EmptyState({
            title: '没有匹配结果',
            message: '调整搜索或筛选条件后再查看'
          })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else {
        List({ space: AppMetrics.space8 }) {
          ForEach(this.visibleItems, (item: ReviewCardHistoryItem) => {
            ListItem() {
              ReviewLibraryListCard({
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
              .height(28)
              .width('100%')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
