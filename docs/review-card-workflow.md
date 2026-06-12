# Review Card Workflow

本文说明 HarmonyOS 复盘卡内容如何流向 Mac，并明确“跨端导入 JSON”和“Mac sidecar archive”是两条不同链路。

## 工作流总览

1. 在 HarmonyOS 编辑摄影复盘内容。
2. 在阅读页点击“复制复盘数据”，得到扁平 `review.json`。
3. 把这份 JSON 粘贴到 Mac 端导入入口。
4. Mac 通过 `ReviewCardImportPayload` 恢复标题、复盘时间、复盘人、是否成立、视觉落点、落点原因、视线路径、画面事实、核心关系、延伸理解、当前卡点。
5. 用户在 Mac 继续排版、导出。
6. Mac 导出后再写自己的 sidecar archive，供以后本地重新导入目录时自动恢复。

## HarmonyOS 输出物

HarmonyOS 当前跨端输出物是 `ReviewCardExchangeSchemaV1`：

- 结构：扁平 JSON
- 目标：Mac `ReviewCardImportPayload`
- 用途：跨端导入

它不是 Mac `ReviewArchive`，因此：

- 不包含 `schemaVersion`
- 不包含 `templateConfig`
- `reviewTimeText` / `reviewerText` 是顶层字段

协议详情见 [photoreview-cross-platform-contract.md](./photoreview-cross-platform-contract.md) 和 [review-card-exchange-schema.md](./review-card-exchange-schema.md)。

## Mac 侧两条链路

### 1. 跨端导入链路

- 输入：HarmonyOS 扁平 `review.json`
- 模型：`ReviewCardImportPayload`
- 行为：把字段写回当前选中照片的复盘模板配置

### 2. 本地 sidecar 恢复链路

- 输入：Mac 自己写在原图旁边的 `basename.review.json`
- 模型：`ReviewArchive`
- 行为：恢复模板配置、排版参数和复盘文本

不要把这两条链路的 JSON 当成同一份协议。

## 字段恢复要求

HarmonyOS 输出到 Mac 时，以下字段必须稳定恢复：

- `titleText`
- `reviewTimeText`
- `reviewerText`
- `decision`
- `firstLookText`
- `attentionReasonText`
- `eyePathText`
- `visualFactText`
- `strongestRelationText`
- `extensionReasonText`
- `blockerText`

`reviewStructure` 当前固定为 `quickReview`。

## 兼容性要求

- 保持 v1 字段名不变
- `decision` 只输出 `works`、`uncertain`、`notWorks`
- 空字段保留 key，不删除
- 不把 `reviewTimeText` / `reviewerText` 改写成 sidecar 式嵌套字段

## 当前边界

- 如果目标是“把手机复盘内容带到 Mac 继续编辑”，用跨端导入 JSON
- 如果目标是“Mac 以后再次导入原图目录时自动恢复”，用 Mac sidecar archive
