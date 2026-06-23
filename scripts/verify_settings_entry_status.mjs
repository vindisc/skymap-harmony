import fs from 'node:fs';

const homeStorageServiceSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

function expectIncludes(source, token, label) {
  if (!source.includes(token)) {
    fail(`${label} missing token: ${token}`);
  }
}

expectIncludes(
  homeStorageServiceSource,
  'static resolveEntryStatusLabel(status: HomeStorageConfigStatus): string',
  'HomeStorageService'
);
expectIncludes(homeStorageServiceSource, "return '已配置';", 'HomeStorageService');
expectIncludes(homeStorageServiceSource, "return '待完善';", 'HomeStorageService');
expectIncludes(homeStorageServiceSource, "return '未配置';", 'HomeStorageService');

expectIncludes(
  myPageSource,
  "@Prop @Watch('refreshPageData') refreshToken: number = 0;",
  'MyPage'
);
expectIncludes(myPageSource, 'refreshPageData(): void {', 'MyPage');
expectIncludes(
  myPageSource,
  'return HomeStorageService.resolveEntryStatusLabel(this.resolveHomeStorageStatus());',
  'MyPage'
);
expectIncludes(myPageSource, 'return this.resolveReviewerSummary();', 'MyPage');

expectIncludes(appShellSource, '@State myRefreshToken: number = 0;', 'AppShellPage');
expectIncludes(appShellSource, 'this.myRefreshToken += 1;', 'AppShellPage');
expectIncludes(appShellSource, 'MyPage({ refreshToken: this.myRefreshToken })', 'AppShellPage');

const HomeStorageConfigStatus = {
  EMPTY: 'empty',
  PARTIAL: 'partial',
  COMPLETE: 'complete'
};

function resolveEntryStatusLabel(status) {
  if (status === HomeStorageConfigStatus.COMPLETE) {
    return '已配置';
  }
  if (status === HomeStorageConfigStatus.PARTIAL) {
    return '待完善';
  }
  return '未配置';
}

function resolveReviewerSummary(reviewerName) {
  return reviewerName.length > 0 ? reviewerName : '未设置';
}

if (resolveEntryStatusLabel(HomeStorageConfigStatus.COMPLETE) !== '已配置') {
  fail('Complete home storage settings must map to 已配置 in outer entries');
}

if (resolveEntryStatusLabel(HomeStorageConfigStatus.EMPTY) !== '未配置') {
  fail('Empty home storage settings must map to 未配置 in outer entries');
}

if (resolveReviewerSummary('见遇') === '未设置') {
  fail('Reviewer entry must not display 未设置 when reviewer name exists');
}

if (failed) {
  process.exit(1);
}

console.log('settings entry status: outer mapping and refresh wiring verified');
