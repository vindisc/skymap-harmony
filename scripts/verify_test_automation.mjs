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

[
  'this.context.applicationInfo.debug',
  'DebugLaunchScenarioService.captureWant'
].forEach((token) => requireIncludes(entryAbility, token, 'EntryAbility debug test guard'));

[
  "const DEBUG_TEST_SCENARIO_KEY: string = 'testScenario'",
  "HOME = 'home'",
  "PENDING = 'pending'",
  "TODAY = 'today'",
  'IntentRouteSource.TEST'
].forEach((token) => requireIncludes(scenarioService, token, 'DebugLaunchScenarioService'));

requireIncludes(routeService, "TEST = 'test'", 'FormLaunchIntentService test source');
requireIncludes(entryBuildProfile, '"name": "ohosTest"', 'entry ohosTest target');
requireIncludes(testScript, 'run_verification_suite.mjs', 'test_app.sh verification entry');
requireIncludes(testScript, 'manage_signing_profile.mjs deactivate', 'test_app.sh unsigned build entry');
requireIncludes(testScript, 'assembleHap', 'test_app.sh standard build entry');
requireIncludes(testScript, 'restore_profile', 'test_app.sh signing restoration');
requireIncludes(testScript, 'VERIFICATION_SUITE="all"', 'test_app.sh full verification option');
requireIncludes(deviceScript, '--ps testScenario', 'smoke_device.sh debug scenario entry');

[
  "describe('AppShellSmokeTest'",
  "it('showsRootTabs'",
  "it('opensStatsTab'",
  "it('opensMyTab'"
].forEach((token) => requireIncludes(uiTests, token, 'Hypium root smoke suite'));

if (failed) {
  process.exit(1);
}

console.log('test automation verified: unified runner, debug scenarios, device smoke, and Hypium suite');
