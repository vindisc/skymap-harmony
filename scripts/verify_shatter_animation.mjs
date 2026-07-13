import fs from 'node:fs';
import path from 'node:path';

const shatterOverlayPath = 'entry/src/main/ets/components/ShatterOverlay.ets';
const projectDetailPath = 'entry/src/main/ets/pages/ProjectDetailPage.ets';
const myPagePath = 'entry/src/main/ets/pages/MyPage.ets';
const settingsServicePath = 'entry/src/main/ets/services/ReviewSettingsService.ets';
const designTokensPath = 'entry/src/main/ets/theme/DesignTokens.ets';

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

function readOrFail(target) {
  try {
    return fs.readFileSync(target, 'utf8');
  } catch (error) {
    fail(`${target}: file missing — required by shatter animation.`);
    return '';
  }
}

function requireIncludes(source, marker, context) {
  if (!source.includes(marker)) {
    fail(`${context}: missing marker ${marker}`);
  }
}

if (!fs.existsSync(shatterOverlayPath)) {
  fail(`${shatterOverlayPath}: ShatterOverlay component file must exist.`);
}

const overlaySource = readOrFail(shatterOverlayPath);
requireIncludes(overlaySource, 'export struct ShatterOverlay', 'ShatterOverlay component');
requireIncludes(overlaySource, 'ParticleType.POINT', 'ShatterOverlay component');
requireIncludes(overlaySource, 'ParticleEmitterShape.RECTANGLE', 'ShatterOverlay component');
requireIncludes(overlaySource, 'aboutToDisappear(): void', 'ShatterOverlay component');
requireIncludes(overlaySource, 'clearTimeout(this.pointDelayTimerId)', 'ShatterOverlay component');

const settingsSource = readOrFail(settingsServicePath);
requireIncludes(settingsSource, "SHATTER_ANIMATION_ENABLED_KEY: string = 'shatter_animation_enabled'", 'ReviewSettingsService');
requireIncludes(settingsSource, 'SHATTER_ANIMATION_DEFAULT', 'ReviewSettingsService');
requireIncludes(settingsSource, 'loadShatterAnimationEnabled', 'ReviewSettingsService');
requireIncludes(settingsSource, 'saveShatterAnimationEnabled', 'ReviewSettingsService');

const projectDetailSource = readOrFail(projectDetailPath);
requireIncludes(projectDetailSource, "from '../components/ShatterOverlay'", 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'ShatterOverlay({', 'ProjectDetailPage');
requireIncludes(projectDetailSource, '`shatter-history-${', 'ProjectDetailPage');
requireIncludes(projectDetailSource, '`shatter-pending-${', 'ProjectDetailPage');
requireIncludes(projectDetailSource, '@State hiddenCardKeys: Array<string>', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'MotionTokens.shatterDurationMs', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'Visibility.Hidden', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'ReviewSettingsService.loadShatterAnimationEnabled', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'private isPageAlive: boolean = false;', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'if (!this.isPageAlive)', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'this.confirmDeleteHistory(document);', 'ProjectDetailPage');

const myPageSource = readOrFail(myPagePath);
requireIncludes(myPageSource, "'删除星河效果'", 'MyPage');
requireIncludes(myPageSource, 'toggleShatterAnimation', 'MyPage');
requireIncludes(myPageSource, 'ReviewSettingsService.saveShatterAnimationEnabled', 'MyPage');

const designTokensSource = readOrFail(designTokensPath);
requireIncludes(designTokensSource, 'shatterDurationMs: number = 800', 'DesignTokens');
requireIncludes(designTokensSource, 'shatterImageLayerMs', 'DesignTokens');
requireIncludes(designTokensSource, 'shatterPointLayerMs', 'DesignTokens');
requireIncludes(designTokensSource, 'shatterRippleBackMs', 'DesignTokens');

if (failed) {
  process.exit(1);
}

console.log('shatter animation verified: local overlay, lifecycle guards, confirmation, preference, and list integration present');
