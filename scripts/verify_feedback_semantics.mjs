import fs from 'node:fs';
import path from 'node:path';

const pagesDir = 'entry/src/main/ets/pages';
const servicesDir = 'entry/src/main/ets/services';
const themeDir = 'entry/src/main/ets/theme';
const componentsDir = 'entry/src/main/ets/components';

const hexPattern = /#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?(?![0-9A-Fa-f])/g;
const opaqueBlackWhite = new Set(['#000000', '#FFFFFF', '#00000000', '#FFFFFF00']);
const allowMarker = '// verify-feedback:allow-raw';

const hexWhitelistFiles = new Set([
  path.join(themeDir, 'DesignTokens.ets'),
  path.join(componentsDir, 'AppDesign.ets'),
  path.join(componentsDir, 'ReviewCardStyleTokens.ets'),
  path.join(componentsDir, 'ReviewCardStylePreset.ets')
]);

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

function listEts(dir) {
  return fs.readdirSync(dir)
    .filter((name) => name.endsWith('.ets'))
    .map((name) => path.join(dir, name));
}

function forbidLegacyToastRaw() {
  const files = listEts(pagesDir);
  for (const file of files) {
    const source = fs.readFileSync(file, 'utf8');
    if (source.includes('ToastService.show(') || source.includes('ToastService._showRaw(')) {
      fail(`${file}: pages must not call ToastService.show / _showRaw — use tone helpers (.success/.info/.warning/.error/.byTone).`);
    }
  }
}

function forbidBareHex() {
  const targets = [...listEts(pagesDir), ...listEts(servicesDir)];
  for (const file of targets) {
    if (hexWhitelistFiles.has(file)) {
      continue;
    }
    const lines = fs.readFileSync(file, 'utf8').split('\n');
    lines.forEach((line, index) => {
      if (line.includes(allowMarker)) {
        return;
      }
      const matches = line.match(hexPattern);
      if (!matches) {
        return;
      }
      for (const match of matches) {
        if (opaqueBlackWhite.has(match.toUpperCase())) {
          continue;
        }
        fail(`${file}:${index + 1}: raw hex color ${match} — move to AppColors or add "${allowMarker}" if intentional.`);
      }
    });
  }
}

function forbidLegacyFeedbackState() {
  const bannedStatePattern = /@State\s+action[fF]eedback\w*/;
  const files = listEts(pagesDir);
  for (const file of files) {
    const source = fs.readFileSync(file, 'utf8');
    if (bannedStatePattern.test(source)) {
      fail(`${file}: pages must not declare @State actionFeedback… — migrate to InlineStatusBanner / FloatingStatusBanner.`);
    }
    if (source.includes('CenterFeedbackOverlay')) {
      fail(`${file}: pages must not reference CenterFeedbackOverlay — it has been retired.`);
    }
  }
}

function ensureBannerImportedWhereUsed() {
  const files = listEts(pagesDir);
  for (const file of files) {
    const source = fs.readFileSync(file, 'utf8');
    if (source.includes('InlineStatusBanner({') && !source.includes("from '../components/InlineStatusBanner'")) {
      fail(`${file}: uses InlineStatusBanner without importing it from components/InlineStatusBanner.`);
    }
    if (source.includes('FloatingStatusBanner({') && !source.includes("from '../components/InlineStatusBanner'")) {
      fail(`${file}: uses FloatingStatusBanner without importing it from components/InlineStatusBanner.`);
    }
  }
}

function ensureToastServiceInternalRaw() {
  const source = fs.readFileSync(path.join(servicesDir, 'ToastService.ets'), 'utf8');
  if (!source.includes('private static _showRaw')) {
    fail('ToastService must keep the raw toast pipeline behind private static _showRaw.');
  }
  if (source.includes('static show(')) {
    fail('ToastService must not re-expose a public static show() — pages should call tone helpers only.');
  }
}

function ensureDialogServiceToneApi() {
  const source = fs.readFileSync(path.join(servicesDir, 'DialogService.ets'), 'utf8');
  if (!source.includes('export enum DialogTone')) {
    fail('DialogService must export a DialogTone enum.');
  }
  if (!source.includes('tone?: DialogTone')) {
    fail('DialogService confirm/alert options must accept an optional tone: DialogTone parameter.');
  }
  if (source.match(/#[0-9A-Fa-f]{6}/)) {
    fail('DialogService must not embed raw hex colors — route through AppColors.');
  }
}

forbidLegacyToastRaw();
forbidBareHex();
forbidLegacyFeedbackState();
ensureBannerImportedWhereUsed();
ensureToastServiceInternalRaw();
ensureDialogServiceToneApi();

if (failed) {
  process.exit(1);
}

console.log('feedback semantics verified: toast tones enforced, hex tokens locked, banners in charge of inline feedback, dialog tone API present');
