import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import http from '@ohos.net.http';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import {
  resolveReviewCardExchangeReviewJsonFileName,
  stringifyReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';
import { HomeStorageSecretService } from './HomeStorageSecretService';
import { Smb2Client, Smb2UploadOptions } from './Smb2Client';

const PREFERENCES_NAME: string = 'home_storage_settings';
const PROTOCOL_KEY: string = 'protocol';
const ENDPOINT_URL_KEY: string = 'endpoint_url';
const USERNAME_KEY: string = 'username';
const LEGACY_PASSWORD_KEY: string = 'password';
const REMOTE_DIRECTORY_KEY: string = 'remote_directory';
const SMB_HOST_KEY: string = 'smb_host';
const SMB_PORT_KEY: string = 'smb_port';
const SMB_SHARE_NAME_KEY: string = 'smb_share_name';
const SMB_DOMAIN_KEY: string = 'smb_domain';
const DEFAULT_REMOTE_DIRECTORY: string = '摄影资料库/Reviews';
const DEFAULT_SMB_PORT: string = '445';
const REQUEST_TIMEOUT_MS: number = 20000;
const BASE64_ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

export enum HomeStorageProtocol {
  WEBDAV = 'webdav',
  SMB = 'smb'
}

export interface HomeStorageSettings {
  protocol: string;
  endpointUrl: string;
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

function normalizeText(value: string | undefined): string {
  if (typeof value === 'string') {
    return value.trim();
  }
  return '';
}

function normalizeProtocol(value: string | undefined): HomeStorageProtocol {
  if (value === HomeStorageProtocol.SMB || value === 'smbSystemPicker') {
    return HomeStorageProtocol.SMB;
  }
  return HomeStorageProtocol.WEBDAV;
}

function normalizeEndpointUrl(value: string | undefined): string {
  const trimmed: string = normalizeText(value);
  return trimmed.replace(/\/+$/g, '');
}

function normalizeRemoteDirectory(value: string | undefined): string {
  const trimmed: string = normalizeText(value);
  if (trimmed.length === 0) {
    return DEFAULT_REMOTE_DIRECTORY;
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

function normalizeSettings(settings: HomeStorageSettings | undefined): HomeStorageSettings {
  const source: HomeStorageSettings = settings ? settings : {} as HomeStorageSettings;
  return {
    protocol: normalizeProtocol(source.protocol),
    endpointUrl: normalizeEndpointUrl(source.endpointUrl),
    username: normalizeText(source.username),
    password: normalizeText(source.password),
    remoteDirectory: normalizeRemoteDirectory(source.remoteDirectory),
    smbHost: normalizeText(source.smbHost).replace(/^smb:\/\//i, '').replace(/\/+$/g, ''),
    smbPort: normalizeSmbPort(source.smbPort),
    smbShareName: normalizeText(source.smbShareName).replace(/^\/+/g, '').replace(/\/+$/g, ''),
    smbDomain: normalizeText(source.smbDomain)
  };
}

function isValidEndpointUrl(value: string): boolean {
  return value.startsWith('https://') || value.startsWith('http://');
}

function parsePort(value: string): number {
  const port: number = Number.parseInt(value, 10);
  if (Number.isNaN(port)) {
    return 0;
  }
  return port;
}

function utf8Bytes(value: string): Array<number> {
  const bytes: Array<number> = [];
  for (let index = 0; index < value.length; index += 1) {
    let codePoint: number = value.charCodeAt(index);
    if (codePoint >= 0xD800 && codePoint <= 0xDBFF && index + 1 < value.length) {
      const next: number = value.charCodeAt(index + 1);
      if (next >= 0xDC00 && next <= 0xDFFF) {
        codePoint = ((codePoint - 0xD800) * 0x400) + (next - 0xDC00) + 0x10000;
        index += 1;
      }
    }

    if (codePoint <= 0x7F) {
      bytes.push(codePoint);
    } else if (codePoint <= 0x7FF) {
      bytes.push(0xC0 | (codePoint >> 6));
      bytes.push(0x80 | (codePoint & 0x3F));
    } else if (codePoint <= 0xFFFF) {
      bytes.push(0xE0 | (codePoint >> 12));
      bytes.push(0x80 | ((codePoint >> 6) & 0x3F));
      bytes.push(0x80 | (codePoint & 0x3F));
    } else {
      bytes.push(0xF0 | (codePoint >> 18));
      bytes.push(0x80 | ((codePoint >> 12) & 0x3F));
      bytes.push(0x80 | ((codePoint >> 6) & 0x3F));
      bytes.push(0x80 | (codePoint & 0x3F));
    }
  }
  return bytes;
}

function base64Encode(value: string): string {
  const bytes: Array<number> = utf8Bytes(value);
  let encoded: string = '';
  for (let index = 0; index < bytes.length; index += 3) {
    const first: number = bytes[index];
    const second: number = index + 1 < bytes.length ? bytes[index + 1] : 0;
    const third: number = index + 2 < bytes.length ? bytes[index + 2] : 0;
    const triple: number = (first << 16) | (second << 8) | third;

    encoded += BASE64_ALPHABET[(triple >> 18) & 0x3F];
    encoded += BASE64_ALPHABET[(triple >> 12) & 0x3F];
    encoded += index + 1 < bytes.length ? BASE64_ALPHABET[(triple >> 6) & 0x3F] : '=';
    encoded += index + 2 < bytes.length ? BASE64_ALPHABET[triple & 0x3F] : '=';
  }
  return encoded;
}

function encodePathSegment(segment: string): string {
  return encodeURIComponent(segment).replace(/%2F/g, '/');
}

function resolveRemoteUrl(settings: HomeStorageSettings, fileName: string | undefined = undefined): string {
  const normalized: HomeStorageSettings = normalizeSettings(settings);
  const pathSegments: Array<string> = normalized.remoteDirectory
    .split('/')
    .map((segment: string) => segment.trim())
    .filter((segment: string) => segment.length > 0);
  if (fileName && fileName.length > 0) {
    pathSegments.push(fileName);
  }

  if (pathSegments.length === 0) {
    return normalized.endpointUrl;
  }
  return `${normalized.endpointUrl}/${pathSegments.map((segment: string) => encodePathSegment(segment)).join('/')}`;
}

function createHeaders(settings: HomeStorageSettings, contentType: string | undefined = undefined): Record<string, string> {
  const headers: Record<string, string> = {
    'Accept': '*/*'
  };
  if (contentType && contentType.length > 0) {
    headers['Content-Type'] = contentType;
  }
  if (settings.username.length > 0 || settings.password.length > 0) {
    headers['Authorization'] = `Basic ${base64Encode(`${settings.username}:${settings.password}`)}`;
  }
  return headers;
}

function isSuccessStatus(statusCode: number): boolean {
  return statusCode >= 200 && statusCode < 300;
}

function statusMessage(statusCode: number): string {
  if (statusCode === 401 || statusCode === 403) {
    return '家庭存储认证失败，请检查用户名和密码';
  }
  if (statusCode === 404 || statusCode === 409) {
    return '家庭存储目录不存在，请先在存储端创建目录';
  }
  return `家庭存储返回 ${statusCode}`;
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

async function requestWebDav(
  method: http.RequestMethod,
  url: string,
  settings: HomeStorageSettings,
  body: string | undefined = undefined
): Promise<http.HttpResponse> {
  const request = http.createHttp();
  try {
    const options: http.HttpRequestOptions = {
      method: method,
      header: createHeaders(settings, body ? 'application/json; charset=utf-8' : undefined),
      connectTimeout: REQUEST_TIMEOUT_MS,
      readTimeout: REQUEST_TIMEOUT_MS
    };
    if (body !== undefined) {
      options.extraData = body;
    }
    return await request.request(url, options);
  } finally {
    request.destroy();
  }
}

export class HomeStorageService {
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
      return legacyPassword;
    } catch (error) {
      return '';
    } finally {
      await HomeStorageService.clearLegacyPassword(store);
      await store.flush();
    }
  }

  static defaultSettings(): HomeStorageSettings {
    return {
      protocol: HomeStorageProtocol.WEBDAV,
      endpointUrl: '',
      username: '',
      password: '',
      remoteDirectory: DEFAULT_REMOTE_DIRECTORY,
      smbHost: '',
      smbPort: DEFAULT_SMB_PORT,
      smbShareName: '',
      smbDomain: ''
    };
  }

  static async loadSettings(context: common.UIAbilityContext): Promise<HomeStorageSettings> {
    try {
      const store = await HomeStorageService.getStore(context);
      const protocol = await store.get(PROTOCOL_KEY, HomeStorageProtocol.WEBDAV);
      const endpointUrl = await store.get(ENDPOINT_URL_KEY, '');
      const username = await store.get(USERNAME_KEY, '');
      let password = await HomeStorageSecretService.loadPassword();
      if (password.length === 0) {
        password = await HomeStorageService.migrateLegacyPassword(store);
      }
      const remoteDirectory = await store.get(REMOTE_DIRECTORY_KEY, DEFAULT_REMOTE_DIRECTORY);
      const smbHost = await store.get(SMB_HOST_KEY, '');
      const smbPort = await store.get(SMB_PORT_KEY, DEFAULT_SMB_PORT);
      const smbShareName = await store.get(SMB_SHARE_NAME_KEY, '');
      const smbDomain = await store.get(SMB_DOMAIN_KEY, '');
      return normalizeSettings({
        protocol: typeof protocol === 'string' ? protocol : HomeStorageProtocol.WEBDAV,
        endpointUrl: typeof endpointUrl === 'string' ? endpointUrl : '',
        username: typeof username === 'string' ? username : '',
        password: password,
        remoteDirectory: typeof remoteDirectory === 'string' ? remoteDirectory : DEFAULT_REMOTE_DIRECTORY,
        smbHost: typeof smbHost === 'string' ? smbHost : '',
        smbPort: typeof smbPort === 'string' ? smbPort : DEFAULT_SMB_PORT,
        smbShareName: typeof smbShareName === 'string' ? smbShareName : '',
        smbDomain: typeof smbDomain === 'string' ? smbDomain : ''
      });
    } catch (error) {
      return HomeStorageService.defaultSettings();
    }
  }

  static async saveSettings(
    context: common.UIAbilityContext,
    settings: HomeStorageSettings
  ): Promise<HomeStorageSettings> {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    await HomeStorageSecretService.savePassword(normalized.password);
    const store = await HomeStorageService.getStore(context);
    await store.put(PROTOCOL_KEY, normalized.protocol);
    await store.put(ENDPOINT_URL_KEY, normalized.endpointUrl);
    await store.put(USERNAME_KEY, normalized.username);
    await HomeStorageService.clearLegacyPassword(store);
    await store.put(REMOTE_DIRECTORY_KEY, normalized.remoteDirectory);
    await store.put(SMB_HOST_KEY, normalized.smbHost);
    await store.put(SMB_PORT_KEY, normalized.smbPort);
    await store.put(SMB_SHARE_NAME_KEY, normalized.smbShareName);
    await store.put(SMB_DOMAIN_KEY, normalized.smbDomain);
    await store.flush();
    return normalized;
  }

  static validateSettings(settings: HomeStorageSettings): string {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    if (normalized.protocol === HomeStorageProtocol.SMB) {
      const port: number = parsePort(normalized.smbPort);
      if (normalized.smbHost.length === 0) {
        return '请先填写 SMB 地址或 IP';
      }
      if (port <= 0 || port > 65535) {
        return 'SMB 端口需要在 1-65535 之间';
      }
      if (normalized.smbShareName.length === 0) {
        return '请先填写 SMB 共享名';
      }
      return '';
    }
    if (normalized.endpointUrl.length === 0) {
      return '请先填写 WebDAV 地址';
    }
    if (!isValidEndpointUrl(normalized.endpointUrl)) {
      return 'WebDAV 地址需要以 http:// 或 https:// 开头';
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

    if (normalized.protocol === HomeStorageProtocol.SMB) {
      const client: Smb2Client = new Smb2Client();
      try {
        await client.testConnection(createSmbUploadOptions(normalized, 'connection-test.review.json', '{}'));
        return {
          success: true,
          remotePath: `\\\\${normalized.smbHost}\\${normalized.smbShareName}`,
          message: 'SMB 连接成功'
        };
      } catch (error) {
        await client.close();
        return {
          success: false,
          remotePath: `\\\\${normalized.smbHost}\\${normalized.smbShareName}`,
          message: error instanceof Error ? error.message : 'SMB 连接失败，请检查地址、账号和共享名'
        };
      }
    }

    const remotePath: string = resolveRemoteUrl(normalized);
    try {
      const response: http.HttpResponse = await requestWebDav(http.RequestMethod.GET, remotePath, normalized);
      const statusCode: number = response.responseCode;
      return {
        success: isSuccessStatus(statusCode),
        remotePath: remotePath,
        message: isSuccessStatus(statusCode) ? '家庭存储连接成功' : statusMessage(statusCode)
      };
    } catch (error) {
      return {
        success: false,
        remotePath: remotePath,
        message: '家庭存储连接失败，请检查地址和网络'
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
    if (settings.protocol === HomeStorageProtocol.SMB) {
      const client: Smb2Client = new Smb2Client();
      try {
        const remotePath: string = await client.uploadText(createSmbUploadOptions(settings, fileName, body));
        return {
          success: true,
          remotePath: remotePath,
          message: '已上传到家庭存储'
        };
      } catch (error) {
        await client.close();
        return {
          success: false,
          remotePath: `\\\\${settings.smbHost}\\${settings.smbShareName}\\${settings.remoteDirectory}\\${fileName}`,
          message: error instanceof Error ? error.message : 'SMB 上传失败，请检查网络、账号和目录'
        };
      }
    }

    const remotePath: string = resolveRemoteUrl(settings, fileName);
    try {
      const response: http.HttpResponse = await requestWebDav(http.RequestMethod.PUT, remotePath, settings, body);
      const statusCode: number = response.responseCode;
      return {
        success: isSuccessStatus(statusCode),
        remotePath: remotePath,
        message: isSuccessStatus(statusCode) ? '已上传到家庭存储' : statusMessage(statusCode)
      };
    } catch (error) {
      return {
        success: false,
        remotePath: remotePath,
        message: '上传家庭存储失败，请检查网络和目录'
      };
    }
  }
}
