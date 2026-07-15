import common from '@ohos.app.ability.common';
import { EDITOR_PAGE, PREVIEW_PAGE } from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  EmptyState,
  PrimaryButton,
  ProjectReviewCard
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
  REVIEW_FLOW_DELETE_FAILED_TEXT,
  REVIEW_FLOW_DELETE_SUCCESS_TEXT,
  REVIEW_FLOW_IMPORT_PENDING_TEXT,
  REVIEW_FLOW_PENDING_DELETE_FAILED_TEXT,
  REVIEW_FLOW_PENDING_DELETE_SUCCESS_TEXT
} from '../services/ReviewFlowFeedback';
import { ToastService } from '../services/ToastService';
import {
  ReviewSettingsService,
  SHATTER_ANIMATION_DEFAULT
} from '../services/ReviewSettingsService';
import { ShatterOverlay } from '../components/ShatterOverlay';
import { formatReviewTime, getImageRatioLabel, hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import { ElevationTokens, MotionTokens } from '../theme/DesignTokens';
import { ShimmerBox } from '../components/motion/ShimmerBox';
import { RippleTouch } from '../components/motion/RippleTouch';
import { StaggeredEnter } from '../components/motion/StaggeredEnter';
import { MotionCurveRole, MotionQualityContext } from '../theme/MotionQualityContext';

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
  private isPageAlive: boolean = false;
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
  @State shatterEnabled: boolean = SHATTER_ANIMATION_DEFAULT;
  @State activeShatterId: string = '';
  @State hiddenCardKeys: Array<string> = [];
  @State collapsingIds: Array<string> = [];
  @State filterPulseValue: string = '';
  private filterPulseTimerId: number = -1;
  private deleteLayoutSettleTimerId: number = -1;
  private isDeleteLayoutSettling: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.isPageAlive = true;
    this.applyInitialFilter();
    this.reloadData();
    this.loadShatterPreference();
  }

  onPageShow(): void {
    this.reloadData();
    this.loadShatterPreference();
  }

  aboutToDisappear(): void {
    this.isPageAlive = false;
    this.loadRequestId += 1;
    this.collapsingIds = [];
    this.hiddenCardKeys = [];
    this.endShatter();
    if (this.filterPulseTimerId >= 0) {
      clearTimeout(this.filterPulseTimerId);
      this.filterPulseTimerId = -1;
    }
    this.cancelDeleteLayoutSettle();
  }

  private selectFilter(value: string): void {
    this.decisionFilter = value;
    this.applyFilters();
    if (this.filterPulseTimerId >= 0) {
      clearTimeout(this.filterPulseTimerId);
    }
    this.filterPulseValue = value;
    this.filterPulseTimerId = setTimeout(() => {
      this.filterPulseValue = '';
      this.filterPulseTimerId = -1;
    }, MotionTokens.durationStandard);
  }

  private async loadShatterPreference(): Promise<void> {
    try {
      const enabled: boolean = await ReviewSettingsService.loadShatterAnimationEnabled(this.getAbilityContext());
      if (this.isPageAlive) {
        this.shatterEnabled = MotionQualityContext.shouldPlayShatter(enabled);
      }
    } catch (error) {
      if (this.isPageAlive) {
        this.shatterEnabled = SHATTER_ANIMATION_DEFAULT;
      }
    }
  }

  private beginShatter(id: string): void {
    this.activeShatterId = id;
  }

  private endShatter(): void {
    this.activeShatterId = '';
  }

  private markCardHidden(key: string): void {
    if (this.hiddenCardKeys.indexOf(key) < 0) {
      this.hiddenCardKeys = this.hiddenCardKeys.concat([key]);
    }
  }

  private markCardVisible(key: string): void {
    this.hiddenCardKeys = this.hiddenCardKeys.filter((existing: string): boolean => existing !== key);
  }

  private isCardHidden(key: string): boolean {
    return this.hiddenCardKeys.indexOf(key) >= 0;
  }

  private isCollapsing(id: string): boolean {
    return this.collapsingIds.indexOf(id) >= 0;
  }

  private beginCollapse(id: string): void {
    if (!this.isCollapsing(id)) {
      this.collapsingIds = this.collapsingIds.concat([id]);
    }
  }

  private endCollapse(id: string): void {
    this.collapsingIds = this.collapsingIds.filter((existing: string): boolean => existing !== id);
  }

  private beginDeleteLayoutTransaction(): void {
    this.loadRequestId += 1;
    this.isLoadingMore = false;
    if (this.deleteLayoutSettleTimerId >= 0) {
      clearTimeout(this.deleteLayoutSettleTimerId);
      this.deleteLayoutSettleTimerId = -1;
    }
    this.isDeleteLayoutSettling = true;
  }

  private settleDeleteLayout(): void {
    if (this.deleteLayoutSettleTimerId >= 0) {
      clearTimeout(this.deleteLayoutSettleTimerId);
    }
    const duration: number = MotionQualityContext.resolveDuration(MotionTokens.shatterRippleBackMs);
    if (duration <= 0) {
      this.isDeleteLayoutSettling = false;
      this.deleteLayoutSettleTimerId = -1;
      return;
    }
    this.deleteLayoutSettleTimerId = setTimeout(() => {
      this.isDeleteLayoutSettling = false;
      this.deleteLayoutSettleTimerId = -1;
    }, duration);
  }

  private cancelDeleteLayoutSettle(): void {
    if (this.deleteLayoutSettleTimerId >= 0) {
      clearTimeout(this.deleteLayoutSettleTimerId);
      this.deleteLayoutSettleTimerId = -1;
    }
    this.isDeleteLayoutSettling = false;
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
    if (this.isLibraryLoading || this.isLoadingMore || !this.hasMoreItems || this.libraryLoadFailed ||
      this.deletingReviewKey.length > 0 || this.isDeleteLayoutSettling || this.collapsingIds.length > 0) {
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
        ToastService.error(this.getUIContext(), result.message);
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
    this.beginDeleteLayoutTransaction();
    const componentId: string = `shatter-pending-${photo.id}`;
    const useShatter: boolean = MotionQualityContext.shouldPlayShatter(this.shatterEnabled);
    if (useShatter) {
      this.markCardHidden(photo.id);
      this.beginShatter(componentId);
    }

    const context: common.UIAbilityContext = this.getAbilityContext();
    try {
      const deleteTask: Promise<void> = PendingReviewPhotoStore.delete(context, photo.id);
      if (useShatter) {
        const animationTask: Promise<void> = new Promise<void>((resolve: () => void): void => {
          setTimeout(resolve, MotionTokens.shatterDurationMs);
        });
        await Promise.all([deleteTask, animationTask]);
      } else {
        await deleteTask;
      }
      await LearningProgressFormService.refreshAllForms(context);
      if (!this.isPageAlive) {
        return;
      }
      if (useShatter) {
        this.beginCollapse(photo.id);
        await new Promise<void>((resolve: () => void): void => {
          setTimeout(resolve, MotionQualityContext.resolveDuration(MotionTokens.durationStandard));
        });
        if (!this.isPageAlive) {
          return;
        }
      }
      this.pendingItems = this.pendingItems.filter((item: PendingReviewPhoto): boolean => item.id !== photo.id);
      this.libraryStats.pendingCount = Math.max(0, this.libraryStats.pendingCount - 1);
      if (useShatter) {
        this.endCollapse(photo.id);
        this.markCardVisible(photo.id);
      }
      this.settleDeleteLayout();
      ToastService.success(this.getUIContext(), REVIEW_FLOW_PENDING_DELETE_SUCCESS_TEXT);
    } catch (error) {
      if (!this.isPageAlive) {
        return;
      }
      this.endCollapse(photo.id);
      this.markCardVisible(photo.id);
      this.cancelDeleteLayoutSettle();
      ToastService.error(this.getUIContext(), REVIEW_FLOW_PENDING_DELETE_FAILED_TEXT);
    } finally {
      if (this.isPageAlive && useShatter) {
        this.endShatter();
      }
      if (this.isPageAlive) {
        this.deletingPendingPhotoId = '';
      }
    }
  }

  private async deleteHistory(document: ReviewCardDocument): Promise<void> {
    const deletingKey: string = getReviewDocumentKey(document);
    if (this.deletingReviewKey.length > 0) {
      return;
    }

    this.deletingReviewKey = deletingKey;
    this.beginDeleteLayoutTransaction();
    const componentId: string = `shatter-history-${deletingKey}`;
    const useShatter: boolean = MotionQualityContext.shouldPlayShatter(this.shatterEnabled);
    if (useShatter) {
      this.markCardHidden(deletingKey);
      this.beginShatter(componentId);
    }

    const previousItems: Array<ReviewCardHistoryItem> = this.summary.items;
    const previousRecordCount: number = this.summary.recordCount;
    const previousLibraryStats: ReviewLibraryStats = this.libraryStats;
    const context: common.UIAbilityContext = this.getAbilityContext();
    try {
      const deleteTask: Promise<void> = ReviewCardHistoryService.deleteDocument(context, document);
      if (useShatter) {
        const animationTask: Promise<void> = new Promise<void>((resolve: () => void): void => {
          setTimeout(resolve, MotionTokens.shatterDurationMs);
        });
        await Promise.all([deleteTask, animationTask]);
      } else {
        await deleteTask;
      }
      await LearningProgressFormService.refreshAllForms(context);
      if (!this.isPageAlive) {
        return;
      }
      if (useShatter) {
        this.beginCollapse(deletingKey);
        await new Promise<void>((resolve: () => void): void => {
          setTimeout(resolve, MotionQualityContext.resolveDuration(MotionTokens.durationStandard));
        });
        if (!this.isPageAlive) {
          return;
        }
      }
      const nextItems: Array<ReviewCardHistoryItem> = previousItems.filter((item: ReviewCardHistoryItem): boolean => {
        return getReviewDocumentKey(item.document) !== deletingKey;
      });
      const nextSummary: ReviewProjectSummary = ReviewProjectService.buildDefaultProjectSummary(nextItems);
      nextSummary.recordCount = Math.max(0, previousRecordCount - 1);
      nextSummary.stats.totalCount = nextSummary.recordCount;
      this.summary = nextSummary;
      this.filteredItems = nextItems;
      const nextLibraryStats: ReviewLibraryStats = {
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
        nextLibraryStats.works = Math.max(0, nextLibraryStats.works - 1);
      } else if (deletingJudgement === ReviewJudgementStatus.INVALID) {
        nextLibraryStats.notWorks = Math.max(0, nextLibraryStats.notWorks - 1);
      } else {
        nextLibraryStats.uncertain = Math.max(0, nextLibraryStats.uncertain - 1);
      }
      this.libraryStats = nextLibraryStats;
      this.hasMoreItems = nextItems.length < nextSummary.recordCount;
      const currentDocument: ReviewCardDocument = ReviewCardStore.getCurrentDocument();
      if (getReviewDocumentKey(currentDocument) === deletingKey) {
        ReviewCardStore.setCurrentDocument(nextItems.length > 0
          ? nextItems[0].document
          : createDefaultReviewCardDocument());
      }
      if (useShatter) {
        this.endCollapse(deletingKey);
        this.markCardVisible(deletingKey);
      }
      this.settleDeleteLayout();
      ToastService.success(this.getUIContext(), REVIEW_FLOW_DELETE_SUCCESS_TEXT);
    } catch (error) {
      if (!this.isPageAlive) {
        return;
      }
      this.endCollapse(deletingKey);
      this.markCardVisible(deletingKey);
      this.cancelDeleteLayoutSettle();
      ToastService.error(this.getUIContext(), REVIEW_FLOW_DELETE_FAILED_TEXT);
      this.reloadData();
    } finally {
      if (this.isPageAlive && useShatter) {
        this.endShatter();
      }
      if (this.isPageAlive) {
        this.deletingReviewKey = '';
      }
    }
  }

  @Builder
  DeleteSwipeAction(document: ReviewCardDocument) {
    Row() {
      Button('删除')
        .height(AppMetrics.compactControlHeight)
        .width(DELETE_SWIPE_BUTTON_WIDTH)
        .borderRadius(AppMetrics.buttonRadius)
        .fontSize(AppTypography.smallButtonText)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.dangerPressed)
        .backgroundColor(AppColors.dangerSoft)
        .shadow({
          radius: 10,
          color: '#14000000', // verify-feedback:allow-raw
          offsetX: 0,
          offsetY: 3
        })
        .stateEffect(this.deletingReviewKey.length === 0)
        .enabled(this.deletingReviewKey.length === 0)
        .onClick(() => {
          if (this.deletingReviewKey.length > 0) {
            return;
          }
          this.deleteHistory(document);
        })
    }
    .width(DELETE_SWIPE_ACTION_WIDTH)
    .height('100%')
    .opacity(this.deletingReviewKey === getReviewDocumentKey(document) ? 0 : 1)
    .visibility(this.deletingReviewKey === getReviewDocumentKey(document) ? Visibility.Hidden : Visibility.Visible)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ left: AppMetrics.space8, right: 0 })
  }

  @Builder
  PendingDeleteSwipeAction(photo: PendingReviewPhoto) {
    Row() {
      Button('删除')
        .height(AppMetrics.compactControlHeight)
        .width(DELETE_SWIPE_BUTTON_WIDTH)
        .borderRadius(AppMetrics.buttonRadius)
        .fontSize(AppTypography.smallButtonText)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.dangerPressed)
        .backgroundColor(AppColors.dangerSoft)
        .shadow({
          radius: 10,
          color: '#14000000', // verify-feedback:allow-raw
          offsetX: 0,
          offsetY: 3
        })
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
    .opacity(this.deletingPendingPhotoId === photo.id ? 0 : 1)
    .visibility(this.deletingPendingPhotoId === photo.id ? Visibility.Hidden : Visibility.Visible)
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
      .scale({
        x: this.filterPulseValue === value ? MotionTokens.scaleCeremony : 1,
        y: this.filterPulseValue === value ? MotionTokens.scaleCeremony : 1
      })
      .animation({
        duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
        curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_BOUNCY)
      })
      .onClick(() => {
        this.selectFilter(value);
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
            ShimmerBox({
              boxHeight: AppMetrics.listThumbnailSize,
              boxRadius: AppMetrics.buttonRadius
            })
          }
          .width(AppMetrics.listThumbnailSize)

          Column({ space: AppMetrics.space10 }) {
            ShimmerBox({ boxWidth: '72%', boxHeight: 16, boxRadius: 8 })
            ShimmerBox({ boxWidth: index === 2 ? '58%' : '86%', boxHeight: 14, boxRadius: 7 })
            ShimmerBox({ boxWidth: '44%', boxHeight: 12, boxRadius: 6 })
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
      .geometryTransition(`review-hero-${photo.id}`)
      .animation({
        duration: MotionQualityContext.resolveDuration(MotionTokens.durationHero),
        curve: MotionQualityContext.resolveCurve(MotionCurveRole.LANDING)
      })

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

  @Builder
  PendingReviewListCardContent(photo: PendingReviewPhoto) {
    Stack() {
      Stack() {
        this.PendingReviewPhotoCard(photo)
      }
        .width('100%')
        .visibility(this.isCardHidden(photo.id) ? Visibility.Hidden : Visibility.Visible)

      if (this.activeShatterId === `shatter-pending-${photo.id}`) {
        ShatterOverlay({
          quality: 'medium'
        })
          .width('100%')
          .height('100%')
          .position({ x: 0, y: 0 })
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .height(this.isCollapsing(photo.id) ? 0 : undefined)
    .constraintSize({
      minHeight: this.isCollapsing(photo.id) ? 0 : AppMetrics.listCardMinHeight,
      maxHeight: this.isCollapsing(photo.id) ? 0 : AppMetrics.listCardMaxHeight
    })
    .opacity(this.isCollapsing(photo.id) ? 0 : 1)
    .animation({
      duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
      curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_SOFT)
    })
    .clip(true)
  }

  @Builder
  PendingReviewListCard(photo: PendingReviewPhoto) {
    RippleTouch({
      clipRadius: AppMetrics.cardRadius,
      content: () => {
        this.PendingReviewListCardContent(photo);
      }
    })
      .width('100%')
  }

  @Builder
  HistoryReviewListCardContent(item: ReviewCardHistoryItem) {
    Stack() {
      ProjectReviewCard({
        item: item,
        onTap: () => {
          this.openHistory(item.document);
        }
      })
        .visibility(this.isCardHidden(getReviewDocumentKey(item.document))
          ? Visibility.Hidden
          : Visibility.Visible)

      if (this.activeShatterId === `shatter-history-${getReviewDocumentKey(item.document)}`) {
        ShatterOverlay({
          quality: 'medium'
        })
          .width('100%')
          .height('100%')
          .position({ x: 0, y: 0 })
          .hitTestBehavior(HitTestMode.None)
      }
    }
    .width('100%')
    .height(this.isCollapsing(getReviewDocumentKey(item.document)) ? 0 : undefined)
    .constraintSize({
      minHeight: this.isCollapsing(getReviewDocumentKey(item.document)) ? 0 : AppMetrics.listCardMinHeight,
      maxHeight: this.isCollapsing(getReviewDocumentKey(item.document)) ? 0 : AppMetrics.listCardMaxHeight
    })
    .opacity(this.isCollapsing(getReviewDocumentKey(item.document)) ? 0 : 1)
    .animation({
      duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
      curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_SOFT)
    })
    .clip(true)
  }

  @Builder
  HistoryReviewListCard(item: ReviewCardHistoryItem) {
    RippleTouch({
      clipRadius: AppMetrics.cardRadius,
      content: () => {
        this.HistoryReviewListCardContent(item);
      }
    })
      .width('100%')
  }

  build() {
    Stack() {
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
        List({ space: 0 }) {
          ForEach(this.resolveVisiblePendingItems(), (photo: PendingReviewPhoto, index: number) => {
            ListItem() {
              StaggeredEnter({
                batchIndex: index,
                batchSize: 1,
                delayMs: MotionTokens.durationStagger,
                content: () => {
                  this.PendingReviewListCard(photo);
                }
              })
                .width('100%')
            }
            .id(`shatter-pending-${photo.id}`)
            .padding({ bottom: this.isCollapsing(photo.id) ? 0 : AppMetrics.cardGap })
            .animation({
              duration: this.isCollapsing(photo.id)
                ? MotionQualityContext.resolveDuration(MotionTokens.durationStandard)
                : MotionTokens.shatterRippleBackMs,
              curve: this.isCollapsing(photo.id)
                ? MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_SOFT)
                : MotionTokens.curveDecelerate
            })
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
        List({ space: 0 }) {
          ForEach(this.filteredItems, (item: ReviewCardHistoryItem, index: number) => {
            ListItem() {
              StaggeredEnter({
                batchIndex: index,
                batchSize: 1,
                delayMs: MotionTokens.durationStagger,
                content: () => {
                  this.HistoryReviewListCard(item);
                }
              })
                .width('100%')
            }
            .id(`shatter-history-${getReviewDocumentKey(item.document)}`)
            .padding({
              bottom: this.isCollapsing(getReviewDocumentKey(item.document)) ? 0 : AppMetrics.cardGap
            })
            .animation({
              duration: this.isCollapsing(getReviewDocumentKey(item.document))
                ? MotionQualityContext.resolveDuration(MotionTokens.durationStandard)
                : MotionTokens.shatterRippleBackMs,
              curve: this.isCollapsing(getReviewDocumentKey(item.document))
                ? MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_SOFT)
                : MotionTokens.curveDecelerate
            })
            .swipeAction({
              end: () => {
                this.DeleteSwipeAction(item.document);
              },
              edgeEffect: SwipeEdgeEffect.Spring
            })
          }, (item: ReviewCardHistoryItem) => getReviewDocumentKey(item.document))
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
    .width('100%')
    .height('100%')
  }
}
