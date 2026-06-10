# 摄影复盘数据链路 v0.3.1

## 当前工作流

```text
拍照
↓
手机复盘
↓
导出 review.json
↓
家庭存储
↓
Mac 导入
↓
导出图片
↓
GPT 交流
```

白天在 HarmonyOS 端查看照片并填写摄影复盘；阅读页导出 `*.review.json` 后，用户在系统保存面板中选择家庭存储里的 `摄影资料库/Reviews` 目录。晚上 Mac 端选择这个 JSON 文件导入，恢复复盘内容，再使用 Mac 端现有导出图片能力生成最终图片。

## review.json 作用

`review.json` 是摄影复盘标准交换文件，用来在 HarmonyOS、家庭存储、Mac 端和 GPT 交流之间传递一次复盘的结构化字段。

当前文件只保存复盘文本字段，不包含照片二进制、导出图片、云同步状态、账号信息、目录扫描状态或设备同步元数据。

## 当前版本

当前版本固定为 `ReviewCardExchangeSchema v1`。

本轮不升级协议、不改字段名、不新增字段。导出文件内容直接使用当前 `ReviewCardExchangeSchema`：

```json
{
  "fileName": "DSC00910.jpg",
  "titleText": "这张照片是否成立",
  "reviewTimeText": "2026-06-07 21:08",
  "reviewerText": "",
  "reviewStructure": "quickReview",
  "decision": "works",
  "firstLookText": "视觉落点",
  "attentionReasonText": "落点原因",
  "eyePathText": "视线路径",
  "visualFactText": "画面事实",
  "strongestRelationText": "核心关系",
  "extensionReasonText": "延伸理解",
  "blockerText": "当前卡点"
}
```

## HarmonyOS 导出

阅读页操作顺序：

```text
编辑
复制复盘数据
导出图片
导出复盘文件
```

点击「导出复盘文件」后，App 使用系统文档保存面板让用户选择保存位置。推荐保存到：

```text
摄影资料库/Reviews
```

文件名规则：

```text
原照片文件名.review.json
```

例如原照片为 `DSC00910.jpg` 时，导出文件名为：

```text
DSC00910.review.json
```

如果无法解析原照片文件名，则使用：

```text
review-时间戳.json
```

## Mac 导入

Mac 端导入入口：

```text
导入复盘文件
```

流程：

```text
选择 *.review.json
↓
解析 ReviewCardExchangeSchema v1
↓
填充现有复盘数据模型
↓
进入现有导出图片流程
```

字段映射：

| review.json 字段 | 恢复内容 |
| --- | --- |
| `titleText` | 标题 |
| `firstLookText` | 视觉落点 |
| `attentionReasonText` | 落点原因 |
| `eyePathText` | 视线路径 |
| `visualFactText` | 画面事实 |
| `strongestRelationText` | 核心关系 |
| `extensionReasonText` | 延伸理解 |
| `blockerText` | 当前卡点 |
| `decision` | 是否成立 |
| `reviewerText` | 复盘人 |
| `reviewTimeText` | 时间 |

`decision` 枚举保持 v1 定义：`works`、`uncertain`、`notWorks`。

## 验证清单

1. HarmonyOS 端填写视觉落点、落点原因、视线路径、画面事实、核心关系、延伸理解、当前卡点。
2. 阅读页点击「导出复盘文件」。
3. 保存为 `DSC00910.review.json`。
4. 保存到 `摄影资料库/Reviews`。
5. Mac 端点击「导入复盘文件」并选择该 JSON。
6. 确认标题、复盘人、时间、是否成立和全部复盘字段恢复。
7. Mac 端导出图片，确认图片内容与 JSON 字段一致。
