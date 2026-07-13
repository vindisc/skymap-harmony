import { spawnSync } from 'node:child_process';
import fs from 'node:fs';

const requiredFiles = [
  '.gitattributes',
  '.gitignore',
  'docs/release/README.md',
  'docs/release/SIGNING_MATERIALS.md',
  'docs/release/ASSET_ARCHIVE_POLICY.md',
  'docs/release/REVIEW_FEEDBACK_TEMPLATE.md',
  'docs/release/HAP_ARCHIVE_LOG.md',
  'docs/RELEASE_CLOSURE_20260709.md',
  'release-assets/README.md',
  'scripts/audit_workspace_hygiene.mjs',
  'scripts/manage_signing_profile.mjs',
  'scripts/run_device.sh',
  'scripts/verify_signing_mode_workflow.mjs',
  'README.md'
];

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

for (const filePath of requiredFiles) {
  assert(fs.existsSync(filePath), `${filePath} must exist`);
}

const gitignore = readText('.gitignore');
for (const token of [
  '.DS_Store',
  '**/.DS_Store',
  '*.p12',
  '*.p7b',
  '*.cer',
  '*.pem',
  '*.profile',
  '*.jks',
  '*.keystore',
  '*.key',
  'build-profile.local.json5',
  'release-assets/appgallery-screenshots/',
  'release-assets/signing/',
  'release-assets/packages/',
  'release-assets/submissions/',
  'release-assets/private/',
  'release-assets/*.pem',
  'release-assets/*.p7b'
]) {
  assert(gitignore.includes(token), `.gitignore missing release hygiene token: ${token}`);
}

const releaseReadme = readText('docs/release/README.md');
for (const token of [
  '发布工程卫生',
  'SIGNING_MATERIALS.md',
  'REVIEW_FEEDBACK_TEMPLATE.md',
  'HAP_ARCHIVE_LOG.md',
  'ASSET_ARCHIVE_POLICY.md',
  'audit_workspace_hygiene.mjs',
  '当前 `0.1.0` 已通过华为审核'
]) {
  assert(releaseReadme.includes(token), `docs/release/README.md missing token: ${token}`);
}

const signingDoc = readText('docs/release/SIGNING_MATERIALS.md');
for (const token of [
  'build-profile.local.json5',
  'bash scripts/build_hap.sh --signing release',
  '自动恢复无签名基线',
  '禁止提交',
  'release-assets/signing/',
  '凭据处置'
]) {
  assert(signingDoc.includes(token), `SIGNING_MATERIALS.md missing token: ${token}`);
}

const reviewTemplate = readText('docs/release/REVIEW_FEEDBACK_TEMPLATE.md');
for (const token of [
  '审核状态',
  '审核反馈原文',
  '复提说明',
  '审核状态：\n- 通过',
  '华为已经审核通过'
]) {
  assert(reviewTemplate.includes(token), `REVIEW_FEEDBACK_TEMPLATE.md missing token: ${token}`);
}

const hapLog = readText('docs/release/HAP_ARCHIVE_LOG.md');
for (const token of [
  'git tag -a v0.1.0',
  'git push origin v0.1.0',
  '华为审核通过',
  '华为审核结果 | 通过'
]) {
  assert(hapLog.includes(token), `HAP_ARCHIVE_LOG.md missing token: ${token}`);
}

const readme = readText('README.md');
assert(readme.includes('docs/release/README.md'), 'README should link to release hygiene docs');

const closure = readText('docs/RELEASE_CLOSURE_20260709.md');
assert(closure.includes('docs/release/README.md'), 'Release closure should link to release hygiene docs');

const archivePolicy = readText('docs/release/ASSET_ARCHIVE_POLICY.md');
for (const token of [
  '资产分层',
  '受控发布归档',
  'HAP_ARCHIVE_LOG.md',
  'audit_workspace_hygiene.mjs',
  '不用 `git add -f`'
]) {
  assert(archivePolicy.includes(token), `ASSET_ARCHIVE_POLICY.md missing token: ${token}`);
}

const releaseAssetsReadme = readText('release-assets/README.md');
for (const token of [
  '当前允许跟踪',
  '仅本机或发布归档保存',
  'appgallery-screenshots/',
  'signing/',
  'packages/',
  'submissions/'
]) {
  assert(releaseAssetsReadme.includes(token), `release-assets/README.md missing token: ${token}`);
}

const workspaceAudit = spawnSync(process.execPath, ['scripts/audit_workspace_hygiene.mjs'], {
  encoding: 'utf8'
});
if (workspaceAudit.stdout) {
  process.stdout.write(workspaceAudit.stdout);
}
if (workspaceAudit.stderr) {
  process.stderr.write(workspaceAudit.stderr);
}
assert(workspaceAudit.status === 0, 'Workspace hygiene audit must pass');

const signingWorkflow = spawnSync(process.execPath, ['scripts/verify_signing_mode_workflow.mjs'], {
  encoding: 'utf8'
});
if (signingWorkflow.stdout) {
  process.stdout.write(signingWorkflow.stdout);
}
if (signingWorkflow.stderr) {
  process.stderr.write(signingWorkflow.stderr);
}
assert(signingWorkflow.status === 0, 'Signing mode workflow verification must pass');

if (failed) {
  process.exit(1);
}

console.log('release hygiene verified: signing isolation, ignore rules, review template, and HAP archive log are documented');
