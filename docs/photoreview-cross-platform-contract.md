# PhotoReview Cross-Platform Contract

本文定义 HarmonyOS 与 Mac 之间可稳定传递的复盘 JSON 合同，并明确区分两类 JSON：

1. 跨端导入 JSON：HarmonyOS 导出、Mac 粘贴或导入时读取
2. Mac sidecar archive：Mac 写回原图旁用于本地自动恢复

这两类 JSON 不能混用，也不要共享同一套“顶层字段必须完全一致”的假设。

## 一句话结论

- HarmonyOS `ReviewCardExchangeSchemaV1` 对接的是 Mac `ReviewCardImportPayload`
- Mac `ReviewArchive` 是本地 sidecar archive，不是 HarmonyOS v1 导出协议

## 协议矩阵

| 场景 | 文件形态 | 真实模型 | 是否跨端 | 说明 |
| --- | --- | --- | --- | --- |
| 手机端复制 / 导出复盘 JSON 给 Mac | 扁平 `*.review.json` 或剪贴板文本 | Harmony `ReviewCardExchangeSchemaV1` / Mac `ReviewCardImportPayload` | 是 | 用于把复盘内容带到 Mac 继续排版 |
| Mac 导出后写入原图旁边的 sidecar | `basename.review.json` | `ReviewArchive` | 否 | 用于 Mac 下次批量导入目录时自动恢复模板与复盘配置 |

## 跨端导入 JSON v1

这是 HarmonyOS 应输出、Mac 应导入的 flat schema。顶层字段如下：

```json
{
  "fileName": "DSC00910.jpg",
  "titleText": "这张照片是否成立",
  "reviewTimeText": "2026-06-07 21:08",
  "reviewerText": "王博",
  "reviewStructure": "quickReview",
  "decision": "works",
  "firstLookText": "视线先落在主体脸部与亮部边缘。",
  "attentionReasonText": "亮度对比和人物完整度让主体先被看到。",
  "eyePathText": "从主体移动到背景高光，再回到人物轮廓。",
  "visualFactText": "人物位于画面左侧，右侧有一块更亮背景。",
  "strongestRelationText": "人物轮廓与背景高光之间的主次关系。",
  "extensionReasonText": "可以继续观察主体、背景与观看顺序之间的关系。",
  "blockerText": "右侧高光抢走部分注意力。"
}
```

字段要求：

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `fileName` | 推荐 | 用于提示当前图片是否匹配 |
| `titleText` | 是 | 标题 |
| `reviewTimeText` | 是 | 复盘时间文本 |
| `reviewerText` | 是 | 复盘人文本，未设置时允许空字符串 |
| `reviewStructure` | 是 | 当前标准值为 `quickReview` |
| `decision` | 是 | 仅允许 `works` / `uncertain` / `notWorks` |
| `firstLookText` | 是 | 视觉落点 |
| `attentionReasonText` | 是 | 落点原因 |
| `eyePathText` | 是 | 视线路径 |
| `visualFactText` | 是 | 画面事实 |
| `strongestRelationText` | 是 | 核心关系 |
| `extensionReasonText` | 是 | 延伸理解；旧记录缺失时 Mac 可用默认值兜底 |
| `blockerText` | 是 | 当前卡点 |

兼容说明：

- HarmonyOS 输出时保留全部 key，空内容用空字符串
- Mac 导入时兼容缺失的 `reviewStructure` 和 `extensionReasonText`
- `reviewTimeText` 与 `reviewerText` 在这里是顶层字段，不能删，也不能误写进别的层级

## Mac sidecar archive

Mac sidecar archive 不是上面的 flat schema，而是 `ReviewArchive`：

```json
{
  "schemaVersion": 1,
  "appVersion": "1.0.0",
  "fileName": "IMG_0001.JPG",
  "fileType": "jpg",
  "pixelWidth": 4032,
  "pixelHeight": 3024,
  "orientation": 1,
  "templateId": "adaptive_review_card",
  "templateConfig": {},
  "titleText": "这张照片是否成立",
  "reviewStructure": "quickReview",
  "decision": "works",
  "firstLookText": "…",
  "attentionReasonText": "…",
  "eyePathText": "…",
  "visualFactText": "…",
  "strongestRelationText": "…",
  "extensionReasonText": "…",
  "blockerText": "…"
}
```

关键区别：

- 顶层有 archive 元数据和复盘摘要字段
- 顶层没有 `reviewTimeText`
- 顶层没有 `reviewerText`
- `reviewTimeText` / `reviewerText` 位于 `templateConfig.settings.reviewCard` 或 `templateConfig.settings.adaptiveReviewCard` 内

## 恢复语义

Mac 两条恢复链路不同：

1. `ReviewCardImportPayload`
   直接把 flat schema 写回当前选中图片的复盘模板配置。
2. `ReviewArchive`
   先从 `templateConfig` 恢复完整模板，再用顶层摘要字段覆盖同名文本。

因此：

- 不要把 `reviewTimeText` / `reviewerText` 误认为 sidecar 顶层字段
- 不要把 sidecar `templateConfig` 误认为跨端导入 JSON 的一部分
- 不要让 HarmonyOS 为了“对齐 sidecar”去重命名现有 v1 flat schema 字段

## 字段映射

| 用户语义 | Harmony v1 / Mac Import | Mac Sidecar 顶层 | Mac Sidecar `templateConfig` |
| --- | --- | --- | --- |
| 标题 | `titleText` | `titleText` | `titleText` |
| 复盘时间 | `reviewTimeText` | 不存在 | `reviewTimeText` |
| 复盘人 | `reviewerText` | 不存在 | `reviewerText` |
| 是否成立 | `decision` | `decision` | `decision` |
| 视觉落点 | `firstLookText` | `firstLookText` | `firstLookText` |
| 落点原因 | `attentionReasonText` | `attentionReasonText` | `attentionReasonText` |
| 视线路径 | `eyePathText` | `eyePathText` | `eyePathText` |
| 画面事实 | `visualFactText` | `visualFactText` | `visualFactText` |
| 核心关系 | `strongestRelationText` | `strongestRelationText` | `strongestRelationText` |
| 延伸理解 | `extensionReasonText` | `extensionReasonText` | `extensionReasonText` |
| 当前卡点 | `blockerText` | `blockerText` | `blockerText` |

## 当前闭环结论

- HarmonyOS 当前输出字段名与 Mac `ReviewCardImportPayload` 一致，可稳定导入
- Mac `ReviewArchive` 与跨端导入 JSON 不是同一种协议，文档必须分开描述
- `reviewTimeText` / `reviewerText` 只能说“跨端导入 JSON 顶层字段 + sidecar 嵌套字段”，不能说成“sidecar 顶层字段”
