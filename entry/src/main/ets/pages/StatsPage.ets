import common from '@ohos.app.ability.common';
import { AppColors, AppMetrics, AppPageHeader } from '../components/AppDesign';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewProjectService } from '../services/ReviewProjectService';

@Component
export struct StatsPage {
  private loadRequestId: number = 0;
  @Prop @Watch('refreshStatsData') refreshToken: number = 0;
  @State totalCount: number = 0;
  @State validCount: number = 0;
  @State invalidCount: number = 0;
  @State unsureCount: number = 0;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadStats();
  }

  onPageShow(): void {
    this.reloadStats();
  }

  refreshStatsData(): void {
    this.reloadStats();
  }

  private async reloadStats(): Promise<void> {
    const requestId: number = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    const items: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(this.getAbilityContext());
    if (requestId !== this.loadRequestId) {
      return;
    }
    const summary = ReviewProjectService.buildHomeSummary(items);
    this.totalCount = summary.recordCount;
    this.validCount = summary.stats.validCount;
    this.invalidCount = summary.stats.invalidCount;
    this.unsureCount = summary.stats.unsureCount;
  }

  private resolveSummaryTitle(): string {
    return this.totalCount > 0 ? `${this.totalCount} 次复盘` : '还没有统计数据';
  }

  private resolveSummaryDescription(): string {
    return this.totalCount > 0
      ? `成立 ${this.validCount} · 待判断 ${this.unsureCount} · 不成立 ${this.invalidCount}`
      : '先从首页导入一张照片，完成第一条摄影复盘。';
  }

  @Builder
  PreviewChip(label: string) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.primary)
        .lineHeight(18)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .borderRadius(12)
    .backgroundColor('#F3F7F9')
    .border({ width: 1, color: '#DEE7EB' })
  }

  build() {
    Column({ space: AppMetrics.cardGap }) {
      AppPageHeader({
        title: '统计',
        subtitle: '完成复盘后，这里会展示你的判断变化。'
      })

      Column({ space: 8 }) {
          Text(this.resolveSummaryTitle())
          .fontSize(18)
          .fontWeight(600)
          .fontColor(AppColors.text)
          .lineHeight(24)
          .width('100%')

        Text(this.resolveSummaryDescription())
          .fontSize(14)
          .fontColor(AppColors.secondaryText)
          .lineHeight(20)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .padding(AppMetrics.space16)
      .width('100%')
      .constraintSize({ minHeight: 132, maxHeight: 148 })
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(AppColors.surface)
      .border({ width: 1, color: AppColors.border })
      .margin({ top: 12 })

      Column({ space: 10 }) {
        Text('将会记录')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.secondaryText)
          .lineHeight(18)
          .width('100%')

        Row({ space: 8 }) {
          this.PreviewChip(`累计 ${this.totalCount}`)
          this.PreviewChip(`成立 ${this.validCount}`)
          this.PreviewChip(`待判断 ${this.unsureCount}`)
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ top: 2, bottom: 0 })
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: AppMetrics.pagePadding,
      right: AppMetrics.pagePadding,
      top: AppMetrics.pageTopPadding,
      bottom: AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding
    })
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
