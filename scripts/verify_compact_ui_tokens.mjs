import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
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
  'static readonly pageTitle: number = 34;',
  'static readonly pageSubtitle: number = 18;',
  'static readonly sectionTitle: number = 20;',
  'static readonly cardTitle: number = 18;',
  'static readonly body: number = 16;',
  'static readonly caption: number = 14;',
  'static readonly meta: number = 13;',
  'static readonly buttonText: number = 17;',
  'static readonly tabLabel: number = 12;',
  'static readonly pageTopPadding: number = 40;',
  'static readonly searchHeight: number = 44;',
  'static readonly chipHeight: number = 36;',
  'static readonly tabBarHeight: number = 64;',
  'static readonly listThumbnailSize: number = 72;'
];

for (const marker of requiredTokens) {
  assertIncludes(appDesignSource, marker, `Compact token missing: ${marker}`);
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
    if (size > 36) {
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
assertIncludes(appShellSource, '.height(AppMetrics.tabBarHeight)', 'TabBar must use 64vp Compact token.');

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

assertIncludes(homePageSource, "this.StatItem(`${this.projectSummary.recordCount}`, '总复盘')", 'Home stats must render true projectSummary.recordCount.');
assertIncludes(homePageSource, "return '—';", 'Home streak fallback must be —, not 0天.');
if (homePageSource.includes('0天')) {
  failed = true;
  console.error('Home page must not render 0天.');
}

assertIncludes(projectDetailSource, '.height(AppMetrics.searchHeight)', 'Library search input must use 44vp Compact token.');
assertIncludes(projectDetailSource, '.height(AppMetrics.chipHeight)', 'Library chips must use 36vp Compact token.');
assertIncludes(appDesignSource, '.width(AppMetrics.listThumbnailSize)', 'List cards must use 72vp thumbnail token.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.cardTitle)', 'Card/list titles must use 18fp Compact token.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.listSubtitle)', 'List subtitle must use 15fp Compact token.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.meta)', 'Status tags must use 13fp Compact token.');

const topAlignedPages = [
  ['HomePage', homePageSource],
  ['ProjectDetailPage', projectDetailSource],
  ['MyPage', myPageSource],
  ['ReviewerProfilePage', reviewerProfileSource],
  ['HomeStoragePage', homeStorageSource],
  ['PreviewPage', previewPageSource],
  ['EditorPage', editorPageSource]
];

for (const [pageName, source] of topAlignedPages) {
  if (source.includes('.justifyContent(FlexAlign.Center)')) {
    failed = true;
    console.error(`${pageName} must not vertically center primary page content.`);
  }
}

assertIncludes(myPageSource, '.fontSize(AppTypography.profileName)', 'My identity card name must use compact profile token.');
assertIncludes(myPageSource, '次复盘 ·', 'My identity card must show compact one-line review stats.');
assertIncludes(reviewerProfileSource, '.justifyContent(FlexAlign.Start)', 'ReviewerProfilePage must explicitly top-align content.');
assertIncludes(homeStorageSource, '.padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding', 'HomeStoragePage must use shared top padding.');

if (failed) {
  process.exit(1);
}

console.log('compact ui tokens verified: typography<=34, tab icons=line assets, density tokens, top alignment, true home stats markers');
