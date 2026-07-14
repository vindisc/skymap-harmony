import fs from 'node:fs';

const checks = new Map([
  ['entry/src/main/ets/entryability/EntryAbility.ets', ['initializeMotionAndLoadContent', 'MotionQualityContext.initialize']],
  ['entry/src/main/ets/pages/AppShellPage.ets', ['playTabIconPulse', 'MotionCurveRole.SPRING_SOFT']],
  ['entry/src/main/ets/pages/HomePage.ets', ['playIntro', 'scaleHeroIntro', 'ShimmerBox', 'PressReactive']],
  ['entry/src/main/ets/pages/ProjectDetailPage.ets', ['StaggeredEnter', 'RippleTouch', 'delayMs: MotionTokens.durationStagger']],
  ['entry/src/main/ets/pages/EditorPage.ets', ['geometryTransition(`review-hero-${this.resolveHeroTag()}`)', 'completesPendingReview', "kind: 'review-done'", 'PressReactive']],
  ['entry/src/main/ets/pages/PreviewPage.ets', ['BottomSheetContainer', 'ExportMenuContent', 'PressReactive']],
  ['entry/src/main/ets/pages/StatsPage.ets', ['CountUpText', 'ShimmerBox', 'MotionCurveRole.LANDING']],
  ['entry/src/main/ets/pages/MyPage.ets', ['RippleTouch', 'RippleSettingsLinkRow']],
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

console.log('motion narrative hooks verified: tabs, CTA press, list stagger/ripple, preview, stats and settings');
