import { AppColors, AppMetrics, AppTypography } from '../components/AppDesign';

@Component
export struct StatsPage {
  build() {
    Column({ space: AppMetrics.space16 }) {
      Text('统计')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(24)
        .width('100%')

      Text('完成第一张复盘后，这里会展示你的判断变化。')
        .fontSize(14)
        .fontColor(AppColors.secondaryText)
        .lineHeight(20)
        .width('100%')

      Column({ space: 6 }) {
        Text('还没有统计数据')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .width('100%')

        Text('先从首页导入一张照片，完成第一条摄影复盘。')
          .fontSize(14)
          .fontColor(AppColors.secondaryText)
          .lineHeight(20)
          .width('100%')
      }
      .padding(AppMetrics.space16)
      .width('100%')
      .borderRadius(12)
      .backgroundColor(AppColors.surface)
      .border({ width: 1, color: AppColors.border })
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
