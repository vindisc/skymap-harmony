# Review Library v0 收口审计

日期：2026-06-12

范围：

- `skymap-mac`
- `skymap-HarmonyOS`

结论：Review Library v0 已形成「创建/导出 `review.json` -> Mac 导入写入复盘库 -> 双端查看、搜索、筛选、详情、删除库记录」的稳定闭环。当前审计只补齐文档边界和同步校验，不新增 v1 功能。

## 收口边界

本轮不新增标签、收藏、批注，不做 AI 分析、成长统计、图表分析、自动评分、云同步或多用户；不改模板系统、不改 `review.json` 字段、不改 sidecar 结构。

Review Library v0 只承担复盘索引与查看入口职责，不承担 Mac `ReviewArchive` 的工程恢复职责，也不替代原照片或原始 `review.json` 文件管理。

## Mac 职责审计

- `ReviewLibraryItem`：复盘库索引实体，负责从 `ReviewCardImportPayload` 或当前 `RenderDocument` 建立稳定记录，提供搜索文本、筛选字段和载入当前复盘卡的字段映射。
- `ReviewLibraryStore`：只负责 UserDefaults JSON 持久化、排序和 upsert，不接触照片文件、sidecar 或 `ReviewArchive`。
- `ReviewLibrarySheet`：只负责复盘库 UI，包括列表、搜索、筛选、详情、删除确认、保存当前复盘和载入当前照片入口。
- `AppModel`：负责把复盘库接入产品状态流。`importReviewCardJSON` 在 `review.json` 解析并通过文件名校验后，同时更新当前复盘卡并 upsert `ReviewLibraryItem`；`deleteReviewLibraryItem` 只移除库记录并持久化。

Mac 的「载入当前照片」会把选中的库记录复制到当前照片的摄影复盘卡字段，并覆盖当前卡片里已有复盘文本；UI 通过状态提示告知用户。这是继续编辑入口，不是原库记录的就地编辑器。

## Harmony 职责审计

- `ReviewLibraryService`：纯搜索、筛选和筛选项生成服务，不持久化、不路由、不删除文件。
- `ProjectDetailPage`：复盘库页面编排层，负责加载历史、应用筛选、打开详情和触发删除确认。
- `ReviewCardHistoryService`：本地历史记录存储层，使用 preferences 保存最多 200 条复盘历史，兼容旧记录并保留 `reviewerText`。`deleteDocument` 只删除 preferences 中的历史项，不删除照片、导出图片或已导出的 `review.json`。

旧 Harmony 历史记录没有 `reviewerText` 时，会被归一为空复盘人；它们仍会出现在「全部复盘人」下，但不会出现在具体复盘人筛选项里，也不会匹配某个具体复盘人筛选。

## 产品语义检查

1. `review.json` 仍是跨端交换来源，Review Library 只是把已接受的复盘内容沉淀成可搜索、可筛选的产品层记录。
2. Mac 导入 `review.json` 后写入复盘库，符合 Product Layer 语义：用户导入的是一条可长期管理的复盘记录，而不是仅恢复工程现场。
3. Review Library 未混入 `ReviewArchive` 职责。`ReviewArchive` 仍用于工程恢复，复盘库不直接依赖 `MacReviewArchive` 或 sidecar。
4. 删除复盘库记录只删除库索引或本地历史记录，不删除原照片，不删除用户已经导出的原始 `review.json`。
5. 双端 v0 文档同步保留相同边界：查看、搜索、筛选、详情和库记录删除；v1 的标签、收藏、批注只作为后续路线，不进入本轮实现。

## 本地环境说明

Harmony `build-profile.json5` 当前存在本机签名配置改动，包含 `/Users/wangbo/.ohos/config/...` 路径和签名材料密码。该文件是已跟踪工程文件，当前 `.gitignore` 不能实际忽略已跟踪改动；本轮确认其属于本机环境配置，保持不提交。后续若要彻底治理，应另起工程配置任务迁移本机签名信息，不能混入 Review Library v0 收口。

## 文档同步口径

- Mac 产品文档：`docs/ReviewLibraryV0.md`
- Harmony 产品文档：`docs/review-library-v0.md`
- 双端收口审计：`docs/product/REVIEW_LIBRARY_V0_AUDIT.md`
- 双端同步校验：`scripts/verify_product_docs_sync.sh`

同步校验要求两端审计文档保持一致，并检查 v0 边界、删除行为、`reviewerText` 兼容说明、`ReviewArchive` 边界和「载入当前照片」风险提示。
