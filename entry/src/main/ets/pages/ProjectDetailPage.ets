import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { PREVIEW_PAGE } from '../app/AppRouter';
import {
  AppColors,
  AppMetrics,
  AppPageHeader,
  AppTypography,
  EmptyState,
  ProjectReviewCard
} from '../components/AppDesign';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { ReviewCardDocument, ReviewCardHistoryItem, ReviewJudgementStatus } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { ReviewCardStore } from '../services/ReviewCardStore';

@Entry
@Component
struct ProjectDetailPage {
  @State summary: ReviewProjectSummary = createDefaultProjectSummary();
  @State filteredItems: Array<ReviewCardHistoryItem> = [];
  @State searchText: string = '';
  @State decisionFilter: string = 'all';

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

  private openCreateFirstReview(): void {
    router.back();
  }

  private isFilterSelected(value: string): boolean {
    return this.decisionFilter === value;
  }

  private resolveFilterChipTextColor(value: string): string {
    return this.isFilterSelected(value) ? '#FFFFFF' : AppColors.secondaryText;
  }

  private resolveFilterChipBackgroundColor(value: string): string {
    return this.isFilterSelected(value) ? AppColors.primary : AppColors.surfaceMuted;
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
        fontColor: '#9A3328',
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

  @Builder
  FilterChip(label: string, value: string) {
    Button(label)
      .height(32)
      .padding({ left: AppMetrics.space12, right: AppMetrics.space12 })
      .borderRadius(AppMetrics.capsuleRadius)
      .fontSize(AppTypography.caption)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.resolveFilterChipTextColor(value))
      .backgroundColor(this.resolveFilterChipBackgroundColor(value))
      .onClick(() => {
        this.decisionFilter = value;
        this.applyFilters();
      })
  }

  build() {
    Column() {
      Column() {
        AppPageHeader({
          title: '复盘库',
          subtitle: '搜索复盘，查看导入后的历史记录'
        })

        Text(this.summary.recordCount === 0
          ? '还没有复盘记录'
          : `当前显示 ${this.filteredItems.length} / ${this.summary.recordCount} 条复盘记录`)
          .fontSize(AppTypography.auxiliary)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.auxiliaryLineHeight)
          .width('100%')
          .margin({ top: AppMetrics.space12 })

        Column({ space: AppMetrics.space12 }) {
          TextInput({ text: this.searchText, placeholder: '搜索标题、核心关系、卡点、文件名' })
            .height(44)
            .borderRadius(AppMetrics.cardRadius)
            .fontSize(AppTypography.auxiliary)
            .fontColor(AppColors.text)
            .placeholderColor('#9AA1AB')
            .backgroundColor(AppColors.surfaceMuted)
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
        }
        .margin({ top: AppMetrics.space16 })
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: 0 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.summary.recordCount === 0) {
        Column() {
          EmptyState({
            title: '暂无复盘记录',
            message: '可先创建第一条复盘，之后这里就是你的复盘库。'
          })

          Button('创建第一条复盘')
            .height(36)
            .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
            .borderRadius(AppMetrics.capsuleRadius)
            .fontSize(AppTypography.auxiliary)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor(AppColors.primary)
            .margin({ top: AppMetrics.space12 })
            .onClick(() => {
              this.openCreateFirstReview();
            })
        }
        .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space32 })
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      } else if (this.filteredItems.length === 0) {
        Column() {
          EmptyState({
            title: '没有找到匹配的复盘',
            message: '试试换一个关键词，或切换成立判断筛选。'
          })

          Button('清空搜索与筛选')
            .height(36)
            .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
            .borderRadius(AppMetrics.capsuleRadius)
            .fontSize(AppTypography.auxiliary)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .backgroundColor(AppColors.surfaceMuted)
            .margin({ top: AppMetrics.space12 })
            .onClick(() => {
              this.clearFilters();
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
