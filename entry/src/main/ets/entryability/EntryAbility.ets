import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import { FormLaunchIntentService } from '../services/FormLaunchIntentService';
import { LearningProgressFormService } from '../services/LearningProgressFormService';
import { DebugLaunchScenarioService } from '../services/DebugLaunchScenarioService';

const APP_PAGE_BACKGROUND: string = '#F5F1E9';
const APP_TRANSPARENT: string = '#00000000';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FormLaunchIntentService.captureWant(want);
    DebugLaunchScenarioService.captureWant(want, this.context.applicationInfo.debug);
  }

  onNewWant(want: Want): void {
    FormLaunchIntentService.captureWant(want);
    DebugLaunchScenarioService.captureWant(want, this.context.applicationInfo.debug);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
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

    windowStage.loadContent('pages/AppShellPage');
    LearningProgressFormService.refreshAllForms(this.context).catch((error: Error) => {
      console.warn(`[EntryAbility] 学习进度服务卡片同步失败：${error.message}`);
    });
  }
}
