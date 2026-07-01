import fs from 'node:fs';
import path from 'node:path';

const productDocs = [
  'docs/product/BETA_CANDIDATE_FREEZE_2026-06.md',
  'docs/product/BETA_READINESS_AUDIT_2026-06.md',
  'docs/product/HISTORICAL_CAPABILITY_AUDIT_2026-06.md',
  'docs/product/REVIEW_LIBRARY_RDB_MIGRATION_DESIGN.md',
  'docs/product/SMB_REALITY_AUDIT.md',
  'docs/product/SMB_RECOVERY_STATUS_2026-06.md',
  'docs/product/SYNC_V0_5.md'
];

const localDocs = [
  'docs/home-stats-regression-audit-2026-06.md',
  'docs/release-v0.2-checklist.md'
];

const currentDocs = [
  'README.md',
  'docs/mobile-main-flow.md',
  'docs/product/README.md',
  'docs/product/DATA_MODEL.md',
  'docs/product/REVIEW_JSON_SEMANTICS.md',
  'docs/product/REVIEW_LIBRARY_STORAGE_AUDIT.md'
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

function assertMissing(filePath) {
  assert(!fs.existsSync(filePath), `${filePath} should stay removed from current docs`);
}

function assertIncludes(source, token, label) {
  assert(source.includes(token), `${label} missing current token: ${token}`);
}

function assertExcludes(source, token, label) {
  assert(!source.includes(token), `${label} still contains stale token: ${token}`);
}

for (const filePath of [...productDocs, ...localDocs]) {
  assertMissing(filePath);
}

const productReadme = readText('docs/product/README.md');
for (const filePath of productDocs) {
  assertExcludes(productReadme, path.basename(filePath), 'Product Layer README');
}
assertIncludes(productReadme, 'REVIEW_LIBRARY_STORAGE_AUDIT.md', 'Product Layer README');
assertIncludes(productReadme, 'HarmonyOS 已支持原图复盘包 v2 导出到家庭存储', 'Product Layer README');
assertIncludes(productReadme, '阶段性 Beta 冻结、已完成迁移设计、历史能力追溯', 'Product Layer README');

const mobileFlow = readText('docs/mobile-main-flow.md');
for (const token of [
  '系统文件保存弹窗',
  '导出复盘包',
  '导出复盘包（含原图）',
  '当前复盘库主索引是 RDB `reviews`',
  '家庭存储页负责 SMB 配置',
  'REVIEW_BUNDLE_V1_V2_CONTRACT.md',
  'REVIEW_LIBRARY_STORAGE_AUDIT.md'
]) {
  assertIncludes(mobileFlow, token, 'mobile-main-flow.md');
}
for (const token of [
  'v0.2',
  '当前导出目录为应用文件目录',
  '首页统计回归审计',
  'docs/home-stats-regression-audit-2026-06.md'
]) {
  assertExcludes(mobileFlow, token, 'mobile-main-flow.md');
}

for (const filePath of currentDocs) {
  const text = readText(filePath);
  assertExcludes(text, '/Users/', filePath);
  assertExcludes(text, 'PycharmProjects', filePath);
  assertExcludes(text, 'Documents/Codex', filePath);
}

if (failed) {
  process.exit(1);
}

console.log('product docs cleanup verified: stale docs removed, current flow updated, no local absolute paths');
