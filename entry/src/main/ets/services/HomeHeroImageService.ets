import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import { SettingsRefreshService } from './SettingsRefreshService';

export type HomeHeroImageMode = 'default' | 'userImages';

export interface HomeHeroImageItem {
  id: string;
  fileName: string;
  createdAt: string;
  sortOrder: number;
}

export interface HomeHeroImageConfig {
  schemaVersion: number;
  selectedMode: HomeHeroImageMode;
  autoplayEnabled: boolean;
  intervalSeconds: number;
  images: Array<HomeHeroImageItem>;
}

export interface HomeHeroDisplayImage extends HomeHeroImageItem {
  localPath: string;
  uri: string;
}

export interface HomeHeroImportResult {
  success: boolean;
  importedCount: number;
  failedCount: number;
  message: string;
}

const PREFERENCES_NAME: string = 'home_hero_config';
const CONFIG_KEY: string = 'config';
const HOME_HERO_DIR_NAME: string = 'home_hero';
const DEFAULT_INTERVAL_SECONDS: number = 4;
const MAX_INTERVAL_SECONDS: number = 20;
const MIN_INTERVAL_SECONDS: number = 2;

function logWarning(message: string, error: Object | null = null): void {
  if (error === null) {
    console.warn(`[HomeHeroImageService] ${message}`);
    return;
  }
  console.warn(`[HomeHeroImageService] ${message}: ${error}`);
}

function ensureHomeHeroDir(context: common.UIAbilityContext): string {
  const directory: string = `${context.filesDir}/${HOME_HERO_DIR_NAME}`;
  try {
    fs.mkdirSync(directory, true);
  } catch (error) {
    logWarning('mkdir failed', error);
  }
  return directory;
}

function getHomeHeroPath(context: common.UIAbilityContext, fileName: string): string {
  return `${context.filesDir}/${HOME_HERO_DIR_NAME}/${fileName}`;
}

function fileExists(path: string): boolean {
  try {
    fs.statSync(path);
    return true;
  } catch (error) {
    return false;
  }
}

function deleteFileIfExists(path: string): boolean {
  if (!fileExists(path)) {
    return true;
  }

  try {
    fs.unlinkSync(path);
    return true;
  } catch (error) {
    logWarning(`delete failed path=${path}`, error);
    return false;
  }
}

function normalizeIntervalSeconds(value: number): number {
  if (!Number.isFinite(value)) {
    return DEFAULT_INTERVAL_SECONDS;
  }
  return Math.min(MAX_INTERVAL_SECONDS, Math.max(MIN_INTERVAL_SECONDS, Math.round(value)));
}

function safeFileExtension(uri: string): string {
  const cleanUri: string = uri.split('?')[0].split('#')[0].toLowerCase();
  const slashIndex: number = cleanUri.lastIndexOf('/');
  const dotIndex: number = cleanUri.lastIndexOf('.');
  if (dotIndex > slashIndex && dotIndex >= 0) {
    const extension: string = cleanUri.slice(dotIndex + 1).replace(/[^a-z0-9]/g, '');
    if (extension === 'jpg' || extension === 'jpeg' || extension === 'png' || extension === 'webp' ||
      extension === 'heic' || extension === 'heif') {
      return extension === 'jpeg' ? 'jpg' : extension;
    }
  }
  return 'jpg';
}

function createSafeFileName(uri: string): string {
  const now = new Date();
  const dateText: string = `${now.getFullYear()}${`${now.getMonth() + 1}`.padStart(2, '0')}${`${now.getDate()}`.padStart(2, '0')}`;
  const entropy: string = `${Date.now()}_${Math.floor(Math.random() * 1000000)}`;
  return `hero_${dateText}_${entropy}.${safeFileExtension(uri)}`;
}

function normalizeImageItem(value: Object, index: number): HomeHeroImageItem | null {
  const raw = value as Record<string, Object>;
  const id: string = typeof raw.id === 'string' ? raw.id.trim() : '';
  const fileName: string = typeof raw.fileName === 'string' ? raw.fileName.trim() : '';
  const createdAt: string = typeof raw.createdAt === 'string' ? raw.createdAt.trim() : '';
  const sortOrderValue: Object | undefined = raw.sortOrder;
  const sortOrder: number = typeof sortOrderValue === 'number' && Number.isFinite(sortOrderValue)
    ? Math.max(0, Math.round(sortOrderValue))
    : index;

  if (id.length === 0 || fileName.length === 0 || fileName.includes('/') || fileName.includes('\\')) {
    return null;
  }

  return {
    id: id,
    fileName: fileName,
    createdAt: createdAt.length > 0 ? createdAt : new Date().toISOString(),
    sortOrder: sortOrder
  };
}

function normalizeConfig(value: HomeHeroImageConfig | null): HomeHeroImageConfig {
  if (value === null) {
    return HomeHeroImageService.getDefaultConfig();
  }

  const images: Array<HomeHeroImageItem> = Array.isArray(value.images)
    ? value.images
      .map((item: HomeHeroImageItem, index: number): HomeHeroImageItem | null => normalizeImageItem(item as Object, index))
      .filter((item: HomeHeroImageItem | null): boolean => item !== null) as Array<HomeHeroImageItem>
    : [];

  const selectedMode: HomeHeroImageMode = value.selectedMode === 'userImages' && images.length > 0
    ? 'userImages'
    : 'default';

  return {
    schemaVersion: 1,
    selectedMode: selectedMode,
    autoplayEnabled: typeof value.autoplayEnabled === 'boolean' ? value.autoplayEnabled : true,
    intervalSeconds: normalizeIntervalSeconds(value.intervalSeconds),
    images: images.sort((left: HomeHeroImageItem, right: HomeHeroImageItem): number => left.sortOrder - right.sortOrder)
      .map((item: HomeHeroImageItem, index: number): HomeHeroImageItem => {
        return {
          id: item.id,
          fileName: item.fileName,
          createdAt: item.createdAt,
          sortOrder: index
        };
      })
  };
}

function toDisplayImage(context: common.UIAbilityContext, item: HomeHeroImageItem): HomeHeroDisplayImage {
  const localPath: string = getHomeHeroPath(context, item.fileName);
  return {
    id: item.id,
    fileName: item.fileName,
    createdAt: item.createdAt,
    sortOrder: item.sortOrder,
    localPath: localPath,
    uri: fileUri.getUriFromPath(localPath)
  };
}

function copySelectedImageToHomeHeroDir(context: common.UIAbilityContext, uri: string, fileName: string): string {
  ensureHomeHeroDir(context);
  const targetPath: string = getHomeHeroPath(context, fileName);
  const sourceFile: fs.File = fs.openSync(uri, fs.OpenMode.READ_ONLY);
  const targetFile: fs.File = fs.openSync(targetPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
  try {
    fs.copyFileSync(sourceFile.fd, targetFile.fd);
  } finally {
    fs.closeSync(sourceFile);
    fs.closeSync(targetFile);
  }
  return targetPath;
}

export class HomeHeroImageService {
  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return preferences.getPreferences(context, { name: PREFERENCES_NAME });
  }

  static getDefaultConfig(): HomeHeroImageConfig {
    return {
      schemaVersion: 1,
      selectedMode: 'default',
      autoplayEnabled: true,
      intervalSeconds: DEFAULT_INTERVAL_SECONDS,
      images: []
    };
  }

  static async loadConfig(context: common.UIAbilityContext): Promise<HomeHeroImageConfig> {
    try {
      const store: preferences.Preferences = await HomeHeroImageService.getStore(context);
      const rawValue: preferences.ValueType = await store.get(CONFIG_KEY, '');
      if (typeof rawValue !== 'string' || rawValue.trim().length === 0) {
        return HomeHeroImageService.getDefaultConfig();
      }
      const parsed = JSON.parse(rawValue) as HomeHeroImageConfig;
      return normalizeConfig(parsed);
    } catch (error) {
      logWarning('load config failed, fallback default', error);
      return HomeHeroImageService.getDefaultConfig();
    }
  }

  static async saveConfig(context: common.UIAbilityContext, config: HomeHeroImageConfig): Promise<HomeHeroImageConfig> {
    const normalizedConfig: HomeHeroImageConfig = normalizeConfig(config);
    const store: preferences.Preferences = await HomeHeroImageService.getStore(context);
    await store.put(CONFIG_KEY, JSON.stringify(normalizedConfig));
    await store.flush();
    SettingsRefreshService.notifySettingsChanged('home_hero_config_changed');
    return normalizedConfig;
  }

  static async importImages(context: common.UIAbilityContext, selectedUris: Array<string>): Promise<HomeHeroImportResult> {
    if (selectedUris.length <= 0) {
      return {
        success: true,
        importedCount: 0,
        failedCount: 0,
        message: '未选择图片'
      };
    }

    const currentConfig: HomeHeroImageConfig = await HomeHeroImageService.loadConfig(context);
    const nextImages: Array<HomeHeroImageItem> = currentConfig.images.slice();
    let importedCount: number = 0;
    let failedCount: number = 0;

    for (const uri of selectedUris) {
      const fileName: string = createSafeFileName(uri);
      try {
        copySelectedImageToHomeHeroDir(context, uri, fileName);
        nextImages.push({
          id: fileName.replace(/\.[^.]+$/g, ''),
          fileName: fileName,
          createdAt: new Date().toISOString(),
          sortOrder: nextImages.length
        });
        importedCount += 1;
      } catch (error) {
        failedCount += 1;
        logWarning(`copy selected image failed uri=${uri}`, error);
        deleteFileIfExists(getHomeHeroPath(context, fileName));
      }
    }

    if (importedCount > 0) {
      await HomeHeroImageService.saveConfig(context, {
        schemaVersion: 1,
        selectedMode: 'userImages',
        autoplayEnabled: currentConfig.autoplayEnabled,
        intervalSeconds: currentConfig.intervalSeconds,
        images: nextImages
      });
    }

    return {
      success: importedCount > 0 && failedCount === 0,
      importedCount: importedCount,
      failedCount: failedCount,
      message: failedCount > 0 && importedCount === 0
        ? '图片保存失败，请重试'
        : '首页图片已更新'
    };
  }

  static copySelectedImageToHomeHeroDir(context: common.UIAbilityContext, uri: string): string {
    return copySelectedImageToHomeHeroDir(context, uri, createSafeFileName(uri));
  }

  static async listImages(context: common.UIAbilityContext): Promise<Array<HomeHeroDisplayImage>> {
    return HomeHeroImageService.getDisplayImages(context);
  }

  static async removeImage(context: common.UIAbilityContext, imageId: string): Promise<boolean> {
    const currentConfig: HomeHeroImageConfig = await HomeHeroImageService.loadConfig(context);
    const target: HomeHeroImageItem | undefined = currentConfig.images.find((item: HomeHeroImageItem): boolean => item.id === imageId);
    if (target === undefined) {
      return true;
    }

    const deleted: boolean = deleteFileIfExists(getHomeHeroPath(context, target.fileName));
    if (!deleted) {
      return false;
    }

    await HomeHeroImageService.saveConfig(context, {
      schemaVersion: 1,
      selectedMode: currentConfig.images.length > 1 ? 'userImages' : 'default',
      autoplayEnabled: currentConfig.autoplayEnabled,
      intervalSeconds: currentConfig.intervalSeconds,
      images: currentConfig.images.filter((item: HomeHeroImageItem): boolean => item.id !== imageId)
    });
    return true;
  }

  static async clearImages(context: common.UIAbilityContext): Promise<boolean> {
    const currentConfig: HomeHeroImageConfig = await HomeHeroImageService.loadConfig(context);
    let allDeleted: boolean = true;
    currentConfig.images.forEach((item: HomeHeroImageItem): void => {
      if (!deleteFileIfExists(getHomeHeroPath(context, item.fileName))) {
        allDeleted = false;
      }
    });

    if (!allDeleted) {
      return false;
    }

    await HomeHeroImageService.saveConfig(context, HomeHeroImageService.getDefaultConfig());
    return true;
  }

  static async getDisplayImages(context: common.UIAbilityContext): Promise<Array<HomeHeroDisplayImage>> {
    const currentConfig: HomeHeroImageConfig = await HomeHeroImageService.loadConfig(context);
    if (currentConfig.selectedMode !== 'userImages' || currentConfig.images.length <= 0) {
      return [];
    }

    const existingImages: Array<HomeHeroImageItem> = currentConfig.images.filter((item: HomeHeroImageItem): boolean => {
      return fileExists(getHomeHeroPath(context, item.fileName));
    });

    if (existingImages.length !== currentConfig.images.length) {
      logWarning('missing image file pruned from config');
      try {
        await HomeHeroImageService.saveConfig(context, {
          schemaVersion: 1,
          selectedMode: existingImages.length > 0 ? 'userImages' : 'default',
          autoplayEnabled: currentConfig.autoplayEnabled,
          intervalSeconds: currentConfig.intervalSeconds,
          images: existingImages
        });
      } catch (error) {
        logWarning('save pruned config failed', error);
      }
    }

    return existingImages.map((item: HomeHeroImageItem): HomeHeroDisplayImage => toDisplayImage(context, item));
  }
}
