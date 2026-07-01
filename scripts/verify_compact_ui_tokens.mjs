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
const reviewInputFormSource = fs.readFileSync('entry/src/main/ets/components/ReviewInputForm.ets', 'utf8');
const longFormExportSource = fs.readFileSync('entry/src/main/ets/components/LongFormExportReviewCard.ets', 'utf8');
const statsPageSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const toastServiceSource = fs.readFileSync('entry/src/main/ets/services/ToastService.ets', 'utf8');

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
  'static readonly pageTopPadding: number = 16;',
  'static readonly searchHeight: number = LayoutTokens.SearchHeight;',
  'static readonly chipHeight: number = LayoutTokens.ChipHeight;',
  'static readonly tabBarHeight: number = LayoutTokens.TabBarHeight;',
  'static readonly listThumbnailSize: number = LayoutTokens.ListThumbnailSize;',
  'static readonly cardRadius: number = RadiusTokens.lg;',
  'static readonly buttonRadius: number = RadiusTokens.md;',
  'static readonly inputRadius: number = RadiusTokens.md;'
];

for (const marker of requiredTokens) {
  assertIncludes(appDesignSource, marker, `Compact token missing: ${marker}`);
}

const requiredDesignTokens = [
  'static readonly PageTitle: number = 26;',
  'static readonly PageSubtitle: number = 14;',
  'static readonly SectionTitle: number = 16;',
  'static readonly CardTitle: number = 16;',
  'static readonly CardBody: number = 14;',
  'static readonly ListTitle: number = 16;',
  'static readonly ListBody: number = 14;',
  'static readonly CardMeta: number = 12;',
  'static readonly ButtonText: number = 14;',
  'static readonly TabLabel: number = 11;',
  'static readonly SearchHeight: number = 44;',
  'static readonly ChipHeight: number = 34;',
  'static readonly SecondaryButtonHeight: number = 44;',
  'static readonly PrimaryButtonHeight: number = 48;',
  'static readonly TabBarHeight: number = 60;',
  'static readonly TabBarItemHeight: number = 44;',
  'static readonly ListThumbnailSize: number = 68;',
  'export class ElevationTokens',
  'static readonly overlay: ShadowToken = {',
  'export class MotionTokens',
  'static readonly scalePressed: number = 0.96;'
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
assertIncludes(appShellSource, "$r('app.media.tab_stats_active')", 'TabBar must use the stats line icon resource.');
assertIncludes(appShellSource, "$r('app.media.tab_user_active')", 'TabBar must use the user line icon resource.');
assertIncludes(appShellSource, '.fontSize(AppTypography.tabLabel)', 'Tab label must use shared tab label token.');
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
  'tab_stats.svg',
  'tab_stats_active.svg',
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

assertIncludes(homePageSource, "AppPageHeader({\n        title: '摄影复盘'", 'Home page must keep the compact title-only header.');
assertIncludes(homePageSource, 'PrimaryButton({', 'Home import entry must use the shared primary button.');
assertIncludes(homePageSource, '.shadow(ElevationTokens.medium)', 'Home hero must keep production elevation.');
assertIncludes(homePageSource, '.shadow(ElevationTokens.subtle)', 'Home feature tags and flow cards must keep subtle elevation.');
assertIncludes(homePageSource, 'HOME_METHOD_TAG_HEIGHT: number = 28;', 'Home feature tags must remain compact enough for the first screen.');

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

assertIncludes(myPageSource, "AppPageHeader({\n            title: '我的'", 'MyPage must keep the compact title-only header.');
assertIncludes(myPageSource, 'SettingsLinkRow({', 'MyPage settings entries must use the shared link row.');
assertIncludes(myPageSource, 'dense: true', 'MyPage settings rows must use compact density.');
assertIncludes(myPageSource, 'SettingsEntryTone.SUCCESS', 'MyPage status badges must use semantic tones.');
assertIncludes(myPageSource, 'SettingsEntryTone.WARNING', 'MyPage status badges must keep warning tone coverage.');
assertIncludes(myPageSource, '.margin({ top: MY_PAGE_TITLE_CONTENT_GAP })', 'MyPage title-to-content gap must stay compact.');
assertIncludes(myPageSource, 'this.VersionInfoCard()', 'MyPage app version must use a static information card.');
assertIncludes(myPageSource, 'this.DeveloperDiagnosticsCard()', 'MyPage diagnostics must be visually separated from ordinary settings.');
assertIncludes(myPageSource, '.backgroundColor(this.isDeveloperDiagnosticsPressed ? AppColors.surfaceMuted : AppColors.tagAmber)',
  'MyPage diagnostics card must keep its highlighted press state.');
assertIncludes(appDesignSource, '@State isPressed: boolean = false;', 'Shared interactive rows and buttons must keep custom press state.');
assertIncludes(appDesignSource, '.scale({ x: this.isPressed ? MotionTokens.scaleSubtle : 1, y: this.isPressed ? MotionTokens.scaleSubtle : 1 })',
  'Shared cards and settings rows must keep subtle press feedback.');
assertIncludes(reviewerProfileSource, '.justifyContent(FlexAlign.Start)', 'ReviewerProfilePage must explicitly top-align content.');
assertIncludes(homeStorageSource, 'top: AppMetrics.pageTopPadding', 'HomeStoragePage must use shared top padding.');
assertIncludes(previewPageSource, '.shadow(ElevationTokens.high)', 'Preview floating action bar must use high elevation.');
assertIncludes(previewPageSource, '@State pressedActionKey: string = \'\';', 'Preview actions must keep explicit press feedback state.');
assertIncludes(editorPageSource, '.shadow(ElevationTokens.medium)', 'Editor photo header must keep medium elevation.');
assertIncludes(editorPageSource, 'duration: MotionTokens.durationStandard', 'Editor focus scrolling must use shared motion tokens.');
assertIncludes(reviewInputFormSource, 'struct ReviewTextAreaField', 'Review text fields must use an isolated @Link component.');
assertIncludes(reviewInputFormSource, 'TextArea({ text: $$this.value', 'Review TextArea must keep true two-way binding.');
assertIncludes(editorPageSource, '@State isDirty: boolean = false;', 'Editor must track unsaved changes.');
assertIncludes(editorPageSource, 'onBackPress(): boolean', 'Editor must intercept back navigation when dirty.');
assertIncludes(editorPageSource, 'EDITOR_TEXTAREA_VERTICAL_PADDING: number = 28;', 'Editor scroll estimation must match ReviewInputForm vertical padding.');
assertIncludes(editorPageSource, 'EDITOR_KEYBOARD_HEIGHT_CHANGE_THRESHOLD: number = 10;', 'Editor keyboard observer must debounce small height jitter.');
assertIncludes(editorPageSource, '.edgeEffect(EdgeEffect.Spring)', 'Editor scroll must keep spring edge feedback.');
assertIncludes(statsPageSource, '.edgeEffect(EdgeEffect.Spring)', 'Stats scroll must keep spring edge feedback.');
assertIncludes(projectDetailSource, '.edgeEffect(EdgeEffect.Spring)', 'Library list must keep spring edge feedback.');
assertIncludes(homePageSource, '@State heroAutoplayPaused: boolean = false;', 'Home hero autoplay must pause after user touch.');
assertIncludes(homePageSource, '.autoPlay(this.shouldAutoplayHero() && !this.heroAutoplayPaused)', 'Home hero autoplay must respect touch pause.');
assertIncludes(homePageSource, '.margin({ top: AppMetrics.space16 })', 'Home hero-to-tags spacing must use space16.');
assertIncludes(homePageSource, '.margin({ top: AppMetrics.space20 })', 'Home tags-to-button spacing must use space20.');
assertIncludes(previewPageSource, 'enum ExportState', 'Preview export actions must use a single export state enum.');
assertIncludes(previewPageSource, 'EXPORT_ACTION_TIMEOUT_MS: number = 30000;', 'Preview export actions must have a 30s timeout.');
assertIncludes(appDesignSource, 'export class ExportCardColors', 'Export card colors must be centralized.');
assertIncludes(appDesignSource, '@Prop icon: Resource | null = null;', 'EmptyState must expose an optional icon prop.');
assertIncludes(longFormExportSource, 'ExportCardColors.', 'Long form export card must use centralized export colors.');
assertIncludes(toastServiceSource, 'export class ToastService', 'ToastService must centralize toast feedback.');

const reviewTextAreaBlock = reviewInputFormSource.split('TextArea({ text: $$this.value')[1]?.split('@Component\nexport struct ReviewInputForm')[0] ?? '';
const reviewTitleInputBlock = reviewInputFormSource.split('TextInput({ text: this.title')[1]?.split('ReviewTextAreaField({')[0] ?? '';

if (reviewTextAreaBlock.includes('.animation(')) {
  failed = true;
  console.error('Review TextArea must not animate height or all property changes.');
}

if (reviewTitleInputBlock.includes('.animation(')) {
  failed = true;
  console.error('Review title TextInput must not use global animation.');
}

for (const filePath of sourceFiles) {
  const relativePath = path.relative(root, filePath);
  const source = fs.readFileSync(filePath, 'utf8');
  if (relativePath.startsWith('entry/src/main/ets/pages/') && source.includes('promptAction.showToast')) {
    failed = true;
    console.error(`Page must use ToastService instead of direct promptAction.showToast: ${relativePath}`);
  }
}

if (/#[0-9A-Fa-f]{6,8}/.test(longFormExportSource)) {
  failed = true;
  console.error('LongFormExportReviewCard must not leak direct color literals; use ExportCardColors or ReviewCardStyleTokens.');
}

if (/borderRadius\((17|20)\)/.test(longFormExportSource)) {
  failed = true;
  console.error('LongFormExportReviewCard must use RadiusTokens instead of non-standard radius literals.');
}

if (failed) {
  process.exit(1);
}

console.log('compact ui tokens verified: production tokens, tab icons, density, shared press feedback, editor/preview elevation');
