import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';

const APP_PAGE_BACKGROUND: string = '#F6F4EF';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      windowStage.getMainWindowSync().setWindowSystemBarProperties({
        statusBarColor: APP_PAGE_BACKGROUND,
        navigationBarColor: APP_PAGE_BACKGROUND,
        statusBarContentColor: '#171A1F',
        navigationBarContentColor: '#171A1F'
      });
    } catch (error) {
    }

    windowStage.loadContent('pages/AppShellPage');
  }
}
