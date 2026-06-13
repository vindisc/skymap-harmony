# Review Library v1 验收审计

日期：2026-06-13

范围：

- `skymap-mac`
- `skymap-HarmonyOS`

结论：Review Library v1 轻量体验增强通过验收。双端改动仍停留在查看、定位、回看和继续编辑体验层，不新增标签、收藏、批注、成长统计或 AI 分析，不修改 `review.json` 字段，不修改 Mac `ReviewArchive` 或 sidecar 结构。

## Mac 验收

1. 本机照片路径只存在于 Mac 本地 Review Library 索引。
   - `localPhotoPath` 只在 `ReviewLibraryItem`、`AppModel.saveCurrentReviewToLibrary` 和复盘库 UI 中使用。
   - `ReviewLibraryItem(payload:)` 从 `review.json` 导入时写入 `localPhotoPath: nil`。
   - `currentReviewCardImportJSON()` 仍只生成 `ReviewCardImportPayload` 字段，不包含本机路径。

2. 缩略图只作为本地运行时展示。
   - 缩略图由 `ReviewLibraryThumbnail` 在运行时用 `NSImage(contentsOf:)` 从本机路径读取。
   - 复盘库不复制原图，不缓存缩略图文件，不把缩略图写入跨端协议。

3. Finder 定位只影响 Mac 本地。
   - `revealReviewLibraryPhotoInFinder` 只在路径可访问时调用 `NSWorkspace.shared.activateFileViewerSelecting`。
   - 该能力不移动、不复制、不修改原图，也不影响 Harmony。

4. 载入当前照片继续编辑不会自动覆盖外部文件。
   - `loadReviewLibraryItemToCurrentPhoto` 只把库记录字段应用到当前工作区的 `RenderDocument`。
   - UI 弹窗和 Toast 均说明不会自动覆盖原始 `review.json`、不会修改原照片，只有保存当前复盘后才会更新复盘库。

## Harmony 验收

1. 列表卡片空字段不显示脏占位。
   - `ReviewLibraryListCard` 使用 `getReviewerDisplayText` 和 `getReviewBlockerText` 归一空字符串。
   - 复盘人为空时不显示复盘人文本；当前卡点为空时不显示卡点行。

2. 空状态入口不破坏原有创建流程。
   - 复盘库空状态按钮复用 `pickSinglePhoto` 和 `ReviewCardStore.createPhotoDraft`，然后进入 `EDITOR_PAGE`。
   - 该流程与首页「开始复盘」保持同一条照片选择和草稿创建链路。

3. 删除边界保持清晰。
   - 删除确认仍说明只删除复盘库记录，不删除原照片或已导出的文件。

4. 旧记录兼容保持不变。
   - 旧记录没有 `reviewerText` 时仍归一为空复盘人。
   - 这些记录仍出现在「全部复盘人」下，但不会进入具体复盘人筛选项，也不会匹配具体复盘人筛选。

## Product Layer 验收

- 双端 `docs/product/FEATURE_MATRIX.md` 保持一致，并标记 Review Library v1 轻量体验增强已推进。
- 双端 `docs/product/ROADMAP.md` 保持一致，并把标签、收藏、批注继续放在后续路线。
- 双端 `scripts/verify_product_docs_sync.sh` 会校验 v0 审计、v1 文档、Feature Matrix、Roadmap 和本验收文档同步。

## 禁止项复核

本轮未新增：

- 标签系统
- 收藏系统
- 批注系统
- 成长统计
- AI 分析
- `review.json` 字段
- Mac `ReviewArchive` / sidecar 结构
- 原图复制或删除能力
