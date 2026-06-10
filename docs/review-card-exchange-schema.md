# ReviewCardExchangeSchema v1

`ReviewCardExchangeSchema v1` 用于在 HarmonyOS 手机端、Mac 端边框 App 和 GPT 交流之间传递一次摄影复盘的结构化字段。本协议只描述复盘字段 JSON，不包含云同步、二维码、账号或导出图片版式。

## 使用场景

1. 白天在 HarmonyOS 手机端完成摄影复盘。
2. 在阅读页点击「复制复盘数据」复制 pretty print JSON，或点击「导出复盘文件」保存 `*.review.json`。
3. 晚上在 Mac 端边框 App 粘贴或导入 JSON，继续排版导出，或直接发给 GPT 交流。

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
- 复制内容和导出文件内容一致，不包含导出路径、页面状态、Toast 文案或 UI 按钮文案。

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
