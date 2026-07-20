import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const scriptsDirectory = path.join(root, 'scripts');
const allScripts = fs.readdirSync(scriptsDirectory)
  .filter((name) => name.startsWith('verify_') && name.endsWith('.mjs'))
  .sort();
const smokeScripts = [
  'verify_compact_typography.mjs',
  'verify_editor_template_selector.mjs',
  'verify_export_sync_copy_semantics.mjs',
  'verify_feedback_semantics.mjs',
  'verify_home_information_architecture.mjs',
  'verify_home_stats.mjs',
  'verify_home_storage_status.mjs',
  'verify_image_layout.mjs',
  'verify_learning_progress_widget.mjs',
  'verify_long_form_export_template.mjs',
  'verify_main_tabs_ui_baseline.mjs',
  'verify_motion_components_shape.mjs',
  'verify_motion_ceremony_hooks.mjs',
  'verify_motion_lifecycle_guards.mjs',
  'verify_motion_narrative_hooks.mjs',
  'verify_motion_tokens.mjs',
  'verify_ripple_layout_contract.mjs',
  'verify_my_page_information_architecture.mjs',
  'verify_my_page_rework.mjs',
  'verify_my_pages_copy_cleanup.mjs',
  'verify_photo_import_crash_guard.mjs',
  'verify_preview_safe_area_actions.mjs',
  'verify_preview_export_preferences.mjs',
  'verify_product_docs_cleanup.mjs',
  'verify_review_bundle_export.mjs',
  'verify_review_bundle_export_diagnostics.mjs',
  'verify_review_bundle_v1_v2_contract.mjs',
  'verify_review_bundle_v2_original_photo_design.mjs',
  'verify_review_bundle_v2_original_photo_export.mjs',
  'verify_review_json_export.mjs',
  'verify_review_library_preferences_retirement.mjs',
  'verify_review_library_rdb_main_read.mjs',
  'verify_review_library_rdb_main_write.mjs',
  'verify_review_library_rdb_migration.mjs',
  'verify_review_library_refresh_flow.mjs',
  'verify_review_library_backup_restore.mjs',
  'verify_review_library_v11.mjs',
  'verify_review_project_service_tests.mjs',
  'verify_scroll_edge_feedback.mjs',
  'verify_settings_entry_status.mjs',
  'verify_settings_scroll_pattern.mjs',
  'verify_settings_refresh_flow.mjs',
  'verify_shatter_animation.mjs',
  'verify_shatter_layers.mjs',
  'verify_smb_storage.mjs',
  'verify_test_automation.mjs',
  'verify_ui_production_completion.mjs',
  'verify_widget_style_lock.mjs',
  'verify_xiaoyi_intents_shape.mjs'
];

const suiteIndex = process.argv.indexOf('--suite');
const suite = suiteIndex >= 0 ? process.argv[suiteIndex + 1] : 'smoke';
if (suite !== 'smoke' && suite !== 'all') {
  console.error(`不支持的验证套件：${suite}`);
  process.exit(2);
}
const scripts = suite === 'all' ? allScripts : smokeScripts;

const failures = [];
const startedAt = Date.now();

for (const script of scripts) {
  const result = spawnSync(process.execPath, [path.join('scripts', script)], {
    cwd: root,
    encoding: 'utf8'
  });
  if (result.status === 0) {
    console.log(`PASS ${script}`);
    continue;
  }

  failures.push(script);
  console.error(`FAIL ${script}`);
  if (result.stdout.trim().length > 0) {
    console.error(result.stdout.trim());
  }
  if (result.stderr.trim().length > 0) {
    console.error(result.stderr.trim());
  }
}

const durationSeconds = ((Date.now() - startedAt) / 1000).toFixed(1);
if (failures.length > 0) {
  console.error(`验证失败：${failures.length}/${scripts.length}，耗时 ${durationSeconds}s。`);
  process.exit(1);
}

console.log(`${suite} 验证通过：${scripts.length}/${scripts.length}，耗时 ${durationSeconds}s。`);
