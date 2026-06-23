import { AppColors, AppMetrics, AppPageHeader } from '../components/AppDesign';

@Component
export struct StatsPage {
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
        Text('还没有统计数据')
          .fontSize(18)
          .fontWeight(600)
          .fontColor(AppColors.text)
          .lineHeight(24)
          .width('100%')

        Text('先从首页导入一张照片，完成第一条摄影复盘。')
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
          this.PreviewChip('累计复盘')
          this.PreviewChip('成立记录')
          this.PreviewChip('常见卡点')
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
