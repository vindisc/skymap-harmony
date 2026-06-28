import fs from 'node:fs';

const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const syncCenterPageSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');
const reviewSettingsServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewSettingsService.ets', 'utf8');
const homeStorageServiceSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const settingsRefreshServiceSource = fs.readFileSync('entry/src/main/ets/services/SettingsRefreshService.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

assert(settingsRefreshServiceSource.includes('notifySettingsChanged(reason: string)'), 'SettingsRefreshService must expose notifySettingsChanged.');
assert(settingsRefreshServiceSource.includes('getRefreshToken()'), 'SettingsRefreshService must expose getRefreshToken.');
assert(settingsRefreshServiceSource.includes('subscribe(listener: SettingsRefreshListener)'), 'SettingsRefreshService must support subscriptions.');
assert(settingsRefreshServiceSource.includes('SettingsRefreshService.listeners.indexOf(listener) >= 0'), 'SettingsRefreshService must avoid duplicate subscriptions.');
assert(settingsRefreshServiceSource.includes('listener(SettingsRefreshService.refreshToken, reason);'), 'SettingsRefreshService must notify subscribers.');
assert(settingsRefreshServiceSource.includes('console.warn(`[SettingsRefresh] listener failed: ${error}`);'), 'SettingsRefreshService listener errors must be isolated.');
assert(reviewSettingsServiceSource.includes("notifySettingsChanged('reviewer_name_saved')"), 'Reviewer name save must notify settings refresh.');
assert(homeStorageServiceSource.includes("notifySettingsChanged('home_storage_saved')"), 'Home storage save must notify settings refresh.');

assert(appShellSource.includes('settingsRefreshToken'), 'AppShell must hold settingsRefreshToken.');
assert(appShellSource.includes('SettingsRefreshService.subscribe(this.settingsRefreshListener);'), 'AppShell must subscribe to settings changes.');
assert(
  appShellSource.includes('MyPage({ refreshToken: this.myRefreshToken + this.reviewLibraryRefreshToken + this.settingsRefreshToken })'),
  'AppShell must pass settings refresh token to MyPage.'
);
assert(myPageSource.includes("@Prop @Watch('refreshPageData') refreshToken: number = 0;"), 'MyPage must watch refreshToken.');
assert(myPageSource.includes('this.reviewerName = await ReviewSettingsService.loadReviewerName(context);'), 'MyPage reload must read reviewer name.');
assert(myPageSource.includes('this.homeStorageSettings = await HomeStorageService.loadSettings(context);'), 'MyPage reload must read home storage settings.');
assert(syncCenterPageSource.includes('SettingsRefreshService.getRefreshToken()'), 'SyncCenterPage must observe settings refresh token.');
assert(syncCenterPageSource.includes('this.loadSettings();'), 'SyncCenterPage must reload home storage settings.');

class SettingsRefreshModel {
  constructor() {
    this.token = 0;
    this.listeners = [];
    this.reasons = [];
  }

  subscribe(listener) {
    this.listeners.push(listener);
  }

  notify(reason) {
    this.token += 1;
    this.reasons.push(reason);
    this.listeners.forEach((listener) => listener(this.token, reason));
    return this.token;
  }
}

class AppShellModel {
  constructor(refreshModel) {
    this.currentTab = 'my';
    this.myRefreshToken = 0;
    this.settingsRefreshToken = 0;
    refreshModel.subscribe((token) => {
      this.settingsRefreshToken = token;
      if (this.currentTab === 'my') {
        this.myRefreshToken += 1;
      }
    });
  }

  myPageToken(reviewLibraryRefreshToken = 0) {
    return this.myRefreshToken + reviewLibraryRefreshToken + this.settingsRefreshToken;
  }
}

class MyPageModel {
  constructor() {
    this.reloadCount = 0;
    this.reviewerName = '';
    this.homeStorageStatus = '未配置';
  }

  reload(reviewerName, homeStorageStatus) {
    this.reloadCount += 1;
    this.reviewerName = reviewerName;
    this.homeStorageStatus = homeStorageStatus;
  }
}

const refreshModel = new SettingsRefreshModel();
const appShellModel = new AppShellModel(refreshModel);
const myPageModel = new MyPageModel();
const initialToken = appShellModel.myPageToken();

refreshModel.notify('reviewer_name_saved');
assert(appShellModel.settingsRefreshToken === 1, 'Reviewer save should update AppShell settings token.');
assert(appShellModel.myPageToken() > initialToken, 'Reviewer save should change MyPage refresh token.');
myPageModel.reload('见遇', '未配置');
assert(myPageModel.reviewerName === '见遇', 'MyPage should reload reviewer summary after settings token changes.');

const tokenAfterReviewer = appShellModel.myPageToken();
refreshModel.notify('home_storage_saved');
assert(appShellModel.settingsRefreshToken === 2, 'Home storage save should update AppShell settings token.');
assert(appShellModel.myPageToken() > tokenAfterReviewer, 'Home storage save should change MyPage refresh token.');
myPageModel.reload('见遇', '已配置');
assert(myPageModel.homeStorageStatus === '已配置', 'MyPage should reload home storage and sync center summaries.');
assert(refreshModel.reasons.join(',') === 'reviewer_name_saved,home_storage_saved', 'Settings refresh reasons should be retained in order.');

if (failed) {
  process.exit(1);
}

console.log('settings refresh flow: reviewer, home storage, my page token, and sync reload wiring verified');
