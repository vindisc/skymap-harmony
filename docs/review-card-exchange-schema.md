# Review JSON Schema v1 字段契约

文档角色：本文件记录 HarmonyOS 当前生成的 `ReviewCardExchangeSchema v1` 字段契约。代码事实来源是 `entry/src/main/ets/services/ReviewCardExchangeSchema.ets`；本文件不定义复盘包目录、云同步、账号、导出图片版式，也不声明任何消费端已经实现的功能。

`Review JSON Schema v1` 只描述一次摄影复盘的结构化正文。它可以作为独立复制内容、沙箱备份正文或 Review Bundle v1 / v2 中的 `review.json`。

## 与复盘包版本的关系

- Review Bundle v1 使用 Review JSON Schema v1。
- Review Bundle v2 仍使用 Review JSON Schema v1。
- `bundleVersion` 写在 `manifest.json`，不得写进 `review.json`。
- Bundle 版本升级不代表 Review JSON Schema 升级。

复盘包容器规则以 [`REVIEW_BUNDLE_V1_V2_CONTRACT.md`](./product/REVIEW_BUNDLE_V1_V2_CONTRACT.md) 为唯一权威基线。

## 使用场景

1. HarmonyOS 在预览页复制 pretty print JSON。
2. HarmonyOS 将同一字段结构写入沙箱备份或家庭存储。
3. HarmonyOS 导出 Review Bundle v1 / v2 时，将其作为 `review.json` 正文。

其他应用可以消费这份 JSON，但消费端兼容性必须在对应仓库验证，不能从本文推导为 HarmonyOS 当前能力。

## 字段定义

| 字段 | 类型 | 手机端来源 | 说明 |
| --- | --- | --- | --- |
| `fileName` | string | 照片文件名 | 从照片 URI 尝试解析；无法读取时为空字符串。 |
| `titleText` | string | 标题 | 对应手机端 `title`。 |
| `reviewTimeText` | string | 复盘时间 | 使用 `YYYY-MM-DD HH:mm` 格式。 |
| `reviewerText` | string | 复盘设置中的复盘人 | 未设置时输出空字符串。 |
| `reviewStructure` | string | 复盘结构 | 固定为 `quickReview`。 |
| `decision` | string | 是否成立 | 使用英文枚举，便于 Mac 端解析。 |
| `firstLookText` | string | 视觉落点 | 第一眼先看到哪里。 |
| `attentionReasonText` | string | 落点原因 | 为什么它会先被看到。 |
| `eyePathText` | string | 视线路径 | 视线接着从哪里走到哪里。 |
| `visualFactText` | string | 画面事实 | 画面里的可见事实。 |
| `strongestRelationText` | string | 核心关系 | 最重要的画面关系。 |
| `extensionReasonText` | string | 延伸理解 | 对成立或不成立的进一步理解。 |
| `blockerText` | string | 当前卡点 | 当前最大问题。 |

所有字段必须保留。旧记录缺少字段时，对应字段输出空字符串，不删除 key。

`reviewerText` 来自「复盘设置」中的复盘人名称；未设置时输出空字符串。复制动作读取已保存配置，不读取未保存的输入框临时值。

## decision 枚举

手机端中文状态先经过 `normalizeReviewJudgement` 统一清洗，再映射为协议枚举：

| 手机端状态 | `decision` |
| --- | --- |
| 成立 | `works` |
| 待判断 / 不确定 | `uncertain` |
| 不成立 | `notWorks` |

JSON 协议不直接输出中文状态；手机端 UI 仍保留中文显示。

## 手机端生成规则

- `reviewStructure` 固定为 `quickReview`。
- `decision` 必须经过 `normalizeReviewJudgement` 后再映射，兼容旧记录中的「待判断」和「不确定」。
- 空字段保留 key，值为空字符串。
- JSON 使用 `JSON.stringify(value, null, 2)` pretty print。
- 复制内容不包含导出路径、页面状态、Toast 文案或 UI 按钮文案。

## 示例 JSON

```json
{
  "fileName": "DSC00910.jpg",
  "titleText": "这张照片是否成立",
  "reviewTimeText": "2026-06-07 21:08",
  "reviewerText": "",
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
