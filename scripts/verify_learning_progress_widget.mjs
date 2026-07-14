import fs from 'node:fs';
import { spawnSync } from 'node:child_process';

let failed = false;

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function requireIncludes(source, token, message) {
  assert(source.includes(token), `${message}: missing "${token}"`);
}

function countOccurrences(source, token) {
  return source.split(token).length - 1;
}

const moduleConfig = read('entry/src/main/module.json5');
const mainPagesConfig = read('entry/src/main/resources/base/profile/main_pages.json');
const appRouter = read('entry/src/main/ets/app/AppRouter.ets');
const formConfig = read('entry/src/main/resources/base/profile/form_config.json');
const formAbility = read('entry/src/main/ets/formability/LearningProgressFormAbility.ets');
const formPage = read('entry/src/main/ets/widget/pages/LearningProgressMediumCard.ets');
const progressSummaryMediumPage = read('entry/src/main/ets/widget/pages/LearningProgressSummaryMediumCard.ets');
const todayReviewPage = read('entry/src/main/ets/widget/pages/TodayReviewCard.ets');
const rhythmReviewPage = read('entry/src/main/ets/widget/pages/ReviewRhythmCard.ets');
const progressService = read('entry/src/main/ets/services/LearningProgressService.ets');
const formService = read('entry/src/main/ets/services/LearningProgressFormService.ets');
const launchService = read('entry/src/main/ets/services/FormLaunchIntentService.ets');
const statsPage = read('entry/src/main/ets/pages/StatsPage.ets');
const appShell = read('entry/src/main/ets/pages/AppShellPage.ets');
const homePage = read('entry/src/main/ets/pages/HomePage.ets');
const editorPage = read('entry/src/main/ets/pages/EditorPage.ets');
const projectDetailPage = read('entry/src/main/ets/pages/ProjectDetailPage.ets');
const previewPage = read('entry/src/main/ets/pages/PreviewPage.ets');
const entryAbility = read('entry/src/main/ets/entryability/EntryAbility.ets');
const appearanceSettingsPage = read('entry/src/main/ets/pages/AppearanceSettingsPage.ets');
const widgetCardBackgroundPage = read('entry/src/main/ets/pages/WidgetCardBackgroundPage.ets');
const widgetCardBackground = read('entry/src/main/ets/components/WidgetCardBackground.ets');
const huiwenSquare = read('entry/src/main/resources/base/media/widget_card_huiwen_square.svg');
const huiwenWide = read('entry/src/main/resources/base/media/widget_card_huiwen_wide.svg');
const huiwenCornerSquare = read('entry/src/main/resources/base/media/widget_card_huiwen_corner_square.svg');
const huiwenCornerWide = read('entry/src/main/resources/base/media/widget_card_huiwen_corner_wide.svg');
const reviewSettingsService = read('entry/src/main/ets/services/ReviewSettingsService.ets');

const styleLockResult = spawnSync(process.execPath, ['scripts/verify_widget_style_lock.mjs'], {
  encoding: 'utf8'
});
if (styleLockResult.status !== 0) {
  failed = true;
  if (styleLockResult.stdout.trim().length > 0) {
    console.error(styleLockResult.stdout.trim());
  }
  if (styleLockResult.stderr.trim().length > 0) {
    console.error(styleLockResult.stderr.trim());
  }
}

[
  '"extensionAbilities"',
  '"LearningProgressFormAbility"',
  '"type": "form"',
  '"resource": "$profile:form_config"'
].forEach((token) => requireIncludes(moduleConfig, token, 'module.json5 must register the learning progress form ability'));

[
  '"LearningProgressMediumCard"',
  '"displayName": "摄影复盘卡"',
  '"src": "./ets/widget/pages/LearningProgressMediumCard.ets"',
  '"LearningProgressSummaryMediumCard"',
  '"displayName": "学习进度"',
  '"src": "./ets/widget/pages/LearningProgressSummaryMediumCard.ets"',
  '"TodayReviewCard"',
  '"displayName": "今日复盘"',
  '"src": "./ets/widget/pages/TodayReviewCard.ets"',
  '"ReviewRhythmCard"',
  '"displayName": "复盘节奏"',
  '"src": "./ets/widget/pages/ReviewRhythmCard.ets"',
  '"uiSyntax": "arkts"',
  '"2*2"',
  '"2*4"',
  '"defaultDimension": "2*4"'
].forEach((token) => requireIncludes(formConfig, token, 'form_config must expose small, medium, and today review ArkTS cards'));

[
  'FormExtensionAbility',
  'onAddForm(want: Want)',
  'LearningProgressFormService.addFormId',
  'LearningProgressFormService.refreshForm',
  'onUpdateForm(formId: string)',
  'onRemoveForm(formId: string)'
].forEach((token) => requireIncludes(formAbility, token, 'LearningProgressFormAbility must manage form lifecycle'));

[
  "Text(this.title)",
  'Text(this.pendingCountText)',
  "@LocalStorageProp('cardBackgroundStyle') cardBackgroundStyle: string = 'plain';",
  "import { WidgetCardBackground } from '../../components/WidgetCardBackground';",
  'style: this.cardBackgroundStyle',
  "layout: 'square'",
  "Text('待复盘')",
  '2*2 左侧小卡片以截图为准',
  'const LEARNING_CARD_2X2_PADDING: number = 16;',
  'const LEARNING_CARD_2X2_RADIUS: number = 24;',
  'const LEARNING_CARD_2X2_COUNT_SIZE: number = 48;',
  'const LEARNING_CARD_2X2_COUNT_LINE_HEIGHT: number = 52;',
  'Column({ space: 0 })',
  '.fontSize(LEARNING_CARD_2X2_TITLE_SIZE)',
  '.textOverflow({ overflow: TextOverflow.Ellipsis })',
  '.fontSize(LEARNING_CARD_2X2_COUNT_SIZE)',
  '.lineHeight(LEARNING_CARD_2X2_COUNT_LINE_HEIGHT)',
  '.fontWeight(900)',
  '.letterSpacing(-2)',
  '.layoutWeight(1)',
  '.padding(LEARNING_CARD_2X2_PADDING)',
  '.borderRadius(LEARNING_CARD_2X2_RADIUS)',
  'postCardAction(this',
  '.onClick(() =>',
  "moduleName: 'entry'",
  "abilityName: 'EntryAbility'",
  'targetRoute: this.targetRoute'
].forEach((token) => requireIncludes(formPage, token, 'LearningProgressMediumCard must match required content and click behavior'));

assert(!formPage.includes('Button('), 'LearningProgressMediumCard must not add card-level buttons.');
assert(!formPage.includes('completionRateText') &&
  !formPage.includes('CompletionBadge()') &&
  !formPage.includes("Text('完成") &&
  !formPage.includes("Text('继续复盘") &&
  !formPage.includes("Text('暂无待复盘") &&
  !formPage.includes("Text('→')"),
  'LearningProgressMediumCard must match the screenshot: no completion badge and no bottom action.');
assert(!formPage.includes('CARD_CONTENT_BACKGROUND') &&
  !formPage.includes('LEARNING_CARD_PADDING') &&
  !formPage.includes('LEARNING_CARD_OUTER_RADIUS'),
  'LearningProgressMediumCard must not restore the old clipped 2*2 layout tokens.');
assert(!formPage.includes('CARD_PRIMARY_SOFT') &&
  !formPage.includes('CARD_HINT_BACKGROUND') &&
  !formPage.includes('LEARNING_CARD_2X2_METRIC_HEIGHT') &&
  !formPage.includes('LEARNING_CARD_2X2_ACTION_HEIGHT'),
  'LearningProgressMediumCard must not restore the previous metric-block/action layout.');
assert(!formPage.includes('MetricTile('), 'LearningProgressMediumCard must not render the dense four-tile layout.');
assert(!formPage.includes("Text('累计导入')") && !formPage.includes("Text('已完成')"),
  'LearningProgressMediumCard must only show the pending count state on the small card.');

[
  "Text(this.title)",
  'Text(this.completionRateText)',
  "@LocalStorageProp('cardBackgroundStyle') cardBackgroundStyle: string = 'plain';",
  "import { WidgetCardBackground } from '../../components/WidgetCardBackground';",
  'style: this.cardBackgroundStyle',
  "layout: 'wide'",
  "Text('完成')",
  'PendingDashboard()',
  "Text('待复盘')",
  'Text(this.pendingCountText)',
  '2*4 中型卡片在真机桌面里底部空间很紧',
  'const SUMMARY_CARD_COLUMN_GAP: number = 9;',
  'const SUMMARY_CARD_METRIC_ROW_HEIGHT: number = 56;',
  'const SUMMARY_CARD_METRIC_TILE_HEIGHT: number = 50;',
  'const SUMMARY_CARD_METRIC_NUMBER_SIZE: number = 26;',
  'const SUMMARY_CARD_METRIC_LABEL_SIZE: number = 10;',
  'const SUMMARY_CARD_PROGRESS_NUMBER_SIZE: number = 22;',
  'const SUMMARY_CARD_ACTION_HEIGHT: number = 30;',
  'const SUMMARY_CARD_BOTTOM_PADDING: number = 15;',
  '.fontSize(SUMMARY_CARD_METRIC_NUMBER_SIZE)',
  '.fontWeight(900)',
  '.letterSpacing(-1)',
  'LearningProgressSummary()',
  'Text(`${this.completedCountText} / ${this.totalImportedCountText}`)',
  "Text('已完成')",
  'SUMMARY_CARD_PROGRESS_SOFT',
  "const SUMMARY_CARD_PRIMARY_SOFT: string = '#D8EDE5';",
  "const SUMMARY_CARD_PROGRESS_SOFT: string = '#E8F3EC';",
  "const SUMMARY_CARD_ACTION_DISABLED: string = '#E7ECE5';",
  'Column({ space: SUMMARY_CARD_COLUMN_GAP })',
  '.layoutWeight(50)',
  '.height(SUMMARY_CARD_METRIC_TILE_HEIGHT)',
  '.height(SUMMARY_CARD_METRIC_ROW_HEIGHT)',
  '.height(SUMMARY_CARD_ACTION_HEIGHT)',
  'ActionHint()',
  "return this.hasPendingReview() ? '继续复盘' : '回到首页';",
  "Text('→')",
  ".backgroundColor(this.hasPendingReview() ? SUMMARY_CARD_PRIMARY : SUMMARY_CARD_ACTION_DISABLED)",
  'left: SUMMARY_CARD_HORIZONTAL_PADDING',
  'right: SUMMARY_CARD_HORIZONTAL_PADDING',
  'top: SUMMARY_CARD_TOP_PADDING',
  'bottom: SUMMARY_CARD_BOTTOM_PADDING',
  'CompletionBadge()',
  'LEARNING_PROGRESS_DIRECT_TARGET_ROUTE',
  'this.hasPendingReview() ? LEARNING_PROGRESS_DIRECT_TARGET_ROUTE : this.targetRoute',
  'postCardAction(this',
  '.onClick(() =>',
  "moduleName: 'entry'",
  "abilityName: 'EntryAbility'"
].forEach((token) => requireIncludes(
  progressSummaryMediumPage,
  token,
  'LearningProgressSummaryMediumCard must show complete learning progress and direct pending review clicks'
));

assert(!progressSummaryMediumPage.includes('Button('), 'LearningProgressSummaryMediumCard must not add card-level buttons.');
assert(!progressSummaryMediumPage.includes('.height(68)'),
  'LearningProgressSummaryMediumCard must not restore the too-tall metric row that pushes the bottom action down.');
assert(!progressSummaryMediumPage.includes('.padding({ left: 14, right: 14, top: 11, bottom: 12 })'),
  'LearningProgressSummaryMediumCard must keep named padding constants so the bottom action clearance is documented.');
assert(!progressSummaryMediumPage.includes('MetricTile('),
  'LearningProgressSummaryMediumCard must not render the dense four-tile layout.');
assert(!progressSummaryMediumPage.includes("MetricRow('待复盘'") &&
  !progressSummaryMediumPage.includes("this.ProgressRow('待复盘'"),
  'LearningProgressSummaryMediumCard must keep pending count as the dashboard hero, not a list row.');
assert(!progressSummaryMediumPage.includes("Text('累计导入')") &&
  !progressSummaryMediumPage.includes("ProgressRow('累计导入'") &&
  !progressSummaryMediumPage.includes('LearningProgressPanel()'),
  'LearningProgressSummaryMediumCard must express imported count only through completed / imported summary.');
assert(!progressSummaryMediumPage.includes('SUMMARY_CARD_DIVIDER') &&
  !progressSummaryMediumPage.includes('Divider()'),
  'LearningProgressSummaryMediumCard must avoid vertical crowding from divider rows.');
assert(!progressSummaryMediumPage.includes("Text('最近照片')") &&
  !progressSummaryMediumPage.includes('Chart') &&
  !progressSummaryMediumPage.includes('Progress('),
  'LearningProgressSummaryMediumCard must not add photos, charts, trends, or progress widgets.');

[
  "Text('今日待复盘')",
  'pendingCountText',
  "@LocalStorageProp('cardBackgroundStyle') cardBackgroundStyle: string = 'plain';",
  "import { WidgetCardBackground } from '../../components/WidgetCardBackground';",
  'style: this.cardBackgroundStyle',
  "layout: 'square'",
  'this.hasPendingReview() ? TODAY_REVIEW_DIRECT_TARGET_ROUTE : this.targetRoute',
  "return this.hasPendingReview() ? '继续复盘' : '暂无待复盘';",
  '2*2 右侧小卡片以截图为准',
  'const TODAY_CARD_2X2_PADDING: number = 16;',
  'const TODAY_CARD_2X2_RADIUS: number = 24;',
  'const TODAY_CARD_2X2_COUNT_SIZE: number = 48;',
  'const TODAY_CARD_2X2_COUNT_LINE_HEIGHT: number = 52;',
  'const TODAY_CARD_2X2_ACTION_WIDTH: number = 116;',
  'const TODAY_CARD_2X2_ACTION_HEIGHT: number = 32;',
  "Text('→')",
  'Column({ space: 0 })',
  "Text(`${this.resolvePendingCount()}`)",
  '.fontSize(TODAY_CARD_2X2_COUNT_SIZE)',
  '.lineHeight(TODAY_CARD_2X2_COUNT_LINE_HEIGHT)',
  '.layoutWeight(1)',
  '.width(TODAY_CARD_2X2_ACTION_WIDTH)',
  '.height(TODAY_CARD_2X2_ACTION_HEIGHT)',
  '.padding(TODAY_CARD_2X2_PADDING)',
  '.borderRadius(TODAY_CARD_2X2_RADIUS)',
  'TODAY_REVIEW_DIRECT_TARGET_ROUTE',
  'postCardAction(this',
  '.onClick(() =>',
  "moduleName: 'entry'",
  "abilityName: 'EntryAbility'"
].forEach((token) => requireIncludes(todayReviewPage, token, 'TodayReviewCard must render the action-driven pending review state'));

assert(!todayReviewPage.includes('Button('), 'TodayReviewCard must not add card-level buttons.');
assert(!todayReviewPage.includes("Text('今日复盘')") &&
  !todayReviewPage.includes("Text('张待复盘')") &&
  !todayReviewPage.includes("Text('已清空')"),
  'TodayReviewCard must match the screenshot title/content, not the older descriptive layout.');
assert(!todayReviewPage.includes('TODAY_CARD_CONTENT_BACKGROUND') &&
  !todayReviewPage.includes('TODAY_CARD_PADDING') &&
  !todayReviewPage.includes('TODAY_CARD_OUTER_RADIUS'),
  'TodayReviewCard must not restore the old clipped 2*2 layout tokens.');
assert(!todayReviewPage.includes('TODAY_CARD_2X2_ACTION_VERTICAL_PADDING') &&
  !todayReviewPage.includes('TODAY_CARD_2X2_COLUMN_GAP'),
  'TodayReviewCard must keep the screenshot layout constants instead of the previous content-area layout.');
assert(!todayReviewPage.includes('待复盘 ${this.resolvePendingCount()} 张'),
  'TodayReviewCard must not squeeze pending count into one sentence.');
assert(!todayReviewPage.includes('completionRateText') &&
  !todayReviewPage.includes('totalImportedCountText') &&
  !todayReviewPage.includes('completedCountText') &&
  !todayReviewPage.includes("Text('累计导入')") &&
  !todayReviewPage.includes("Text('已完成')") &&
  !todayReviewPage.includes("Text('完成率')"),
  'TodayReviewCard must only show the pending action state.');

[
  "Text('连续复盘')",
  "@LocalStorageProp('cardBackgroundStyle') cardBackgroundStyle: string = 'plain';",
  "import { WidgetCardBackground } from '../../components/WidgetCardBackground';",
  'style: this.cardBackgroundStyle',
  "layout: 'square'",
  "Text(`${this.resolveStreakDays()}`)",
  "Text('天')",
  "Text('去复盘')",
  "Text('→')",
  "@LocalStorageProp('reviewStreakDaysText') reviewStreakDaysText: string = '3';",
  'RHYTHM_REVIEW_DIRECT_TARGET_ROUTE',
  'targetRoute: this.hasPendingReview() ? RHYTHM_REVIEW_DIRECT_TARGET_ROUTE : this.targetRoute',
  "const RHYTHM_CARD_BACKGROUND: string = '#F8F6F1';",
  'const RHYTHM_CARD_DAY_SIZE: number = 54;',
  'const RHYTHM_CARD_DAY_LINE_HEIGHT: number = 58;',
  'const RHYTHM_CARD_DAY_UNIT_SIZE: number = 18;',
  'const RHYTHM_CARD_DAY_UNIT_LINE_HEIGHT: number = 24;',
  'const RHYTHM_CARD_ACTION_HEIGHT: number = 32;',
  'const RHYTHM_CARD_RADIUS: number = 24;',
  '.alignItems(VerticalAlign.Center)',
  '.backgroundColor(this.hasPendingReview() ? RHYTHM_CARD_ACCENT : RHYTHM_CARD_ACTION_DISABLED)',
  'postCardAction(this',
  '.onClick(() =>',
  "moduleName: 'entry'",
  "abilityName: 'EntryAbility'"
].forEach((token) => requireIncludes(rhythmReviewPage, token, 'ReviewRhythmCard must render the habit rhythm reminder'));

assert(!rhythmReviewPage.includes('Button('), 'ReviewRhythmCard must not add card-level buttons.');
assert(countOccurrences(rhythmReviewPage, "Text('连续复盘')") === 1,
  'ReviewRhythmCard must use 连续复盘 only as the title, not repeat it in the body.');
assert(!rhythmReviewPage.includes("Text('完成率')") &&
  !rhythmReviewPage.includes("Text('已完成')") &&
  !rhythmReviewPage.includes("Text('张待复盘')") &&
  !rhythmReviewPage.includes("Text('每天一张") &&
  !rhythmReviewPage.includes("Text('复盘节奏')") &&
  !rhythmReviewPage.includes("Text('已连续复盘')") &&
  !rhythmReviewPage.includes("const RHYTHM_CARD_BACKGROUND: string = '#FFF3D6';"),
  'ReviewRhythmCard must stay focused on habit streak and action.');

[
  'PendingReviewPhotoStore.getStats(context)',
  'ReviewCardHistoryService.load(context)',
  'pendingStats.pendingCount',
  'reviewItems.length',
  'safePendingCount + safeCompletedCount',
  "completionRateText: totalImportedCount <= 0",
  'reviewStreakDays: number;',
  'reviewStreakDays: 3',
  'buildReviewStreakDays(reviewItems)',
  'reviewStreakDays: Math.max(0, reviewStreakDays)'
].forEach((token) => requireIncludes(progressService, token, 'LearningProgressService must be the shared stats source'));

[
  'LearningProgressService.load(context as common.UIAbilityContext)',
  'ReviewSettingsService.loadWidgetCardBackgroundStyle(context as common.UIAbilityContext)',
  'formProvider.updateForm',
  'LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING',
  'LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT',
  'LEARNING_PROGRESS_WIDGET_ROUTE_HOME',
  "title: '摄影学习'",
  'cardBackgroundStyle,',
  'reviewStreakDaysText: `${snapshot.reviewStreakDays}`'
].forEach((token) => requireIncludes(formService, token, 'LearningProgressFormService must bind shared data to widget'));

[
  'REVIEW_WIDGET_CARD_BACKGROUND_PLAIN',
  'REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN',
  'REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN_CORNER',
  'WIDGET_CARD_BACKGROUND_STYLE_KEY',
  'loadWidgetCardBackgroundStyle',
  'saveWidgetCardBackgroundStyle',
  "SettingsRefreshService.notifySettingsChanged('widget_card_background_saved')",
  'resolveWidgetCardBackgroundLabel'
].forEach((token) => requireIncludes(reviewSettingsService, token, 'ReviewSettingsService must persist widget card background settings'));

[
  'widgetCardBackgroundStyle',
  "title: '卡片背景'",
  'WIDGET_CARD_BACKGROUND_PAGE',
  'pushUrl({ url: WIDGET_CARD_BACKGROUND_PAGE })',
  'ReviewSettingsService.loadWidgetCardBackgroundStyle(context)'
].forEach((token) => requireIncludes(
  appearanceSettingsPage,
  token,
  'AppearanceSettingsPage must expose widget card background as a secondary settings entry'
));

[
  'WidgetBackgroundCurrentPreview',
  'WidgetBackgroundPatternPreview',
  '当前卡片背景纹样',
  '下方预览当前纹样',
  "import { WidgetCardBackground }"
].forEach((token) => {
  assert(!appearanceSettingsPage.includes(token),
    `AppearanceSettingsPage must not duplicate the current background as a preview card: ${token}`);
});

[
  "export const WIDGET_CARD_BACKGROUND_PAGE: string = 'pages/WidgetCardBackgroundPage';",
  '"pages/WidgetCardBackgroundPage"'
].forEach((token) => requireIncludes(`${appRouter}\n${mainPagesConfig}`, token, 'Widget card background page must be registered'));

[
  'widgetCardBackgroundStyle',
  "title: '卡片背景'",
  "this.WidgetBackgroundOption('素纸', REVIEW_WIDGET_CARD_BACKGROUND_PLAIN)",
  "this.WidgetBackgroundOption('密集回纹', REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN)",
  "this.WidgetBackgroundOption('回纹角花', REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN_CORNER)",
  'SettingsLinkRow',
  "status: this.widgetCardBackgroundStyle === style ? '当前使用' : ''",
  'ReviewSettingsService.loadWidgetCardBackgroundStyle(this.getAbilityContext())',
  'ReviewSettingsService.saveWidgetCardBackgroundStyle(context, style)',
  'LearningProgressFormService.refreshAllForms(context)'
].forEach((token) => requireIncludes(widgetCardBackgroundPage, token, 'WidgetCardBackgroundPage must apply widget card background settings'));

[
  'PatternPreview(',
  'WidgetCardBackground({',
  "import { WidgetCardBackground }"
].forEach((token) => {
  assert(!widgetCardBackgroundPage.includes(token),
    `WidgetCardBackgroundPage must keep background choices as text-only settings rows: ${token}`);
});

[
  '浅纹',
  '云雷',
  '如意',
  '锦格',
  '密纸',
  '绢纹',
  '细锦'
].forEach((label) => {
  assert(!widgetCardBackgroundPage.includes(`WidgetBackgroundOption('${label}'`),
    `WidgetCardBackgroundPage must not expose retired background option: ${label}`);
});

[
  'REVIEW_WIDGET_CARD_BACKGROUND_TEXTURE',
  'REVIEW_WIDGET_CARD_BACKGROUND_YUNLEI',
  'REVIEW_WIDGET_CARD_BACKGROUND_RUYI',
  'REVIEW_WIDGET_CARD_BACKGROUND_BROCADE',
  'REVIEW_WIDGET_CARD_BACKGROUND_DENSE_PAPER',
  'REVIEW_WIDGET_CARD_BACKGROUND_SILK_GRAIN',
  'REVIEW_WIDGET_CARD_BACKGROUND_FINE_BROCADE'
].forEach((token) => {
  assert(!reviewSettingsService.includes(token), `ReviewSettingsService must retire unsupported background style: ${token}`);
});

[
  "WIDGET_BACKGROUND_STYLE_HUIWEN: string = 'huiwen'",
  "WIDGET_BACKGROUND_STYLE_HUIWEN_CORNER: string = 'huiwen_corner'",
  "WIDGET_BACKGROUND_LAYOUT_WIDE: string = 'wide'",
  "Image($r('app.media.widget_card_huiwen_square'))",
  "Image($r('app.media.widget_card_huiwen_wide'))",
  "Image($r('app.media.widget_card_huiwen_corner_square'))",
  "Image($r('app.media.widget_card_huiwen_corner_wide'))",
  '.objectFit(ImageFit.Cover)'
].forEach((token) => requireIncludes(widgetCardBackground, token, 'WidgetCardBackground must render every supported card background'));

[
  ['密集回纹方卡', huiwenSquare, 16],
  ['密集回纹横卡', huiwenWide, 32]
].forEach(([name, source, expectedTileCount]) => {
  assert(!source.includes('<pattern'), `${name} must not use SVG pattern because the card renderer does not expand it reliably`);
  assert(!source.includes('<use'), `${name} must keep every repeated unit as an explicit static path`);
  assert(countOccurrences(source, '<path') === expectedTileCount,
    `${name} must contain ${expectedTileCount} explicit huiwen units`);
});

[
  ['回纹角花方卡', huiwenCornerSquare, 'M14 54V14H54'],
  ['回纹角花横卡', huiwenCornerWide, 'M12 42V12H42']
].forEach(([name, source, safeCornerPath]) => {
  assert(!source.includes('<defs') && !source.includes('<use'), `${name} must use explicit static corner paths`);
  assert(source.includes(safeCornerPath), `${name} must keep the ornament inside its compact corner safe area`);
});

[
  'FormLaunchIntentService.captureWant(want)',
  'LearningProgressFormService.refreshAllForms(this.context)'
].forEach((token) => requireIncludes(entryAbility, token, 'EntryAbility must sync widget on startup and capture card clicks'));

[
  'FormLaunchIntentService.consumeRoute()',
  'FormLaunchIntentService.subscribe(this.formLaunchIntentListener)',
  'FormLaunchIntentService.unsubscribe(this.formLaunchIntentListener)',
  'LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING',
  'LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT',
  'PendingReviewPhotoStore.getOldestPending(',
  'ReviewCardStore.createPendingPhotoDraft(',
  "this.getUIContext().getRouter().pushUrl({ url: EDITOR_PAGE })",
  'openPendingLibraryFromWidget()',
  'openHomeFromWidget()',
  'RootTabKey.LIBRARY',
  "ProjectDetailPage({ refreshToken: this.reviewLibraryRefreshToken, initialFilter: this.libraryInitialFilter })"
].forEach((token) => requireIncludes(appShell, token, 'AppShell must route widget clicks to library pending filter'));

[
  'LearningProgressService.loadWithReviewItems(context)',
  'ReviewProjectService.buildStatsFeedback(progressResult.reviewItems)'
].forEach((token) => requireIncludes(statsPage, token, 'StatsPage must reuse the shared learning progress source'));

const pageContextRefresh = 'LearningProgressFormService.refreshAllForms(this.getAbilityContext())';
requireIncludes(homePage, pageContextRefresh, 'Pending import must refresh the service widget');
requireIncludes(editorPage, pageContextRefresh, 'Review save must refresh the service widget');
requireIncludes(previewPage, pageContextRefresh, 'Preview fallback save must refresh the service widget');
requireIncludes(
  projectDetailPage,
  'LearningProgressFormService.refreshAllForms(context)',
  'Pending state changes in library must refresh the service widget with the captured page context'
);

[
  'LEARNING_PROGRESS_WIDGET_ROUTE_HOME',
  'LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING',
  'LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT',
  'consumeRoute()',
  'subscribe(listener: FormLaunchIntentListener)',
  'notifyListeners()'
].forEach((token) => requireIncludes(launchService, token, 'FormLaunchIntentService must keep launch targets explicit'));

if (failed) {
  process.exit(1);
}
