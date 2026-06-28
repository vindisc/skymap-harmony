import fs from 'node:fs';

const projectDetailSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const statsPageSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function requireIncludes(source, marker, message) {
  assert(source.includes(marker), `${message}: ${marker}`);
}

function forbidIncludes(source, marker, message) {
  assert(!source.includes(marker), `${message}: ${marker}`);
}

[
  '按照片、判断和卡点回看你的复盘记录。',
  '完成复盘后，这里会展示你的判断变化。',
  '复盘身份、存储同步和应用状态。',
  '影响新建复盘、导出和家庭存储连接。'
].forEach((copy) => {
  forbidIncludes(projectDetailSource, copy, 'ProjectDetailPage must remove low-value explanatory copy');
  forbidIncludes(statsPageSource, copy, 'StatsPage must remove low-value explanatory copy');
  forbidIncludes(myPageSource, copy, 'MyPage must remove low-value explanatory copy');
});

[
  "title: '复盘库'",
  'this.SearchField()',
  "this.FilterChip('全部', 'all')",
  "this.FilterChip('成立', ReviewJudgementStatus.VALID)",
  "this.FilterChip('待判断', ReviewJudgementStatus.UNSURE)",
  "this.FilterChip('不成立', ReviewJudgementStatus.INVALID)",
  'Text(this.resolveResultCountText())'
].forEach((marker) => requireIncludes(projectDetailSource, marker, 'ProjectDetailPage must keep core library controls'));

[
  "AppPageHeader({\n          title: '统计'",
  'this.OverviewCard()',
  'this.Recent30DaysCard()',
  'this.DistributionCard()',
  'this.BlockersCard()',
  'this.RecentReviewsCard()',
  'EmptyState({\n              title: \'还没有复盘数据\'',
  '完成第一张照片复盘后，这里会显示你的判断变化。'
].forEach((marker) => requireIncludes(statsPageSource, marker, 'StatsPage must keep stats cards and empty-state guidance'));

[
  "AppPageHeader({\n          title: '我的'",
  "title: '设置'",
  "title: '复盘人'",
  "title: '首页图片'",
  "title: '家庭存储'",
  "title: '同步中心'",
  'bottom: MY_PAGE_BOTTOM_PADDING',
  '.layoutWeight(1)'
].forEach((marker) => requireIncludes(myPageSource, marker, 'MyPage must keep settings entries and tab clearance'));

[
  "label: '首页', activeIcon:",
  "label: '复盘库', activeIcon:",
  "label: '统计', activeIcon:",
  "label: '我的', activeIcon:"
].forEach((marker) => requireIncludes(appShellSource, marker, 'Bottom tab must remain unchanged'));

[
  'static readonly pageTitle: number = TypographyTokens.PageTitle;',
  'static readonly pageSubtitle: number = TypographyTokens.PageSubtitle;',
  'static readonly sectionTitle: number = TypographyTokens.SectionTitle;',
  'static readonly cardTitle: number = TypographyTokens.CardTitle;',
  'static readonly body: number = TypographyTokens.CardBody;'
].forEach((marker) => requireIncludes(appDesignSource, marker, 'Global typography baseline must remain intact'));

[
  'static readonly space4:',
  'static readonly space12:',
  'AppMetrics.space4',
  'AppMetrics.space12'
].forEach((marker) => {
  forbidIncludes(appDesignSource, marker, 'Global spacing baseline must remain intact');
  forbidIncludes(projectDetailSource, marker, 'ProjectDetailPage must keep existing spacing scale');
  forbidIncludes(statsPageSource, marker, 'StatsPage must keep existing spacing scale');
  forbidIncludes(myPageSource, marker, 'MyPage must keep existing spacing scale');
});

if (failed) {
  process.exit(1);
}

console.log('page description cleanup verified: library/stats/my explanatory copy removed, controls and tab clearance preserved');
