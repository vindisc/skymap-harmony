import fs from 'node:fs';

const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const projectDetailSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const statsPageSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const styleTokensSource = fs.readFileSync('entry/src/main/ets/components/ReviewCardStyleTokens.ets', 'utf8');
const mobileCardSource = fs.readFileSync('entry/src/main/ets/components/MobileReadingReviewCard.ets', 'utf8');
const horizontalCardSource = fs.readFileSync('entry/src/main/ets/components/HorizontalReviewCard.ets', 'utf8');
const verticalCardSource = fs.readFileSync('entry/src/main/ets/components/VerticalReviewCard.ets', 'utf8');
const squareCardSource = fs.readFileSync('entry/src/main/ets/components/SquareReviewCard.ets', 'utf8');
const exportHorizontalSource = fs.readFileSync('entry/src/main/ets/components/ExportHorizontalReviewCard.ets', 'utf8');
const exportVerticalSource = fs.readFileSync('entry/src/main/ets/components/ExportVerticalReviewCard.ets', 'utf8');
const exportSquareSource = fs.readFileSync('entry/src/main/ets/components/ExportSquareReviewCard.ets', 'utf8');

let failed = false;

function assertIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    failed = true;
    console.error(message);
  }
}

function assertNotIncludes(source, marker, message) {
  if (source.includes(marker)) {
    failed = true;
    console.error(message);
  }
}

assertIncludes(appDesignSource, 'export struct SkeletonBlock', 'AppDesign must expose the shared SkeletonBlock.');
assertIncludes(appDesignSource, 'iterations: -1', 'SkeletonBlock must keep a pulsing loading animation.');
assertIncludes(appDesignSource, '@Prop actionLabel: string = \'\';', 'EmptyState must support an optional action.');
assertIncludes(appDesignSource, 'export struct ProjectReviewCard', 'ProjectReviewCard compatibility wrapper must remain exported.');
assertIncludes(appDesignSource, 'RecentReviewCard({\n      item: this.item,', 'ProjectReviewCard must delegate to RecentReviewCard.');

assertIncludes(homePageSource, '@State isHistoryLoading: boolean = false;', 'HomePage must track history loading.');
assertIncludes(homePageSource, 'this.HomeHistorySkeleton()', 'HomePage must render a history skeleton while loading.');
assertIncludes(projectDetailSource, '@State isLibraryLoading: boolean = false;', 'ProjectDetailPage must track initial library loading.');
assertIncludes(projectDetailSource, 'this.ReviewListSkeleton()', 'ProjectDetailPage must render list skeletons before data resolves.');
assertIncludes(statsPageSource, '@State isStatsLoading: boolean = false;', 'StatsPage must track initial stats loading.');
assertIncludes(statsPageSource, 'this.StatsSkeleton()', 'StatsPage must render stats skeletons before data resolves.');
assertIncludes(statsPageSource, "actionLabel: this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '去创建第一条复盘'",
  'StatsPage empty state must offer a first-review CTA.');
assertIncludes(statsPageSource, 'ReviewCardStore.createPhotoDraft(', 'StatsPage CTA must create the same photo draft as the main flow.');

assertIncludes(styleTokensSource, 'import { ElevationTokens, RadiusTokens, ShadowToken, SpacingTokens }', 'ReviewCardStyleTokens must import shared tokens.');
assertIncludes(styleTokensSource, 'static readonly previewCardShadow: ShadowToken = ElevationTokens.medium;', 'Preview card shadow must use shared elevation.');
assertIncludes(styleTokensSource, 'static readonly mobileCardShadow: ShadowToken = ElevationTokens.high;', 'Mobile reading card shadow must use shared elevation.');
assertIncludes(styleTokensSource, 'static readonly exportCardShadow: ShadowToken = ElevationTokens.high;', 'Export card shadow must use shared elevation.');
assertIncludes(styleTokensSource, 'static readonly cardPadding: number = SpacingTokens.lg;', 'Review card padding must use shared spacing.');
assertIncludes(mobileCardSource, '.shadow(ReviewCardStyleTokens.mobileCardShadow)', 'MobileReadingReviewCard must use the shared review-card shadow.');

for (const [name, source] of [
  ['HorizontalReviewCard', horizontalCardSource],
  ['VerticalReviewCard', verticalCardSource],
  ['SquareReviewCard', squareCardSource]
]) {
  assertIncludes(source, '.shadow(ReviewCardStyleTokens.resolveRenderShadow(this.displayMode))',
    `${name} must resolve shadow through ReviewCardStyleTokens.`);
  assertNotIncludes(source, 'ReviewCardStyleTokens.shadowColor', `${name} must not use a local shadow color.`);
}

for (const [name, source] of [
  ['ExportHorizontalReviewCard', exportHorizontalSource],
  ['ExportVerticalReviewCard', exportVerticalSource],
  ['ExportSquareReviewCard', exportSquareSource]
]) {
  assertIncludes(source, '.shadow(ReviewCardStyleTokens.exportCardShadow)', `${name} must use exportCardShadow.`);
  assertNotIncludes(source, 'ReviewCardStyleTokens.shadowColor', `${name} must not use a local shadow color.`);
}

assertIncludes(appShellSource, '@State tabContentVisible: boolean = true;', 'AppShellPage must own tab transition state.');
assertIncludes(appShellSource, 'TAB_PAGE_EXIT_DELAY', 'AppShellPage must keep a short tab exit delay.');
assertIncludes(appShellSource, '.translate({ y: this.tabContentVisible ? 0 : 10 })', 'AppShellPage tab transition must include subtle vertical motion.');
assertIncludes(appShellSource, 'duration: this.tabContentVisible ? MotionTokens.durationStandard : MotionTokens.durationQuick',
  'AppShellPage tab transition must use shared motion tokens.');

if (failed) {
  process.exit(1);
}

console.log('ui production completion verified: skeletons, empty CTA, list-card delegation, review-card tokens, tab transition');
