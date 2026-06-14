import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import {
  resolveReviewCardExchangeReviewJsonFileName,
  stringifyReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';
import { HomeStorageSecretService } from './HomeStorageSecretService';
import { Smb2Client, Smb2UploadOptions } from './Smb2Client';

const PREFERENCES_NAME: string = 'home_storage_settings';
const USERNAME_KEY: string = 'username';
const LEGACY_PASSWORD_KEY: string = 'password';
const SETTINGS_SNAPSHOT_KEY: string = 'settings_snapshot';
const REMOTE_DIRECTORY_KEY: string = 'remote_directory';
const SMB_HOST_KEY: string = 'smb_host';
const SMB_PORT_KEY: string = 'smb_port';
const SMB_SHARE_NAME_KEY: string = 'smb_share_name';
const SMB_DOMAIN_KEY: string = 'smb_domain';
const LAST_UPLOADED_AT_KEY: string = 'last_uploaded_at';
const DEFAULT_REMOTE_DIRECTORY: string = '';
const DEFAULT_SMB_PORT: string = '445';

export interface HomeStorageSettings {
  username: string;
  password: string;
  remoteDirectory: string;
  smbHost: string;
  smbPort: string;
  smbShareName: string;
  smbDomain: string;
}

export interface HomeStorageOperationResult {
  success: boolean;
  remotePath: string;
  message: string;
}

interface ParsedSmbAddress {
  host: string;
  shareName: string;
  remoteDirectory: string;
}

function normalizeText(value: string | undefined): string {
  if (typeof value === 'string') {
    return value.trim();
  }
  return '';
}

function normalizeRemoteDirectory(value: string | undefined): string {
  const trimmed: string = normalizeText(value);
  if (trimmed.length === 0) {
    return '';
  }
  return trimmed.replace(/^\/+/g, '').replace(/\/+$/g, '');
}

function normalizeSmbPort(value: string | undefined): string {
  const trimmed: string = normalizeText(value);
  if (trimmed.length === 0) {
    return DEFAULT_SMB_PORT;
  }
  return trimmed;
}

function parseSmbAddress(rawHost: string | undefined): ParsedSmbAddress {
  const withoutScheme: string = normalizeText(rawHost).replace(/^smb:\/\//i, '').replace(/\\/g, '/');
  const parts: Array<string> = withoutScheme
    .split('/')
    .map((part: string): string => part.trim())
    .filter((part: string): boolean => part.length > 0);

  if (parts.length === 0) {
    return {
      host: '',
      shareName: '',
      remoteDirectory: ''
    };
  }

  return {
    host: parts[0],
    shareName: parts.length > 1 ? parts[1] : '',
    remoteDirectory: parts.length > 2 ? parts.slice(2).join('/') : ''
  };
}

function normalizeSettings(settings: HomeStorageSettings | undefined): HomeStorageSettings {
  const source: HomeStorageSettings = settings ? settings : {} as HomeStorageSettings;
  const parsedAddress: ParsedSmbAddress = parseSmbAddress(source.smbHost);
  const sourceShareName: string = normalizeText(source.smbShareName).replace(/^\/+/g, '').replace(/\/+$/g, '');
  const sourceRemoteDirectory: string = normalizeText(source.remoteDirectory);
  const remoteDirectory: string = sourceRemoteDirectory.length > 0 ? sourceRemoteDirectory : parsedAddress.remoteDirectory;
  return {
    username: normalizeText(source.username),
    password: normalizeText(source.password),
    remoteDirectory: normalizeRemoteDirectory(remoteDirectory),
    smbHost: parsedAddress.host,
    smbPort: normalizeSmbPort(source.smbPort),
    smbShareName: sourceShareName.length > 0 ? sourceShareName : parsedAddress.shareName,
    smbDomain: normalizeText(source.smbDomain)
  };
}

function parsePort(value: string): number {
  const port: number = Number.parseInt(value, 10);
  if (Number.isNaN(port)) {
    return 0;
  }
  return port;
}

function createSmbUploadOptions(settings: HomeStorageSettings, fileName: string, body: string): Smb2UploadOptions {
  return {
    host: settings.smbHost,
    port: parsePort(settings.smbPort),
    shareName: settings.smbShareName,
    remoteDirectory: settings.remoteDirectory,
    username: settings.username,
    password: settings.password,
    domain: settings.smbDomain,
    fileName: fileName,
    content: body
  };
}

function resolveRemotePathText(settings: HomeStorageSettings, remoteDirectory: string, fileName: string): string {
  const directory: string = normalizeRemoteDirectory(remoteDirectory).replace(/\//g, '\\');
  const basePath: string = `\\\\${settings.smbHost}\\${settings.smbShareName}`;
  return directory.length > 0 ? `${basePath}\\${directory}\\${fileName}` : `${basePath}\\${fileName}`;
}

function isMissingRemoteDirectoryError(message: string): boolean {
  return message.indexOf('SMB 目标路径不存在') >= 0;
}

async function uploadReviewJsonBySmb(
  settings: HomeStorageSettings,
  fileName: string,
  body: string,
  remoteDirectory: string = settings.remoteDirectory
): Promise<HomeStorageOperationResult> {
  const client: Smb2Client = new Smb2Client();
  try {
    const nextSettings: HomeStorageSettings = {
      username: settings.username,
      password: settings.password,
      remoteDirectory: remoteDirectory,
      smbHost: settings.smbHost,
      smbPort: settings.smbPort,
      smbShareName: settings.smbShareName,
      smbDomain: settings.smbDomain
    };
    const remotePath: string = await client.uploadText(createSmbUploadOptions(nextSettings, fileName, body));
    return {
      success: true,
      remotePath: remotePath,
      message: 'review.json 已上传到家庭存储'
    };
  } catch (error) {
    const message: string = error instanceof Error ? error.message : '上传家庭存储失败，请检查网络、账号和目录';
    return {
      success: false,
      remotePath: resolveRemotePathText(settings, remoteDirectory, fileName),
      message: message
    };
  } finally {
    await client.close();
  }
}

async function safeGetString(
  store: preferences.Preferences,
  key: string,
  fallback: string
): Promise<string> {
  try {
    const value = await store.get(key, fallback);
    return typeof value === 'string' ? value : fallback;
  } catch (error) {
    return fallback;
  }
}

export class HomeStorageService {
  private static cachedSettings: HomeStorageSettings = {
    username: '',
    password: '',
    remoteDirectory: DEFAULT_REMOTE_DIRECTORY,
    smbHost: '',
    smbPort: DEFAULT_SMB_PORT,
    smbShareName: '',
    smbDomain: ''
  };
  private static hasCachedSettings: boolean = false;

  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return preferences.getPreferences(context, { name: PREFERENCES_NAME });
  }

  private static async clearLegacyPassword(store: preferences.Preferences): Promise<void> {
    try {
      await store.delete(LEGACY_PASSWORD_KEY);
    } catch (error) {
    }
  }

  private static async migrateLegacyPassword(store: preferences.Preferences): Promise<string> {
    const legacyPassword = await store.get(LEGACY_PASSWORD_KEY, '');
    if (typeof legacyPassword !== 'string' || legacyPassword.length === 0) {
      return '';
    }

    try {
      await HomeStorageSecretService.savePassword(legacyPassword);
      await HomeStorageService.clearLegacyPassword(store);
      await store.flush();
      return legacyPassword;
    } catch (error) {
      return legacyPassword;
    }
  }

  static defaultSettings(): HomeStorageSettings {
    return {
      username: '',
      password: '',
      remoteDirectory: '',
      smbHost: '',
      smbPort: DEFAULT_SMB_PORT,
      smbShareName: '',
      smbDomain: ''
    };
  }

  private static rememberSettings(settings: HomeStorageSettings): HomeStorageSettings {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    HomeStorageService.cachedSettings = normalized;
    HomeStorageService.hasCachedSettings = true;
    return normalized;
  }

  private static currentCachedSettings(): HomeStorageSettings {
    if (HomeStorageService.hasCachedSettings) {
      return normalizeSettings(HomeStorageService.cachedSettings);
    }
    return HomeStorageService.defaultSettings();
  }

  private static async loadSettingsSnapshot(store: preferences.Preferences): Promise<HomeStorageSettings | null> {
    const rawSnapshot = await safeGetString(store, SETTINGS_SNAPSHOT_KEY, '');
    if (typeof rawSnapshot !== 'string' || rawSnapshot.length === 0) {
      return null;
    }

    try {
      const parsedSnapshot = JSON.parse(rawSnapshot) as HomeStorageSettings;
      return normalizeSettings(parsedSnapshot);
    } catch (error) {
      return null;
    }
  }

  private static createSettingsSnapshot(settings: HomeStorageSettings): string {
    return JSON.stringify({
      username: settings.username,
      password: '',
      remoteDirectory: settings.remoteDirectory,
      smbHost: settings.smbHost,
      smbPort: settings.smbPort,
      smbShareName: settings.smbShareName,
      smbDomain: settings.smbDomain
    });
  }

  private static async loadStoredPassword(store: preferences.Preferences): Promise<string> {
    let password = '';
    try {
      password = await HomeStorageSecretService.loadPassword();
    } catch (error) {
      password = '';
    }
    if (password.length === 0) {
      password = await HomeStorageService.migrateLegacyPassword(store);
    }
    return password;
  }

  private static async loadLegacySettings(store: preferences.Preferences): Promise<HomeStorageSettings | null> {
    const username = await safeGetString(store, USERNAME_KEY, '');
    const password = await HomeStorageService.loadStoredPassword(store);
    const remoteDirectory = await safeGetString(store, REMOTE_DIRECTORY_KEY, DEFAULT_REMOTE_DIRECTORY);
    const smbHost = await safeGetString(store, SMB_HOST_KEY, '');
    const smbPort = await safeGetString(store, SMB_PORT_KEY, DEFAULT_SMB_PORT);
    const smbShareName = await safeGetString(store, SMB_SHARE_NAME_KEY, '');
    const smbDomain = await safeGetString(store, SMB_DOMAIN_KEY, '');

    return normalizeSettings({
      username: typeof username === 'string' ? username : '',
      password: password,
      remoteDirectory: typeof remoteDirectory === 'string' ? remoteDirectory : DEFAULT_REMOTE_DIRECTORY,
      smbHost: typeof smbHost === 'string' ? smbHost : '',
      smbPort: typeof smbPort === 'string' ? smbPort : DEFAULT_SMB_PORT,
      smbShareName: typeof smbShareName === 'string' ? smbShareName : '',
      smbDomain: typeof smbDomain === 'string' ? smbDomain : ''
    });
  }

  static async loadSettings(context: common.UIAbilityContext): Promise<HomeStorageSettings> {
    try {
      const store = await HomeStorageService.getStore(context);
      const snapshotSettings = await HomeStorageService.loadSettingsSnapshot(store);
      if (snapshotSettings !== null) {
        snapshotSettings.password = await HomeStorageService.loadStoredPassword(store);
        return HomeStorageService.rememberSettings(snapshotSettings);
      }

      const legacySettings = await HomeStorageService.loadLegacySettings(store);
      if (legacySettings !== null) {
        return HomeStorageService.rememberSettings(legacySettings);
      }

      return HomeStorageService.currentCachedSettings();
    } catch (error) {
      return HomeStorageService.currentCachedSettings();
    }
  }

  static async saveSettings(
    context: common.UIAbilityContext,
    settings: HomeStorageSettings
  ): Promise<HomeStorageSettings> {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    const store = await HomeStorageService.getStore(context);
    await store.put(USERNAME_KEY, normalized.username);
    await store.put(REMOTE_DIRECTORY_KEY, normalized.remoteDirectory);
    await store.put(SMB_HOST_KEY, normalized.smbHost);
    await store.put(SMB_PORT_KEY, normalized.smbPort);
    await store.put(SMB_SHARE_NAME_KEY, normalized.smbShareName);
    await store.put(SMB_DOMAIN_KEY, normalized.smbDomain);

    let passwordSavedSecurely: boolean = false;
    try {
      await HomeStorageSecretService.savePassword(normalized.password);
      passwordSavedSecurely = true;
    } catch (error) {
      passwordSavedSecurely = false;
    }
    if (passwordSavedSecurely || normalized.password.length === 0) {
      await HomeStorageService.clearLegacyPassword(store);
    } else {
      await store.put(LEGACY_PASSWORD_KEY, normalized.password);
    }

    await store.put(SETTINGS_SNAPSHOT_KEY, HomeStorageService.createSettingsSnapshot(normalized));
    await store.flush();
    return HomeStorageService.rememberSettings(normalized);
  }

  static async loadLastUploadedAt(context: common.UIAbilityContext): Promise<number> {
    try {
      const store = await HomeStorageService.getStore(context);
      const value = await store.get(LAST_UPLOADED_AT_KEY, 0);
      return typeof value === 'number' && Number.isFinite(value) && value > 0 ? value : 0;
    } catch (error) {
      return 0;
    }
  }

  private static async markLastUploadedAt(context: common.UIAbilityContext, timestamp: number): Promise<void> {
    const store = await HomeStorageService.getStore(context);
    await store.put(LAST_UPLOADED_AT_KEY, timestamp);
    await store.flush();
  }

  static validateSettings(settings: HomeStorageSettings): string {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    const port: number = parsePort(normalized.smbPort);
    if (normalized.smbHost.length === 0) {
      return '请先填写 SMB 地址或 IP';
    }
    if (port <= 0 || port > 65535) {
      return 'SMB 端口需要在 1-65535 之间';
    }
    if (normalized.smbShareName.length === 0) {
      return '请先填写共享目录';
    }
    return '';
  }

  static async testConnection(settings: HomeStorageSettings): Promise<HomeStorageOperationResult> {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    const validationMessage: string = HomeStorageService.validateSettings(normalized);
    if (validationMessage.length > 0) {
      return {
        success: false,
        remotePath: '',
        message: validationMessage
      };
    }

    const client: Smb2Client = new Smb2Client();
    try {
      await client.testConnection(createSmbUploadOptions(normalized, 'connection-test.review.json', '{}'));
      return {
        success: true,
        remotePath: `\\\\${normalized.smbHost}\\${normalized.smbShareName}`,
        message: '家庭存储连接成功'
      };
    } catch (error) {
      await client.close();
      return {
        success: false,
        remotePath: `\\\\${normalized.smbHost}\\${normalized.smbShareName}`,
        message: error instanceof Error ? error.message : '家庭存储连接失败，请检查地址、账号和共享目录'
      };
    }
  }

  static async uploadReviewJson(
    context: common.UIAbilityContext,
    document: ReviewCardDocument,
    reviewerText: string = ''
  ): Promise<HomeStorageOperationResult> {
    const settings: HomeStorageSettings = await HomeStorageService.loadSettings(context);
    const validationMessage: string = HomeStorageService.validateSettings(settings);
    if (validationMessage.length > 0) {
      return {
        success: false,
        remotePath: '',
        message: validationMessage
      };
    }

    const fileName: string = resolveReviewCardExchangeReviewJsonFileName(document);
    const body: string = stringifyReviewCardExchangeSchemaV1(document, reviewerText);
    const primaryResult: HomeStorageOperationResult = await uploadReviewJsonBySmb(settings, fileName, body);
    if (primaryResult.success) {
      await HomeStorageService.markLastUploadedAt(context, Date.now());
      return primaryResult;
    }

    if (settings.remoteDirectory.length > 0 && isMissingRemoteDirectoryError(primaryResult.message)) {
      const fallbackResult: HomeStorageOperationResult = await uploadReviewJsonBySmb(settings, fileName, body, '');
      if (fallbackResult.success) {
        await HomeStorageService.markLastUploadedAt(context, Date.now());
        return {
          success: true,
          remotePath: fallbackResult.remotePath,
          message: 'review.json 已上传到家庭存储（已自动保存到共享根目录）'
        };
      }
    }

    return primaryResult;
  }
}
