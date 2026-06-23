import fs from 'node:fs';

const serviceSource = fs.readFileSync('entry/src/main/ets/services/HomeStorageService.ets', 'utf8');

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

const requiredMarkers = [
  'export enum HomeStorageConfigStatus',
  'static getConfigurationStatus(settings: HomeStorageSettings): HomeStorageConfigStatus',
  "return '已配置';",
  "return '待完善';",
  "return '未配置';",
  "return '可用';",
  "return '请先填写目标路径';",
  "return '请先填写用户名';",
  "return '请先填写密码或凭据';"
];

for (const marker of requiredMarkers) {
  if (!serviceSource.includes(marker)) {
    fail(`HomeStorageService missing marker: ${marker}`);
  }
}

function normalizeText(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function normalizeRemoteDirectory(value) {
  const trimmed = normalizeText(value);
  if (trimmed.length === 0) {
    return '';
  }
  return trimmed.replace(/^\/+/g, '').replace(/\/+$/g, '');
}

function normalizeSmbPort(value) {
  const trimmed = normalizeText(value);
  if (trimmed.length === 0) {
    return '445';
  }
  return trimmed;
}

function parsePort(value) {
  const port = Number.parseInt(value, 10);
  if (Number.isNaN(port)) {
    return 0;
  }
  return port;
}

function normalizeSettings(settings) {
  return {
    username: normalizeText(settings.username),
    password: normalizeText(settings.password),
    remoteDirectory: normalizeRemoteDirectory(settings.remoteDirectory),
    smbHost: normalizeText(settings.smbHost),
    smbPort: normalizeSmbPort(settings.smbPort),
    smbShareName: normalizeText(settings.smbShareName),
    smbDomain: normalizeText(settings.smbDomain)
  };
}

const HomeStorageConfigStatus = {
  EMPTY: 'empty',
  PARTIAL: 'partial',
  COMPLETE: 'complete'
};

function getConfigurationStatus(settings) {
  const normalized = normalizeSettings(settings);
  const hasHost = normalized.smbHost.length > 0;
  const hasValidPort = parsePort(normalized.smbPort) > 0 && parsePort(normalized.smbPort) <= 65535;
  const hasShareName = normalized.smbShareName.length > 0;
  const hasRemoteDirectory = normalized.remoteDirectory.length > 0;
  const hasUsername = normalized.username.length > 0;
  const hasPassword = normalized.password.length > 0;
  const meaningfulCount = [
    hasHost,
    hasShareName,
    hasRemoteDirectory,
    hasUsername,
    hasPassword
  ].filter(Boolean).length;

  if (meaningfulCount === 0 && (normalized.smbPort.length === 0 || normalized.smbPort === '445')) {
    return HomeStorageConfigStatus.EMPTY;
  }

  if (hasHost && hasValidPort && hasShareName && hasRemoteDirectory && hasUsername && hasPassword) {
    return HomeStorageConfigStatus.COMPLETE;
  }

  return HomeStorageConfigStatus.PARTIAL;
}

function validateSettings(settings) {
  const normalized = normalizeSettings(settings);
  const port = parsePort(normalized.smbPort);
  if (normalized.smbHost.length === 0) {
    return '请先填写 SMB 地址或 IP';
  }
  if (port <= 0 || port > 65535) {
    return 'SMB 端口需要在 1-65535 之间';
  }
  if (normalized.smbShareName.length === 0) {
    return '请先填写共享目录';
  }
  if (normalized.remoteDirectory.length === 0) {
    return '请先填写目标路径';
  }
  if (normalized.username.length === 0) {
    return '请先填写用户名';
  }
  if (normalized.password.length === 0) {
    return '请先填写密码或凭据';
  }
  return '';
}

function expectEqual(actual, expected, message) {
  if (actual !== expected) {
    fail(`${message}: expected=${expected} actual=${actual}`);
  }
}

const emptySettings = {
  username: '',
  password: '',
  remoteDirectory: '',
  smbHost: '',
  smbPort: '445',
  smbShareName: '',
  smbDomain: ''
};

const partialSettings = {
  username: 'user',
  password: '',
  remoteDirectory: 'reviews',
  smbHost: '192.168.3.29',
  smbPort: '445',
  smbShareName: '',
  smbDomain: ''
};

const completeSettings = {
  username: 'user',
  password: 'secret',
  remoteDirectory: 'reviews',
  smbHost: '192.168.3.29',
  smbPort: '445',
  smbShareName: 'photos',
  smbDomain: ''
};

expectEqual(getConfigurationStatus(emptySettings), HomeStorageConfigStatus.EMPTY, 'Empty settings should be 未配置');
expectEqual(getConfigurationStatus(partialSettings), HomeStorageConfigStatus.PARTIAL, 'Partial settings should be 待完善');
expectEqual(getConfigurationStatus(completeSettings), HomeStorageConfigStatus.COMPLETE, 'Complete settings should be 已配置');

expectEqual(validateSettings(emptySettings), '请先填写 SMB 地址或 IP', 'Empty validation should start from host');
expectEqual(validateSettings({
  ...completeSettings,
  remoteDirectory: ''
}), '请先填写目标路径', 'Missing target path must block configuration');
expectEqual(validateSettings({
  ...completeSettings,
  username: ''
}), '请先填写用户名', 'Missing username must block configuration');
expectEqual(validateSettings({
  ...completeSettings,
  password: ''
}), '请先填写密码或凭据', 'Missing password must block configuration');
expectEqual(validateSettings(completeSettings), '', 'Complete settings should validate');

expectEqual(getConfigurationStatus(emptySettings), HomeStorageConfigStatus.EMPTY, 'Cleared settings should return 未配置');

if (failed) {
  process.exit(1);
}

console.log('home storage status: empty/partial/complete/cleared verified');
