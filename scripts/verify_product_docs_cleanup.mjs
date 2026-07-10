import fs from 'node:fs';

const removedDocs = [
  'docs/product/CHANGE_RULES.md',
  'docs/product/FEATURE_MATRIX.md',
  'docs/product/HARMONYOS_V0_BASELINE.md',
  'docs/product/REVIEW_BUNDLE_STORAGE_BROWSER.md',
  'docs/product/REVIEW_BUNDLE_V1_DESIGN.md',
  'docs/product/REVIEW_BUNDLE_V1_E2E_CHECKLIST.md',
  'docs/product/REVIEW_BUNDLE_V1_V2_E2E_CHECKLIST.md',
  'docs/product/REVIEW_LIBRARY_V1_1.md',
  'docs/product/ROADMAP.md',
  'docs/product/SYNC_SYSTEM_V1.md',
  'docs/product/SYNC_V0_MANUAL_EXCHANGE.md',
  'docs/product/UI_INTERACTION_GUIDE.md',
  'docs/product/VISION.md',
  'docs/product/WORKFLOW.md',
  'docs/harmony/ui-production-quality-progress-2026-07-01.md'
];

const currentDocs = [
  'README.md',
  'docs/README.md',
  'docs/AUDIT_CLEANUP_SUMMARY.md',
  'docs/mobile-main-flow.md',
  'docs/review-card-exchange-schema.md',
  'docs/review-card-template-spec.md',
  'docs/harmony/main-tabs-ui-baseline-20260628.md',
  'docs/product/README.md',
  'docs/product/CURRENT_PRODUCT_SPEC.md',
  'docs/product/DATA_MODEL.md',
  'docs/product/REVIEW_BUNDLE_V1_V2_CONTRACT.md',
  'docs/product/REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md',
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

for (const filePath of removedDocs) {
  assert(!fs.existsSync(filePath), `${filePath} should stay removed from current docs`);
}

const readme = readText('README.md');
assert(readme.includes('导入待复盘'), 'README should describe the pending-review import entry');
assert(readme.includes('学习进度'), 'README should use the current stats naming');
assert(readme.includes('复盘结果'), 'README should use the current stats naming');
assert(readme.includes('docs/README.md'), 'README should point to the documentation authority index');
assert(!readme.includes('图片单选'), 'README should not describe the whole product as single-select only');

const docsReadme = readText('docs/README.md');
for (const token of [
  '唯一总入口',
  '权威顺序',
  '两条独立版本轴',
  'Review JSON Schema v1',
  'Review Bundle v1',
  'Review Bundle v2',
  '跨端边界',
  '验收快照，不是产品需求文档'
]) {
  assert(docsReadme.includes(token), `docs/README.md missing authority marker: ${token}`);
}

const mobileFlow = readText('docs/mobile-main-flow.md');
for (const token of [
  '并行双入口',
  '导入待复盘',
  '多选照片',
  '待复盘 = pendingCount',
  '复盘结果',
  'pending_review_photos'
]) {
  assert(mobileFlow.includes(token), `docs/mobile-main-flow.md missing token: ${token}`);
}

const productReadme = readText('docs/product/README.md');
assert(productReadme.includes('CURRENT_PRODUCT_SPEC.md'), 'Product README should point to the current product spec');
assert(productReadme.includes('唯一权威基线'), 'Product README should identify the authoritative bundle contract');
assert(productReadme.includes('彼此独立'), 'Product README should separate app, bundle and Review JSON versions');
for (const token of ['ROADMAP.md', 'VISION.md', 'WORKFLOW.md', 'FEATURE_MATRIX.md']) {
  assert(!productReadme.includes(token), `Product README should not keep removed doc entry: ${token}`);
}

const exchangeSchema = readText('docs/review-card-exchange-schema.md');
for (const token of [
  'Review JSON Schema v1 字段契约',
  '代码事实来源',
  'Review Bundle v1 使用 Review JSON Schema v1',
  'Review Bundle v2 仍使用 Review JSON Schema v1',
  '消费端兼容性必须在对应仓库验证'
]) {
  assert(exchangeSchema.includes(token), `Review JSON schema doc missing boundary marker: ${token}`);
}

const bundleContract = readText('docs/product/REVIEW_BUNDLE_V1_V2_CONTRACT.md');
for (const token of [
  '唯一权威基线',
  'Review Bundle v1 和 v2 当前都使用 `Review JSON Schema v1`',
  'Mac 行为属于消费端兼容约束',
  '应用版本、Bundle 版本和 Review JSON Schema 版本彼此独立'
]) {
  assert(bundleContract.includes(token), `Bundle contract missing authority marker: ${token}`);
}

const v2Doc = readText('docs/product/REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md');
assert(v2Doc.includes('专项补充'), 'Bundle v2 doc should identify itself as a supplement');
assert(v2Doc.includes('以主契约和当前代码为准'), 'Bundle v2 doc should defer to the authoritative contract');

const uiBaseline = readText('docs/harmony/main-tabs-ui-baseline-20260628.md');
for (const token of ['验收快照，不是产品需求文档', '替换规则', '旧快照随 Git 历史保留']) {
  assert(uiBaseline.includes(token), `UI baseline doc missing snapshot boundary: ${token}`);
}

const currentProductSpec = readText('docs/product/CURRENT_PRODUCT_SPEC.md');
for (const token of [
  '导入待复盘',
  '学习进度',
  '复盘结果',
  'Pending',
  'Review'
]) {
  assert(currentProductSpec.includes(token), `CURRENT_PRODUCT_SPEC.md missing token: ${token}`);
}

const storageAudit = readText('docs/product/REVIEW_LIBRARY_STORAGE_AUDIT.md');
for (const token of ['pending_review_photos', '当前是两层模型', '待复盘 = pendingCount']) {
  assert(storageAudit.includes(token), `REVIEW_LIBRARY_STORAGE_AUDIT.md missing token: ${token}`);
}

for (const filePath of currentDocs) {
  const text = readText(filePath);
  for (const token of ['/Users/', 'PycharmProjects', 'Documents/Codex']) {
    assert(!text.includes(token), `${filePath} should not contain local absolute path token: ${token}`);
  }
}

if (failed) {
  process.exit(1);
}

console.log('product docs cleanup verified: stale docs removed, current terminology retained, and no local absolute paths');
