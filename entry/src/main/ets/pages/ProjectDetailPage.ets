import common from '@ohos.app.ability.common';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  EmptyState,
  PrimaryButton,
  ProjectReviewCard,
  SkeletonBlock
} from '../components/AppDesign';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import {
  createDefaultReviewCardDocument,
  getReviewDocumentKey,
  normalizeReviewJudgement,
  ReviewCardDocument,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { PendingReviewPhoto } from '../model/PendingReviewPhotoModel';
import { ReviewCardHistoryPageResult, ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewCardRdbMapper, ReviewLibraryStats } from '../services/ReviewCardRdbModel';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { pickSinglePhoto, PickedPhotoResult } from '../services/PhotoPickerService';
import { PendingReviewPhotoStore } from '../services/PendingReviewPhotoStore';
import { LearningProgressFormService } from '../services/LearningProgressFormService';
import {
  REVIEW_FLOW_DELETE_CONFIRM_MESSAGE,
  REVIEW_FLOW_DELETE_CONFIRM_TITLE,
  REVIEW_FLOW_DELETE_FAILED_TEXT,
  REVIEW_FLOW_DELETE_PENDING_TEXT,
  REVIEW_FLOW_DELETE_SUCCESS_TEXT,
  REVIEW_FLOW_IMPORT_PENDING_TEXT,
  REVIEW_FLOW_PENDING_DELETE_FAILED_TEXT,
  REVIEW_FLOW_PENDING_DELETE_SUCCESS_TEXT
} from '../services/ReviewFlowFeedback';
import { ToastService } from '../services/ToastService';
import { DialogService } from '../services/DialogService';
import { formatReviewTime, getImageRatioLabel, hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import { ElevationTokens } from '../theme/DesignTokens';

const DELETE_SWIPE_ACTION_WIDTH: number = 92;
const DELETE_SWIPE_BUTTON_WIDTH: number = 68;
const LIBRARY_HEADER_CONTROL_GAP: number = AppMetrics.space10;
const LIBRARY_LIST_TOP_GAP: number = AppMetrics.space8;
const LIBRARY_BOTTOM_CLEARANCE: number = AppMetrics.tabContentBottomPadding + AppMetrics.space8;
const REVIEW_LIBRARY_PAGE_SIZE: number = 5;
const PENDING_REVIEW_FILTER: string = 'pending';

@Component
export struct ProjectDetailPage {
  private loadRequestId: number = 0;
  @Prop @Watch('refreshReviewLibraryData') refreshToken: number = 0;
  @Prop @Watch('refreshReviewLibraryData') initialFilter: string = 'all';
  @State summary: ReviewProjectSummary = createDefaultProjectSummary();
  @State filteredItems: Array<ReviewCardHistoryItem> = [];
  @State pendingItems: Array<PendingReviewPhoto> = [];
  @State pendingImageFailedIds: Array<string> = [];
  @State searchText: string = '';
  @State decisionFilter: string = 'all';
  @State isPickingPhoto: boolean = false;
  @State deletingReviewKey: string = '';
  @State deletingPendingPhotoId: string = '';
  @State libraryLoadFailed: boolean = false;
  @State isLibraryLoading: boolean = false;
  @State isLoadingMore: boolean = false;
  @State hasMoreItems: boolean = false;
  @State libraryStats: ReviewLibraryStats = ReviewCardRdbMapper.emptyStats();

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.applyInitialFilter();
    this.reloadData();
  }

  onPageShow(): void {
    this.reloadData();
  }

  refreshReviewLibraryData(): void {
    this.applyInitialFilter();
    this.reloadData();
  }

  private applyInitialFilter(): void {
    if (this.initialFilter === PENDING_REVIEW_FILTER) {
      this.decisionFilter = PENDING_REVIEW_FILTER;
    }
  }

  private async reloadData(): Promise<void> {
    const requestId: number = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    this.isLibraryLoading = true;
    this.isLoadingMore = false;
    try {
      const pendingItems: Array<PendingReviewPhoto> = await PendingReviewPhotoStore.listPending(this.getAbilityContext());
      const result: ReviewCardHistoryPageResult = await ReviewCardHistoryService.loadPage(this.getAbilityContext(), {
        decision: this.resolveDecisionQuery(),
        keyword: this.isPendingFilter() ? '' : this.searchText,
        limit: this.isPendingFilter() ? 1 : REVIEW_LIBRARY_PAGE_SIZE,
        offset: 0
      });
      if (requestId !== this.loadRequestId) {
        return;
      }
      const summary: ReviewProjectSummary = ReviewProjectService.buildDefaultProjectSummary(result.items);
      summary.recordCount = result.totalCount;
      summary.stats.totalCount = result.totalCount;
      this.summary = summary;
      this.filteredItems = this.isPendingFilter() ? [] : result.items;
      this.pendingItems = pendingItems;
      this.libraryStats = result.libraryStats;
      this.libraryStats.pendingCount = pendingItems.length;
      this.hasMoreItems = !this.isPendingFilter() && this.filteredItems.length < result.totalCount;
      this.libraryLoadFailed = false;
      this.isLibraryLoading = false;
    } catch (error) {
      if (requestId !== this.loadRequestId) {
        return;
      }
      this.libraryLoadFailed = true;
      this.isLibraryLoading = false;
      this.hasMoreItems = false;
    }
  }

  private applyFilters(): void {
    this.reloadData();
  }

  private resolveDecisionQuery(): string | undefined {
    return this.decisionFilter === 'all' || this.isPendingFilter() ? undefined : this.decisionFilter;
  }

  private isPendingFilter(): boolean {
    return this.decisionFilter === PENDING_REVIEW_FILTER;
  }

  private async loadMoreItems(): Promise<void> {
    if (this.isLibraryLoading || this.isLoadingMore || !this.hasMoreItems || this.libraryLoadFailed) {
      return;
    }

    const requestId: number = this.loadRequestId;
    this.isLoadingMore = true;
    try {
      const result: ReviewCardHistoryPageResult = await ReviewCardHistoryService.loadPage(this.getAbilityContext(), {
        decision: this.resolveDecisionQuery(),
        keyword: this.searchText,
        limit: REVIEW_LIBRARY_PAGE_SIZE,
        offset: this.filteredItems.length
      });
      if (requestId !== this.loadRequestId) {
        return;
      }
      const nextItems: Array<ReviewCardHistoryItem> = this.filteredItems.concat(result.items);
      const summary: ReviewProjectSummary = ReviewProjectService.buildDefaultProjectSummary(nextItems);
      summary.recordCount = result.totalCount;
      summary.stats.totalCount = result.totalCount;
      this.summary = summary;
      this.filteredItems = nextItems;
      this.libraryStats = result.libraryStats;
      this.hasMoreItems = this.filteredItems.length < result.totalCount;
    } catch (error) {
      if (requestId === this.loadRequestId) {
        this.hasMoreItems = false;
      }
    } finally {
      if (requestId === this.loadRequestId) {
        this.isLoadingMore = false;
      }
    }
  }

  private resolveResultCountText(): string {
    if (this.isPendingFilter()) {
      return `待复盘 ${this.libraryStats.pendingCount}`;
    }
    if (this.libraryStats.total === 0) {
      return `待复盘 ${this.libraryStats.pendingCount}`;
    }
    return `已判断 ${this.libraryStats.works + this.libraryStats.notWorks}/${this.libraryStats.total} · 待复盘 ${this.libraryStats.pendingCount}`;
  }

  private hasActiveFilters(): boolean {
    return this.searchText.length > 0 || this.decisionFilter !== 'all';
  }

  private shouldShowLibrarySkeleton(): boolean {
    return this.isLibraryLoading && this.summary.recordCount === 0 && !this.libraryLoadFailed;
  }

  private resolveVisiblePendingItems(): Array<PendingReviewPhoto> {
    const query: string = this.searchText.trim().toLocaleLowerCase();
    if (query.length === 0) {
      return this.pendingItems;
    }
    return this.pendingItems.filter((item: PendingReviewPhoto): boolean => {
      return `${item.fileName}\n${item.photoUri}`.toLocaleLowerCase().includes(query);
    });
  }

  private resolveVisibleReviewItems(): Array<ReviewCardHistoryItem> {
    return ReviewProjectService.filterItems(
      this.filteredItems,
      this.searchText,
      this.resolveDecisionQuery() ? this.resolveDecisionQuery() as string : 'all'
    );
  }

  private isPendingImageFailed(photoId: string): boolean {
    return this.pendingImageFailedIds.indexOf(photoId) >= 0;
  }

  private markPendingImageFailed(photoId: string): void {
    if (this.isPendingImageFailed(photoId)) {
      return;
    }
    this.pendingImageFailedIds = this.pendingImageFailedIds.concat([photoId]);
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
        ToastService.show(this.getUIContext(), result.message);
      }
      return;
    }

    ReviewCardStore.createPhotoDraft(
      result.imageUri,
      result.imageWidth,
      result.imageHeight,
      result.imageSizeFallbackUsed
    );
    this.getUIContext().getRouter().pushUrl({ url: EDITOR_PAGE }).catch((error: Error) => {
      console.error(`[ProjectDetailPage] 创建复盘跳转失败：${error.message}`);
    });
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
    ReviewCardStore.clearCurrentPendingPhotoId();
    this.getUIContext().getRouter().pushUrl({ url: PREVIEW_PAGE }).catch((error: Error) => {
      console.error(`[ProjectDetailPage] 打开复盘预览失败：${error.message}`);
    });
  }

  private openPendingPhoto(photo: PendingReviewPhoto): void {
    ReviewCardStore.createPendingPhotoDraft(
      photo.id,
      photo.photoUri,
      photo.width,
      photo.height,
      photo.orientation === 'unknown'
    );
    this.getUIContext().getRouter().pushUrl({ url: EDITOR_PAGE }).catch((error: Error) => {
      console.error(`[ProjectDetailPage] 打开待复盘照片失败：${error.message}`);
    });
  }

  private async deletePendingPhoto(photo: PendingReviewPhoto): Promise<void> {
    if (this.deletingPendingPhotoId.length > 0) {
      return;
    }

    this.deletingPendingPhotoId = photo.id;
    const previousItems: Array<PendingReviewPhoto> = this.pendingItems;
    this.pendingItems = previousItems.filter((item: PendingReviewPhoto): boolean => item.id !== photo.id);
    this.libraryStats.pendingCount = Math.max(0, this.libraryStats.pendingCount - 1);
    try {
      await PendingReviewPhotoStore.delete(this.getAbilityContext(), photo.id);
      await LearningProgressFormService.refreshAllForms(this.getAbilityContext());
      ToastService.show(this.getUIContext(), REVIEW_FLOW_PENDING_DELETE_SUCCESS_TEXT);
      this.reloadData();
    } catch (error) {
      this.pendingItems = previousItems;
      this.libraryStats.pendingCount = previousItems.length;
      ToastService.show(this.getUIContext(), REVIEW_FLOW_PENDING_DELETE_FAILED_TEXT);
    } finally {
      this.deletingPendingPhotoId = '';
    }
  }

  private confirmDeleteHistory(document: ReviewCardDocument): void {
    if (this.deletingReviewKey.length > 0) {
      return;
    }

    DialogService.confirm(this.getUIContext(), {
      title: REVIEW_FLOW_DELETE_CONFIRM_TITLE,
      message: REVIEW_FLOW_DELETE_CONFIRM_MESSAGE,
      cancelText: '取消',
      confirmText: '删除',
      confirmColor: AppColors.danger,
      onConfirm: () => {
        this.deleteHistory(document);
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
    const previousRecordCount: number = this.summary.recordCount;
    const previousLibraryStats: ReviewLibraryStats = this.libraryStats;
    const nextItems: Array<ReviewCardHistoryItem> = previousItems.filter((item: ReviewCardHistoryItem): boolean => {
      return getReviewDocumentKey(item.document) !== deletingKey;
    });
    const optimisticSummary: ReviewProjectSummary = ReviewProjectService.buildDefaultProjectSummary(nextItems);
    optimisticSummary.recordCount = Math.max(0, previousRecordCount - 1);
    optimisticSummary.stats.totalCount = optimisticSummary.recordCount;
    this.summary = optimisticSummary;
    this.filteredItems = nextItems;
    const optimisticLibraryStats: ReviewLibraryStats = {
      total: Math.max(0, previousLibraryStats.total - 1),
      works: previousLibraryStats.works,
      notWorks: previousLibraryStats.notWorks,
      uncertain: previousLibraryStats.uncertain,
      pendingCount: previousLibraryStats.pendingCount
    };
    const deletingJudgement: ReviewJudgementStatus = document.content.judgement === 'works'
      ? ReviewJudgementStatus.VALID
      : document.content.judgement === 'notWorks'
        ? ReviewJudgementStatus.INVALID
        : document.content.judgement === 'uncertain'
          ? ReviewJudgementStatus.UNSURE
          : normalizeReviewJudgement(document.content.judgement);
    if (deletingJudgement === ReviewJudgementStatus.VALID) {
      optimisticLibraryStats.works = Math.max(0, optimisticLibraryStats.works - 1);
    } else if (deletingJudgement === ReviewJudgementStatus.INVALID) {
      optimisticLibraryStats.notWorks = Math.max(0, optimisticLibraryStats.notWorks - 1);
    } else {
      optimisticLibraryStats.uncertain = Math.max(0, optimisticLibraryStats.uncertain - 1);
    }
    this.libraryStats = optimisticLibraryStats;
    this.hasMoreItems = nextItems.length < optimisticSummary.recordCount;
    try {
      await ReviewCardHistoryService.deleteDocument(this.getAbilityContext(), document);
      const currentDocument: ReviewCardDocument = ReviewCardStore.getCurrentDocument();
      if (getReviewDocumentKey(currentDocument) === deletingKey) {
        ReviewCardStore.setCurrentDocument(nextItems.length > 0
          ? nextItems[0].document
          : createDefaultReviewCardDocument());
      }
      ToastService.show(this.getUIContext(), REVIEW_FLOW_DELETE_SUCCESS_TEXT);
      this.reloadData();
    } catch (error) {
      const restoredSummary: ReviewProjectSummary = ReviewProjectService.buildDefaultProjectSummary(previousItems);
      restoredSummary.recordCount = previousRecordCount;
      restoredSummary.stats.totalCount = previousRecordCount;
      this.summary = restoredSummary;
      this.filteredItems = previousItems;
      this.libraryStats = previousLibraryStats;
      ToastService.show(this.getUIContext(), REVIEW_FLOW_DELETE_FAILED_TEXT);
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
  PendingDeleteSwipeAction(photo: PendingReviewPhoto) {
    Row() {
      Button(this.deletingPendingPhotoId === photo.id ? REVIEW_FLOW_DELETE_PENDING_TEXT : '删除')
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
        .opacity(this.deletingPendingPhotoId === photo.id ? 0.52 : 1)
        .stateEffect(this.deletingPendingPhotoId.length === 0)
        .enabled(this.deletingPendingPhotoId.length === 0)
        .onClick(() => {
          if (this.deletingPendingPhotoId.length > 0) {
            return;
          }
          this.deletePendingPhoto(photo);
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
      .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
      .borderRadius(AppMetrics.filterChipRadius)
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
          .borderRadius(AppMetrics.capsuleRadius)
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
    .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
    .borderRadius(AppMetrics.inputRadius)
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
          .maxLines(1)
          .padding({
            left: AppMetrics.compactBadgePaddingHorizontal,
            right: AppMetrics.compactBadgePaddingHorizontal,
            top: AppMetrics.compactBadgePaddingVertical,
            bottom: AppMetrics.compactBadgePaddingVertical
          })
          .borderRadius(AppMetrics.badgeRadius)
          .backgroundColor(AppColors.surfaceMuted)
          .border({ width: 1, color: AppColors.border })
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ReviewListSkeleton() {
    Column({ space: AppMetrics.cardGap }) {
      ForEach([0, 1, 2], (index: number) => {
        Row({ space: AppMetrics.cardGap }) {
          Column() {
            SkeletonBlock({
              blockHeight: AppMetrics.listThumbnailSize,
              blockRadius: AppMetrics.buttonRadius
            })
          }
          .width(AppMetrics.listThumbnailSize)

          Column({ space: AppMetrics.space10 }) {
            SkeletonBlock({ blockWidth: '72%', blockHeight: 16, blockRadius: 8 })
            SkeletonBlock({ blockWidth: index === 2 ? '58%' : '86%', blockHeight: 14, blockRadius: 7 })
            SkeletonBlock({ blockWidth: '44%', blockHeight: 12, blockRadius: 6 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(VerticalAlign.Center)
        .padding(AppMetrics.listCardPadding)
        .width('100%')
        .constraintSize({ minHeight: AppMetrics.listCardMinHeight, maxHeight: AppMetrics.listCardMaxHeight })
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surfaceElevated)
        .border({ width: 1, color: AppColors.border })
      }, (index: number) => `${index}`)
    }
    .width('100%')
  }

  @Builder
  PendingReviewPhotoCard(photo: PendingReviewPhoto) {
    Row({ space: AppMetrics.cardGap }) {
      Stack() {
        if (hasDisplayableImageUri(photo.photoUri) && !this.isPendingImageFailed(photo.id)) {
          Image(photo.photoUri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .syncLoad(true)
            .onError(() => {
              this.markPendingImageFailed(photo.id);
            })
        } else {
          Text('图片不可访问')
            .fontSize(AppTypography.caption)
            .fontColor(AppColors.mutedText)
            .lineHeight(AppTypography.captionLineHeight)
            .textAlign(TextAlign.Center)
            .padding({ left: AppMetrics.space8, right: AppMetrics.space8 })
        }
      }
      .width(AppMetrics.listThumbnailSize)
      .height(AppMetrics.listThumbnailSize)
      .borderRadius(AppMetrics.thumbnailRadius)
      .clip(true)
      .backgroundColor(AppColors.surfaceMuted)
      .border({ width: 1, color: AppColors.border })

      Column({ space: AppMetrics.space8 }) {
        Text(photo.fileName.length > 0 ? photo.fileName : '待复盘照片')
          .fontSize(AppTypography.listTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.listTitleLineHeight)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(`导入时间 ${formatReviewTime(photo.importTime)}`)
          .fontSize(AppTypography.listSubtitle)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.listSubtitleLineHeight)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: AppMetrics.space8 }) {
          Text(getImageRatioLabel(photo.width, photo.height, photo.orientation === 'unknown'))
            .fontSize(AppTypography.meta)
            .fontColor(AppColors.secondaryText)
            .padding({
              left: AppMetrics.compactBadgePaddingHorizontal,
              right: AppMetrics.compactBadgePaddingHorizontal,
              top: AppMetrics.compactBadgePaddingVertical,
              bottom: AppMetrics.compactBadgePaddingVertical
            })
            .borderRadius(AppMetrics.badgeRadius)
            .backgroundColor(AppColors.surfaceMuted)

          Text('待复盘')
            .fontSize(AppTypography.meta)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.primary)
            .padding({
              left: AppMetrics.compactBadgePaddingHorizontal,
              right: AppMetrics.compactBadgePaddingHorizontal,
              top: AppMetrics.compactBadgePaddingVertical,
              bottom: AppMetrics.compactBadgePaddingVertical
            })
            .borderRadius(AppMetrics.badgeRadius)
            .backgroundColor(AppColors.primarySoft)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.listCardPadding)
    .width('100%')
    .constraintSize({ minHeight: AppMetrics.listCardMinHeight, maxHeight: AppMetrics.listCardMaxHeight })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
    .onClick(() => {
      this.openPendingPhoto(photo);
    })
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
              this.FilterChip('待复盘', PENDING_REVIEW_FILTER)
              this.FilterChip('成立', ReviewJudgementStatus.VALID)
              this.FilterChip('待判断', ReviewJudgementStatus.UNSURE)
              this.FilterChip('不成立', ReviewJudgementStatus.INVALID)
            }
          }
          .width('100%')
          .height(AppMetrics.filterChipHeight)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)

        }
        .margin({ top: LIBRARY_HEADER_CONTROL_GAP })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: 0 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.shouldShowLibrarySkeleton()) {
        Column() {
          this.ReviewListSkeleton()
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.tabContentBottomPadding })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else if (this.libraryLoadFailed) {
        Column() {
          EmptyState({
            title: '复盘库暂时无法刷新',
            message: '稍后返回本页会自动重试，已保存的复盘不会受影响。'
          })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.tabContentBottomPadding })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else if (this.isPendingFilter() && this.resolveVisiblePendingItems().length === 0) {
        Column() {
          EmptyState({
            title: this.searchText.length > 0 ? '没有找到匹配的待复盘照片' : '暂无待复盘照片',
            message: this.searchText.length > 0 ? '换个关键词，或清空搜索后再看。' : '从首页点「导入待复盘」，先收集照片，之后再逐张复盘。'
          })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else if (this.isPendingFilter()) {
        List({ space: AppMetrics.cardGap }) {
          ForEach(this.resolveVisiblePendingItems(), (photo: PendingReviewPhoto) => {
            ListItem() {
              this.PendingReviewPhotoCard(photo)
            }
            .swipeAction({
              end: () => {
                this.PendingDeleteSwipeAction(photo);
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (photo: PendingReviewPhoto) => photo.id)

          ListItem() {
            Column()
              .height(LIBRARY_BOTTOM_CLEARANCE)
              .width('100%')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: LIBRARY_LIST_TOP_GAP })
      } else if (this.summary.recordCount === 0 && !this.hasActiveFilters()) {
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
            message: '换个关键词，或点「全部」查看所有状态。'
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
          .height(this.isLoadingMore ? AppMetrics.space32 : 1)
          .width('100%')
      }
      if (this.isLoadingMore) {
        ListItem() {
          Text('正在加载更多复盘')
            .fontSize(AppTypography.caption)
            .fontColor(AppColors.secondaryText)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ bottom: AppMetrics.space16 })
        }
      }
      ListItem() {
        Column()
          .height(LIBRARY_BOTTOM_CLEARANCE)
          .width('100%')
      }
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: LIBRARY_LIST_TOP_GAP })
        .onReachEnd(() => {
          this.loadMoreItems();
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
