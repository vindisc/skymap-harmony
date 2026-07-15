import fs from 'node:fs';

const checks = new Map([
  ['entry/src/main/ets/entryability/EntryAbility.ets', ['initializeMotionAndLoadContent', 'MotionQualityContext.initialize']],
  ['entry/src/main/ets/pages/AppShellPage.ets', ['playTabIconPulse', 'MotionCurveRole.SPRING_SOFT']],
  ['entry/src/main/ets/pages/HomePage.ets', ['playIntro', 'scaleHeroIntro', 'ShimmerBox', 'PressReactive', "kind: 'review-done'"]],
  ['entry/src/main/ets/pages/ProjectDetailPage.ets', ['RippleTouch', 'MotionTokens.shatterRippleBackMs', 'MotionCurveRole.SPRING_SOFT']],
  ['entry/src/main/ets/pages/EditorPage.ets', ['geometryTransition(`review-hero-${this.resolveHeroTag()}`)', 'LearningProgressService.notifyPendingReviewCompleted', 'PressReactive']],
  ['entry/src/main/ets/pages/PreviewPage.ets', ['BottomSheetContainer', 'ExportMenuContent', 'PressReactive']],
  ['entry/src/main/ets/pages/StatsPage.ets', ['CountUpText', 'ShimmerBox', 'playIntro', 'introStage', 'InsightsIntro', 'MotionCurveRole.LANDING']],
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

const projectDetailSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
if (projectDetailSource.includes('StaggeredEnter')) {
  throw new Error('ProjectDetailPage 动态列表禁止恢复可重播的 StaggeredEnter，避免删除后幸存卡片整批闪烁');
}

console.log('motion narrative hooks verified: tabs, CTA press, list collapse/ripple, preview, stats and settings');
