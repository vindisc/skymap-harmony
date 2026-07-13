import fs from 'node:fs';

const checks = new Map([
  ['entry/src/main/ets/pages/AppShellPage.ets', ['MotionQualityContext.initialize', 'playTabIconPulse', 'MotionCurveRole.SPRING_SOFT']],
  ['entry/src/main/ets/pages/HomePage.ets', ['playIntro', 'scaleHeroIntro', 'ShimmerBox']],
  ['entry/src/main/ets/pages/EditorPage.ets', ['SharedHero', 'completesPendingReview', "kind: 'review-done'"]],
  ['entry/src/main/ets/pages/PreviewPage.ets', ['BottomSheetContainer', 'ExportMenuContent']],
  ['entry/src/main/ets/pages/StatsPage.ets', ['CountUpText', 'ShimmerBox', 'MotionCurveRole.LANDING']],
  ['entry/src/main/ets/pages/MotionSettingsPage.ets', ['MotionQuality.FULL', 'MotionQuality.CALM', 'MotionQuality.MINIMAL']]
]);

for (const [path, markers] of checks.entries()) {
  const source = fs.readFileSync(path, 'utf8');
  for (const marker of markers) {
    if (!source.includes(marker)) {
      throw new Error(`${path} 缺少叙事动效挂点: ${marker}`);
    }
  }
}

console.log('motion narrative hooks verified: tabs, home, editor, preview, stats and settings');
