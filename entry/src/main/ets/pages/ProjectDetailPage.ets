import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { PREVIEW_PAGE } from '../app/AppRouter';
import { AppColors, AppPageHeader, EmptyState, ProjectReviewCard } from '../components/AppDesign';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { ReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { ReviewCardStore } from '../services/ReviewCardStore';

@Entry
@Component
struct ProjectDetailPage {
  @State summary: ReviewProjectSummary = createDefaultProjectSummary();

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadData();
  }

  private async reloadData(): Promise<void> {
    const items = await ReviewCardHistoryService.load(this.getAbilityContext());
    this.summary = ReviewProjectService.buildDefaultProjectSummary(items);
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
      .width(76)
      .borderRadius(8)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .backgroundColor('#B73A31')
      .onClick(() => {
        this.confirmDeleteHistory(document);
      })
  }

  build() {
    Scroll() {
      Column() {
        AppPageHeader({
          title: this.summary.project.name,
          subtitle: ''
        })

        Text(`${this.summary.recordCount} 条复盘记录`)
          .fontSize(14)
          .fontColor(AppColors.secondaryText)
          .lineHeight(22)
          .width('100%')
          .margin({ top: 10 })

        if (this.summary.recordCount === 0) {
          EmptyState({
            title: '暂无复盘记录',
            message: '请回到首页选择照片开始复盘'
          })
            .margin({ top: 18 })
        } else {
          List({ space: 8 }) {
            ForEach(this.summary.items, (item: ReviewCardHistoryItem) => {
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
          }
          .width('100%')
          .height(this.summary.items.length * 92)
          .scrollBar(BarState.Off)
          .margin({ top: 18 })
        }
      }
      .padding({ left: 20, right: 20, top: 24, bottom: 32 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
