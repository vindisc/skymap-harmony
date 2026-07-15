import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const pagesDirectory = path.join(root, 'entry/src/main/ets/pages');
const appDesignPath = path.join(root, 'entry/src/main/ets/components/AppDesign.ets');
const bareScrollPattern = /Scroll\s*\(\s*\)\s*\{/;
const exemptionMarker = '// eslint-disable-next-line settings-scroll';
let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

const appDesignSource = fs.readFileSync(appDesignPath, 'utf8');
assert(appDesignSource.includes('export struct SettingsScrollContainer'),
  'AppDesign 缺少共享 SettingsScrollContainer。');
assert(appDesignSource.includes(".constraintSize({ minHeight: '100%' })"),
  'SettingsScrollContainer 必须固定声明 minHeight 100%。');

const settingsPageFiles = fs.readdirSync(pagesDirectory)
  .filter((name) => name.endsWith('SettingsPage.ets'))
  .sort();

for (const fileName of settingsPageFiles) {
  const source = fs.readFileSync(path.join(pagesDirectory, fileName), 'utf8');
  if (bareScrollPattern.test(source) && !source.includes(exemptionMarker)) {
    failed = true;
    console.error(`${fileName} 不得直接声明 Scroll()，请使用 SettingsScrollContainer 或添加显式豁免注释。`);
  }
}

for (const fileName of ['AppearanceSettingsPage.ets', 'BackupCenterPage.ets', 'MotionSettingsPage.ets']) {
  const source = fs.readFileSync(path.join(pagesDirectory, fileName), 'utf8');
  assert(source.includes('SettingsScrollContainer({'), `${fileName} 未使用共享设置滚动容器。`);
  assert(!bareScrollPattern.test(source), `${fileName} 仍包含裸 Scroll()。`);
}

for (const [fileName, builderCall] of [
  ['AppearanceSettingsPage.ets', 'this.AppearanceSettingsContent();'],
  ['BackupCenterPage.ets', 'this.BackupCenterContent();'],
  ['MotionSettingsPage.ets', 'this.MotionSettingsContent();']
]) {
  const source = fs.readFileSync(path.join(pagesDirectory, fileName), 'utf8');
  assert(source.includes(builderCall), `${fileName} 必须通过独立 Builder 向共享容器传递内容。`);
}

if (failed) {
  process.exit(1);
}

console.log(`settings scroll pattern verified: shared minHeight container and ${settingsPageFiles.length} settings pages guarded`);
