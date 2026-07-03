import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';

const APP_PAGE_BACKGROUND: string = '#F5F1E9';
const APP_TRANSPARENT: string = '#00000000';

export default class EntryAbility extends UIAbility {
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
  }
}
