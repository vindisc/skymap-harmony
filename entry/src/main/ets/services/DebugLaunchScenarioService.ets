import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import {
  FormLaunchIntentService,
  IntentRouteSource
} from './FormLaunchIntentService';
import {
  LEARNING_PROGRESS_WIDGET_ROUTE_HOME,
  LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING,
  LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT
} from './LearningProgressFormService';
import {
  ReviewCardDocument,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { ReviewCardStore } from './ReviewCardStore';
import { SampleImageKind } from '../utils/ImageLayoutUtils';

const DEBUG_TEST_SCENARIO_KEY: string = 'testScenario';
const APP_SHELL_PAGE: string = 'pages/AppShellPage';
const EDITOR_PAGE: string = 'pages/EditorPage';
const PREVIEW_PAGE: string = 'pages/PreviewPage';
const REVIEWER_PROFILE_PAGE: string = 'pages/ReviewerProfilePage';
const HOME_HERO_IMAGE_PAGE: string = 'pages/HomeHeroImagePage';
const WIDGET_CARD_BACKGROUND_PAGE: string = 'pages/WidgetCardBackgroundPage';
const HOME_STORAGE_PAGE: string = 'pages/HomeStoragePage';
const REVIEW_SETTINGS_PAGE: string = 'pages/ReviewSettingsPage';
const SYNC_CENTER_PAGE: string = 'pages/SyncCenterPage';
const DEBUG_FIXTURE_FILE_NAME: string = 'fixture-l3-photo.jpg';
const DEBUG_FIXTURE_WIDTH: number = 7878;
const DEBUG_FIXTURE_HEIGHT: number = 5252;

export enum DebugTestScenario {
  HOME = 'home',
  PENDING = 'pending',
  TODAY = 'today',
  EDITOR_HORIZONTAL = 'editor_horizontal',
  EDITOR_VERTICAL = 'editor_vertical',
  EDITOR_SQUARE = 'editor_square',
  PREVIEW_HORIZONTAL = 'preview_horizontal',
  PREVIEW_VERTICAL = 'preview_vertical',
  PREVIEW_SQUARE = 'preview_square',
  PREVIEW_LONG_TEXT = 'preview_long_text',
  REVIEWER_PROFILE = 'reviewer_profile',
  HOME_HERO_SETTINGS = 'home_hero_settings',
  WIDGET_CARD_SETTINGS = 'widget_card_settings',
  HOME_STORAGE = 'home_storage',
  REVIEW_SETTINGS = 'review_settings',
  SYNC_CENTER = 'sync_center',
  CANVAS_SPIKE = 'canvas_spike',
  CANVAS_SPIKE_V2 = 'canvas_spike_v2',
  CANVAS_SPIKE_V2_DECODE = 'canvas_spike_v2_decode',
  CANVAS_SPIKE_V2_L3_EXPORT = 'canvas_spike_v2_l3_export',
  CANVAS_SPIKE_V2_L0_EXPORT = 'canvas_spike_v2_l0_export',
  CANVAS_SPIKE_V2_L1_EXPORT = 'canvas_spike_v2_l1_export'
}

export class DebugLaunchScenarioService {
  private static pendingInitialPage: string = '';
  private static automatedTestLaunch: boolean = false;
  private static canvasSpikeScenario: boolean = false;
  private static canvasSpikeV2Scenario: boolean = false;
  private static canvasSpikeV2DecodeScenario: boolean = false;
  private static canvasSpikeV2L3ExportScenario: boolean = false;
  private static canvasSpikeV2L0ExportScenario: boolean = false;
  private static canvasSpikeV2L1ExportScenario: boolean = false;
  private static debugContext: common.UIAbilityContext | null = null;

  static captureWant(
    want: Want | undefined,
    isDebugBuild: boolean,
    context: common.UIAbilityContext
  ): void {
    if (!isDebugBuild) {
      return;
    }
    DebugLaunchScenarioService.debugContext = context;
    const scenarioValue: Object | undefined = want?.parameters?.[DEBUG_TEST_SCENARIO_KEY];
    const scenario: string = `${scenarioValue ?? ''}`;
    DebugLaunchScenarioService.automatedTestLaunch = scenario.length > 0;
    DebugLaunchScenarioService.canvasSpikeScenario = scenario === DebugTestScenario.CANVAS_SPIKE;
    DebugLaunchScenarioService.canvasSpikeV2Scenario = scenario === DebugTestScenario.CANVAS_SPIKE_V2;
    DebugLaunchScenarioService.canvasSpikeV2DecodeScenario =
      scenario === DebugTestScenario.CANVAS_SPIKE_V2_DECODE;
    DebugLaunchScenarioService.canvasSpikeV2L3ExportScenario =
      scenario === DebugTestScenario.CANVAS_SPIKE_V2_L3_EXPORT;
    DebugLaunchScenarioService.canvasSpikeV2L0ExportScenario =
      scenario === DebugTestScenario.CANVAS_SPIKE_V2_L0_EXPORT;
    DebugLaunchScenarioService.canvasSpikeV2L1ExportScenario =
      scenario === DebugTestScenario.CANVAS_SPIKE_V2_L1_EXPORT;
    DebugLaunchScenarioService.pendingInitialPage = DebugLaunchScenarioService.resolveDirectPage(scenario);
    if (DebugLaunchScenarioService.pendingInitialPage.length > 0) {
      DebugLaunchScenarioService.prepareDraft(scenario);
      return;
    }
    const route: string = DebugLaunchScenarioService.resolveRoute(scenario);
    if (route.length > 0) {
      DebugLaunchScenarioService.pendingInitialPage = APP_SHELL_PAGE;
      FormLaunchIntentService.captureRouteFromIntent(route, IntentRouteSource.TEST);
    }
  }

  static consumeInitialPage(): string {
    const page: string = DebugLaunchScenarioService.pendingInitialPage;
    DebugLaunchScenarioService.pendingInitialPage = '';
    return page;
  }

  static isAutomatedTestLaunch(): boolean {
    return DebugLaunchScenarioService.automatedTestLaunch;
  }

  static isCanvasSpikeScenario(): boolean {
    return DebugLaunchScenarioService.canvasSpikeScenario;
  }

  static isCanvasSpikeV2Scenario(): boolean {
    return DebugLaunchScenarioService.canvasSpikeV2Scenario;
  }

  static isCanvasSpikeV2DecodeScenario(): boolean {
    return DebugLaunchScenarioService.canvasSpikeV2DecodeScenario;
  }

  static isCanvasSpikeV2L3ExportScenario(): boolean {
    return DebugLaunchScenarioService.canvasSpikeV2L3ExportScenario;
  }

  static isCanvasSpikeV2L0ExportScenario(): boolean {
    return DebugLaunchScenarioService.canvasSpikeV2L0ExportScenario;
  }

  static isCanvasSpikeV2L1ExportScenario(): boolean {
    return DebugLaunchScenarioService.canvasSpikeV2L1ExportScenario;
  }

  private static resolveRoute(scenario: string): string {
    if (scenario === DebugTestScenario.HOME) {
      return LEARNING_PROGRESS_WIDGET_ROUTE_HOME;
    }
    if (scenario === DebugTestScenario.PENDING) {
      return LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING;
    }
    if (scenario === DebugTestScenario.TODAY) {
      return LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT;
    }
    return '';
  }

  private static resolveDirectPage(scenario: string): string {
    if (scenario.startsWith('editor_')) {
      return EDITOR_PAGE;
    }
    if (scenario.startsWith('preview_')) {
      return PREVIEW_PAGE;
    }
    if (scenario === DebugTestScenario.REVIEWER_PROFILE) {
      return REVIEWER_PROFILE_PAGE;
    }
    if (scenario === DebugTestScenario.HOME_HERO_SETTINGS) {
      return HOME_HERO_IMAGE_PAGE;
    }
    if (scenario === DebugTestScenario.WIDGET_CARD_SETTINGS) {
      return WIDGET_CARD_BACKGROUND_PAGE;
    }
    if (scenario === DebugTestScenario.HOME_STORAGE) {
      return HOME_STORAGE_PAGE;
    }
    if (scenario === DebugTestScenario.REVIEW_SETTINGS) {
      return REVIEW_SETTINGS_PAGE;
    }
    if (scenario === DebugTestScenario.SYNC_CENTER) {
      return SYNC_CENTER_PAGE;
    }
    if (scenario === DebugTestScenario.CANVAS_SPIKE) {
      return APP_SHELL_PAGE;
    }
    if (scenario === DebugTestScenario.CANVAS_SPIKE_V2) {
      return APP_SHELL_PAGE;
    }
    if (scenario === DebugTestScenario.CANVAS_SPIKE_V2_DECODE) {
      return APP_SHELL_PAGE;
    }
    if (scenario === DebugTestScenario.CANVAS_SPIKE_V2_L3_EXPORT) {
      return APP_SHELL_PAGE;
    }
    if (scenario === DebugTestScenario.CANVAS_SPIKE_V2_L0_EXPORT) {
      return APP_SHELL_PAGE;
    }
    if (scenario === DebugTestScenario.CANVAS_SPIKE_V2_L1_EXPORT) {
      return APP_SHELL_PAGE;
    }
    return '';
  }

  private static prepareDraft(scenario: string): void {
    if (!scenario.startsWith('editor_') && !scenario.startsWith('preview_')) {
      return;
    }
    const context: common.UIAbilityContext | null = DebugLaunchScenarioService.debugContext;
    if (context === null) {
      return;
    }
    const kind: SampleImageKind = DebugLaunchScenarioService.resolveImageKind(scenario);
    const document: ReviewCardDocument = ReviewCardStore.createDraft(kind);
    const fixturePath: string = DebugLaunchScenarioService.ensureFixturePhotoInSandbox(context);
    document.imageUri = fixturePath;
    document.imageWidth = DEBUG_FIXTURE_WIDTH;
    document.imageHeight = DEBUG_FIXTURE_HEIGHT;
    document.imageSizeFallbackUsed = false;
    document.content.title = '自动化测试复盘';
    document.content.visualFocus = '人物与窗边的高光';
    document.content.focusReason = '亮度反差形成第一视觉落点';
    document.content.visualPath = '从人物面部移动到窗框，再回到桌面物件';
    document.content.visibleFacts = '室内自然光，人物位于画面左侧，背景保持简洁';
    document.content.coreRelation = '人物和环境形成安静但明确的空间关系';
    document.content.judgement = ReviewJudgementStatus.VALID;
    document.content.extendedUnderstanding = '画面的节奏来自明暗区域之间的停顿';
    document.content.currentBlocker = scenario === DebugTestScenario.PREVIEW_LONG_TEXT
      ? '这是用于验证长文本换行、滚动边界、卡片高度和底部操作区不重叠的测试内容。'.repeat(8)
      : '人物右侧仍有少量无效空间';
    ReviewCardStore.setCurrentDocument(document);
  }

  private static ensureFixturePhotoInSandbox(context: common.UIAbilityContext): string {
    const sandboxPath: string = `${context.filesDir}/${DEBUG_FIXTURE_FILE_NAME}`;
    if (fs.accessSync(sandboxPath)) {
      return sandboxPath;
    }
    const rawContent: Uint8Array = context.resourceManager.getRawFileContentSync(DEBUG_FIXTURE_FILE_NAME);
    const contentBuffer: ArrayBuffer = new ArrayBuffer(rawContent.byteLength);
    new Uint8Array(contentBuffer).set(rawContent);
    const fixtureFile: fs.File = fs.openSync(
      sandboxPath,
      fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC
    );
    try {
      fs.writeSync(fixtureFile.fd, contentBuffer);
    } finally {
      fs.closeSync(fixtureFile);
    }
    return sandboxPath;
  }

  private static resolveImageKind(scenario: string): SampleImageKind {
    if (scenario.includes('vertical')) {
      return 'vertical';
    }
    if (scenario.includes('square')) {
      return 'square';
    }
    return 'horizontal';
  }
}
