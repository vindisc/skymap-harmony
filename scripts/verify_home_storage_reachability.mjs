import { execFileSync } from 'node:child_process';
import fs from 'node:fs';

const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const bundleServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewBundleExportService.ets', 'utf8');
const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const feedbackSource = fs.readFileSync('entry/src/main/ets/services/ReviewFlowFeedback.ets', 'utf8');
const syncCenterSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');
const homeStoragePageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const reviewSettingsSource = fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function assertIncludes(source, token, label) {
  assert(source.includes(token), `${label} missing token: ${token}`);
}

function assertNotIncludes(source, token, label) {
  assert(!source.includes(token), `${label} must not include token: ${token}`);
}

for (const token of [
  "NOT_CONFIGURED = 'notConfigured'",
  "INCOMPLETE_CONFIG = 'incompleteConfig'",
  "UNREACHABLE = 'unreachable'",
  "AUTH_FAILED = 'authFailed'",
  "DIRECTORY_CREATE_FAILED = 'directoryCreateFailed'",
  "UPLOAD_FAILED = 'uploadFailed'",
  "UNKNOWN = 'unknown'"
]) {
  assertIncludes(homeStorageSource, token, 'HomeStorageErrorType');
}

for (const token of [
  "return '请先配置家庭存储';",
  "return '家庭存储配置不完整，请检查设置';",
  "return '无法连接家庭存储。请连接家庭 Wi-Fi 或 VPN 后重试。';",
  "return '家庭存储账号或密码不正确，请检查设置';",
  "return '家庭存储目录创建失败，请稍后重试';",
  "return '复盘包导出失败，请重试';"
]) {
  assertIncludes(homeStorageSource, token, 'HomeStorageService user copy');
}

assertIncludes(homeStorageSource, 'static async checkAvailability(context: common.UIAbilityContext): Promise<HomeStorageOperationResult>', 'HomeStorageService');
assertIncludes(homeStorageSource, 'availability_check status=', 'HomeStorageService diagnostics');
assertIncludes(homeStorageSource, 'classifyHomeStorageError(rawMessage, HomeStorageErrorType.UNREACHABLE)', 'HomeStorageService unreachable mapping');
assertIncludes(homeStorageSource, 'classifyHomeStorageError(rawMessage, fallback)', 'HomeStorageService upload mapping');
assertIncludes(homeStorageSource, "normalized.indexOf('network unreachable')", 'HomeStorageService network unreachable matcher');
assertIncludes(homeStorageSource, "normalized.indexOf('host unreachable')", 'HomeStorageService host unreachable matcher');
assertIncludes(homeStorageSource, "normalized.indexOf('timeout')", 'HomeStorageService timeout matcher');
assertIncludes(homeStorageSource, "message.indexOf('SMB 认证失败')", 'HomeStorageService auth matcher');

assertIncludes(bundleServiceSource, 'HomeStorageService.checkAvailability(context)', 'ReviewBundleExportService preflight');
assertIncludes(bundleServiceSource, 'availability_checked success=', 'ReviewBundleExportService diagnostics');
assertIncludes(bundleServiceSource, 'message: availabilityResult.message', 'ReviewBundleExportService preflight user message');
assertIncludes(bundleServiceSource, 'errorType: availabilityResult.errorType', 'ReviewBundleExportService preflight error type');
assertIncludes(bundleServiceSource, "message: '复盘包导出失败，请重试'", 'ReviewBundleExportService generic upload failure');

assertNotIncludes(previewSource, 'result.message.length > 0 ? result.message : REVIEW_FLOW_BUNDLE_EXPORT_FAILED_TEXT', 'PreviewPage must hide non-Beta bundle failure copy');
assertIncludes(feedbackSource, "REVIEW_FLOW_BUNDLE_EXPORT_UNREACHABLE_TEXT: string = '无法连接家庭存储。请连接家庭 Wi-Fi 或 VPN 后重试。'", 'ReviewFlowFeedback');
assertIncludes(feedbackSource, "REVIEW_FLOW_BUNDLE_EXPORT_AUTH_FAILED_TEXT: string = '家庭存储账号或密码不正确，请检查设置'", 'ReviewFlowFeedback');

assertIncludes(syncCenterSource, '当前家庭存储需要在同一网络或 VPN 下使用。', 'SyncCenterPage');
assertIncludes(syncCenterSource, '家庭存储仍是 Beta 后实验能力。当前 Beta 请使用导出 review.json 完成手动交换。', 'SyncCenterPage');
assertIncludes(homeStoragePageSource, '适合在家庭 Wi-Fi 内使用。外出时需要先连接 VPN / Tailscale 等安全网络，再访问家庭存储。', 'HomeStoragePage');
assertNotIncludes(reviewSettingsSource, "Text('连接与凭据')", 'ReviewSettingsPage must hide non-Beta storage entry');

const ordinaryUserCopy = [
  previewSource,
  syncCenterSource,
  homeStoragePageSource,
  reviewSettingsSource
].join('\n').replace(/console\.[^\n]+/g, '');

for (const forbidden of ['RDB', 'manifest', 'raw JSON', '公网 SMB', '开放端口']) {
  assertNotIncludes(ordinaryUserCopy, forbidden, 'ordinary user copy');
}

assert(!/开放.{0,8}445/.test(ordinaryUserCopy), 'ordinary user copy must not guide users to open port 445.');
assert(!/445.{0,8}公网/.test(ordinaryUserCopy), 'ordinary user copy must not mention port 445 for public access.');

const changedFiles = execFileSync('git', ['diff', '--name-only'], { encoding: 'utf8' })
  .split('\n')
  .map((line) => line.trim())
  .filter(Boolean);

for (const forbiddenFile of [
  'entry/src/main/ets/services/ReviewCardExchangeSchema.ets',
  'entry/src/main/ets/services/ReviewCardRdbModel.ets',
  'entry/src/main/module.json5',
  'build-profile.json5',
  'entry/build-profile.json5'
]) {
  assert(!changedFiles.includes(forbiddenFile), `${forbiddenFile} must not change in this reachability pass.`);
}

if (failed) {
  process.exit(1);
}

console.log('home storage reachability: export preflight, classified copy, safe network guidance, and forbidden-scope boundaries verified');
