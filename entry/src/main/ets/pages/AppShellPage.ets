import common from '@ohos.app.ability.common';
import { AppColors, AppMetrics, AppTypography } from '../components/AppDesign';
import { HomePage } from './HomePage';
import { ProjectDetailPage } from './ProjectDetailPage';
import { StatsPage } from './StatsPage';
import { MyPage } from './MyPage';
import { PendingReviewPhoto } from '../model/PendingReviewPhotoModel';
import { FormLaunchIntentService } from '../services/FormLaunchIntentService';
import {
  LEARNING_PROGRESS_WIDGET_ROUTE_HOME,
  LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING,
  LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT
} from '../services/LearningProgressFormService';
import { PendingReviewPhotoStore } from '../services/PendingReviewPhotoStore';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { ReviewLibraryRefreshService } from '../services/ReviewLibraryRefreshService';
import { SettingsRefreshService } from '../services/SettingsRefreshService';
import { MotionTokens } from '../theme/DesignTokens';
import { MotionCurveRole, MotionQualityContext } from '../theme/MotionQualityContext';
import { DialogService } from '../services/DialogService';
import { ToastService, ToastTone } from '../services/ToastService';
import { DebugLaunchScenarioService } from '../services/DebugLaunchScenarioService';
import {
  ReviewLibraryBackupInspection,
  ReviewLibraryBackupRestoreResult,
  ReviewLibraryBackupService
} from '../services/ReviewLibraryBackupService';

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

const TAB_PAGE_EXIT_DELAY: number = MotionTokens.durationStaggerLong;
const LIBRARY_INITIAL_FILTER_ALL: string = 'all';
const LIBRARY_INITIAL_FILTER_PENDING: string = 'pending';
const EDITOR_PAGE: string = 'pages/EditorPage';

@Entry
@Component
struct AppShellPage {
  private settingsRefreshListener: (token: number, reason: string) => void = (token: number, reason: string): void => {
    this.settingsRefreshToken = token;
    if (this.currentTab === RootTabKey.MY) {
      this.myRefreshToken += 1;
    }
  };
  private formLaunchIntentListener: () => void = (): void => {
    this.applyFormLaunchIntent();
  };
  @State currentTab: RootTabKey = RootTabKey.HOME;
  @State homeRefreshToken: number = 0;
  @State myRefreshToken: number = 0;
  @State reviewLibraryRefreshToken: number = ReviewLibraryRefreshService.getRefreshToken();
  @State settingsRefreshToken: number = SettingsRefreshService.getRefreshToken();
  @State libraryInitialFilter: string = LIBRARY_INITIAL_FILTER_ALL;
  @State tabContentVisible: boolean = true;
  @State tabIconScale: number = 1;
  private tabSwitchTimerId: number = -1;
  private tabIconTimerId: number = -1;
  private firstRestoreGuideChecked: boolean = false;

  aboutToAppear(): void {
    SettingsRefreshService.subscribe(this.settingsRefreshListener);
    FormLaunchIntentService.subscribe(this.formLaunchIntentListener);
    this.applyFormLaunchIntent();
    this.offerFirstLaunchRestore();
    MotionQualityContext.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  private async offerFirstLaunchRestore(): Promise<void> {
    if (this.firstRestoreGuideChecked || DebugLaunchScenarioService.isAutomatedTestLaunch()) {
      return;
    }
    this.firstRestoreGuideChecked = true;
    try {
      const shouldOffer: boolean = await ReviewLibraryBackupService.shouldOfferFirstLaunchRestore(
        this.getUIContext().getHostContext() as common.UIAbilityContext
      );
      if (!shouldOffer) {
        return;
      }
      DialogService.confirm(this.getUIContext(), {
        title: '恢复以前的复盘？',
        message: '本机还没有复盘记录。如果你保存过见遇完整备份，可以现在恢复；也可以稍后到“我的”中操作。',
        cancelText: '稍后',
        confirmText: '选择备份',
        onConfirm: () => {
          this.selectFirstLaunchBackup();
        }
      });
    } catch (error) {
      console.warn(`[AppShellPage] 首次恢复引导检查失败：${error}`);
    }
  }

  private async selectFirstLaunchBackup(): Promise<void> {
    try {
      const inspection: ReviewLibraryBackupInspection = await ReviewLibraryBackupService.selectAndInspectBackup(
        this.getUIContext().getHostContext() as common.UIAbilityContext
      );
      if (!inspection.success) {
        if (!inspection.cancelled) {
          ToastService.error(this.getUIContext(), inspection.message);
        }
        return;
      }
      const imageSummary: string = inspection.missingImageCount > 0
        ? `包含 ${inspection.imageCount} 张照片，旧版备份另有 ${inspection.missingImageCount} 张未包含。`
        : `包含 ${inspection.imageCount} 张照片。`;
      DialogService.confirm(this.getUIContext(), {
        title: `恢复 ${inspection.itemCount} 条复盘？`,
        message: `已合并 ${inspection.fileCount} 个备份并通过完整性校验，${imageSummary}家庭存储密码不会恢复。`,
        cancelText: '取消',
        confirmText: '确认恢复',
        onConfirm: () => {
          this.restoreFirstLaunchBackup(inspection);
        }
      });
    } catch (error) {
      ToastService.error(this.getUIContext(), `读取备份失败：${error}`);
    }
  }

  private async restoreFirstLaunchBackup(inspection: ReviewLibraryBackupInspection): Promise<void> {
    try {
      const result: ReviewLibraryBackupRestoreResult = await ReviewLibraryBackupService.restoreInspectedBackup(
        this.getUIContext().getHostContext() as common.UIAbilityContext,
        inspection
      );
      if (!result.success) {
        ToastService.error(this.getUIContext(), result.message);
        return;
      }
      ToastService.byTone(
        this.getUIContext(),
        result.message,
        result.settingsRestored ? ToastTone.SUCCESS : ToastTone.WARNING
      );
      this.syncReviewLibraryRefreshToken();
      this.syncSettingsRefreshToken();
      this.homeRefreshToken += 1;
    } catch (error) {
      ToastService.error(this.getUIContext(), `恢复失败，当前数据未被替换：${error}`);
    }
  }

  aboutToDisappear(): void {
    SettingsRefreshService.unsubscribe(this.settingsRefreshListener);
    FormLaunchIntentService.unsubscribe(this.formLaunchIntentListener);
    if (this.tabSwitchTimerId >= 0) {
      clearTimeout(this.tabSwitchTimerId);
      this.tabSwitchTimerId = -1;
    }
    if (this.tabIconTimerId >= 0) {
      clearTimeout(this.tabIconTimerId);
      this.tabIconTimerId = -1;
    }
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
    if (route === LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT) {
      this.openTodayReviewDirectly().catch((error: Error) => {
        console.warn(`[AppShellPage] 今日复盘直达失败，进入待复盘列表：${error.message}`);
        this.openPendingLibraryFromWidget();
      });
      return;
    }

    if (route === LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING) {
      this.openPendingLibraryFromWidget();
      return;
    }

    if (route === LEARNING_PROGRESS_WIDGET_ROUTE_HOME) {
      this.openHomeFromWidget();
    }
  }

  private async openTodayReviewDirectly(): Promise<void> {
    const photo: PendingReviewPhoto | undefined = await PendingReviewPhotoStore.getOldestPending(
      this.getUIContext().getHostContext() as common.UIAbilityContext
    );
    if (!photo) {
      this.openHomeFromWidget();
      return;
    }

    ReviewCardStore.createPendingPhotoDraft(
      photo.id,
      photo.photoUri,
      photo.width,
      photo.height,
      photo.orientation === 'unknown'
    );
    this.getUIContext().getRouter().pushUrl({ url: EDITOR_PAGE }).catch((error: Error) => {
      console.error(`[AppShellPage] 打开今日复盘失败：${error.message}`);
      this.openPendingLibraryFromWidget();
    });
  }

  private openPendingLibraryFromWidget(): void {
    this.libraryInitialFilter = LIBRARY_INITIAL_FILTER_PENDING;
    this.currentTab = RootTabKey.LIBRARY;
    this.reviewLibraryRefreshToken = ReviewLibraryRefreshService.getRefreshToken() + 1;
    this.tabContentVisible = true;
  }

  private openHomeFromWidget(): void {
    this.libraryInitialFilter = LIBRARY_INITIAL_FILTER_ALL;
    this.currentTab = RootTabKey.HOME;
    this.homeRefreshToken += 1;
    this.tabContentVisible = true;
  }

  private isCurrentTab(key: RootTabKey): boolean {
    return this.currentTab === key;
  }

  private selectTab(key: RootTabKey): void {
    if (this.currentTab === key) {
      return;
    }

    if (this.tabSwitchTimerId >= 0) {
      clearTimeout(this.tabSwitchTimerId);
    }
    this.tabContentVisible = false;
    this.tabSwitchTimerId = setTimeout(() => {
      this.tabSwitchTimerId = -1;
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
      this.playTabIconPulse();
    }, TAB_PAGE_EXIT_DELAY);
  }

  private playTabIconPulse(): void {
    if (this.tabIconTimerId >= 0) {
      clearTimeout(this.tabIconTimerId);
    }
    this.tabIconScale = MotionTokens.scaleCeremony;
    this.tabIconTimerId = setTimeout(() => {
      this.tabIconScale = 1;
      this.tabIconTimerId = -1;
    }, MotionTokens.durationQuick);
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
        .opacity(this.isCurrentTab(item.key) ? 1 : 0.6)
        .scale({
          x: this.isCurrentTab(item.key) ? this.tabIconScale : 1,
          y: this.isCurrentTab(item.key) ? this.tabIconScale : 1
        })
        .animation({
          duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
          curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_BOUNCY)
        })

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
      .translate({ y: this.tabContentVisible ? 0 : MotionTokens.offsetEnterY })
      .scale({
        x: this.tabContentVisible ? 1 : MotionTokens.scaleSubtle,
        y: this.tabContentVisible ? 1 : MotionTokens.scaleSubtle
      })
      .animation({
        duration: MotionQualityContext.resolveDuration(
          this.tabContentVisible ? MotionTokens.durationStandard : MotionTokens.durationQuick
        ),
        curve: MotionQualityContext.resolveCurve(
          this.tabContentVisible ? MotionCurveRole.SPRING_SOFT : MotionCurveRole.EMPHASIZED
        )
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
