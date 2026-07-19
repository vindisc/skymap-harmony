import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import { font } from '@kit.ArkUI';
import window from '@ohos.window';
import { FormLaunchIntentService } from '../services/FormLaunchIntentService';
import { LearningProgressFormService } from '../services/LearningProgressFormService';
import { DebugLaunchScenarioService } from '../services/DebugLaunchScenarioService';
import { CanvasSpikeService } from '../services/CanvasSpikeService';
import { CanvasSpikeV2Service } from '../services/CanvasSpikeV2Service';
import { CanvasSpikeV2DecodeService } from '../services/CanvasSpikeV2DecodeService';
import { CanvasSpikeV2L0ExportService } from '../services/CanvasSpikeV2L0ExportService';
import { CanvasSpikeV2L1ExportService } from '../services/CanvasSpikeV2L1ExportService';
import { CanvasSpikeV2L3ExportService } from '../services/CanvasSpikeV2L3ExportService';
import { MotionQualityContext } from '../theme/MotionQualityContext';

const APP_PAGE_BACKGROUND: string = '#F5F1E9';
const APP_TRANSPARENT: string = '#00000000';

export default class EntryAbility extends UIAbility {
  private mainWindowStage: window.WindowStage | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FormLaunchIntentService.captureWant(want);
    DebugLaunchScenarioService.captureWant(want, this.context.applicationInfo.debug);
    this.registerV2Fonts();
  }

  private registerV2Fonts(): void {
    try {
      font.registerFont({
        familyName: 'NotoSansSC-Regular',
        familySrc: '/font/NotoSansSC-Regular.ttf'
      });
      font.registerFont({
        familyName: 'NotoSansSC-Bold',
        familySrc: '/font/NotoSansSC-Bold.ttf'
      });
    } catch (error) {
      console.warn(`[EntryAbility] 思源黑体注册失败：${error}`);
    }
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
    if (DebugLaunchScenarioService.isCanvasSpikeV2L1ExportScenario()) {
      CanvasSpikeV2L1ExportService.runL1ExportPoC(this.context).catch((error: Error) => {
        console.error(`[CanvasSpikeV2L1Export] 失败：${error.message}`);
      });
    } else if (DebugLaunchScenarioService.isCanvasSpikeV2L0ExportScenario()) {
      CanvasSpikeV2L0ExportService.runL0ExportPoC(this.context).catch((error: Error) => {
        console.error(`[CanvasSpikeV2L0Export] 失败：${error.message}`);
      });
    } else if (DebugLaunchScenarioService.isCanvasSpikeV2L3ExportScenario()) {
      CanvasSpikeV2L3ExportService.runL3ExportPoC(this.context).catch((error: Error) => {
        console.error(`[CanvasSpikeV2L3Export] 失败：${error.message}`);
      });
    } else if (DebugLaunchScenarioService.isCanvasSpikeV2DecodeScenario()) {
      CanvasSpikeV2DecodeService.runDecodeRegionPoC(this.context).catch((error: Error) => {
        console.error(`[CanvasSpikeV2Decode] 失败：${error.message}`);
      });
    } else if (DebugLaunchScenarioService.isCanvasSpikeV2Scenario()) {
      CanvasSpikeV2Service.runEncoderPoC(this.context).catch((error: Error) => {
        console.error(`[CanvasSpikeV2] 失败：${error.message}`);
      });
    } else if (DebugLaunchScenarioService.isCanvasSpikeScenario()) {
      CanvasSpikeService.runSpike(this.context).catch((error: Error) => {
        console.error(`[CanvasSpike] 失败：${error.message}`);
      });
    }
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
