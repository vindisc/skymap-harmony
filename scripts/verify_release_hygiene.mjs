import fs from 'node:fs';

const requiredFiles = [
  '.gitignore',
  'docs/release/README.md',
  'docs/release/SIGNING_MATERIALS.md',
  'docs/release/REVIEW_FEEDBACK_TEMPLATE.md',
  'docs/release/HAP_ARCHIVE_LOG.md',
  'docs/RELEASE_CLOSURE_20260709.md',
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
  'release-assets/appgallery-screenshots/',
  'release-assets/signing/',
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
  '不提前创建 `v0.1.0` tag'
]) {
  assert(releaseReadme.includes(token), `docs/release/README.md missing token: ${token}`);
}

const signingDoc = readText('docs/release/SIGNING_MATERIALS.md');
for (const token of [
  'products[0].signingConfig',
  '提审 / 发布态必须指向 `release`',
  '禁止提交',
  'release-assets/signing/',
  'git status --short'
]) {
  assert(signingDoc.includes(token), `SIGNING_MATERIALS.md missing token: ${token}`);
}

const reviewTemplate = readText('docs/release/REVIEW_FEEDBACK_TEMPLATE.md');
for (const token of [
  '审核状态',
  '审核反馈原文',
  '复提说明',
  '等待华为审核结果'
]) {
  assert(reviewTemplate.includes(token), `REVIEW_FEEDBACK_TEMPLATE.md missing token: ${token}`);
}

const hapLog = readText('docs/release/HAP_ARCHIVE_LOG.md');
for (const token of [
  'git tag -a v0.1.0',
  'git push origin v0.1.0',
  '等待华为审核结果',
  '当前不提前创建 tag'
]) {
  assert(hapLog.includes(token), `HAP_ARCHIVE_LOG.md missing token: ${token}`);
}

const readme = readText('README.md');
assert(readme.includes('docs/release/README.md'), 'README should link to release hygiene docs');

const closure = readText('docs/RELEASE_CLOSURE_20260709.md');
assert(closure.includes('docs/release/README.md'), 'Release closure should link to release hygiene docs');

if (failed) {
  process.exit(1);
}

console.log('release hygiene verified: signing isolation, ignore rules, review template, and HAP archive log are documented');
