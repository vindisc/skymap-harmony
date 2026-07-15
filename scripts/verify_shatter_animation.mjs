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

function extractMethod(source, methodName) {
  const signature = `private async ${methodName}`;
  const start = source.indexOf(signature);
  if (start < 0) {
    return '';
  }
  const bodyStart = source.indexOf('{', start);
  let depth = 0;
  for (let index = bodyStart; index < source.length; index += 1) {
    if (source[index] === '{') {
      depth += 1;
    } else if (source[index] === '}') {
      depth -= 1;
      if (depth === 0) {
        return source.slice(bodyStart, index + 1);
      }
    }
  }
  return '';
}

function countOccurrences(source, marker) {
  return source.split(marker).length - 1;
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
requireIncludes(projectDetailSource, '@State collapsingIds: Array<string>', 'ProjectDetailPage collapse state');
requireIncludes(projectDetailSource, 'private beginCollapse(id: string): void', 'ProjectDetailPage collapse state');
requireIncludes(projectDetailSource, 'private endCollapse(id: string): void', 'ProjectDetailPage collapse state');
requireIncludes(projectDetailSource, 'MotionCurveRole.SPRING_SOFT', 'ProjectDetailPage collapse animation');

const pendingDeleteSource = extractMethod(projectDetailSource, 'deletePendingPhoto');
const historyDeleteSource = extractMethod(projectDetailSource, 'deleteHistory');
const pendingCollapseIndex = pendingDeleteSource.indexOf('this.beginCollapse(photo.id);');
const pendingRemovalIndex = pendingDeleteSource.indexOf('this.pendingItems = this.pendingItems.filter');
const historyCollapseIndex = historyDeleteSource.indexOf('this.beginCollapse(deletingKey);');
const historyRemovalIndex = historyDeleteSource.indexOf('const nextItems: Array<ReviewCardHistoryItem> = previousItems.filter');
if (pendingCollapseIndex < 0 || pendingRemovalIndex < 0 || pendingCollapseIndex >= pendingRemovalIndex) {
  fail('deletePendingPhoto must begin collapse before removing the pending item.');
}
if (historyCollapseIndex < 0 || historyRemovalIndex < 0 || historyCollapseIndex >= historyRemovalIndex) {
  fail('deleteHistory must begin collapse before removing the history item.');
}
const pendingCatchSource = pendingDeleteSource.slice(pendingDeleteSource.indexOf('} catch'));
const historyCatchSource = historyDeleteSource.slice(historyDeleteSource.indexOf('} catch'));
requireIncludes(pendingCatchSource, 'this.endCollapse(photo.id);', 'deletePendingPhoto catch recovery');
requireIncludes(pendingCatchSource, 'this.markCardVisible(photo.id);', 'deletePendingPhoto catch recovery');
requireIncludes(historyCatchSource, 'this.endCollapse(deletingKey);', 'deleteHistory catch recovery');
requireIncludes(historyCatchSource, 'this.markCardVisible(deletingKey);', 'deleteHistory catch recovery');
if (countOccurrences(projectDetailSource, '.height(this.isCollapsing(') < 2 ||
  countOccurrences(projectDetailSource, '.opacity(this.isCollapsing(') < 2) {
  fail('Both pending and history card shells must animate height and opacity while collapsing.');
}

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
