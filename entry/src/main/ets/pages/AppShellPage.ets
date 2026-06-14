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
  symbol: string;
}

const ROOT_TABS: Array<RootTabItem> = [
  { key: RootTabKey.HOME, label: '首页', symbol: '首' },
  { key: RootTabKey.LIBRARY, label: '复盘库', symbol: '库' },
  { key: RootTabKey.MY, label: '我的', symbol: '我' }
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

  private resolveTabSymbolColor(key: RootTabKey): string {
    return this.isCurrentTab(key) ? AppColors.primary : AppColors.mutedText;
  }

  private resolveTabLabelColor(key: RootTabKey): string {
    return this.isCurrentTab(key) ? AppColors.text : AppColors.secondaryText;
  }

  private resolveTabSymbolWeight(key: RootTabKey): number {
    return this.isCurrentTab(key) ? FontWeight.Bold : FontWeight.Medium;
  }

  private resolveTabLabelWeight(key: RootTabKey): number {
    return this.isCurrentTab(key) ? FontWeight.Medium : FontWeight.Regular;
  }

  private resolveTabBackground(key: RootTabKey): string {
    return this.isCurrentTab(key) ? AppColors.surface : '#00000000';
  }

  @Builder
  TabButton(item: RootTabItem) {
    Column({ space: AppMetrics.space4 }) {
      Text(item.symbol)
        .fontSize(AppTypography.body)
        .fontWeight(this.resolveTabSymbolWeight(item.key))
        .fontColor(this.resolveTabSymbolColor(item.key))

      Text(item.label)
        .fontSize(AppTypography.caption)
        .fontWeight(this.resolveTabLabelWeight(item.key))
        .fontColor(this.resolveTabLabelColor(item.key))
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .height(56)
    .borderRadius(AppMetrics.cardRadius)
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
      .backgroundColor(AppColors.pageBackground)
      .border({ width: 1, color: AppColors.border })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
