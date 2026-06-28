import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const designTokensSource = fs.readFileSync('entry/src/main/ets/theme/DesignTokens.ets', 'utf8');
const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const projectDetailSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const reviewerProfileSource = fs.readFileSync('entry/src/main/ets/pages/ReviewerProfilePage.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const editorPageSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');

let failed = false;

function assertIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    failed = true;
    console.error(message);
  }
}

const requiredTokens = [
  'static readonly pageTitle: number = TypographyTokens.PageTitle;',
  'static readonly pageSubtitle: number = TypographyTokens.PageSubtitle;',
  'static readonly sectionTitle: number = TypographyTokens.SectionTitle;',
  'static readonly cardTitle: number = TypographyTokens.CardTitle;',
  'static readonly body: number = TypographyTokens.CardBody;',
  'static readonly caption: number = TypographyTokens.SectionSubtitle;',
  'static readonly meta: number = TypographyTokens.CardMeta;',
  'static readonly buttonText: number = TypographyTokens.ButtonText;',
  'static readonly tabLabel: number = TypographyTokens.TabLabel;',
  'static readonly pageTopPadding: number = 28;',
  'static readonly searchHeight: number = LayoutTokens.SearchHeight;',
  'static readonly chipHeight: number = LayoutTokens.ChipHeight;',
  'static readonly tabBarHeight: number = LayoutTokens.TabBarHeight;',
  'static readonly listThumbnailSize: number = LayoutTokens.ListThumbnailSize;'
];

for (const marker of requiredTokens) {
  assertIncludes(appDesignSource, marker, `Compact token missing: ${marker}`);
}

const requiredDesignTokens = [
  'static readonly PageTitle: number = 24;',
  'static readonly PageSubtitle: number = 14;',
  'static readonly SectionTitle: number = 17;',
  'static readonly CardTitle: number = 16;',
  'static readonly CardBody: number = 15;',
  'static readonly ListTitle: number = 16;',
  'static readonly ListBody: number = 14;',
  'static readonly CardMeta: number = 12;',
  'static readonly ButtonText: number = 15;',
  'static readonly TabLabel: number = 12;',
  'static readonly SearchHeight: number = 44;',
  'static readonly ChipHeight: number = 44;',
  'static readonly SecondaryButtonHeight: number = 44;',
  'static readonly PrimaryButtonHeight: number = 48;',
  'static readonly TabBarHeight: number = 58;',
  'static readonly TabBarItemHeight: number = 50;',
  'static readonly ListThumbnailSize: number = 68;'
];

for (const marker of requiredDesignTokens) {
  assertIncludes(designTokensSource, marker, `DesignTokens missing: ${marker}`);
}

const forbiddenOversizedTokens = [
  'static readonly level1: number = 48;',
  'static readonly level1LineHeight: number = 56;',
  'static readonly level2: number = 32;',
  'static readonly level3: number = 26;',
  'static readonly body: number = 20;',
  'static readonly caption: number = 16;'
];

for (const marker of forbiddenOversizedTokens) {
  if (appDesignSource.includes(marker)) {
    failed = true;
    console.error(`Oversized typography token is forbidden: ${marker}`);
  }
}

const sourceFiles = [];
function collectEtsFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectEtsFiles(fullPath);
      continue;
    }
    if (entry.isFile() && entry.name.endsWith('.ets')) {
      sourceFiles.push(fullPath);
    }
  }
}

collectEtsFiles(path.join(root, 'entry/src/main/ets/pages'));
collectEtsFiles(path.join(root, 'entry/src/main/ets/components'));

for (const filePath of sourceFiles) {
  const source = fs.readFileSync(filePath, 'utf8');
  const fontSizeRegex = /\.fontSize\((\d+)\)/g;
  let match = fontSizeRegex.exec(source);
  while (match !== null) {
    const size = Number(match[1]);
    if (size >= 36) {
      failed = true;
      console.error(`Oversized literal font size ${size} in ${path.relative(root, filePath)}`);
    }
    match = fontSizeRegex.exec(source);
  }
}

const forbiddenTabMarkers = [
  "icon: '●'",
  "icon: '■'",
  "icon: '◆'",
  'Text(item.icon)'
];

for (const marker of forbiddenTabMarkers) {
  if (appShellSource.includes(marker)) {
    failed = true;
    console.error(`TabBar must not use placeholder icon marker: ${marker}`);
  }
}

assertIncludes(appShellSource, "$r('app.media.tab_home_active')", 'TabBar must use the home line icon resource.');
assertIncludes(appShellSource, "$r('app.media.tab_library_active')", 'TabBar must use the library line icon resource.');
assertIncludes(appShellSource, "$r('app.media.tab_user_active')", 'TabBar must use the user line icon resource.');
assertIncludes(appShellSource, '.fontSize(AppTypography.tabLabel)', 'Tab label must use 12fp Compact token.');
assertIncludes(appShellSource, '.height(AppMetrics.tabBarHeight)', 'TabBar must use shared touch-safe token.');
assertIncludes(appShellSource, 'bottom: 4', 'TabBar must not leave oversized blank bottom padding.');
assertIncludes(appShellSource, 'Divider()', 'TabBar must use a light top divider instead of a boxed border.');
assertIncludes(appShellSource, '.opacity(0.42)', 'TabBar divider must stay visually soft.');
if (appShellSource.includes('.border({ width: 1, color: AppColors.border })')) {
  failed = true;
  console.error('TabBar must not use a full boxed border because it creates a detached bottom area.');
}

const iconFiles = [
  'tab_home.svg',
  'tab_home_active.svg',
  'tab_library.svg',
  'tab_library_active.svg',
  'tab_user.svg',
  'tab_user_active.svg'
];
for (const fileName of iconFiles) {
  const iconPath = path.join(root, 'entry/src/main/resources/base/media', fileName);
  if (!fs.existsSync(iconPath)) {
    failed = true;
    console.error(`Missing Tab icon asset: ${fileName}`);
  }
}

assertIncludes(homePageSource, 'createHomeDashboardReloadState', 'Home stats must be owned by dashboard presenter state.');
assertIncludes(homePageSource, 'applyHomeDashboardReloadSuccess', 'Home stats must update through presenter success path.');
assertIncludes(homePageSource, 'applyHomeDashboardReloadFailure', 'Home stats must preserve stable state on failure.');
assertIncludes(homePageSource, 'ReviewCardHistoryService.loadWithDiagnostics(context)', 'Home stats must load persisted history with diagnostics.');
if (homePageSource.includes('0天')) {
  failed = true;
  console.error('Home page must not render 0天.');
}

assertIncludes(projectDetailSource, '.height(AppMetrics.searchHeight)', 'Library search input must use shared touch-safe token.');
assertIncludes(projectDetailSource, '.height(AppMetrics.filterChipHeight)', 'Library chips must use compact filter token.');
assertIncludes(projectDetailSource, '.constraintSize({ minWidth: value === \'all\' ? 60 : 72 })', 'Library filter chips must read as compact horizontal pills.');
assertIncludes(projectDetailSource, '.borderRadius(12)', 'Library filter chips must avoid oversized capsule corners.');
assertIncludes(projectDetailSource, '.fontSize(AppTypography.meta)', 'Library filter chips must use small label typography.');
assertIncludes(projectDetailSource, '.fontSize(AppTypography.inputText)', 'Library search text must use shared input typography.');
assertIncludes(appDesignSource, '.width(AppMetrics.listThumbnailSize)', 'List cards must use compact 68vp thumbnail token.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.listTitle)', 'List titles must use compact token.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.listSubtitle)', 'List subtitle must use compact token.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.meta)', 'Status tags must use compact token.');

function buildBody(source) {
  const index = source.lastIndexOf('\n  build()');
  return index >= 0 ? source.slice(index) : source;
}

const topAlignedPages = [
  ['HomePage', buildBody(homePageSource)],
  ['ProjectDetailPage', buildBody(projectDetailSource)],
  ['MyPage', buildBody(myPageSource)],
  ['ReviewerProfilePage', buildBody(reviewerProfileSource)],
  ['HomeStoragePage', buildBody(homeStorageSource)],
  ['PreviewPage', buildBody(previewPageSource)],
  ['EditorPage', buildBody(editorPageSource)]
];

for (const [pageName, source] of topAlignedPages) {
  if (source.includes('.justifyContent(FlexAlign.Center)')) {
    failed = true;
    console.error(`${pageName} must not vertically center primary page content.`);
  }
}

assertIncludes(myPageSource, "title: '复盘人'", 'My page must keep reviewer settings entry.');
assertIncludes(myPageSource, "title: '首页图片'", 'My page must keep home image settings entry.');
assertIncludes(appDesignSource, 'static readonly profileName: number = TypographyTokens.CardTitle;', 'Profile typography token should remain available for shared components.');
if (myPageSource.includes("title: '家庭存储'") || myPageSource.includes("title: '同步中心'")) {
  failed = true;
  console.error('MyPage must hide non-Beta storage and sync entries.');
}
assertIncludes(reviewerProfileSource, '.justifyContent(FlexAlign.Start)', 'ReviewerProfilePage must explicitly top-align content.');
assertIncludes(homeStorageSource, 'top: AppMetrics.pageTopPadding', 'HomeStoragePage must use shared top padding.');

if (failed) {
  process.exit(1);
}

console.log('compact ui tokens verified: typography<=34, tab icons=line assets, density tokens, top alignment, true home stats markers');
