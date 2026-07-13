import fs from 'node:fs';

const photoPickerSource = fs.readFileSync('entry/src/main/ets/services/PhotoPickerService.ets', 'utf8');
const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const reviewPhotoBlockSource = fs.readFileSync('entry/src/main/ets/components/ReviewPhotoBlock.ets', 'utf8');
const projectDetailSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const editorPageSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function assertIncludes(source, marker, message) {
  assert(source.includes(marker), `${message}: ${marker}`);
}

function assertNotIncludes(source, marker, message) {
  assert(!source.includes(marker), `${message}: ${marker}`);
}

assertIncludes(
  photoPickerSource,
  'function shouldResolveImageSizeByFdFirst(imageUri: string): boolean',
  'Photo picker must detect media-library URIs before resolving image size'
);
assertIncludes(
  photoPickerSource,
  'return await resolveDisplayImageSizeByFd(imageUri);',
  'Media-library image size resolution must try fd first'
);
assertIncludes(
  photoPickerSource,
  "normalizedUri.startsWith('file://media/')",
  'Photo picker must cover the common media-library URI format'
);

for (const [name, source] of [
  ['PhotoWritingHero', appDesignSource],
  ['ReviewPhotoBlock', reviewPhotoBlockSource],
  ['ProjectDetailPage pending thumbnail', projectDetailSource]
]) {
  assertNotIncludes(source, '.syncLoad(true)', `${name} must not synchronously decode user-selected photos`);
}

assertIncludes(
  homePageSource,
  'result.photos[index].imageUri.trim().length <= 0',
  'Pending import should only reject empty picker URIs'
);
assertNotIncludes(
  homePageSource,
  'if (result.photos[index].imageSizeFallbackUsed)',
  'Pending import must not reject photos only because metadata size fallback was used'
);

assertNotIncludes(
  editorPageSource,
  'content: this.SharedHeroPhotoHeader',
  'Editor shared hero must not pass an unbound component builder through BuilderParam'
);
assertNotIncludes(
  editorPageSource,
  'SharedHeroPhotoHeader()',
  'Editor must not retain the crashing BuilderParam wrapper'
);
assertIncludes(
  editorPageSource,
  'geometryTransition(`review-hero-${this.resolveHeroTag()}`)',
  'Editor must keep the shared hero transition inline'
);

if (failed) {
  process.exit(1);
}

console.log('photo import crash guard verified: fd-first probing, async rendering, pending fallback import, inline shared hero');
