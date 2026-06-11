import fs from 'node:fs';

const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const secretServiceSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageSecretService.ets', 'utf8');
const settingsPageSource = fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');

let failed = false;

function assertIncludes(source, snippet, message) {
  if (!source.includes(snippet)) {
    failed = true;
    console.error(message);
  }
}

function assertNotIncludes(source, snippet, message) {
  if (source.includes(snippet)) {
    failed = true;
    console.error(message);
  }
}

assertIncludes(secretServiceSource, "import asset from '@ohos.security.asset'", 'HomeStorageSecretService must use HarmonyOS Asset Store.');
assertIncludes(secretServiceSource, 'asset.Tag.SECRET', 'HomeStorageSecretService must store password as an asset secret.');
assertIncludes(secretServiceSource, 'asset.Tag.SYNC_TYPE', 'HomeStorageSecretService must set a sync policy for the password asset.');
assertIncludes(homeStorageSource, 'HomeStorageSecretService.savePassword(normalized.password)', 'HomeStorageService must save passwords through HomeStorageSecretService.');
assertNotIncludes(homeStorageSource, 'store.put(PASSWORD_KEY', 'HomeStorageService must not write password to preferences.');
assertNotIncludes(homeStorageSource, "const PASSWORD_KEY: string = 'password'", 'HomeStorageService must not define an active preferences password key.');

assertIncludes(settingsPageSource, 'keyboardHeightChange', 'ReviewSettingsPage must observe keyboard height changes.');
assertIncludes(settingsPageSource, 'Scroll(this.settingsScroller)', 'ReviewSettingsPage must use a controlled settings scroller.');
assertIncludes(settingsPageSource, 'this.getSettingsBottomPadding()', 'ReviewSettingsPage must reserve keyboard-aware bottom padding.');

assertIncludes(previewPageSource, 'isActionBusy()', 'PreviewPage must centralize action busy state.');
assertIncludes(previewPageSource, '.enabled(!isDisabled)', 'PreviewPage action buttons must be disabled while busy.');
assertIncludes(previewPageSource, '.stateEffect(!isDisabled)', 'PreviewPage action buttons must disable pressed state while busy.');

if (failed) {
  process.exit(1);
}

console.log('security hardening: secure password storage, keyboard form, preview actions ok');
