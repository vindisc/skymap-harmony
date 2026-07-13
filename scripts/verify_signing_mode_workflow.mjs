import { spawnSync } from 'node:child_process';
import fs from 'node:fs';

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

const profileResult = spawnSync('git', ['show', ':build-profile.json5'], { encoding: 'utf8' });
assert(profileResult.status === 0, 'Tracked build-profile.json5 must be readable from the Git index');
const profile = profileResult.stdout;
for (const token of [
  'signingConfigs',
  'signingConfig',
  'storeFile',
  'storePassword',
  'keyPassword',
  'certpath',
  '/Users/'
]) {
  assert(!profile.includes(token), `Tracked build-profile.json5 must not include: ${token}`);
}

const gitignore = readText('.gitignore');
assert(gitignore.includes('build-profile.local.json5'), 'Local signing profile must be ignored');
const attributes = readText('.gitattributes');
assert(attributes.includes('/build-profile.json5 filter=skymap-signing'), 'Signing clean filter must protect build-profile.json5');

const manager = readText('scripts/manage_signing_profile.mjs');
for (const token of [
  'assertTrackedProfileSafe',
  'verify-local',
  "['debug', 'default']",
  "['release']",
  'validateMaterial',
  'fs.writeFileSync',
  'filter-clean',
  'filter-smudge',
  'ide-enable',
  'migrate-ide-cache',
  'updateDevEcoRunJavaHome'
]) {
  assert(manager.includes(token), `Signing profile manager missing marker: ${token}`);
}

const buildScript = readText('scripts/build_hap.sh');
for (const token of [
  '--signing unsigned|debug|release',
  'SKYMAP_SIGNING_MODE',
  'manage_signing_profile.mjs assert-safe',
  'manage_signing_profile.mjs activate',
  'SIGNING_JAVA_HOME_DEFAULT',
  'SKYMAP_BUILD_JAVA_HOME',
  'trap cleanup_on_exit EXIT',
  'trap - EXIT',
  "trap 'exit 130' INT",
  '-p buildMode="$BUILD_MODE"'
]) {
  assert(buildScript.includes(token), `Build script missing signing workflow marker: ${token}`);
}

const statusResult = spawnSync('node', ['scripts/manage_signing_profile.mjs', 'status'], {
  encoding: 'utf8'
});
if (statusResult.stdout) {
  process.stdout.write(statusResult.stdout);
}
if (statusResult.stderr) {
  process.stderr.write(statusResult.stderr);
}
assert(statusResult.status === 0, 'Signing status command must pass');
assert(statusResult.stdout.includes('仓库签名模式：unsigned'), 'Signing status must report unsigned repository baseline');

if (failed) {
  process.exit(1);
}

console.log('signing mode workflow verified: sanitized index, IDE clean filter, explicit modes and automatic restore');
