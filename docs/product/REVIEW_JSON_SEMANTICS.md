# Review JSON 语义说明

本文只说明当前 `review.json` 在 HarmonyOS 仓库中的真实职责和字段边界。

## 1. 当前角色

`review.json` 当前承担三种角色：

- 交换格式
- 沙箱备份格式
- 复盘包中的复盘正文格式

它当前不承担：

- 本地复盘库主索引
- 待复盘任务模型
- bundle 文件清单

## 2. 当前统一规则

- 字段名继续冻结，不新增另一套 v1 字段命名
- 空字段保留 key，值用空字符串
- `decision` 输出值继续冻结为：
  - `works`
  - `notWorks`
  - `uncertain`
- 不把 bundle 路径、导出图路径、缩略图路径、家庭存储路径或原图二进制写进 `review.json`

## 3. 与 Harmony 当前数据模型的关系

当前必须明确：

- 本地复盘库主索引是 RDB `reviews`
- `PendingReviewPhoto` 另存于 `pending_review_photos`
- `review_exchange/*.review.json` 是备份 / 交换 / 有限恢复来源
- `review.json` 不等于本地复盘库主查询源

## 4. 当前字段语义

| 字段 | 当前用户含义 |
| --- | --- |
| `titleText` | 这次复盘想回答的问题或标题 |
| `reviewTimeText` | 用户看到的复盘时间文本 |
| `reviewerText` | 当前复盘人名称 |
| `decision` | 这张照片是否成立的判断 |
| `firstLookText` | 第一眼视觉落点 |
| `attentionReasonText` | 落点原因 |
| `eyePathText` | 视线路径 |
| `visualFactText` | 画面事实 |
| `strongestRelationText` | 核心关系 |
| `extensionReasonText` | 延伸理解 |
| `blockerText` | 当前卡点 |

## 5. 当前导出责任

Harmony 当前在内部写入或打包 `review.json` 时必须保证：

- 与阅读页、导出图使用同一份复盘语义
- 阅读页可省略空段落，但 JSON 不删除对应 key
- `decision` 必须在导出前先归一化

当前状态补充：

- 独立 `review.json` 文件导出入口已暂时屏蔽
- `review.json` 仍继续作为沙箱备份和复盘包正文格式保留

## 6. 与复盘包的关系

当前复盘包使用 `review.json` 作为复盘正文，但还会额外包含：

- `manifest.json`
- 导出图
- 缩略图
- 可选原图

因此：

- `review.json` 只表达复盘正文
- 复盘包文件清单由 `manifest.json` 表达

详细边界见 [`REVIEW_BUNDLE_V1_V2_CONTRACT.md`](./REVIEW_BUNDLE_V1_V2_CONTRACT.md)。
