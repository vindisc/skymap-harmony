import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const designTokensPath = 'entry/src/main/ets/theme/DesignTokens.ets';
const appDesignPath = 'entry/src/main/ets/components/AppDesign.ets';
const homePagePath = 'entry/src/main/ets/pages/HomePage.ets';
const appShellPath = 'entry/src/main/ets/pages/AppShellPage.ets';

const designTokensSource = fs.readFileSync(designTokensPath, 'utf8');
const appDesignSource = fs.readFileSync(appDesignPath, 'utf8');
const homePageSource = fs.readFileSync(homePagePath, 'utf8');
const appShellSource = fs.readFileSync(appShellPath, 'utf8');

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

function assertIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    fail(message);
  }
}

const requiredTypographyTokens = [
  ['PageTitle', 24],
  ['PageSubtitle', 14],
  ['SectionTitle', 17],
  ['SectionSubtitle', 13],
  ['CardTitle', 16],
  ['CardBody', 15],
  ['CardMeta', 12],
  ['ListTitle', 16],
  ['ListBody', 14],
  ['ListMeta', 12],
  ['StatNumber', 26],
  ['StatLabel', 12],
  ['ButtonText', 15],
  ['SmallButtonText', 14],
  ['InputText', 15],
  ['InputPlaceholder', 15],
  ['InputLabel', 14],
  ['TabIcon', 21],
  ['TabLabel', 12]
];

for (const [name, value] of requiredTypographyTokens) {
  assertIncludes(
    designTokensSource,
    `static readonly ${name}: number = ${value};`,
    `Typography token mismatch: ${name} must be ${value}`
  );
}

const requiredLayoutTokens = [
  ['TabBarHeight', 58],
  ['TabBarItemHeight', 50],
  ['SearchHeight', 44],
  ['ChipHeight', 44],
  ['PrimaryButtonHeight', 48],
  ['SecondaryButtonHeight', 44],
  ['ListThumbnailSize', 68],
  ['ListCardMinHeight', 88],
  ['ListCardMaxHeight', 100]
];

for (const [name, value] of requiredLayoutTokens) {
  assertIncludes(
    designTokensSource,
    `static readonly ${name}: number = ${value};`,
    `Layout token mismatch: ${name} must be ${value}`
  );
}

assertIncludes(appDesignSource, 'static readonly pageTitle: number = TypographyTokens.PageTitle;', 'PageTitle must be mapped from DesignTokens.');
assertIncludes(appDesignSource, 'static readonly buttonText: number = TypographyTokens.ButtonText;', 'ButtonText must be mapped from DesignTokens.');
assertIncludes(appDesignSource, 'static readonly tabLabel: number = TypographyTokens.TabLabel;', 'TabLabel must be mapped from DesignTokens.');
assertIncludes(appDesignSource, 'static readonly tabIconSize: number = TypographyTokens.TabIcon;', 'Tab icon size must be mapped from DesignTokens.');

const maxByToken = new Map([
  ['PageTitle', 24],
  ['PageSubtitle', 14],
  ['SectionTitle', 17],
  ['SectionSubtitle', 13],
  ['CardTitle', 16],
  ['CardBody', 15],
  ['CardMeta', 12],
  ['ListTitle', 17],
  ['ListBody', 14],
  ['ListMeta', 12],
  ['StatNumber', 26],
  ['StatLabel', 12],
  ['ButtonText', 15],
  ['SmallButtonText', 14],
  ['InputText', 15],
  ['InputPlaceholder', 15],
  ['InputLabel', 14],
  ['TabLabel', 12]
]);

const typographyBlockMatch = designTokensSource.match(/export class TypographyTokens \{([\s\S]*?)\n\}/);
if (!typographyBlockMatch) {
  fail('TypographyTokens class is missing.');
}

const typographyBlock = typographyBlockMatch ? typographyBlockMatch[1] : '';
const tokenRegex = /static readonly ([A-Za-z]+): number = (\d+);/g;
let tokenMatch = tokenRegex.exec(typographyBlock);
while (tokenMatch !== null) {
  const tokenName = tokenMatch[1];
  const tokenValue = Number(tokenMatch[2]);
  const maxValue = maxByToken.get(tokenName);
  if (maxValue !== undefined && tokenValue > maxValue) {
    fail(`${tokenName} exceeds compact max ${maxValue}: ${tokenValue}`);
  }
  tokenMatch = tokenRegex.exec(typographyBlock);
}

const sourceFiles = [];
function collectFiles(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      collectFiles(fullPath);
    } else if (entry.isFile() && entry.name.endsWith('.ets')) {
      sourceFiles.push(fullPath);
    }
  }
}

collectFiles(path.join(root, 'entry/src/main/ets/pages'));
collectFiles(path.join(root, 'entry/src/main/ets/components'));

for (const filePath of sourceFiles) {
  const relativePath = path.relative(root, filePath);
  const source = fs.readFileSync(filePath, 'utf8');
  const literalFontSizeRegex = /\.fontSize\((\d+)\)/g;
  let match = literalFontSizeRegex.exec(source);
  while (match !== null) {
    const size = Number(match[1]);
    if (size >= 36) {
      fail(`Forbidden literal font size ${size} in ${relativePath}`);
    }
    match = literalFontSizeRegex.exec(source);
  }

  const literalFontObjectRegex = /\.font\(\{\s*size:\s*(\d+)/g;
  match = literalFontObjectRegex.exec(source);
  while (match !== null) {
    const size = Number(match[1]);
    if (size >= 36) {
      fail(`Forbidden literal font object size ${size} in ${relativePath}`);
    }
    match = literalFontObjectRegex.exec(source);
  }
}

for (const forbiddenSize of [40, 44, 48, 56]) {
  const forbiddenFontMarkers = [
    `.fontSize(${forbiddenSize})`,
    `font({ size: ${forbiddenSize}`,
    `font: { size: ${forbiddenSize}`
  ];
  for (const marker of forbiddenFontMarkers) {
    for (const filePath of sourceFiles) {
      const source = fs.readFileSync(filePath, 'utf8');
      if (source.includes(marker)) {
        fail(`Forbidden font marker ${marker} in ${path.relative(root, filePath)}`);
      }
    }
  }
}

assertIncludes(appShellSource, '.fontSize(AppTypography.tabLabel)', 'Tab label must use TabLabel token.');
assertIncludes(appShellSource, '.width(AppMetrics.tabIconSize)', 'Tab icon must use TabIcon token.');
assertIncludes(appShellSource, 'bottom: 4', 'TabBar must keep compact bottom-safe padding.');
if (typographyBlock.includes('static readonly TabLabel: number = 13;') ||
  typographyBlock.includes('static readonly TabLabel: number = 14;')) {
  fail('TabLabel must not exceed 12fp.');
}
if (designTokensSource.includes('static readonly ButtonText: number = 16;') ||
  designTokensSource.includes('static readonly ButtonText: number = 17;')) {
  fail('ButtonText must not exceed 15fp.');
}

assertIncludes(homePageSource, 'createHomeDashboardReloadState', 'Home dashboard state must be presenter-backed.');
assertIncludes(homePageSource, 'applyHomeDashboardReloadSuccess', 'Home dashboard success must go through presenter.');
assertIncludes(homePageSource, 'applyHomeDashboardReloadFailure', 'Home dashboard failure must go through presenter.');

const primaryPageFiles = [
  'entry/src/main/ets/pages/HomePage.ets',
  'entry/src/main/ets/pages/ProjectDetailPage.ets',
  'entry/src/main/ets/pages/MyPage.ets',
  'entry/src/main/ets/pages/ReviewerProfilePage.ets',
  'entry/src/main/ets/pages/HomeStoragePage.ets',
  'entry/src/main/ets/pages/EditorPage.ets'
];

for (const filePath of primaryPageFiles) {
  const source = fs.readFileSync(filePath, 'utf8');
  const buildIndex = source.lastIndexOf('\n  build()');
  const buildSource = buildIndex >= 0 ? source.slice(buildIndex) : source;
  if (buildSource.includes('.justifyContent(FlexAlign.Center)')) {
    fail(`${filePath} must not vertically center primary page content.`);
  }
}

assertIncludes(appDesignSource, '.constraintSize({ minHeight: AppMetrics.listCardMinHeight, maxHeight: AppMetrics.listCardMaxHeight })', 'List cards must use compact 88-100vp height tokens.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.listTitle)', 'List titles must use ListTitle token.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.listSubtitle)', 'List bodies must use ListBody token.');
assertIncludes(appDesignSource, '.fontSize(AppTypography.meta)', 'List meta and badges must use 13fp token.');

if (failed) {
  process.exit(1);
}

console.log('compact typography verified: tokens, font caps, tab density, home stats, top alignment');
