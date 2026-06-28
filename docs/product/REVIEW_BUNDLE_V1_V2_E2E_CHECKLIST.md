# Review Bundle v1 / v2 E2E Checklist

日期：2026-06-28

本文是 review bundle 双协议端到端回归清单。执行时必须同时保护 v1 成品图复盘包和 v2 原图复盘包，不能让两条链路串线。

## A. HarmonyOS v1 导出

1. 当前复盘点击“导出复盘包”。
2. 家庭存储生成 v1 bundle。
3. bundle 包含 `manifest.json`、`review.json`、`exports/review-card.png`、`thumbnails/thumb.jpg`、`assets/README.md`。
4. `manifest.bundleVersion=1`。
5. `manifest.originalPhoto.included=false`。
6. `manifest.exportedImages` 不为空，且包含 `exports/review-card.png`。
7. `review.json` 字段未污染，不包含 bundleId、originalPhoto、thumbnailPath、exportedImages、远端路径或本地路径。

## B. Mac v1 导入

1. 导入 v1 bundle。
2. 复盘库新增记录。
3. 记录来源显示为复盘包或只读成品图。
4. 中栏显示 `review-card.png`。
5. 右栏显示 `review.json` 复盘内容。
6. 不显示“打开为复盘卡”。
7. 关闭复盘库后主编辑器状态不污染。
8. `review-card.png` 不能作为当前照片进入主编辑器。

## C. HarmonyOS v2 导出

1. 当前复盘点击“导出复盘包（含原图）”。
2. 家庭存储生成 v2 bundle。
3. bundle 包含 `manifest.json`、`review.json`、`assets/original/original.*`、`assets/README.md`。
4. `manifest.bundleVersion=2`。
5. `manifest.bundleType=original-photo-review`。
6. `manifest.originalPhoto.included=true`。
7. `manifest.originalPhoto.path` 指向存在且 size 大于 0 的原图文件。
8. `manifest.exportedImages=[]` 合法。
9. v2 不要求 `exports/review-card.png`。
10. 原图文件可打开。
11. `review.json` 字段未污染，不包含 bundle 级路径或远端信息。

## D. Mac v2 导入

1. 导入 v2 bundle。
2. 复盘库新增“原图复盘包”记录。
3. 中栏显示原图。
4. 右栏显示 `review.json` 复盘内容。
5. 显示“打开为复盘卡”。
6. 原图缺失时按钮禁用或打开失败。
7. 重复导入同一 bundle 不新增第二条记录。

## E. Mac v2 打开为复盘卡

1. 点击“打开为复盘卡”。
2. 如果已有当前照片，出现确认弹窗。
3. 用户确认后复盘库关闭。
4. 主编辑器显示基于原图和复盘内容的复盘卡。
5. Inspector 显示可编辑模板和复盘内容。
6. `review.json` 中标题、复盘时间、复盘人、结构、decision、视觉落点、视线路径、画面事实、最强关系、延伸理解、卡点等字段已恢复。
7. `templateId` 可识别时优先恢复；缺失或不兼容时降级默认摄影复盘卡。
8. 可从 Mac 导出当前复盘卡图片。
9. 不写回原 bundle，不写回家庭存储远端文件。

## F. 错误场景

1. v1 缺 `exports/review-card.png`，导入失败。
2. v2 缺 `originalPhoto.path`，导入失败。
3. v2 `originalPhoto.path` 指向文件不存在，导入失败。
4. v2 原图文件 size 为 0，导入失败。
5. v1 / v2 重复导入不新增第二条。
6. 非家庭网络导出提示连接家庭 Wi-Fi 或 VPN。
7. 家庭存储账号密码错误时提示检查设置。
8. v2 原图不可读时提示重新选择照片。
9. v1 不出现“打开为复盘卡”。
10. v2 不因为缺少 `review-card.png` 被当作 v1 失败。

## G. 自动化回归

HarmonyOS：

```bash
JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home bash scripts/build_hap.sh
node scripts/verify_review_bundle_export.mjs
node scripts/verify_review_bundle_export_diagnostics.mjs
node scripts/verify_review_bundle_v2_original_photo_design.mjs
node scripts/verify_review_bundle_v2_original_photo_export.mjs
node scripts/verify_export_sync_copy_semantics.mjs
node scripts/verify_home_storage_reachability.mjs
node scripts/verify_review_bundle_v1_v2_contract.mjs
git diff --check
```

Mac：

```bash
swift test --filter ReviewBundleReaderTests
swift test --filter ReviewBundleImportServiceTests
swift test --filter ReviewBundleReadonlyPreviewTests
swift test --filter ReviewBundleOriginalPhotoRestoreTests
swift test --filter ReviewLibraryStoreTests
swift test --filter GlobalUIPolishRegressionTests
swift test
git diff --check
```

Docs：

```bash
bash scripts/verify_product_docs_sync.sh
```

## H. fixture 说明

自动化 fixture 可以使用脱敏小图，但必须保留真实 HarmonyOS 导出目录结构。不得把真实隐私照片、家庭存储绝对路径或用户本地路径提交到公开仓库。
