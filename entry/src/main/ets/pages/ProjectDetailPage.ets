import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  EmptyState,
  PrimaryButton,
  ProjectReviewCard,
  SecondaryButton
} from '../components/AppDesign';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import {
  createDefaultReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import {
  REVIEW_FLOW_DELETE_CONFIRM_MESSAGE,
  REVIEW_FLOW_DELETE_CONFIRM_TITLE,
  REVIEW_FLOW_DELETE_FAILED_TEXT,
  REVIEW_FLOW_DELETE_PENDING_TEXT,
  REVIEW_FLOW_DELETE_SUCCESS_TEXT,
  REVIEW_FLOW_IMPORT_PENDING_TEXT
} from '../services/ReviewFlowFeedback';

const DELETE_SWIPE_ACTION_WIDTH: number = 92;
const DELETE_SWIPE_BUTTON_WIDTH: number = 68;
const LIBRARY_HEADER_CONTROL_GAP: number = AppMetrics.space10;
const LIBRARY_LIST_TOP_GAP: number = AppMetrics.space8;
const LIBRARY_BOTTOM_CLEARANCE: number = AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding + AppMetrics.space8;

@Component
export struct ProjectDetailPage {
  private loadRequestId: number = 0;
  @Prop @Watch('refreshReviewLibraryData') refreshToken: number = 0;
  @State summary: ReviewProjectSummary = createDefaultProjectSummary();
  @State filteredItems: Array<ReviewCardHistoryItem> = [];
  @State searchText: string = '';
  @State decisionFilter: string = 'all';
  @State isPickingPhoto: boolean = false;
  @State deletingReviewKey: string = '';
  @State libraryLoadFailed: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadData();
  }

  onPageShow(): void {
    this.reloadData();
  }

  refreshReviewLibraryData(): void {
    this.reloadData();
  }

  private async reloadData(): Promise<void> {
    const requestId: number = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    try {
      const items = await ReviewCardHistoryService.load(this.getAbilityContext());
      if (requestId !== this.loadRequestId) {
        return;
      }
      this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
      this.libraryLoadFailed = false;
      this.applyFilters();
    } catch (error) {
      if (requestId !== this.loadRequestId) {
        return;
      }
      this.libraryLoadFailed = true;
    }
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
    return this.isFilterSelected(value) ? AppColors.primary : AppColors.secondaryText;
  }

  private resolveFilterChipBackgroundColor(value: string): string {
    return this.isFilterSelected(value) ? AppColors.primarySoft : AppColors.surface;
  }

  private openHistory(document: ReviewCardDocument): void {
    ReviewCardStore.setCurrentDocument(document);
    router.pushUrl({ url: PREVIEW_PAGE });
  }

  private confirmDeleteHistory(document: ReviewCardDocument): void {
    if (this.deletingReviewKey.length > 0) {
      return;
    }

    AlertDialog.show({
      title: REVIEW_FLOW_DELETE_CONFIRM_TITLE,
      message: REVIEW_FLOW_DELETE_CONFIRM_MESSAGE,
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
    const deletingKey: string = getReviewDocumentKey(document);
    if (this.deletingReviewKey.length > 0) {
      return;
    }

    this.deletingReviewKey = deletingKey;
    const previousItems: Array<ReviewCardHistoryItem> = this.summary.items;
    const nextItems: Array<ReviewCardHistoryItem> = previousItems.filter((item: ReviewCardHistoryItem): boolean => {
      return getReviewDocumentKey(item.document) !== deletingKey;
    });
    this.summary = ReviewProjectService.buildDefaultProjectSummary(nextItems);
    this.applyFilters();
    try {
      const items = await ReviewCardHistoryService.deleteDocument(this.getAbilityContext(), document);
      this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
      this.applyFilters();
      const currentDocument: ReviewCardDocument = ReviewCardStore.getCurrentDocument();
      if (getReviewDocumentKey(currentDocument) === deletingKey) {
        ReviewCardStore.setCurrentDocument(this.summary.items.length > 0
          ? this.summary.items[0].document
          : createDefaultReviewCardDocument());
      }
      promptAction.showToast({ message: REVIEW_FLOW_DELETE_SUCCESS_TEXT });
      this.reloadData();
    } catch (error) {
      this.summary = ReviewProjectService.buildDefaultProjectSummary(previousItems);
      this.applyFilters();
      promptAction.showToast({ message: REVIEW_FLOW_DELETE_FAILED_TEXT });
      this.reloadData();
    } finally {
      this.deletingReviewKey = '';
    }
  }

  @Builder
  DeleteSwipeAction(document: ReviewCardDocument) {
    Row() {
      Button(this.deletingReviewKey === getReviewDocumentKey(document) ? REVIEW_FLOW_DELETE_PENDING_TEXT : '删除')
        .height(AppMetrics.compactControlHeight)
        .width(DELETE_SWIPE_BUTTON_WIDTH)
        .borderRadius(AppMetrics.buttonRadius)
        .fontSize(AppTypography.smallButtonText)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.dangerPressed)
        .backgroundColor(AppColors.dangerSoft)
        .shadow({
          radius: 10,
          color: '#14000000',
          offsetX: 0,
          offsetY: 3
        })
        .opacity(this.deletingReviewKey === getReviewDocumentKey(document) ? 0.52 : 1)
        .stateEffect(this.deletingReviewKey.length === 0)
        .enabled(this.deletingReviewKey.length === 0)
        .onClick(() => {
          if (this.deletingReviewKey.length > 0) {
            return;
          }
          this.confirmDeleteHistory(document);
        })
    }
    .width(DELETE_SWIPE_ACTION_WIDTH)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ left: AppMetrics.space8, right: 0 })
  }

  @Builder
  FilterChip(label: string, value: string) {
    Button(label)
      .height(AppMetrics.filterChipHeight)
      .constraintSize({ minWidth: value === 'all' ? 60 : 72 })
      .padding({ left: 14, right: 14 })
      .borderRadius(12)
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
  SearchField() {
    Row({ space: 10 }) {
      Text('⌕')
        .fontSize(18)
        .fontColor(AppColors.placeholderText)

      TextInput({ text: this.searchText, placeholder: '标题、关系、卡点、文件名' })
        .layoutWeight(1)
        .height(AppMetrics.searchHeight)
        .fontSize(AppTypography.inputText)
        .fontColor(AppColors.text)
        .placeholderColor(AppColors.placeholderText)
        .backgroundColor(AppColors.transparent)
        .padding({ left: 0, right: 0 })
        .onChange((value: string) => {
          this.searchText = value;
          this.applyFilters();
        })

      if (this.searchText.length > 0) {
        Button('×')
          .height(34)
          .width(34)
          .padding(0)
          .borderRadius(17)
          .fontSize(18)
          .fontColor(AppColors.secondaryText)
          .backgroundColor(AppColors.surfaceMuted)
          .stateEffect(true)
          .onClick(() => {
            this.searchText = '';
            this.applyFilters();
          })
      }
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height(AppMetrics.searchHeight)
    .padding({ left: 14, right: 14 })
    .borderRadius(14)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  @Builder
  HeaderRow() {
    Column({ space: 6 }) {
      Row() {
        Column({ space: 6 }) {
          AppPageHeader({
            title: '复盘库'
          })
        }
        .layoutWeight(1)

        Text(this.resolveResultCountText())
          .fontSize(13)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.metaLineHeight)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor(AppColors.surfaceMuted)
          .border({ width: 1, color: AppColors.border })
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')
    }
    .width('100%')
  }

  build() {
    Column() {
      Column() {
        this.HeaderRow()

        Column({ space: AppMetrics.cardGap }) {
          this.SearchField()

          Scroll() {
            Row({ space: AppMetrics.space8 }) {
              this.FilterChip('全部', 'all')
              this.FilterChip('成立', ReviewJudgementStatus.VALID)
              this.FilterChip('待判断', ReviewJudgementStatus.UNSURE)
              this.FilterChip('不成立', ReviewJudgementStatus.INVALID)
            }
          }
          .width('100%')
          .height(AppMetrics.filterChipHeight)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)

          if (this.hasActiveFilters()) {
            Row() {
              SecondaryButton({
                label: '清空筛选',
                onTap: () => {
                  this.clearFilters();
                }
              })
                .width(112)
            }
            .width('100%')
          }
        }
        .margin({ top: LIBRARY_HEADER_CONTROL_GAP })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: 0 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.libraryLoadFailed) {
        Column() {
          EmptyState({
            title: '复盘库暂时无法刷新',
            message: '稍后返回本页会自动重试，已保存的复盘不会受影响。'
          })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else if (this.summary.recordCount === 0) {
        Column() {
          EmptyState({
            title: '暂无复盘记录',
            message: '从相册选择一张照片，创建第一条可回看的复盘。'
          })

          Row() {
            PrimaryButton({
              label: this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '创建第一条复盘',
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
        List({ space: AppMetrics.cardGap }) {
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
              .height(LIBRARY_BOTTOM_CLEARANCE)
              .width('100%')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: LIBRARY_LIST_TOP_GAP })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
