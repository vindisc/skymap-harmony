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
const verificationSuite = read('scripts/run_verification_suite.mjs');
const testingGuide = read('docs/TESTING.md');
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
requireIncludes(testScript, 'zulu-11.jdk', 'test_app.sh compatible signing JDK');
requireIncludes(testScript, 'SKYMAP_DEVICE_JAVA_HOME', 'test_app.sh explicit device JDK override');
requireIncludes(testScript, 'RUN_HYPIUM=false', 'test_app.sh safe default');
requireIncludes(testScript, 'SKYMAP_ALLOW_DATA_RESET', 'test_app.sh destructive test confirmation');
requireIncludes(testScript, 'onDeviceTest 会卸载应用并清空全部应用数据', 'test_app.sh data loss warning');
requireIncludes(testScript, 'restore_full_app_after_ui_test', 'test_app.sh full app restoration');
[
  'verify_motion_lifecycle_guards.mjs',
  'verify_photo_import_crash_guard.mjs',
  'verify_shatter_animation.mjs'
].forEach((token) => requireIncludes(verificationSuite, token, 'Default smoke regression coverage'));
requireIncludes(testingGuide, '测试数据中的固定日期是确定性夹具', 'Testing date semantics');
const datedVerificationScripts = fs.readdirSync('scripts')
  .filter((name) => /^verify_.*_20\d{6}\.mjs$/.test(name));
if (datedVerificationScripts.length > 0) {
  failed = true;
  console.error(`dated one-off verification scripts must be retired: ${datedVerificationScripts.join(', ')}`);
}
requireIncludes(deviceScript, '--ps testScenario', 'smoke_device.sh debug scenario entry');
requireIncludes(deviceScript, '--check-only', 'smoke_device.sh device preflight');
requireIncludes(deviceScript, '--restore-app', 'smoke_device.sh full app restore entry');
requireIncludes(deviceScript, '卸载测试应用', 'smoke_device.sh test app uninstall');
requireIncludes(deviceScript, '安装完整 Debug HAP', 'smoke_device.sh full app install');
requireIncludes(deviceScript, 'Connected', 'smoke_device.sh online device guard');
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
