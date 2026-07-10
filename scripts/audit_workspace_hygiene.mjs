import { spawnSync } from 'node:child_process';

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
    sensitiveExtension.test(filePath) ||
    forbiddenTrackedPrefixes.some((prefix) => filePath.startsWith(prefix));
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

const buildProfileStatus = git(['status', '--porcelain=v1', '--', 'build-profile.json5']);
if (buildProfileStatus.length > 0) {
  fail('build-profile.json5 存在未提交的本机签名切换，请在发布或提交前单独处理。');
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
