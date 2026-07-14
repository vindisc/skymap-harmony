import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import fs from '@ohos.file.fs';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import {
  resolveReviewCardExchangeReviewJsonFileName,
  stringifyReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';
import { HomeStorageSecretService } from './HomeStorageSecretService';
import { Smb2Client, Smb2UploadBytesOptions, Smb2UploadFileOptions, Smb2UploadOptions } from './Smb2Client';
import { SettingsRefreshService } from './SettingsRefreshService';

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
  errorType: HomeStorageErrorType;
}

export interface HomeStorageUploadFileEntry {
  localPath: string;
  remoteRelativePath: string;
}

export enum HomeStorageConfigStatus {
  EMPTY = 'empty',
  PARTIAL = 'partial',
  COMPLETE = 'complete'
}

export enum HomeStorageErrorType {
  NONE = 'none',
  NOT_CONFIGURED = 'notConfigured',
  INCOMPLETE_CONFIG = 'incompleteConfig',
  UNREACHABLE = 'unreachable',
  AUTH_FAILED = 'authFailed',
  DIRECTORY_CREATE_FAILED = 'directoryCreateFailed',
  ORIGINAL_READ_FAILED = 'originalReadFailed',
  ORIGINAL_COPY_FAILED = 'originalCopyFailed',
  LOCAL_BUNDLE_VALIDATION_FAILED = 'localBundleValidationFailed',
  UPLOAD_FAILED = 'uploadFailed',
  UNKNOWN = 'unknown'
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

function createSmbUploadBytesOptions(
  settings: HomeStorageSettings,
  remoteDirectory: string,
  fileName: string,
  contentBytes: Array<number>
): Smb2UploadBytesOptions {
  return {
    host: settings.smbHost,
    port: parsePort(settings.smbPort),
    shareName: settings.smbShareName,
    remoteDirectory: remoteDirectory,
    username: settings.username,
    password: settings.password,
    domain: settings.smbDomain,
    fileName: fileName,
    contentBytes: contentBytes
  };
}

function createSmbUploadFileOptions(
  settings: HomeStorageSettings,
  remoteDirectory: string,
  fileName: string,
  localPath: string
): Smb2UploadFileOptions {
  return {
    host: settings.smbHost,
    port: parsePort(settings.smbPort),
    shareName: settings.smbShareName,
    remoteDirectory: remoteDirectory,
    username: settings.username,
    password: settings.password,
    domain: settings.smbDomain,
    fileName: fileName,
    localPath: localPath
  };
}

function resolveRemotePathText(settings: HomeStorageSettings, remoteDirectory: string, fileName: string): string {
  const directory: string = normalizeRemoteDirectory(remoteDirectory).replace(/\//g, '\\');
  const basePath: string = `\\\\${settings.smbHost}\\${settings.smbShareName}`;
  return directory.length > 0 ? `${basePath}\\${directory}\\${fileName}` : `${basePath}\\${fileName}`;
}

function joinRemotePath(left: string, right: string): string {
  const normalizedLeft: string = normalizeRemoteDirectory(left);
  const normalizedRight: string = normalizeRemoteDirectory(right);
  if (normalizedLeft.length === 0) {
    return normalizedRight;
  }
  if (normalizedRight.length === 0) {
    return normalizedLeft;
  }
  return `${normalizedLeft}/${normalizedRight}`;
}

function splitRemoteRelativePath(value: string): Array<string> {
  return normalizeRemoteDirectory(value)
    .split('/')
    .map((part: string): string => part.trim())
    .filter((part: string): boolean => part.length > 0);
}

function isMissingRemoteDirectoryError(message: string): boolean {
  return message.indexOf('SMB 目标路径不存在') >= 0;
}

function resolveHomeStorageErrorMessage(errorType: HomeStorageErrorType): string {
  if (errorType === HomeStorageErrorType.NOT_CONFIGURED) {
    return '请先配置家庭存储';
  }
  if (errorType === HomeStorageErrorType.INCOMPLETE_CONFIG) {
    return '家庭存储配置不完整，请检查设置';
  }
  if (errorType === HomeStorageErrorType.UNREACHABLE) {
    return '无法连接家庭存储。请连接家庭 Wi-Fi 或 VPN 后重试。';
  }
  if (errorType === HomeStorageErrorType.AUTH_FAILED) {
    return '家庭存储账号或密码不正确，请检查设置';
  }
  if (errorType === HomeStorageErrorType.DIRECTORY_CREATE_FAILED) {
    return '家庭存储目录创建失败，请稍后重试';
  }
  if (errorType === HomeStorageErrorType.ORIGINAL_READ_FAILED) {
    return '原始照片无法读取，请重新导入。';
  }
  if (errorType === HomeStorageErrorType.ORIGINAL_COPY_FAILED) {
    return '原始照片保存失败，请重试。';
  }
  if (errorType === HomeStorageErrorType.LOCAL_BUNDLE_VALIDATION_FAILED) {
    return '含原图复盘包导出失败，请重试。';
  }
  if (errorType === HomeStorageErrorType.UPLOAD_FAILED) {
    return '复盘包导出失败，请重试';
  }
  if (errorType === HomeStorageErrorType.UNKNOWN) {
    return '家庭存储暂时不可用，请稍后重试';
  }
  return '';
}

function classifyHomeStorageError(message: string, fallback: HomeStorageErrorType): HomeStorageErrorType {
  const normalized: string = message.toLowerCase();
  if (message.indexOf('SMB 认证失败') >= 0 ||
    message.indexOf('用户名和密码') >= 0 ||
    message.indexOf('认证协商失败') >= 0 ||
    message.indexOf('认证响应异常') >= 0 ||
    normalized.indexOf('access denied') >= 0 ||
    normalized.indexOf('logon failure') >= 0 ||
    normalized.indexOf('0xc000006d') >= 0 ||
    normalized.indexOf('0xc0000022') >= 0) {
    return HomeStorageErrorType.AUTH_FAILED;
  }
  if (message.indexOf('响应超时') >= 0 ||
    message.indexOf('连接异常') >= 0 ||
    message.indexOf('连接失败') >= 0 ||
    normalized.indexOf('timeout') >= 0 ||
    normalized.indexOf('timed out') >= 0 ||
    normalized.indexOf('network unreachable') >= 0 ||
    normalized.indexOf('host unreachable') >= 0 ||
    normalized.indexOf('no route to host') >= 0 ||
    normalized.indexOf('enetunreach') >= 0 ||
    normalized.indexOf('ehostunreach') >= 0 ||
    normalized.indexOf('econnrefused') >= 0 ||
    normalized.indexOf('econnreset') >= 0 ||
    normalized.indexOf('socket') >= 0) {
    return HomeStorageErrorType.UNREACHABLE;
  }
  if (message.indexOf('创建目录') >= 0 ||
    message.indexOf('目标路径不存在') >= 0 ||
    message.indexOf('共享目录不存在') >= 0 ||
    normalized.indexOf('path not found') >= 0 ||
    normalized.indexOf('object path not found') >= 0) {
    return HomeStorageErrorType.DIRECTORY_CREATE_FAILED;
  }
  if (message.indexOf('文件正在被占用') >= 0 ||
    message.indexOf('写入') >= 0 ||
    message.indexOf('创建文件') >= 0 ||
    normalized.indexOf('upload') >= 0 ||
    normalized.indexOf('write') >= 0) {
    return HomeStorageErrorType.UPLOAD_FAILED;
  }
  return fallback;
}

function normalizeHomeStorageErrorMessage(message: string): string {
  const errorType: HomeStorageErrorType = classifyHomeStorageError(message, HomeStorageErrorType.UNKNOWN);
  return resolveHomeStorageErrorMessage(errorType);
}

function createOperationResult(
  success: boolean,
  remotePath: string,
  message: string,
  errorType: HomeStorageErrorType = HomeStorageErrorType.NONE
): HomeStorageOperationResult {
  return {
    success: success,
    remotePath: remotePath,
    message: message,
    errorType: errorType
  };
}

function createConfigurationFailureResult(settings: HomeStorageSettings): HomeStorageOperationResult {
  const status: HomeStorageConfigStatus = HomeStorageService.getConfigurationStatus(settings);
  if (status === HomeStorageConfigStatus.EMPTY) {
    return createOperationResult(false, '', resolveHomeStorageErrorMessage(HomeStorageErrorType.NOT_CONFIGURED), HomeStorageErrorType.NOT_CONFIGURED);
  }
  return createOperationResult(false, '', resolveHomeStorageErrorMessage(HomeStorageErrorType.INCOMPLETE_CONFIG), HomeStorageErrorType.INCOMPLETE_CONFIG);
}

function createErrorResult(
  settings: HomeStorageSettings,
  remoteDirectory: string,
  fileName: string,
  rawMessage: string,
  fallback: HomeStorageErrorType
): HomeStorageOperationResult {
  const errorType: HomeStorageErrorType = classifyHomeStorageError(rawMessage, fallback);
  return createOperationResult(
    false,
    resolveRemotePathText(settings, remoteDirectory, fileName),
    resolveHomeStorageErrorMessage(errorType),
    errorType
  );
}

function fileSizeText(localPath: string): string {
  try {
    return `${fs.statSync(localPath).size}`;
  } catch (error) {
    return 'unknown';
  }
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
    return createOperationResult(true, remotePath, '已上传家庭存储');
  } catch (error) {
    const rawMessage: string = error instanceof Error ? error.message : `${error}`;
    return createErrorResult(settings, remoteDirectory, fileName, rawMessage, HomeStorageErrorType.UPLOAD_FAILED);
  } finally {
    await client.close();
  }
}

async function uploadFileBySmb(
  settings: HomeStorageSettings,
  localPath: string,
  remoteDirectory: string,
  fileName: string
): Promise<HomeStorageOperationResult> {
  const client: Smb2Client = new Smb2Client();
  const byteSize: string = fileSizeText(localPath);
  console.info(`[HomeStorageService] file_upload_start local=${localPath} remoteDirectory=${remoteDirectory} file=${fileName} bytes=${byteSize}`);
  try {
    const remotePath: string = await client.uploadFile(createSmbUploadFileOptions(
      settings,
      remoteDirectory,
      fileName,
      localPath
    ));
    console.info(`[HomeStorageService] file_upload_success remote=${remotePath} bytes=${byteSize}`);
    return createOperationResult(true, remotePath, '已上传家庭存储');
  } catch (error) {
    const rawMessage: string = error instanceof Error ? error.message : `${error}`;
    const result: HomeStorageOperationResult = createErrorResult(
      settings,
      remoteDirectory,
      fileName,
      rawMessage,
      HomeStorageErrorType.UPLOAD_FAILED
    );
    console.error(`[HomeStorageService] file_upload_failed local=${localPath} remoteDirectory=${remoteDirectory} file=${fileName} bytes=${byteSize} error=${rawMessage} normalized=${result.message}`);
    return result;
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
    try {
      return await preferences.getPreferences(context, { name: PREFERENCES_NAME });
    } catch (error) {
      throw new Error(`打开家庭存储设置失败：${error}`);
    }
  }

  private static async getPreference(
    store: preferences.Preferences,
    key: string,
    fallback: preferences.ValueType
  ): Promise<preferences.ValueType> {
    try {
      return await store.get(key, fallback);
    } catch (error) {
      throw new Error(`读取家庭存储设置 ${key} 失败：${error}`);
    }
  }

  private static async putPreference(
    store: preferences.Preferences,
    key: string,
    value: preferences.ValueType
  ): Promise<void> {
    try {
      await store.put(key, value);
    } catch (error) {
      throw new Error(`保存家庭存储设置 ${key} 失败：${error}`);
    }
  }

  private static async flushPreferences(store: preferences.Preferences): Promise<void> {
    try {
      await store.flush();
    } catch (error) {
      throw new Error(`提交家庭存储设置失败：${error}`);
    }
  }

  private static async clearLegacyPassword(store: preferences.Preferences): Promise<void> {
    try {
      await store.delete(LEGACY_PASSWORD_KEY);
    } catch (error) {
    }
  }

  private static async migrateLegacyPassword(store: preferences.Preferences): Promise<string> {
    const legacyPassword = await HomeStorageService.getPreference(store, LEGACY_PASSWORD_KEY, '');
    if (typeof legacyPassword !== 'string' || legacyPassword.length === 0) {
      return '';
    }

    try {
      await HomeStorageSecretService.savePassword(legacyPassword);
      await HomeStorageService.clearLegacyPassword(store);
      await HomeStorageService.flushPreferences(store);
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
    await HomeStorageService.putPreference(store, USERNAME_KEY, normalized.username);
    await HomeStorageService.putPreference(store, REMOTE_DIRECTORY_KEY, normalized.remoteDirectory);
    await HomeStorageService.putPreference(store, SMB_HOST_KEY, normalized.smbHost);
    await HomeStorageService.putPreference(store, SMB_PORT_KEY, normalized.smbPort);
    await HomeStorageService.putPreference(store, SMB_SHARE_NAME_KEY, normalized.smbShareName);
    await HomeStorageService.putPreference(store, SMB_DOMAIN_KEY, normalized.smbDomain);

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
      await HomeStorageService.putPreference(store, LEGACY_PASSWORD_KEY, normalized.password);
    }

    await HomeStorageService.putPreference(store, SETTINGS_SNAPSHOT_KEY, HomeStorageService.createSettingsSnapshot(normalized));
    await HomeStorageService.flushPreferences(store);
    const savedSettings: HomeStorageSettings = HomeStorageService.rememberSettings(normalized);
    SettingsRefreshService.notifySettingsChanged('home_storage_saved');
    return savedSettings;
  }

  static async verifySavedSettings(context: common.UIAbilityContext): Promise<HomeStorageSettings> {
    return HomeStorageService.loadSettings(context);
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
    await HomeStorageService.putPreference(store, LAST_UPLOADED_AT_KEY, timestamp);
    await HomeStorageService.flushPreferences(store);
  }

  static validateSettings(settings: HomeStorageSettings): string {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    const port: number = parsePort(normalized.smbPort);
    if (normalized.smbHost.length === 0) {
      return '请先填写家庭存储地址';
    }
    if (port <= 0 || port > 65535) {
      return '连接端口需要在 1-65535 之间';
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
      return '请先填写密码';
    }
    return '';
  }

  static getConfigurationStatus(settings: HomeStorageSettings): HomeStorageConfigStatus {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    const hasHost: boolean = normalized.smbHost.length > 0;
    const hasValidPort: boolean = parsePort(normalized.smbPort) > 0 && parsePort(normalized.smbPort) <= 65535;
    const hasShareName: boolean = normalized.smbShareName.length > 0;
    const hasRemoteDirectory: boolean = normalized.remoteDirectory.length > 0;
    const hasUsername: boolean = normalized.username.length > 0;
    const hasPassword: boolean = normalized.password.length > 0;
    const meaningfulCount: number = [
      hasHost,
      hasShareName,
      hasRemoteDirectory,
      hasUsername,
      hasPassword
    ].filter((item: boolean): boolean => item).length;

    if (meaningfulCount === 0 && (normalized.smbPort.length === 0 || normalized.smbPort === DEFAULT_SMB_PORT)) {
      return HomeStorageConfigStatus.EMPTY;
    }

    if (hasHost && hasValidPort && hasShareName && hasRemoteDirectory && hasUsername && hasPassword) {
      return HomeStorageConfigStatus.COMPLETE;
    }

    return HomeStorageConfigStatus.PARTIAL;
  }

  static isConfigured(settings: HomeStorageSettings): boolean {
    return HomeStorageService.getConfigurationStatus(settings) === HomeStorageConfigStatus.COMPLETE;
  }

  static resolveConfigurationStatusLabel(status: HomeStorageConfigStatus): string {
    if (status === HomeStorageConfigStatus.COMPLETE) {
      return '已配置';
    }
    if (status === HomeStorageConfigStatus.PARTIAL) {
      return '待完善';
    }
    return '未配置';
  }

  static resolveEntryStatusLabel(status: HomeStorageConfigStatus): string {
    if (status === HomeStorageConfigStatus.COMPLETE) {
      return '已配置';
    }
    if (status === HomeStorageConfigStatus.PARTIAL) {
      return '待完善';
    }
    return '未配置';
  }

  static resolveAvailabilityLabel(status: HomeStorageConfigStatus): string {
    if (status === HomeStorageConfigStatus.COMPLETE) {
      return '可用';
    }
    if (status === HomeStorageConfigStatus.PARTIAL) {
      return '待完善';
    }
    return '未配置';
  }

  static async testConnection(settings: HomeStorageSettings): Promise<HomeStorageOperationResult> {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    const validationMessage: string = HomeStorageService.validateSettings(normalized);
    if (validationMessage.length > 0) {
      return createConfigurationFailureResult(normalized);
    }

    const client: Smb2Client = new Smb2Client();
    try {
      await client.testConnection(createSmbUploadOptions(normalized, 'connection-test.review.json', '{}'));
      return createOperationResult(true, `\\\\${normalized.smbHost}\\${normalized.smbShareName}`, '家庭存储连接成功');
    } catch (error) {
      await client.close();
      const rawMessage: string = error instanceof Error ? error.message : `${error}`;
      const errorType: HomeStorageErrorType = classifyHomeStorageError(rawMessage, HomeStorageErrorType.UNREACHABLE);
      return createOperationResult(
        false,
        `\\\\${normalized.smbHost}\\${normalized.smbShareName}`,
        resolveHomeStorageErrorMessage(errorType),
        errorType
      );
    }
  }

  static async checkAvailability(context: common.UIAbilityContext): Promise<HomeStorageOperationResult> {
    const settings: HomeStorageSettings = await HomeStorageService.loadSettings(context);
    const validationMessage: string = HomeStorageService.validateSettings(settings);
    console.info(`[HomeStorageService] availability_check status=${HomeStorageService.getConfigurationStatus(settings)} host=${settings.smbHost.length > 0 ? 'set' : 'empty'} share=${settings.smbShareName.length > 0 ? 'set' : 'empty'} remoteDirectory=${settings.remoteDirectory.length > 0 ? settings.remoteDirectory : 'empty'}`);
    if (validationMessage.length > 0) {
      const result: HomeStorageOperationResult = createConfigurationFailureResult(settings);
      console.warn(`[HomeStorageService] availability_config_invalid raw=${validationMessage} message=${result.message}`);
      return result;
    }

    const result: HomeStorageOperationResult = await HomeStorageService.testConnection(settings);
    console.info(`[HomeStorageService] availability_check_finished success=${result.success} type=${result.errorType} message=${result.message}`);
    return result;
  }

  static async uploadReviewJson(
    context: common.UIAbilityContext,
    document: ReviewCardDocument,
    reviewerText: string = ''
  ): Promise<HomeStorageOperationResult> {
    const settings: HomeStorageSettings = await HomeStorageService.loadSettings(context);
    const validationMessage: string = HomeStorageService.validateSettings(settings);
    if (validationMessage.length > 0) {
      return createConfigurationFailureResult(settings);
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
          message: '已上传共享根目录',
          errorType: HomeStorageErrorType.NONE
        };
      }
    }

    return primaryResult;
  }

  static async uploadFilesToDirectory(
    context: common.UIAbilityContext,
    remoteDirectory: string,
    files: Array<HomeStorageUploadFileEntry>
  ): Promise<HomeStorageOperationResult> {
    const settings: HomeStorageSettings = await HomeStorageService.loadSettings(context);
    const validationMessage: string = HomeStorageService.validateSettings(settings);
    console.info(`[HomeStorageService] bundle_upload_config status=${HomeStorageService.getConfigurationStatus(settings)} host=${settings.smbHost.length > 0 ? 'set' : 'empty'} share=${settings.smbShareName.length > 0 ? 'set' : 'empty'} remoteDirectory=${settings.remoteDirectory.length > 0 ? settings.remoteDirectory : 'empty'} fileCount=${files.length}`);
    if (validationMessage.length > 0) {
      console.warn(`[HomeStorageService] bundle_upload_config_invalid message=${validationMessage}`);
      return createConfigurationFailureResult(settings);
    }

    if (files.length === 0) {
      return createOperationResult(false, '', '复盘包导出失败，请重试', HomeStorageErrorType.UPLOAD_FAILED);
    }

    const targetDirectory: string = joinRemotePath(settings.remoteDirectory, remoteDirectory);
    console.info(`[HomeStorageService] bundle_upload_start targetDirectory=${targetDirectory} fileCount=${files.length}`);
    let lastRemotePath: string = '';
    for (let index = 0; index < files.length; index += 1) {
      const entry: HomeStorageUploadFileEntry = files[index];
      const parts: Array<string> = splitRemoteRelativePath(entry.remoteRelativePath);
      if (parts.length === 0) {
        return createOperationResult(
          false,
          resolveRemotePathText(settings, targetDirectory, ''),
          '复盘包导出失败，请重试',
          HomeStorageErrorType.UPLOAD_FAILED
        );
      }

      const fileName: string = parts[parts.length - 1];
      const subDirectory: string = parts.length > 1 ? parts.slice(0, parts.length - 1).join('/') : '';
      const fileRemoteDirectory: string = joinRemotePath(targetDirectory, subDirectory);
      console.info(`[HomeStorageService] bundle_upload_file index=${index + 1}/${files.length} relative=${entry.remoteRelativePath} directory=${fileRemoteDirectory} bytes=${fileSizeText(entry.localPath)}`);
      const isOriginalUpload: boolean =
        entry.remoteRelativePath.indexOf('assets/original/') === 0 ||
          entry.remoteRelativePath.indexOf('original.') === 0;
      if (isOriginalUpload) {
        console.info(`[HomeStorageService] original_upload_start relative=${entry.remoteRelativePath} directory=${fileRemoteDirectory} bytes=${fileSizeText(entry.localPath)}`);
      }
      const result: HomeStorageOperationResult = await uploadFileBySmb(
        settings,
        entry.localPath,
        fileRemoteDirectory,
        fileName
      );
      if (!result.success) {
        console.error(`[HomeStorageService] bundle_upload_failed index=${index + 1}/${files.length} relative=${entry.remoteRelativePath} remote=${result.remotePath} message=${result.message}`);
        if (isOriginalUpload) {
          console.error(`[HomeStorageService] original_upload_failed relative=${entry.remoteRelativePath} remote=${result.remotePath} type=${result.errorType} message=${result.message}`);
        }
        return result;
      }
      if (isOriginalUpload) {
        console.info(`[HomeStorageService] original_upload_success relative=${entry.remoteRelativePath} remote=${result.remotePath}`);
      }
      lastRemotePath = result.remotePath;
    }

    await HomeStorageService.markLastUploadedAt(context, Date.now());
    console.info(`[HomeStorageService] bundle_upload_success targetDirectory=${targetDirectory} lastRemotePath=${lastRemotePath}`);
    return createOperationResult(
      true,
      resolveRemotePathText(settings, targetDirectory, ''),
      lastRemotePath.length > 0 ? '复盘包已写入家庭存储' : '已上传家庭存储'
    );
  }
}
