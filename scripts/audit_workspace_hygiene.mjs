import { spawnSync } from 'node:child_process';
import fs from 'node:fs';

const sensitiveExtension = /\.(p12|p7b|cer|pem|profile|jks|keystore|key|csr|der|hap|hsp|har|zip)$/i;
const forbiddenTrackedPrefixes = [
  'release-assets/appgallery-screenshots/',
  'release-assets/signing/',
  'release-assets/packages/',
  'release-assets/submissions/',
  'release-assets/private/'
];
const allowedTrackedReleaseAssets = new Set([
  'release-assets/README.md',
  'release-assets/appgallery-icon-1024.png',
  'release-assets/appgallery-icon-216.png',
  'release-assets/appgallery-icon-background-1024.png',
  'release-assets/appgallery-icon-foreground-1024.png'
]);

let failed = false;

function fail(message) {
  failed = true;
  console.error(message);
}

function git(args) {
  const result = spawnSync('git', args, { encoding: 'utf8' });
  if (result.status !== 0) {
    if (result.stderr) {
      process.stderr.write(result.stderr);
    }
    throw new Error(`git ${args.join(' ')} failed`);
  }
  return result.stdout.trim();
}

function lines(value) {
  return value.length === 0 ? [] : value.split('\n').filter(Boolean);
}

function isSensitivePath(filePath) {
  return filePath.endsWith('/.DS_Store') ||
    filePath === '.DS_Store' ||
    filePath === 'build-profile.local.json5' ||
    sensitiveExtension.test(filePath) ||
    forbiddenTrackedPrefixes.some((prefix) => filePath.startsWith(prefix));
}

const forbiddenBuildProfileMarkers = [
  'signingConfigs',
  'signingConfig',
  'storeFile',
  'storePassword',
  'keyPassword',
  'certpath',
  '/Users/'
];

function assertBuildProfileSafe(label, source) {
  for (const marker of forbiddenBuildProfileMarkers) {
    if (source.includes(marker)) {
      fail(`${label}含禁止提交的签名内容: ${marker}`);
    }
  }
}

const worktreeBuildProfile = fs.readFileSync('build-profile.json5', 'utf8');
const indexBuildProfile = git(['show', ':build-profile.json5']);
assertBuildProfileSafe('暂存区 build-profile.json5 ', indexBuildProfile);

if (forbiddenBuildProfileMarkers.some((marker) => worktreeBuildProfile.includes(marker))) {
  const filterRequired = git(['config', '--local', '--get', 'filter.skymap-signing.required']);
  const cleanHash = git(['hash-object', '--path=build-profile.json5', 'build-profile.json5']);
  const indexHash = git(['rev-parse', ':build-profile.json5']);
  if (filterRequired !== 'true' || cleanHash !== indexHash) {
    fail('工作树本机签名只有在 clean filter 可净化为暂存区基线时才允许存在。');
  }
}

const buildProfileIndexState = git(['ls-files', '-v', '--', 'build-profile.json5']);
if (!buildProfileIndexState.startsWith('H ')) {
  fail('build-profile.json5 不得设置 skip-worktree 或 assume-unchanged。');
}

const trackedFiles = lines(git(['ls-files']));
const forbiddenTracked = trackedFiles.filter((filePath) => isSensitivePath(filePath));
for (const filePath of forbiddenTracked) {
  fail(`禁止跟踪发布私有材料或生成产物: ${filePath}`);
}

const unexpectedTrackedReleaseAssets = trackedFiles.filter((filePath) =>
  filePath.startsWith('release-assets/') && !allowedTrackedReleaseAssets.has(filePath)
);
for (const filePath of unexpectedTrackedReleaseAssets) {
  fail(`发布资产未进入允许清单: ${filePath}`);
}

const visibleUntracked = lines(git(['ls-files', '--others', '--exclude-standard']));
const unsafeUntracked = visibleUntracked.filter((filePath) => isSensitivePath(filePath));
for (const filePath of unsafeUntracked) {
  fail(`发布私有材料或生成产物未被忽略: ${filePath}`);
}

const ignoredFiles = lines(git(['ls-files', '--others', '--ignored', '--exclude-standard']));
const ignoredReleaseArtifacts = ignoredFiles.filter((filePath) =>
  filePath.startsWith('release-assets/') || isSensitivePath(filePath)
);
const worktreeEntries = lines(git(['status', '--porcelain=v1', '--untracked-files=all']));

if (failed) {
  process.exit(1);
}

console.log(
  `workspace hygiene verified: ${trackedFiles.length} tracked files checked, ` +
  `${ignoredReleaseArtifacts.length} local release artifacts safely ignored, ` +
  `${worktreeEntries.length} ordinary worktree changes preserved`
);
