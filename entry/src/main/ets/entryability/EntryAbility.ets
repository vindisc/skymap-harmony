import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { FormLaunchIntentService } from '../services/FormLaunchIntentService';
import { LearningProgressFormService } from '../services/LearningProgressFormService';
import { DebugLaunchScenarioService } from '../services/DebugLaunchScenarioService';
import { MotionQualityContext } from '../theme/MotionQualityContext';

const APP_PAGE_BACKGROUND: string = '#F5F1E9';
const APP_TRANSPARENT: string = '#00000000';

export default class EntryAbility extends UIAbility {
  private mainWindowStage: window.WindowStage | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FormLaunchIntentService.captureWant(want);
    DebugLaunchScenarioService.captureWant(want, this.context.applicationInfo.debug);
  }

  onNewWant(want: Want): void {
    FormLaunchIntentService.captureWant(want);
    DebugLaunchScenarioService.captureWant(want, this.context.applicationInfo.debug);
    const initialPage: string = DebugLaunchScenarioService.consumeInitialPage();
    if (this.mainWindowStage && initialPage.length > 0) {
      this.mainWindowStage.loadContent(initialPage);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.mainWindowStage = windowStage;
    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true).catch(() => {
      });
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: APP_TRANSPARENT,
        navigationBarColor: APP_TRANSPARENT,
        statusBarContentColor: '#171A1F',
        navigationBarContentColor: '#171A1F'
      });
    } catch (error) {
    }

    const debugInitialPage: string = DebugLaunchScenarioService.consumeInitialPage();
    this.initializeMotionAndLoadContent(
      windowStage,
      debugInitialPage.length > 0 ? debugInitialPage : 'pages/AppShellPage'
    );
    LearningProgressFormService.refreshAllForms(this.context).catch((error: Error) => {
      console.warn(`[EntryAbility] 学习进度服务卡片同步失败：${error.message}`);
    });
  }

  private async initializeMotionAndLoadContent(windowStage: window.WindowStage, page: string): Promise<void> {
    try {
      await MotionQualityContext.initialize(this.context);
    } catch (error) {
      console.warn(`[EntryAbility] 动效强度读取失败，使用默认设置：${error}`);
    }
    windowStage.loadContent(page);
  }
}
