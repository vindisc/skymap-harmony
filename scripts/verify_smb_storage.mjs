import fs from 'node:fs';

const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const settingsPageSource = fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8');
const homeStoragePageSource = fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8');
const syncCenterPageSource = fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8');
const settingsFormSource = fs.readFileSync('entry/src/main/ets/components/SettingsForm.ets', 'utf8');
const homeStorageSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');
const secretServiceSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageSecretService.ets', 'utf8');
const smbClientSource = fs.readFileSync('entry/src/main/ets/services/Smb2Client.ets', 'utf8');
const moduleSource = fs.readFileSync('entry/src/main/module.json5', 'utf8');

let failed = false;

const forbiddenPreviewTokens = [
  "this.ExportSheetAction(this.isUploadingHomeStorage ? '上传中...' : '上传家庭存储'",
  'private async uploadReviewJsonToHomeStorage(): Promise<void>',
  'HomeStorageService.uploadReviewJson(',
  "this.ExportSheetAction('导出 JSON'"
];

for (const token of forbiddenPreviewTokens) {
  if (previewPageSource.includes(token)) {
    failed = true;
    console.error(`PreviewPage must not expose retired SMB token: ${token}`);
  }
}

const requiredSettingsTokens = [
  "Text('家庭存储')",
  'getRouter().pushUrl({ url: HOME_STORAGE_PAGE })',
  "Text('家庭存储')"
];

for (const token of requiredSettingsTokens) {
  if (!settingsPageSource.includes(token)) {
    failed = true;
    console.error(`ReviewSettingsPage missing home-storage link token: ${token}`);
  }
}

const forbiddenSettingsTokens = [
  "SettingsInput('SMB 地址或 IP'",
  "SettingsInput('共享目录'",
  "SettingsInput('目标路径'",
  "SettingsInput('用户名'",
  "SettingsInput('密码'",
  'HomeStorageService.saveSettings',
  'testHomeStorage',
  'homeStorageRemoteDirectory'
];

for (const token of forbiddenSettingsTokens) {
  if (settingsPageSource.includes(token)) {
    failed = true;
    console.error(`ReviewSettingsPage must not own SMB form state anymore: ${token}`);
  }
}

const requiredHomeStoragePageTokens = [
  "SettingsInput('家庭存储地址'",
  "SettingsInput('共享目录'",
  "SettingsInput('目标路径'",
  "SettingsInput('用户名'",
  "SettingsInput('密码'",
  '检查'
];

for (const token of requiredHomeStoragePageTokens) {
  if (!homeStoragePageSource.includes(token)) {
    failed = true;
    console.error(`HomeStoragePage missing SMB form token: ${token}`);
  }
}

if (!homeStoragePageSource.includes('this.homeStorageRemoteDirectory = homeStorageSettings.remoteDirectory;') ||
  !homeStoragePageSource.includes('remoteDirectory: this.homeStorageRemoteDirectory')) {
  failed = true;
  console.error('HomeStoragePage must load, save, and render the optional target path.');
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

if (!settingsFormSource.includes('.onChange((value: string) => {') ||
  !settingsFormSource.includes('this.onChange(value);') ||
  !settingsFormSource.includes('@Prop showsPasswordToggle: boolean = false;') ||
  !settingsFormSource.includes('this.isPasswordVisible ?') ||
  !homeStoragePageSource.includes('SettingsTextInput({') ||
  !settingsPageSource.includes('SettingsTextInput({')) {
  failed = true;
  console.error('Settings inputs must forward TextInput changes back into component state.');
}

if (!homeStoragePageSource.includes('InputType.Number') ||
  !homeStoragePageSource.includes('this.sanitizePort(value)') ||
  !homeStoragePageSource.includes('showsPasswordToggle: showsPasswordToggle') ||
  !homeStoragePageSource.includes('CenterFeedbackOverlay()') ||
  !homeStoragePageSource.includes('this.setActionFeedback(result.message, result.success ?') ||
  !homeStoragePageSource.includes('this.clearActionFeedback();')) {
  failed = true;
  console.error('HomeStoragePage must provide numeric port input, password visibility, centered operation feedback, and stale-feedback clearing.');
}

if (homeStoragePageSource.includes("SettingsInput('工作组或域'") ||
  homeStoragePageSource.includes('StatusSummary()') ||
  homeStoragePageSource.includes('ToastService.show(this.getUIContext(), result.message)')) {
  failed = true;
  console.error('HomeStoragePage must hide workgroup/domain, remove status summary, and avoid duplicate toast feedback.');
}

if (!homeStoragePageSource.includes('@State isSettingsLoaded: boolean = false;') ||
  !homeStoragePageSource.includes('this.isSettingsLoaded = false;') ||
  !homeStoragePageSource.includes('this.isSettingsLoaded = true;') ||
  !homeStoragePageSource.includes('if (this.isSettingsLoaded) {') ||
  !homeStoragePageSource.includes("Text('读取中'") ||
  !settingsPageSource.includes('@State isSettingsLoaded: boolean = false;') ||
  !settingsPageSource.includes('this.isSettingsLoaded = false;') ||
  !settingsPageSource.includes('this.isSettingsLoaded = true;') ||
  !settingsPageSource.includes('if (this.isSettingsLoaded) {') ||
  !settingsPageSource.includes("Text('正在读取设置'")) {
  failed = true;
  console.error('Settings inputs must mount only after persisted values are loaded, so TextInput can display saved values.');
}

if (!syncCenterPageSource.includes("this.InfoRow('保存位置'") || !syncCenterPageSource.includes("'共享根目录'")) {
  failed = true;
  console.error('SyncCenterPage must show the simplified share-root upload location.');
}

const requiredHomeStorageTokens = [
  "const DEFAULT_REMOTE_DIRECTORY: string = '';",
  'HomeStorageSecretService.savePassword(normalized.password)',
  "return '请先填写家庭存储地址';",
  "return '请先填写共享目录';",
  "return '请先填写密码';",
  "createOperationResult(true, `\\\\\\\\${normalized.smbHost}\\\\${normalized.smbShareName}`, '家庭存储连接成功')",
  "createOperationResult(true, remotePath, '已上传家庭存储')",
  "message: '已上传共享根目录'",
  'let passwordSavedSecurely: boolean = false;',
  'await store.put(LEGACY_PASSWORD_KEY, normalized.password);',
  'private static async loadSettingsSnapshot(store: preferences.Preferences): Promise<HomeStorageSettings | null> {',
  'await store.put(SETTINGS_SNAPSHOT_KEY, HomeStorageService.createSettingsSnapshot(normalized));',
  "isMissingRemoteDirectoryError(primaryResult.message)",
  'client.uploadFile(createSmbUploadFileOptions('
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
  'async uploadText(options: Smb2UploadOptions): Promise<string>',
  'async uploadFile(options: Smb2UploadFileOptions): Promise<string>',
  'private async writeFileFromPath(fileId: Array<number>, localPath: string, byteSize: number): Promise<void>'
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
