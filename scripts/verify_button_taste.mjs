import fs from 'node:fs';

const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
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

assertIncludes(appDesignSource, 'export struct CompactPrimaryButton', 'AppDesign must expose a compact primary button.');
assertIncludes(appDesignSource, 'export struct CompactTonalButton', 'AppDesign must expose a compact tonal button.');
assertIncludes(homePageSource, 'CompactPrimaryButton({', 'HomePage start action must use a compact primary button.');
assertIncludes(homePageSource, 'buttonWidth: 168', 'HomePage start action must not stretch across the screen.');
assertIncludes(settingsPageSource, 'CompactTonalButton({', 'ReviewSettingsPage test action must use a compact tonal button.');
assertIncludes(settingsPageSource, 'CompactPrimaryButton({', 'ReviewSettingsPage save action must use a compact primary button.');
assertNotIncludes(settingsPageSource, "label: this.isSaving ? '保存中...' : '保存',\n              isDisabled: this.isSaving,", 'ReviewSettingsPage must not keep the old full-width save button shape.');
assertNotIncludes(previewPageSource, "this.ActionButton('复制复盘数据'", 'PreviewPage action label should be shortened to avoid visual noise.');
assertNotIncludes(previewPageSource, "this.ActionButton('导出复盘文件'", 'PreviewPage action label should be shortened to avoid visual noise.');
assertNotIncludes(previewPageSource, "this.ActionButton('上传家庭存储'", 'PreviewPage action label should be shortened to avoid visual noise.');
assertIncludes(previewPageSource, '.height(34)', 'PreviewPage action pills must use a stable compact height.');

if (failed) {
  process.exit(1);
}

console.log('button taste: compact primary actions and shortened preview labels ok');
