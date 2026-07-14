import fs from 'node:fs';
import path from 'node:path';

const shatterOverlayPath = 'entry/src/main/ets/components/ShatterOverlay.ets';
const projectDetailPath = 'entry/src/main/ets/pages/ProjectDetailPage.ets';
const appearanceSettingsPath = 'entry/src/main/ets/pages/AppearanceSettingsPage.ets';
const settingsServicePath = 'entry/src/main/ets/services/ReviewSettingsService.ets';
const designTokensPath = 'entry/src/main/ets/theme/DesignTokens.ets';
const motionQualityPath = 'entry/src/main/ets/theme/MotionQualityContext.ets';
const haloResourcePath = 'entry/src/main/resources/base/media/particle_halo.png';

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
requireIncludes(overlaySource, 'ParticleType.IMAGE', 'ShatterOverlay component');
requireIncludes(overlaySource, "$r('app.media.particle_halo')", 'ShatterOverlay component');
requireIncludes(overlaySource, 'ParticleEmitterShape.RECTANGLE', 'ShatterOverlay component');
requireIncludes(overlaySource, 'MotionQualityContext.resolveShatterLayerCount()', 'ShatterOverlay component');

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
requireIncludes(projectDetailSource, 'MotionQualityContext.shouldPlayShatter', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'private isPageAlive: boolean = false;', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'if (!this.isPageAlive)', 'ProjectDetailPage');
requireIncludes(projectDetailSource, 'this.deleteHistory(document);', 'ProjectDetailPage');

const appearanceSettingsSource = readOrFail(appearanceSettingsPath);
requireIncludes(appearanceSettingsSource, "Text('删除星河效果')", 'AppearanceSettingsPage');
requireIncludes(appearanceSettingsSource, 'Toggle({', 'AppearanceSettingsPage');
requireIncludes(appearanceSettingsSource, 'ReviewSettingsService.saveShatterAnimationEnabled', 'AppearanceSettingsPage');

const designTokensSource = readOrFail(designTokensPath);
requireIncludes(designTokensSource, 'shatterDurationMs: number = 1300', 'DesignTokens');
requireIncludes(designTokensSource, 'export class ShatterTokens', 'DesignTokens');
requireIncludes(designTokensSource, 'shatterRippleBackMs', 'DesignTokens');

const motionQualitySource = readOrFail(motionQualityPath);
requireIncludes(motionQualitySource, 'resolveShatterLayerCount()', 'MotionQualityContext');
requireIncludes(motionQualitySource, 'ShatterTokens.fullLayerCount', 'MotionQualityContext');
requireIncludes(motionQualitySource, 'ShatterTokens.reducedLayerCount', 'MotionQualityContext');

if (!fs.existsSync(haloResourcePath)) {
  fail(`${haloResourcePath}: halo PNG resource must exist.`);
}

if (failed) {
  process.exit(1);
}

console.log('shatter animation verified: three-layer overlay, quality fallback, halo resource, preference, and list integration present');
