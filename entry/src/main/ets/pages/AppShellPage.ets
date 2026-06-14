import { AppColors, AppMetrics, AppTypography } from '../components/AppDesign';
import { HomePage } from './HomePage';
import { ProjectDetailPage } from './ProjectDetailPage';
import { MyPage } from './MyPage';

enum RootTabKey {
  HOME = 'home',
  LIBRARY = 'library',
  MY = 'my'
}

interface RootTabItem {
  key: RootTabKey;
  label: string;
  activeIcon: Resource;
  inactiveIcon: Resource;
}

const ROOT_TABS: Array<RootTabItem> = [
  { key: RootTabKey.HOME, label: '首页', activeIcon: $r('app.media.tab_home_active'), inactiveIcon: $r('app.media.tab_home') },
  { key: RootTabKey.LIBRARY, label: '复盘库', activeIcon: $r('app.media.tab_library_active'), inactiveIcon: $r('app.media.tab_library') },
  { key: RootTabKey.MY, label: '我的', activeIcon: $r('app.media.tab_user_active'), inactiveIcon: $r('app.media.tab_user') }
];

@Entry
@Component
struct AppShellPage {
  @State currentTab: RootTabKey = RootTabKey.HOME;

  private isCurrentTab(key: RootTabKey): boolean {
    return this.currentTab === key;
  }

  private selectTab(key: RootTabKey): void {
    this.currentTab = key;
  }

  private resolveTabLabelColor(key: RootTabKey): string {
    return this.isCurrentTab(key) ? AppColors.text : AppColors.secondaryText;
  }

  private resolveTabLabelWeight(key: RootTabKey): number {
    return this.isCurrentTab(key) ? FontWeight.Medium : FontWeight.Regular;
  }

  private resolveTabBackground(key: RootTabKey): string {
    return '#00000000';
  }

  @Builder
  TabButton(item: RootTabItem) {
    Column() {
      Image(this.isCurrentTab(item.key) ? item.activeIcon : item.inactiveIcon)
        .width(AppMetrics.tabIconSize)
        .height(AppMetrics.tabIconSize)

      Text(item.label)
        .fontSize(AppTypography.tabLabel)
        .fontWeight(this.resolveTabLabelWeight(item.key))
        .fontColor(this.resolveTabLabelColor(item.key))
        .lineHeight(AppTypography.tabLabelLineHeight)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .height(AppMetrics.tabBarItemHeight)
    .padding({ left: AppMetrics.space8, right: AppMetrics.space8 })
    .borderRadius(AppMetrics.buttonRadius)
    .backgroundColor(this.resolveTabBackground(item.key))
    .onClick(() => {
      this.selectTab(item.key);
    })
  }

  @Builder
  CurrentTabPage() {
    if (this.currentTab === RootTabKey.HOME) {
      HomePage()
    } else if (this.currentTab === RootTabKey.LIBRARY) {
      ProjectDetailPage()
    } else {
      MyPage()
    }
  }

  build() {
    Column() {
      Column() {
        this.CurrentTabPage()
      }
      .layoutWeight(1)
      .width('100%')

      Row({ space: AppMetrics.space8 }) {
        ForEach(ROOT_TABS, (item: RootTabItem) => {
          this.TabButton(item);
        }, (item: RootTabItem) => item.key)
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space8, bottom: AppMetrics.space8 })
      .width('100%')
      .height(AppMetrics.tabBarHeight)
      .backgroundColor(AppColors.pageBackground)
      .border({ width: 1, color: '#EEEAE4' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
