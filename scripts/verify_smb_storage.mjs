import fs from 'node:fs';

const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const settingsPageSource = fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8');
const homeStoragePageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const syncCenterPageSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const secretServiceSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageSecretService.ets', 'utf8');
const smbClientSource = fs.readFileSync('entry/src/main/ets/services/Smb2Client.ets', 'utf8');
const moduleSource = fs.readFileSync('entry/src/main/module.json5', 'utf8');

let failed = false;

const requiredPreviewTokens = [
  "this.ExportSheetAction(this.isUploadingHomeStorage ? '上传到家庭存储中...' : '上传到家庭存储'",
  'private async uploadReviewJsonToHomeStorage(): Promise<void>',
  'HomeStorageService.uploadReviewJson(',
  'ReviewCardHistoryService.markExported(context, this.document, result.remotePath)',
  "this.ExportSheetAction('导出 review.json'"
];

for (const token of requiredPreviewTokens) {
  if (!previewPageSource.includes(token)) {
    failed = true;
    console.error(`PreviewPage missing SMB token: ${token}`);
  }
}

const requiredSettingsTokens = [
  "Text('家庭存储')",
  "SettingsInput('SMB 地址或 IP'",
  "SettingsInput('共享目录'",
  "SettingsInput('目标路径'",
  "SettingsInput('用户名'",
  "SettingsInput('密码或凭据'",
  '测试家庭存储连接'
];

for (const token of requiredSettingsTokens) {
  if (!settingsPageSource.includes(token)) {
    failed = true;
    console.error(`ReviewSettingsPage missing SMB token: ${token}`);
  }
}

if (!homeStoragePageSource.includes('this.homeStorageRemoteDirectory = homeStorageSettings.remoteDirectory;') ||
  !settingsPageSource.includes('this.homeStorageRemoteDirectory = homeStorageSettings.remoteDirectory;') ||
  !homeStoragePageSource.includes('remoteDirectory: this.homeStorageRemoteDirectory') ||
  !settingsPageSource.includes('remoteDirectory: this.homeStorageRemoteDirectory')) {
  failed = true;
  console.error('SMB settings pages must load, save, and render the optional target path.');
}

if (!homeStoragePageSource.includes('onPageShow(): void {') ||
  !homeStoragePageSource.includes('this.loadSettings();') ||
  !settingsPageSource.includes('onPageShow(): void {') ||
  !settingsPageSource.includes('this.loadSettings();') ||
  !syncCenterPageSource.includes('onPageShow(): void {') ||
  !syncCenterPageSource.includes('this.loadSettings();')) {
  failed = true;
  console.error('SMB settings and status pages must reload persisted values whenever the page is shown again.');
}

if (!syncCenterPageSource.includes("this.InfoRow('保存位置'") || !syncCenterPageSource.includes("'共享根目录'")) {
  failed = true;
  console.error('SyncCenterPage must show the simplified share-root upload location.');
}

const requiredHomeStorageTokens = [
  "const DEFAULT_REMOTE_DIRECTORY: string = '';",
  'HomeStorageSecretService.savePassword(normalized.password)',
  "return '请先填写 SMB 地址或 IP';",
  "return '请先填写共享目录';",
  "message: '家庭存储连接成功'",
  "message: 'review.json 已上传到家庭存储'",
  "message: 'review.json 已上传到家庭存储（已自动保存到共享根目录）'",
  'let passwordSavedSecurely: boolean = false;',
  'await store.put(LEGACY_PASSWORD_KEY, normalized.password);',
  'private static async loadSettingsSnapshot(store: preferences.Preferences): Promise<HomeStorageSettings | null> {',
  'await store.put(SETTINGS_SNAPSHOT_KEY, HomeStorageService.createSettingsSnapshot(normalized));',
  "isMissingRemoteDirectoryError(primaryResult.message)"
];

for (const token of requiredHomeStorageTokens) {
  if (!homeStorageSource.includes(token)) {
    failed = true;
    console.error(`HomeStorageService missing token: ${token}`);
  }
}

const requiredSecretTokens = [
  "const HOME_STORAGE_PASSWORD_ALIAS: string = 'skymap.home_storage.password';",
  'asset.add(attributes)',
  'asset.remove(createPasswordQuery())'
];

for (const token of requiredSecretTokens) {
  if (!secretServiceSource.includes(token)) {
    failed = true;
    console.error(`HomeStorageSecretService missing token: ${token}`);
  }
}

const requiredSmbTokens = [
  "return 'SMB 认证失败，请检查用户名和密码';",
  "return 'SMB 共享目录不存在，请检查共享目录';",
  "return 'SMB 目标路径不存在，请先在家庭存储中创建目录';",
  'await this.ensureRemoteDirectory(options.remoteDirectory);',
  'private async createDirectory(remotePath: string): Promise<Array<number>>',
  'writeUInt32LE(body, 40, 0x00000021);',
  'async uploadText(options: Smb2UploadOptions): Promise<string>'
];

for (const token of requiredSmbTokens) {
  if (!smbClientSource.includes(token)) {
    failed = true;
    console.error(`Smb2Client missing token: ${token}`);
  }
}

if (!moduleSource.includes('"ohos.permission.INTERNET"')) {
  failed = true;
  console.error('module.json5 missing INTERNET permission.');
}

if (failed) {
  process.exit(1);
}

console.log('smb storage: settings, upload entry, secret storage, smb client, and permission present');
