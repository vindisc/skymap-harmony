import fs from 'node:fs';

let failed = false;

function read(filePath) {
  if (!fs.existsSync(filePath)) {
    failed = true;
    console.error(`missing required file: ${filePath}`);
    return '';
  }
  return fs.readFileSync(filePath, 'utf8');
}

function requireIncludes(source, token, scope) {
  if (!source.includes(token)) {
    failed = true;
    console.error(`${scope}: missing "${token}"`);
  }
}

const entryAbility = read('entry/src/main/ets/entryability/EntryAbility.ets');
const scenarioService = read('entry/src/main/ets/services/DebugLaunchScenarioService.ets');
const routeService = read('entry/src/main/ets/services/FormLaunchIntentService.ets');
const entryBuildProfile = read('entry/build-profile.json5');
const testScript = read('scripts/test_app.sh');
const deviceScript = read('scripts/smoke_device.sh');
const uiTests = read('entry/src/ohosTest/ets/test/AppShellSmoke.test.ets');
const reviewFlowTests = read('entry/src/ohosTest/ets/test/ReviewFlowSmoke.test.ets');
const settingsTests = read('entry/src/ohosTest/ets/test/SettingsSmoke.test.ets');

[
  'this.context.applicationInfo.debug',
  'DebugLaunchScenarioService.captureWant'
].forEach((token) => requireIncludes(entryAbility, token, 'EntryAbility debug test guard'));

[
  "const DEBUG_TEST_SCENARIO_KEY: string = 'testScenario'",
  "HOME = 'home'",
  "PENDING = 'pending'",
  "TODAY = 'today'",
  "EDITOR_HORIZONTAL = 'editor_horizontal'",
  "PREVIEW_LONG_TEXT = 'preview_long_text'",
  "WIDGET_CARD_SETTINGS = 'widget_card_settings'",
  'prepareDraft(scenario: string)',
  'IntentRouteSource.TEST'
].forEach((token) => requireIncludes(scenarioService, token, 'DebugLaunchScenarioService'));

requireIncludes(routeService, "TEST = 'test'", 'FormLaunchIntentService test source');
requireIncludes(entryBuildProfile, '"name": "ohosTest"', 'entry ohosTest target');
requireIncludes(testScript, 'run_verification_suite.mjs', 'test_app.sh verification entry');
requireIncludes(testScript, 'manage_signing_profile.mjs deactivate', 'test_app.sh unsigned build entry');
requireIncludes(testScript, 'assembleHap', 'test_app.sh standard build entry');
requireIncludes(testScript, 'restore_profile', 'test_app.sh signing restoration');
requireIncludes(testScript, 'VERIFICATION_SUITE="all"', 'test_app.sh full verification option');
requireIncludes(testScript, 'onDeviceTest', 'test_app.sh Hypium device entry');
requireIncludes(deviceScript, '--ps testScenario', 'smoke_device.sh debug scenario entry');
requireIncludes(deviceScript, '--check-only', 'smoke_device.sh device preflight');
requireIncludes(deviceScript, 'preview_long_text', 'smoke_device.sh visual state matrix');
requireIncludes(deviceScript, 'report.md', 'smoke_device.sh visual report');

[
  "describe('AppShellSmokeTest'",
  "it('showsRootTabs'",
  "it('opensStatsTab'",
  "it('opensMyTab'"
].forEach((token) => requireIncludes(uiTests, token, 'Hypium root smoke suite'));

[
  "it('showsHorizontalEditor'",
  "it('savesEditorAndEntersPreview'",
  "it('opensPreviewExportMenu'",
  "it('rendersLongTextPreview'"
].forEach((token) => requireIncludes(reviewFlowTests, token, 'Hypium review flow suite'));

[
  "scenario: 'reviewer_profile'",
  "scenario: 'widget_card_settings'",
  "scenario: 'sync_center'",
  "it('navigatesFromMyToCardSettings'"
].forEach((token) => requireIncludes(settingsTests, token, 'Hypium settings suite'));

if (failed) {
  process.exit(1);
}

console.log('test automation verified: unified runner, debug scenarios, device smoke, and Hypium suite');
