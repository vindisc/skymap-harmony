import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const shellSource = fs.readFileSync(path.join(root, 'entry/src/main/ets/pages/AppShellPage.ets'), 'utf8');
const designSource = fs.readFileSync(path.join(root, 'entry/src/main/ets/components/AppDesign.ets'), 'utf8');

function assertIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    throw new Error(message);
  }
}

assertIncludes(
  designSource,
  'static readonly tabBarShellHeight: number = LayoutTokens.TabBarHeight + 20 + TAB_BAR_SAFE_AREA_HEIGHT;',
  'Tab bar shell must reserve a bottom safe-area gutter without changing the touch target token.'
);
assertIncludes(
  shellSource,
  '.height(AppMetrics.tabBarHeight)\n        .padding({',
  'Tab button row must stay fixed at the normal tab height instead of stretching into the system gesture area.'
);
assertIncludes(
  shellSource,
  '.height(AppMetrics.tabBarShellHeight)\n      .backgroundColor(AppColors.tabBarBackground)\n      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])',
  'Tab bar background must extend through the bottom safe area while the content remains lifted.'
);

if (shellSource.includes('.layoutWeight(1)\n        .padding({\n          left: AppMetrics.pagePadding,\n          right: AppMetrics.pagePadding,\n          top: 4,\n          bottom: 4\n        })')) {
  throw new Error('Tab button row must not use layoutWeight because it sinks into the expanded bottom safe area.');
}

console.log('Tab bar safe-area layout verified.');
