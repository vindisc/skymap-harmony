import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rulesPath = path.join(root, 'docs/harmony/UI_CLOSURE_RULES.md');
const templatePath = path.join(root, 'docs/harmony/UI_CHANGE_RECORD_TEMPLATE.md');

function fail(message) {
  console.error(message);
  process.exit(1);
}

function requireIncludes(source, marker, label) {
  if (!source.includes(marker)) {
    fail(`${label} 缺少收口规则: ${marker}`);
  }
}

if (!fs.existsSync(rulesPath) || !fs.existsSync(templatePath)) {
  fail('UI 收口规则或 UI 变更单模板缺失。');
}

const rules = fs.readFileSync(rulesPath, 'utf8');
const template = fs.readFileSync(templatePath, 'utf8');

[
  '生产基线以华为审核通过的安装包、Git 标签 `v0.1.0` 和提交 `bd4fcda` 为准',
  'P0 阻断缺陷',
  'P3 主观微调',
  '单一变更流程',
  '最低真机验收矩阵',
  '完成定义'
].forEach((marker) => requireIncludes(rules, marker, 'UI 收口规则'));

[
  '问题证据',
  '本次明确不修改',
  '验收标准',
  '验收证据',
  '决策：接受 / 退回修改 / 取消'
].forEach((marker) => requireIncludes(template, marker, 'UI 变更单模板'));

const checks = [
  'verify_compact_typography.mjs',
  'verify_main_tabs_ui_baseline.mjs',
  'verify_my_page_information_architecture.mjs',
  'verify_preview_safe_area_actions.mjs',
  'verify_widget_style_lock.mjs',
  'verify_learning_progress_widget.mjs',
  'verify_ui_copy_density.mjs',
  'verify_ui_production_completion.mjs',
  'verify_image_layout.mjs',
  'verify_feedback_semantics.mjs',
  'verify_shatter_animation.mjs',
  'verify_settings_scroll_pattern.mjs'
];

for (const check of checks) {
  const result = spawnSync(process.execPath, [path.join(root, 'scripts', check)], {
    cwd: root,
    encoding: 'utf8'
  });

  if (result.stdout) {
    process.stdout.write(result.stdout);
  }
  if (result.stderr) {
    process.stderr.write(result.stderr);
  }
  if (result.status !== 0) {
    fail(`UI 收口门禁失败: ${check}`);
  }
}

console.log(`UI closure verified: governance docs and ${checks.length} stable checks passed`);
