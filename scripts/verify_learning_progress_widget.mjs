import fs from 'node:fs';

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

const moduleConfig = read('entry/src/main/module.json5');
const formConfig = read('entry/src/main/resources/base/profile/form_config.json');
const formAbility = read('entry/src/main/ets/formability/LearningProgressFormAbility.ets');
const formPage = read('entry/src/main/ets/widget/pages/LearningProgressMediumCard.ets');
const todayReviewPage = read('entry/src/main/ets/widget/pages/TodayReviewCard.ets');
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

[
  '"extensionAbilities"',
  '"LearningProgressFormAbility"',
  '"type": "form"',
  '"resource": "$profile:form_config"'
].forEach((token) => requireIncludes(moduleConfig, token, 'module.json5 must register the learning progress form ability'));

[
  '"LearningProgressMediumCard"',
  '"displayName": "摄影学习"',
  '"src": "./ets/widget/pages/LearningProgressMediumCard.ets"',
  '"TodayReviewCard"',
  '"displayName": "今日复盘"',
  '"src": "./ets/widget/pages/TodayReviewCard.ets"',
  '"uiSyntax": "arkts"',
  '"2*2"'
].forEach((token) => requireIncludes(formConfig, token, 'form_config must expose learning progress and today review ArkTS cards'));

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
  "Text('待复盘')",
  "Text('完成率')",
  'Text(this.completionRateText)',
  'resolveHintText()',
  "'点击继续复盘'",
  "'暂无待复盘'",
  'FormLink({',
  "abilityName: 'EntryAbility'",
  'targetRoute: this.targetRoute'
].forEach((token) => requireIncludes(formPage, token, 'LearningProgressMediumCard must match required content and click behavior'));

assert(!formPage.includes('Button('), 'LearningProgressMediumCard must not add card-level buttons.');
assert(!formPage.includes("Text(`完成率 ${this.completionRateText}`)"),
  'LearningProgressMediumCard must not place completion rate in the title row.');
assert(!formPage.includes('MetricTile('), 'LearningProgressMediumCard must not render the dense four-tile layout.');
assert(!formPage.includes("Text('累计导入')") && !formPage.includes("Text('已完成')"),
  'LearningProgressMediumCard must only show pending count and completion rate on the small card.');

[
  "Text('今日复盘')",
  'pendingCountText',
  'targetRoute: this.targetRoute',
  "return `待复盘 ${this.resolvePendingCount()} 张`;",
  "return '今日已清空';",
  "return this.hasPendingReview() ? '点击继续' : '暂无待复盘';",
  'FormLink({',
  "abilityName: 'EntryAbility'"
].forEach((token) => requireIncludes(todayReviewPage, token, 'TodayReviewCard must render the action-driven pending review state'));

assert(!todayReviewPage.includes('Button('), 'TodayReviewCard must not add card-level buttons.');
assert(!todayReviewPage.includes('completionRateText') &&
  !todayReviewPage.includes('totalImportedCountText') &&
  !todayReviewPage.includes('completedCountText') &&
  !todayReviewPage.includes("Text('累计导入')") &&
  !todayReviewPage.includes("Text('已完成')") &&
  !todayReviewPage.includes("Text('完成率')"),
  'TodayReviewCard must only show the pending action state.');

[
  'PendingReviewPhotoStore.getStats(context)',
  'ReviewCardHistoryService.load(context)',
  'pendingStats.pendingCount',
  'reviewItems.length',
  'safePendingCount + safeCompletedCount',
  "completionRateText: totalImportedCount <= 0"
].forEach((token) => requireIncludes(progressService, token, 'LearningProgressService must be the shared stats source'));

[
  'LearningProgressService.load(context as common.UIAbilityContext)',
  'formProvider.updateForm',
  'LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING',
  'LEARNING_PROGRESS_WIDGET_ROUTE_HOME',
  "title: '摄影学习'"
].forEach((token) => requireIncludes(formService, token, 'LearningProgressFormService must bind shared data to widget'));

[
  'FormLaunchIntentService.captureWant(want)',
  'LearningProgressFormService.refreshAllForms(this.context)'
].forEach((token) => requireIncludes(entryAbility, token, 'EntryAbility must sync widget on startup and capture card clicks'));

[
  'FormLaunchIntentService.consumeRoute()',
  'LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING',
  'RootTabKey.LIBRARY',
  "ProjectDetailPage({ refreshToken: this.reviewLibraryRefreshToken, initialFilter: this.libraryInitialFilter })"
].forEach((token) => requireIncludes(appShell, token, 'AppShell must route widget clicks to library pending filter'));

[
  'LearningProgressService.loadWithReviewItems(context)',
  'ReviewProjectService.buildStatsFeedback(progressResult.reviewItems)'
].forEach((token) => requireIncludes(statsPage, token, 'StatsPage must reuse the shared learning progress source'));

[
  'LearningProgressFormService.refreshAllForms(this.getAbilityContext())'
].forEach((token) => {
  requireIncludes(homePage, token, 'Pending import must refresh the service widget');
  requireIncludes(editorPage, token, 'Review save must refresh the service widget');
  requireIncludes(projectDetailPage, token, 'Pending state changes in library must refresh the service widget');
  requireIncludes(previewPage, token, 'Preview fallback save must refresh the service widget');
});

[
  'LEARNING_PROGRESS_WIDGET_ROUTE_HOME',
  'LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING',
  'consumeRoute()'
].forEach((token) => requireIncludes(launchService, token, 'FormLaunchIntentService must keep launch targets explicit'));

if (failed) {
  process.exit(1);
}
