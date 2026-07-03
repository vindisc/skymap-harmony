import { AppColors, AppMetrics, AppTypography } from '../components/AppDesign';
import { HomePage } from './HomePage';
import { ProjectDetailPage } from './ProjectDetailPage';
import { StatsPage } from './StatsPage';
import { MyPage } from './MyPage';
import { FormLaunchIntentService } from '../services/FormLaunchIntentService';
import {
  LEARNING_PROGRESS_WIDGET_ROUTE_HOME,
  LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING
} from '../services/LearningProgressFormService';
import { ReviewLibraryRefreshService } from '../services/ReviewLibraryRefreshService';
import { SettingsRefreshService } from '../services/SettingsRefreshService';
import { MotionTokens } from '../theme/DesignTokens';

enum RootTabKey {
  HOME = 'home',
  LIBRARY = 'library',
  STATS = 'stats',
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
  { key: RootTabKey.STATS, label: '统计', activeIcon: $r('app.media.tab_stats_active'), inactiveIcon: $r('app.media.tab_stats') },
  { key: RootTabKey.MY, label: '我的', activeIcon: $r('app.media.tab_user_active'), inactiveIcon: $r('app.media.tab_user') }
];

const TAB_PAGE_EXIT_DELAY: number = 90;
const LIBRARY_INITIAL_FILTER_ALL: string = 'all';
const LIBRARY_INITIAL_FILTER_PENDING: string = 'pending';

@Entry
@Component
struct AppShellPage {
  private settingsRefreshListener: (token: number, reason: string) => void = (token: number, reason: string): void => {
    this.settingsRefreshToken = token;
    if (this.currentTab === RootTabKey.MY) {
      this.myRefreshToken += 1;
    }
  };
  @State currentTab: RootTabKey = RootTabKey.HOME;
  @State homeRefreshToken: number = 0;
  @State myRefreshToken: number = 0;
  @State reviewLibraryRefreshToken: number = ReviewLibraryRefreshService.getRefreshToken();
  @State settingsRefreshToken: number = SettingsRefreshService.getRefreshToken();
  @State libraryInitialFilter: string = LIBRARY_INITIAL_FILTER_ALL;
  @State tabContentVisible: boolean = true;

  aboutToAppear(): void {
    SettingsRefreshService.subscribe(this.settingsRefreshListener);
    this.applyFormLaunchIntent();
  }

  onPageShow(): void {
    this.applyFormLaunchIntent();
    this.syncReviewLibraryRefreshToken();
    this.syncSettingsRefreshToken();
    this.refreshCurrentTabIfNeeded();
  }

  private syncReviewLibraryRefreshToken(): void {
    const nextToken: number = ReviewLibraryRefreshService.getRefreshToken();
    if (nextToken !== this.reviewLibraryRefreshToken) {
      this.reviewLibraryRefreshToken = nextToken;
    }
  }

  private syncSettingsRefreshToken(): void {
    const nextToken: number = SettingsRefreshService.getRefreshToken();
    if (nextToken !== this.settingsRefreshToken) {
      this.settingsRefreshToken = nextToken;
    }
  }

  private refreshCurrentTabIfNeeded(): void {
    if (this.currentTab === RootTabKey.HOME) {
      this.homeRefreshToken += 1;
      return;
    }

    if (this.currentTab === RootTabKey.MY) {
      this.myRefreshToken += 1;
    }
  }

  private applyFormLaunchIntent(): void {
    const route: string = FormLaunchIntentService.consumeRoute();
    if (route === LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING) {
      this.libraryInitialFilter = LIBRARY_INITIAL_FILTER_PENDING;
      this.currentTab = RootTabKey.LIBRARY;
      this.reviewLibraryRefreshToken = ReviewLibraryRefreshService.getRefreshToken() + 1;
      this.tabContentVisible = true;
      return;
    }

    if (route === LEARNING_PROGRESS_WIDGET_ROUTE_HOME) {
      this.libraryInitialFilter = LIBRARY_INITIAL_FILTER_ALL;
      this.currentTab = RootTabKey.HOME;
      this.homeRefreshToken += 1;
      this.tabContentVisible = true;
    }
  }

  private isCurrentTab(key: RootTabKey): boolean {
    return this.currentTab === key;
  }

  private selectTab(key: RootTabKey): void {
    if (this.currentTab === key) {
      return;
    }

    this.tabContentVisible = false;
    setTimeout(() => {
      this.currentTab = key;
      if (key !== RootTabKey.LIBRARY) {
        this.libraryInitialFilter = LIBRARY_INITIAL_FILTER_ALL;
      }
      this.syncReviewLibraryRefreshToken();
      this.syncSettingsRefreshToken();
      if (key === RootTabKey.HOME) {
        this.homeRefreshToken += 1;
      }
      if (key === RootTabKey.MY) {
        this.myRefreshToken += 1;
      }
      this.tabContentVisible = true;
    }, TAB_PAGE_EXIT_DELAY);
  }

  private resolveTabLabelColor(key: RootTabKey): string {
    return this.isCurrentTab(key) ? AppColors.primary : AppColors.mutedText;
  }

  private resolveTabLabelWeight(key: RootTabKey): number {
    return this.isCurrentTab(key) ? 600 : FontWeight.Regular;
  }

  private resolveTabBackground(key: RootTabKey): string {
    return this.isCurrentTab(key) ? AppColors.primarySoft : AppColors.transparent;
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
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .height(AppMetrics.tabBarItemHeight)
    .padding({ left: 6, right: 6, top: 4, bottom: 4 })
    .borderRadius(AppMetrics.buttonRadius)
    .backgroundColor(this.resolveTabBackground(item.key))
    .opacity(this.isCurrentTab(item.key) ? 1 : 0.86)
    .onClick(() => {
      this.selectTab(item.key);
    })
  }

  @Builder
  CurrentTabPage() {
    if (this.currentTab === RootTabKey.HOME) {
      HomePage({ refreshToken: this.homeRefreshToken + this.reviewLibraryRefreshToken })
    } else if (this.currentTab === RootTabKey.LIBRARY) {
      ProjectDetailPage({ refreshToken: this.reviewLibraryRefreshToken, initialFilter: this.libraryInitialFilter })
    } else if (this.currentTab === RootTabKey.STATS) {
      StatsPage({ refreshToken: this.reviewLibraryRefreshToken })
    } else {
      MyPage({ refreshToken: this.myRefreshToken + this.reviewLibraryRefreshToken + this.settingsRefreshToken })
    }
  }

  build() {
    Column() {
      Column() {
        this.CurrentTabPage()
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(AppColors.pageBackground)
      .opacity(this.tabContentVisible ? 1 : 0)
      .translate({ y: this.tabContentVisible ? 0 : 10 })
      .animation({
        duration: this.tabContentVisible ? MotionTokens.durationStandard : MotionTokens.durationQuick,
        curve: this.tabContentVisible ? MotionTokens.curveDecelerate : MotionTokens.curveAccelerate
      })

      Column() {
        Divider()
          .strokeWidth(1)
          .color(AppColors.border)
          .opacity(0.42)
          .width('100%')

        Row({ space: AppMetrics.space8 }) {
          ForEach(ROOT_TABS, (item: RootTabItem) => {
            this.TabButton(item);
          }, (item: RootTabItem) => item.key)
        }
        .height(AppMetrics.tabBarHeight)
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: 4,
          bottom: 4
        })
        .width('100%')
      }
      .width('100%')
      .height(AppMetrics.tabBarShellHeight)
      .backgroundColor(AppColors.tabBarBackground)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
