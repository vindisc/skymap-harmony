import fs from 'node:fs';

const baselineDocPath = 'docs/harmony/main-tabs-ui-baseline-20260628.md';
const baselineImagePaths = [
  'docs/assets/main-tabs-ui-baseline-20260628/home.jpg',
  'docs/assets/main-tabs-ui-baseline-20260628/library.jpg',
  'docs/assets/main-tabs-ui-baseline-20260628/stats.jpg',
  'docs/assets/main-tabs-ui-baseline-20260628/my.jpg'
];

const sources = {
  home: fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8'),
  library: fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8'),
  stats: fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8'),
  my: fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8'),
  appearance: fs.readFileSync('entry/src/main/ets/pages/AppearanceSettingsPage.ets', 'utf8'),
  shell: fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8'),
  design: fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8'),
  tokens: fs.readFileSync('entry/src/main/ets/theme/DesignTokens.ets', 'utf8'),
  baselineDoc: fs.readFileSync(baselineDocPath, 'utf8')
};

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

function requireIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    fail(`${message}: ${marker}`);
  }
}

function forbidIncludes(source, marker, message) {
  if (source.includes(marker)) {
    fail(`${message}: ${marker}`);
  }
}

function requireOrder(source, first, second, message) {
  const firstIndex = source.indexOf(first);
  const secondIndex = source.indexOf(second);
  if (firstIndex < 0 || secondIndex < 0 || firstIndex >= secondIndex) {
    fail(message);
  }
}

requireIncludes(sources.baselineDoc, 'HarmonyOS 四个主 Tab UI 基线（2026-06-28）', 'Main tabs UI baseline doc must exist');
requireIncludes(sources.baselineDoc, '不建议继续开启 HarmonyOS UI 小修', 'Baseline doc must freeze further UI-only churn');
[
  'docs/assets/main-tabs-ui-baseline-20260628/home.jpg',
  'docs/assets/main-tabs-ui-baseline-20260628/library.jpg',
  'docs/assets/main-tabs-ui-baseline-20260628/stats.jpg',
  'docs/assets/main-tabs-ui-baseline-20260628/my.jpg',
  'node scripts/verify_main_tabs_ui_baseline.mjs'
].forEach((marker) => requireIncludes(sources.baselineDoc, marker, 'Baseline doc must list screenshots and regression command'));
baselineImagePaths.forEach((imagePath) => {
  if (!fs.existsSync(imagePath)) {
    fail(`Baseline screenshot is missing: ${imagePath}`);
    return;
  }
  const size = fs.statSync(imagePath).size;
  if (size <= 0) {
    fail(`Baseline screenshot is empty: ${imagePath}`);
  }
});

[
  'ScrollDirection.Vertical',
  'Scroll() {\n        Column() {\n          this.HeroPanel()'
].forEach((marker) => forbidIncludes(sources.home, marker, 'HomePage must keep the fixed first-screen baseline'));
[
  'HomeHeroImageService.getDisplayImages',
  'this.heroImages.length > 1',
  'Swiper()',
  '.autoPlay(this.shouldAutoplayHero() && !this.heroAutoplayPaused)',
  '.indicator(this.resolveHeroIndicator())',
  '.aspectRatio(HOME_HERO_ASPECT_RATIO)',
  'PrimaryButton({',
  "label: this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '导入照片，开始复盘'",
  'bottom: AppMetrics.tabContentBottomPadding'
].forEach((marker) => requireIncludes(sources.home, marker, 'HomePage must keep hero config, carousel and tab clearance'));

[
  'setInterval(() =>',
  'clearInterval(this.heroAutoplayTimer)',
  'heroAutoplayTimer',
  'heroCurrentIndex',
  'resolveCurrentHeroImageUri'
].forEach((marker) => forbidIncludes(sources.home, marker, 'HomePage must not regress to manual hero timer'));

[
  '按照片、判断和卡点回看你的复盘记录。',
  '完成复盘后，这里会展示你的判断变化。',
  '复盘身份、存储同步和应用状态。',
  '影响新建复盘、导出和家庭存储连接。',
  "subtitle: ''",
  "description: ''",
  'Text(\'\')',
  'Text("")',
  'Blank()',
  'Spacer()'
].forEach((marker) => {
  forbidIncludes(sources.library, marker, 'Review library must not keep title explanatory copy or placeholders');
  forbidIncludes(sources.stats, marker, 'Stats page must not keep title explanatory copy or placeholders');
  forbidIncludes(sources.my, marker, 'My page must not keep title explanatory copy or placeholders');
});

[
  "AppPageHeader({\n            title: '复盘库'",
  'this.SearchField()',
  "this.FilterChip('全部', 'all')",
  "this.FilterChip('成立', ReviewJudgementStatus.VALID)",
  "this.FilterChip('待判断', ReviewJudgementStatus.UNSURE)",
  "this.FilterChip('不成立', ReviewJudgementStatus.INVALID)",
  'LIBRARY_HEADER_CONTROL_GAP',
  'LIBRARY_LIST_TOP_GAP',
  'ProjectReviewCard({'
].forEach((marker) => requireIncludes(sources.library, marker, 'Review library must keep compact search, filters and cards'));
requireOrder(sources.library, 'this.SearchField()', "this.FilterChip('全部', 'all')", 'Review library search must appear before filters.');
requireOrder(sources.library, "this.FilterChip('不成立', ReviewJudgementStatus.INVALID)", 'this.HistoryReviewListCard(item);', 'Review library list should appear directly after filters.');

[
  "title: '统计'",
  'STATS_PAGE_TOP_PADDING',
  'this.LearningOverviewCard()',
  'this.OverviewCard()',
  'this.Recent30DaysCard()',
  'this.DistributionCard()',
  'this.BlockersCard()',
  '还没有复盘数据',
  '完成第一张照片复盘后，这里会显示你的判断变化。',
  'top: STATS_PAGE_TOP_PADDING',
  ".constraintSize({ minHeight: '100%' })",
  '.justifyContent(FlexAlign.Start)'
].forEach((marker) => requireIncludes(sources.stats, marker, 'Stats page must keep compact stats cards and empty-state-only guidance'));

[
  "AppPageHeader({ title: '我的' })",
  'const MY_PAGE_TITLE_CONTENT_GAP: number = AppMetrics.space10;',
  'this.SettingsSection()',
  'this.AboutSection()',
  "title: '复盘人'",
  "title: '外观与动效'",
  "title: '家庭存储'",
  "title: '同步中心'",
  "title: '备份与恢复'",
  "Text('关于')",
  "this.AboutField('版本'",
  "this.AboutField('作者 QQ'",
  'APP_AUTHOR_QQ_TEXT: string = \'921086628\'',
  'this.AboutInfoCard()',
  'this.DeveloperDiagnosticsCard()',
  'dense: true',
  'bottom: MY_PAGE_BOTTOM_PADDING',
  '.justifyContent(FlexAlign.Start)'
].forEach((marker) => requireIncludes(sources.my, marker, 'My page must show settings first with compact rows and bottom clearance'));
[
  "title: '首页图片'",
  "title: '卡片背景'",
  "title: '显示与动效'",
  "Text('删除星河效果')"
].forEach((marker) => requireIncludes(
  sources.appearance,
  marker,
  'Appearance settings page must keep the secondary visual settings'
));
[
  "title: '设置'",
  "title: '应用'",
  'SettingsSectionHeader({'
].forEach((marker) => forbidIncludes(sources.my, marker, 'My page must not reintroduce redundant section labels'));
[
  'this.IdentityCard()',
  '@Builder\n  IdentityCard()',
  "Text('当前复盘人')",
  "Text('累计复盘')",
  "Text('成立记录')",
  'ReviewCardHistoryService.load(context)',
  'ReviewProjectService.buildHomeSummary',
  'top: AppMetrics.sectionGap'
].forEach((marker) => forbidIncludes(sources.my, marker, 'My page must not restore the profile/stat card or title gap'));
requireOrder(sources.my, "AppPageHeader({ title: '我的' })", 'Scroll() {', 'My page title must stay fixed above the scroll region.');
requireOrder(sources.my, 'this.SettingsSection()', 'this.AboutSection()', 'My page settings should appear before app information.');

[
  "label: '首页', activeIcon:",
  "label: '复盘库', activeIcon:",
  "label: '统计', activeIcon:",
  "label: '我的', activeIcon:",
  '.fontSize(AppTypography.tabLabel)',
  '.height(AppMetrics.tabBarHeight)',
  '.height(AppMetrics.tabBarShellHeight)',
  '.backgroundColor(AppColors.tabBarBackground)',
  '.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])',
  'Divider()'
].forEach((marker) => requireIncludes(sources.shell, marker, 'Bottom tab must keep four tabs, selected styling and safe-area background'));

[
  'static readonly PageTitle: number = 26;',
  'static readonly SectionTitle: number = 16;',
  'static readonly CardTitle: number = 16;',
  'static readonly CardBody: number = 14;',
  'static readonly ButtonText: number = 14;',
  'static readonly InputText: number = 14;',
  'static readonly CardMeta: number = 12;',
  'static readonly TabLabel: number = 11;'
].forEach((marker) => requireIncludes(sources.tokens, marker, 'Typography baseline must remain unchanged'));
[
  'static readonly pageTitle: number = TypographyTokens.PageTitle;',
  'static readonly sectionTitle: number = TypographyTokens.SectionTitle;',
  'static readonly cardTitle: number = TypographyTokens.CardTitle;',
  'static readonly body: number = TypographyTokens.CardBody;',
  'static readonly inputText: number = TypographyTokens.InputText;',
  'static readonly tabLabel: number = TypographyTokens.TabLabel;',
  '@Prop dense: boolean = false;',
  '.constraintSize({ minHeight: this.dense ? 60 : 68 })'
].forEach((marker) => requireIncludes(sources.design, marker, 'Design component baseline must keep typography tokens and compact settings row support'));

[
  'Preferences',
  'RDB',
  'URI',
  'manifest',
  'raw JSON'
].forEach((word) => {
  [sources.home, sources.library, sources.stats].forEach((source) => {
    forbidIncludes(source, `'${word}'`, `Main tabs must not expose technical word ${word} to ordinary users`);
  });
});
forbidIncludes(sources.my, "title: 'Preferences'", 'My page must not expose Preferences to ordinary users');
forbidIncludes(sources.my, "title: 'RDB'", 'My page must not expose RDB as a normal setting');
forbidIncludes(sources.my, "title: 'URI'", 'My page must not expose URI to ordinary users');
forbidIncludes(sources.my, "title: 'manifest'", 'My page must not expose manifest to ordinary users');
forbidIncludes(sources.my, "title: 'raw JSON'", 'My page must not expose raw JSON to ordinary users');

if (failed) {
  process.exit(1);
}

console.log('main tabs UI baseline verified: compact headers, settings-first MyPage, stats/library density, fixed HomePage, tab safe area and typography baseline');
