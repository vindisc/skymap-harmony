import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import http from '@ohos.net.http';
import { ReviewCardDocument } from '../model/ReviewCardModel';
import {
  resolveReviewCardExchangeReviewJsonFileName,
  stringifyReviewCardExchangeSchemaV1
} from './ReviewCardExchangeSchema';
import { ReviewCardReviewFileExportResult, ReviewCardReviewFileService } from './ReviewCardReviewFileService';

const PREFERENCES_NAME: string = 'home_storage_settings';
const PROTOCOL_KEY: string = 'protocol';
const ENDPOINT_URL_KEY: string = 'endpoint_url';
const USERNAME_KEY: string = 'username';
const PASSWORD_KEY: string = 'password';
const REMOTE_DIRECTORY_KEY: string = 'remote_directory';
const DEFAULT_REMOTE_DIRECTORY: string = '摄影资料库/Reviews';
const REQUEST_TIMEOUT_MS: number = 20000;
const BASE64_ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

export enum HomeStorageProtocol {
  WEBDAV = 'webdav',
  SMB_SYSTEM_PICKER = 'smbSystemPicker'
}

export interface HomeStorageSettings {
  protocol: string;
  endpointUrl: string;
  username: string;
  password: string;
  remoteDirectory: string;
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
  if (value === HomeStorageProtocol.SMB_SYSTEM_PICKER) {
    return HomeStorageProtocol.SMB_SYSTEM_PICKER;
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

function normalizeSettings(settings: HomeStorageSettings | undefined): HomeStorageSettings {
  const source: HomeStorageSettings = settings ? settings : {} as HomeStorageSettings;
  return {
    protocol: normalizeProtocol(source.protocol),
    endpointUrl: normalizeEndpointUrl(source.endpointUrl),
    username: normalizeText(source.username),
    password: normalizeText(source.password),
    remoteDirectory: normalizeRemoteDirectory(source.remoteDirectory)
  };
}

function isValidEndpointUrl(value: string): boolean {
  return value.startsWith('https://') || value.startsWith('http://');
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

  static defaultSettings(): HomeStorageSettings {
    return {
      protocol: HomeStorageProtocol.WEBDAV,
      endpointUrl: '',
      username: '',
      password: '',
      remoteDirectory: DEFAULT_REMOTE_DIRECTORY
    };
  }

  static async loadSettings(context: common.UIAbilityContext): Promise<HomeStorageSettings> {
    try {
      const store = await HomeStorageService.getStore(context);
      const protocol = await store.get(PROTOCOL_KEY, HomeStorageProtocol.WEBDAV);
      const endpointUrl = await store.get(ENDPOINT_URL_KEY, '');
      const username = await store.get(USERNAME_KEY, '');
      const password = await store.get(PASSWORD_KEY, '');
      const remoteDirectory = await store.get(REMOTE_DIRECTORY_KEY, DEFAULT_REMOTE_DIRECTORY);
      return normalizeSettings({
        protocol: typeof protocol === 'string' ? protocol : HomeStorageProtocol.WEBDAV,
        endpointUrl: typeof endpointUrl === 'string' ? endpointUrl : '',
        username: typeof username === 'string' ? username : '',
        password: typeof password === 'string' ? password : '',
        remoteDirectory: typeof remoteDirectory === 'string' ? remoteDirectory : DEFAULT_REMOTE_DIRECTORY
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
    const store = await HomeStorageService.getStore(context);
    await store.put(PROTOCOL_KEY, normalized.protocol);
    await store.put(ENDPOINT_URL_KEY, normalized.endpointUrl);
    await store.put(USERNAME_KEY, normalized.username);
    await store.put(PASSWORD_KEY, normalized.password);
    await store.put(REMOTE_DIRECTORY_KEY, normalized.remoteDirectory);
    await store.flush();
    return normalized;
  }

  static validateSettings(settings: HomeStorageSettings): string {
    const normalized: HomeStorageSettings = normalizeSettings(settings);
    if (normalized.protocol === HomeStorageProtocol.SMB_SYSTEM_PICKER) {
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
    if (normalized.protocol === HomeStorageProtocol.SMB_SYSTEM_PICKER) {
      return {
        success: true,
        remotePath: '',
        message: 'SMB 将在上传时打开系统保存面板'
      };
    }

    const validationMessage: string = HomeStorageService.validateSettings(normalized);
    if (validationMessage.length > 0) {
      return {
        success: false,
        remotePath: '',
        message: validationMessage
      };
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
    if (settings.protocol === HomeStorageProtocol.SMB_SYSTEM_PICKER) {
      const result: ReviewCardReviewFileExportResult = await ReviewCardReviewFileService.exportReviewJson(
        context,
        document,
        reviewerText
      );
      return {
        success: result.success,
        remotePath: result.path,
        message: result.success ? '已保存到家庭存储' : result.message
      };
    }

    const validationMessage: string = HomeStorageService.validateSettings(settings);
    if (validationMessage.length > 0) {
      return {
        success: false,
        remotePath: '',
        message: validationMessage
      };
    }

    const fileName: string = resolveReviewCardExchangeReviewJsonFileName(document);
    const remotePath: string = resolveRemoteUrl(settings, fileName);
    const body: string = stringifyReviewCardExchangeSchemaV1(document, reviewerText);
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
