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

const profile = readText('build-profile.json5');
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

const manager = readText('scripts/manage_signing_profile.mjs');
for (const token of [
  'assertTrackedProfileSafe',
  'verify-local',
  "['debug', 'default']",
  "['release']",
  'validateMaterial',
  'fs.writeFileSync'
]) {
  assert(manager.includes(token), `Signing profile manager missing marker: ${token}`);
}

const buildScript = readText('scripts/build_hap.sh');
for (const token of [
  '--signing unsigned|debug|release',
  'SKYMAP_SIGNING_MODE',
  'manage_signing_profile.mjs assert-safe',
  'manage_signing_profile.mjs activate',
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

console.log('signing mode workflow verified: sanitized repository profile, local overlay, explicit modes and automatic restore');
