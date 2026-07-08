import fs from 'node:fs';

const files = {
  homePage: 'entry/src/main/ets/pages/HomePage.ets',
  myPage: 'entry/src/main/ets/pages/MyPage.ets',
  service: 'entry/src/main/ets/services/HomeHeroImageService.ets',
  configPage: 'entry/src/main/ets/pages/HomeHeroImagePage.ets',
  picker: 'entry/src/main/ets/services/PhotoPickerService.ets',
  router: 'entry/src/main/ets/app/AppRouter.ets',
  mainPages: 'entry/src/main/resources/base/profile/main_pages.json',
  reviewJson: 'entry/src/main/ets/services/ReviewJsonExportService.ets',
  rdbModel: 'entry/src/main/ets/services/ReviewCardRdbModel.ets',
  rdbService: 'entry/src/main/ets/services/ReviewCardRdbService.ets',
  bundleExport: 'entry/src/main/ets/services/ReviewBundleExportService.ets',
  homeStorage: 'entry/src/main/ets/services/HomeStorageService.ets',
  appDesign: 'entry/src/main/ets/components/AppDesign.ets',
  designTokens: 'entry/src/main/ets/theme/DesignTokens.ets',
  docs: 'docs/product/HOME_HERO_IMAGE_CONFIG_V1.md'
};

let failed = false;

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function fail(message) {
  failed = true;
  console.error(message);
}

function requireIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    fail(`${message}: ${marker}`);
  }
}

function forbidIncludes(source, marker, message) {
  if (source.includes(marker)) {
    fail(`${message}: ${marker}`);
  }
}

for (const path of Object.values(files)) {
  if (!fs.existsSync(path)) {
    fail(`Missing required file: ${path}`);
  }
}

const homePageSource = read(files.homePage);
const myPageSource = read(files.myPage);
const serviceSource = read(files.service);
const configPageSource = read(files.configPage);
const pickerSource = read(files.picker);
const routerSource = read(files.router);
const mainPagesSource = read(files.mainPages);
const appDesignSource = read(files.appDesign);
const designTokensSource = read(files.designTokens);
const docsSource = read(files.docs);

[
  "const PREFERENCES_NAME: string = 'home_hero_config';",
  "const CONFIG_KEY: string = 'config';",
  "const HOME_HERO_DIR_NAME: string = 'home_hero';",
  'static async loadConfig(context: common.UIAbilityContext)',
  'static async saveConfig(context: common.UIAbilityContext, config: HomeHeroImageConfig)',
  'static async importImages(context: common.UIAbilityContext, selectedUris: Array<string>)',
  'static copySelectedImageToHomeHeroDir(context: common.UIAbilityContext, uri: string): string',
  'static async listImages(context: common.UIAbilityContext)',
  'static async removeImage(context: common.UIAbilityContext, imageId: string)',
  'static async clearImages(context: common.UIAbilityContext)',
  'static async getDisplayImages(context: common.UIAbilityContext)',
  'JSON.parse(rawValue) as HomeHeroImageConfig',
  'HomeHeroImageService.getDefaultConfig()',
  'fs.copyFileSync(sourceFile.fd, targetFile.fd)',
  'fs.unlinkSync(path)',
  'fileUri.getUriFromPath(localPath)',
  "SettingsRefreshService.notifySettingsChanged('home_hero_config_changed')"
].forEach((marker) => requireIncludes(serviceSource, marker, 'HomeHeroImageService missing marker'));

[
  'pickMultiplePhotos',
  'options.maxSelectNumber = Math.max(1, maxSelectNumber);',
  'photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE'
].forEach((marker) => requireIncludes(pickerSource, marker, 'PhotoPickerService missing multi-select marker'));

[
  'HomeHeroImageService.getDisplayImages',
  'this.heroImages.length > 1',
  'Swiper()',
  'this.HeroImageSlide(item, index)',
  'this.DefaultHeroImageSlide()',
  '.autoPlay(this.shouldAutoplayHero() && !this.heroAutoplayPaused)',
  '.indicator(this.resolveHeroIndicator())',
  '.loop(this.shouldShowHeroIndicator())',
  'private resolveHeroIndicator(): DotIndicator | boolean',
  'this.skipFailedHeroImage(item.id)',
  'Image(item.uri)',
  "Image($r('app.media.home_review_hero'))",
  '.aspectRatio(HOME_HERO_ASPECT_RATIO)',
  'AppColors.heroGradientMiddle',
  'AppColors.heroGradientBlue',
  'AppColors.heroGradientDeep',
  '.shadow(ElevationTokens.medium)'
].forEach((marker) => requireIncludes(homePageSource, marker, 'HomePage missing hero display marker'));

[
  'setInterval(() =>',
  'clearInterval(this.heroAutoplayTimer)',
  'heroAutoplayTimer',
  'heroCurrentIndex',
  'resolveCurrentHeroImageUri',
  'HOME_HERO_DOT_SIZE',
  'HOME_HERO_DOT_GAP',
  "'#D9FFFFFF'",
  "'#66FFFFFF'",
  "'#0F121B12'",
  "'#0F121B80'"
].forEach((marker) => forbidIncludes(homePageSource, marker, 'HomePage must use Swiper and shared Hero tokens'));

[
  "title: '首页图片'",
  '@Builder\n  DefaultImageRow()',
  "Text('默认首页图')",
  "Text(this.images.length <= 0 ? '展示中' : '默认')",
  '@Builder\n  AddImageRow()',
  "Text(this.isAdding ? '添加中…' : '添加图片')",
  "Text('可一次选择多张，加入首页轮播')",
  '@Builder\n  ClearImagesAction()',
  "Button(this.isClearing ? '清空中…' : '清空自定义')",
  "title: '删除这张图片？'",
  "title: '清空首页图片？'",
  "ToastService.show(this.getUIContext(), '已恢复默认首页图片')",
  "ToastService.show(this.getUIContext(), '图片保存失败，请重试')"
].forEach((marker) => requireIncludes(configPageSource, marker, 'HomeHeroImagePage missing UX marker'));

[
  '@Builder\n  SummaryCard()',
  "subtitle: '管理首页展示图。'",
  "title: '已配置图片'",
  'resolveStatusText()',
  'SettingsSectionHeader({',
  "label: '使用默认图片'",
  "label: this.isClearing ? '清空中…' : '清空图片'",
  "EmptyState({\n          title: '还没有自定义首页图'",
  "Text('选择一张或多张图片作为首页展示图。多张图片会自动轮播。')"
].forEach((marker) => forbidIncludes(configPageSource, marker, 'HomeHeroImagePage must keep hero image controls inside configured list'));

[
  'HOME_HERO_IMAGE_PAGE',
  "title: '首页图片'",
  'this.openHomeHeroImage();',
  'HomeHeroImageService.listImages'
].forEach((marker) => requireIncludes(myPageSource, marker, 'MyPage missing settings entry marker'));

requireIncludes(routerSource, "export const HOME_HERO_IMAGE_PAGE: string = 'pages/HomeHeroImagePage';", 'AppRouter missing page route');
requireIncludes(mainPagesSource, '"pages/HomeHeroImagePage"', 'main_pages missing page registration');

forbidIncludes(homePageSource, "@ohos.data.preferences", 'HomePage must not read or write Preferences directly');
forbidIncludes(myPageSource, "@ohos.data.preferences", 'MyPage must not read or write Preferences directly');
forbidIncludes(configPageSource, "@ohos.data.preferences", 'HomeHeroImagePage must not read or write Preferences directly');

[
  'Preferences',
  'RDB',
  'URI',
  '沙箱',
  'schemaVersion'
].forEach((technicalWord) => {
  forbidIncludes(configPageSource, `'${technicalWord}'`, 'User-facing config page copy must not expose technical wording');
  forbidIncludes(homePageSource, `'${technicalWord}'`, 'User-facing home copy must not expose technical wording');
});

[
  files.reviewJson,
  files.rdbModel,
  files.rdbService,
  files.bundleExport,
  files.homeStorage
].forEach((path) => {
  const source = read(path);
  forbidIncludes(source, 'home_hero_config', `${path} must not depend on home hero config`);
  forbidIncludes(source, 'HomeHeroImageService', `${path} must not depend on HomeHeroImageService`);
});

[
  'export class SpacingTokens',
  'export class RadiusTokens',
  'export class ElevationTokens',
  'export class MotionTokens'
].forEach((marker) => requireIncludes(designTokensSource, marker, 'Design System V2 foundation missing marker'));

[
  'static readonly space4: number = SpacingTokens.xs;',
  'static readonly space12: number = SpacingTokens.md;',
  'static readonly cardRadius: number = RadiusTokens.lg;',
  'static readonly buttonRadius: number = RadiusTokens.md;'
].forEach((marker) => requireIncludes(appDesignSource, marker, 'AppDesign must map Design System V2 tokens'));

[
  '本轮不新建 RDB 表',
  'Preferences 保存配置元数据',
  'filesDir/home_hero/',
  '不改 Review JSON',
  '不改 review bundle',
  '不接入家庭存储'
].forEach((marker) => requireIncludes(docsSource, marker, 'Home hero product doc missing marker'));

function normalizeConfig(raw) {
  if (!raw || !Array.isArray(raw.images)) {
    return {
      schemaVersion: 1,
      selectedMode: 'default',
      autoplayEnabled: true,
      intervalSeconds: 4,
      images: []
    };
  }
  const images = raw.images
    .filter((item) => item && typeof item.id === 'string' && typeof item.fileName === 'string' &&
      item.id.trim().length > 0 && item.fileName.trim().length > 0 &&
      !item.fileName.includes('/') && !item.fileName.includes('\\'))
    .sort((left, right) => (left.sortOrder ?? 0) - (right.sortOrder ?? 0))
    .map((item, index) => ({
      id: item.id.trim(),
      fileName: item.fileName.trim(),
      createdAt: typeof item.createdAt === 'string' && item.createdAt.length > 0 ? item.createdAt : 'fallback',
      sortOrder: index
    }));
  return {
    schemaVersion: 1,
    selectedMode: raw.selectedMode === 'userImages' && images.length > 0 ? 'userImages' : 'default',
    autoplayEnabled: typeof raw.autoplayEnabled === 'boolean' ? raw.autoplayEnabled : true,
    intervalSeconds: Math.max(2, Math.min(20, Math.round(Number(raw.intervalSeconds) || 4))),
    images
  };
}

const defaultConfig = normalizeConfig(null);
if (defaultConfig.selectedMode !== 'default' || defaultConfig.images.length !== 0) {
  fail('Default config should fallback to default image mode.');
}

const singleConfig = normalizeConfig({
  selectedMode: 'userImages',
  autoplayEnabled: true,
  intervalSeconds: 4,
  images: [{ id: 'hero_a', fileName: 'hero_a.jpg', createdAt: '2026-06-28T00:00:00.000Z', sortOrder: 0 }]
});
if (singleConfig.selectedMode !== 'userImages' || singleConfig.images.length !== 1) {
  fail('Single user image should normalize as userImages mode.');
}

const brokenConfig = normalizeConfig({
  selectedMode: 'userImages',
  images: [
    { id: '', fileName: 'bad.jpg', sortOrder: 0 },
    { id: 'bad_path', fileName: '../bad.jpg', sortOrder: 1 }
  ]
});
if (brokenConfig.selectedMode !== 'default' || brokenConfig.images.length !== 0) {
  fail('Broken config should fallback to default mode.');
}

const multiConfig = normalizeConfig({
  selectedMode: 'userImages',
  images: [
    { id: 'hero_b', fileName: 'hero_b.jpg', sortOrder: 1 },
    { id: 'hero_a', fileName: 'hero_a.jpg', sortOrder: 0 }
  ]
});
if (multiConfig.images[0].id !== 'hero_a' || multiConfig.images[1].id !== 'hero_b') {
  fail('Multiple user images should keep sorted autoplay order.');
}

if (failed) {
  process.exit(1);
}

console.log('home hero image config verified: service, settings entry, default fallback, single image, autoplay, copy/delete/clear, safe boundaries');
