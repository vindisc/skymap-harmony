import fs from 'node:fs';
import path from 'node:path';

const EXECUTOR_PATH = 'entry/src/main/ets/insightintents/PhotoReviewIntentExecutor.ets';
const ROUTE_SERVICE_PATH = 'entry/src/main/ets/services/FormLaunchIntentService.ets';
const INTENT_CONFIG_PATH = 'entry/src/main/resources/base/profile/insight_intent.json';

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function readRequired(filePath) {
  assert(fs.existsSync(filePath), `missing required file: ${filePath}`);
  return fs.existsSync(filePath) ? fs.readFileSync(filePath, 'utf8') : '';
}

function requireIncludes(source, token, scope) {
  assert(source.includes(token), `${scope}: missing "${token}"`);
}

const executor = readRequired(EXECUTOR_PATH);
const routeService = readRequired(ROUTE_SERVICE_PATH);

[
  'extends InsightIntentExecutor',
  'onExecuteInUIAbilityForegroundMode(',
  "'StartPhotoReview'",
  "'ViewPendingReviews'",
  'LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT',
  'LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING',
  'FormLaunchIntentService.captureRouteFromIntent(route, IntentRouteSource.XIAOYI)'
].forEach((token) => requireIncludes(executor, token, EXECUTOR_PATH));

[
  'PendingReviewPhotoStore',
  'ReviewCardStore',
  '.pushUrl(',
  '.loadContent('
].forEach((token) => assert(!executor.includes(token), `${EXECUTOR_PATH}: forbidden direct dependency "${token}"`));

[
  'export enum IntentRouteSource',
  "FORM = 'form'",
  "XIAOYI = 'xiaoyi'",
  'captureRouteFromIntent(route: string, source: IntentRouteSource)',
  'LEARNING_PROGRESS_WIDGET_ROUTE_HOME',
  'LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING',
  'LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT'
].forEach((token) => requireIncludes(routeService, token, ROUTE_SERVICE_PATH));

if (fs.existsSync(INTENT_CONFIG_PATH)) {
  let config;
  try {
    config = JSON.parse(fs.readFileSync(INTENT_CONFIG_PATH, 'utf8'));
  } catch (error) {
    assert(false, `${INTENT_CONFIG_PATH}: invalid JSON (${error.message})`);
  }

  const intents = config?.insightIntents;
  assert(Array.isArray(intents) && intents.length > 0,
    `${INTENT_CONFIG_PATH}: insightIntents must be a non-empty array`);

  if (Array.isArray(intents)) {
    intents.forEach((intent, index) => {
      const scope = `${INTENT_CONFIG_PATH} insightIntents[${index}]`;
      assert(typeof intent?.domain === 'string' && intent.domain.length > 0, `${scope}: domain is required`);
      assert(intent?.domain !== 'TBD_DOMAIN_FROM_HUAWEI', `${scope}: domain still uses the placeholder`);
      assert(typeof intent?.intentName === 'string' && intent.intentName.length > 0, `${scope}: intentName is required`);
      assert(typeof intent?.intentVersion === 'string' && /^\d+\.\d+\.\d+$/.test(intent.intentVersion),
        `${scope}: intentVersion must use semantic version format`);
      assert(intent?.uiAbility?.executeMode?.includes('foreground'),
        `${scope}: uiAbility.executeMode must include foreground`);
      assert(intent?.uiAbility?.ability === 'EntryAbility', `${scope}: uiAbility.ability must be EntryAbility`);
      assert(typeof intent?.srcEntry === 'string' && intent.srcEntry.length > 0, `${scope}: srcEntry is required`);
      if (typeof intent?.srcEntry === 'string') {
        const sourcePath = path.join('entry/src/main', intent.srcEntry.replace(/^\.\//, ''));
        assert(fs.existsSync(sourcePath), `${scope}: srcEntry does not resolve to ${sourcePath}`);
      }
    });
  }
}

if (failed) {
  process.exit(1);
}

if (fs.existsSync(INTENT_CONFIG_PATH)) {
  console.log('小艺 Intents Kit 执行器与意图配置结构校验通过。');
} else {
  console.log('小艺 Intents Kit 阶段 A 骨架校验通过；insight_intent.json 按计划暂未创建。');
}
