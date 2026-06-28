# Review Bundle v2 Original Photo

日期：2026-06-28

本文定义 review bundle v2 的产品边界、文件结构和双端接力规则。v2 是新增的“原图复盘包”，用于把 HarmonyOS 端的原始照片和 `review.json` 一起交给 Mac 端，为后续 Mac 可编辑复盘恢复打基础。v2 不替代 v1，不修改 Review JSON v1 字段，不引入云同步、自动同步、批量导入、双向同步、远端删除或冲突自动合并。

## 一、产品定位

review bundle 现在分成两类：

| 类型 | 定位 | 主要资产 | Mac 行为 |
| --- | --- | --- | --- |
| v1 成品图复盘包 | 归档、只读查看、跨端展示 | `review.json`、`exports/review-card.png`、`thumbnails/thumb.jpg` | 导入为 `readonlyExportReview`，展示导出的复盘成品图 |
| v2 原图复盘包 | 跨端接力、Mac 继续处理 | `review.json`、`assets/original/original.*`、可选缩略图 | 导入为 `originalPhotoReview`，保存原图和复盘内容，可显式打开为复盘卡 |

v1 继续保留当前结构和语义。v2 第一版可以不包含 `exports/review-card.png`，但必须把原图文件复制进 bundle。

## 二、目录结构

v1 结构保持不变：

```text
review_xxx/
├── manifest.json
├── review.json
├── exports/
│   └── review-card.png
├── thumbnails/
│   └── thumb.jpg
└── assets/
    └── README.md
```

v2 结构：

```text
review_xxx/
├── manifest.json
├── review.json
├── assets/
│   ├── README.md
│   └── original/
│       └── original.jpg
└── thumbnails/
    └── thumb.jpg
```

v2 第一版规则：

- `manifest.json`、`review.json`、`assets/original/original.*` 是必要文件。
- `thumbnails/thumb.jpg` 和 `assets/README.md` 是可选文件。
- `exports/review-card.png` 可缺失。
- `exportedImages` 字段仍保留，但允许为空数组。
- 如果 `thumbnailPath` 写入 manifest，则对应文件必须存在。
- 原图实际文件名使用安全 ASCII 名称，例如 `original.jpg`、`original.heic`、`original.png`。
- 原始文件名只保留在 `manifest.originalPhoto.fileName`，不作为实际路径。

家庭存储路径继续使用：

```text
Skymap/ReviewBundles/YYYY/MM/review_xxx/
```

## 三、manifest v2

v2 manifest 示例：

```json
{
  "bundleVersion": 2,
  "bundleType": "original-photo-review",
  "bundleId": "review-bundle-20260628-153000-xxxxxxxx",
  "createdAt": "2026-06-28T07:30:00.000Z",
  "updatedAt": "2026-06-28T07:30:00.000Z",
  "sourceApp": "skymap-harmonyos",
  "sourceAppVersion": "0.1.0",
  "platform": "HarmonyOS",
  "reviewJsonPath": "review.json",
  "exportedImages": [],
  "thumbnailPath": "thumbnails/thumb.jpg",
  "originalPhoto": {
    "included": true,
    "path": "assets/original/original.jpg",
    "fileName": "何藩-2.jpg",
    "mimeType": "image/jpeg",
    "pixelWidth": 7518,
    "pixelHeight": 3500,
    "fileSize": 18324521
  },
  "review": {
    "decision": "works",
    "titleText": "这张照片是否成立",
    "reviewTimeText": "2026-06-27 00:47",
    "reviewerText": "见遇"
  }
}
```

必要校验：

- `bundleVersion` 必须为 `2`。
- `bundleType` 必须为 `original-photo-review`。
- `bundleId` 必须非空。
- `reviewJsonPath` 必须为 `review.json`。
- `exportedImages` 必须存在，允许为空数组。
- `originalPhoto.included` 必须为 `true`。
- `originalPhoto.path` 必须非空且文件存在。
- `thumbnailPath` 可缺失；如果存在，对应文件必须存在。
- Mac Reader 必须同时识别 v1 和 v2，不能用 v1 的 `exports/review-card.png` 必填规则误判 v2。

## 四、Review JSON 边界

Review JSON v1 字段冻结。v2 不新增、删除、重命名或改变 `review.json` 字段语义。

禁止写入 `review.json` 的 bundle 字段：

- `bundleId`
- `bundleType`
- `originalPhoto`
- `originalPhotoPath`
- `localPath`
- `remotePath`
- `thumbnailPath`
- `exportedImages`
- `checksum`
- HarmonyOS 或 Mac 内部路径

`review.json` 仍只表达复盘内容，例如：

- `fileName`
- `titleText`
- `reviewTimeText`
- `reviewerText`
- `reviewStructure`
- `decision`
- `firstLookText`
- `attentionReasonText`
- `eyePathText`
- `visualFactText`
- `strongestRelationText`
- `extensionReasonText`
- `blockerText`

所有 bundle 级信息只进入 `manifest.json`。

## 五、HarmonyOS 导出规则

HarmonyOS 后续新增入口：

1. `导出复盘包`
   - 使用 v1。
   - 包含复盘数据和成品图。
   - 适合归档、只读查看和 Mac 展示。
2. `导出复盘包（含原图）`
   - 使用 v2。
   - 包含原始照片和复盘数据。
   - 适合 Mac 端继续处理。

v2 原图读取规则：

- 不能只保存相册 URI。
- 导出时必须立即把原图复制到 `assets/original/original.*`。
- 原图 URI 失效时提示：`原始照片无法读取，请重新选择照片。`
- 原图复制失败时提示：`原始照片保存失败，请重试。`
- 大文件沿用现有 SMB 分片上传能力。
- 必要文件任一写入或上传失败，整体导出失败。
- 不允许误提示成功。

v2 日志应区分：

- `original_read_failed`
- `original_copy_failed`
- `original_upload_failed`
- `manifest_write_failed`
- `review_json_write_failed`
- `bundle_v2_upload_failed`

本阶段暂不要求 HarmonyOS 真实 v2 导出闭环；当前 v1 导出不得被替换或破坏。

## 六、Mac 导入规则

Mac Reader 支持两类 bundle：

- v1：`bundleVersion = 1`、`originalPhoto.included = false`、`exportedImages` 包含 `exports/review-card.png`。
- v2：`bundleVersion = 2`、`bundleType = original-photo-review`、`originalPhoto.included = true`、`originalPhoto.path` 指向存在的原图文件，`exportedImages` 允许为空。

Mac library 记录类型：

| 类型 | 来源 | 资产 | 行为 |
| --- | --- | --- | --- |
| `readonlyExportReview` | v1 bundle | `review-card.png` | 只读预览成品图 |
| `originalPhotoReview` | v2 bundle | original photo | 原图预览 + 复盘内容，可点击“打开为复盘卡”恢复编辑 |

v2 不能：

- 当成 v1 只读成品图。
- 要求必须有 `exports/review-card.png`。
- 因为 `exportedImages = []` 直接判定非法。
- 把 original photo 当成 `review-card.png`。
- 污染普通照片导入流程。

Mac 端当前已支持 v2 导入和可编辑恢复入口。导入时只进入复盘库查看态；只有用户点击“打开为复盘卡”后，才把原图和 `review.json` 复盘字段恢复到主编辑器。Mac 不写回原 bundle，不自动同步。

## 七、本轮交付边界

已进入当前范围：

- 新增 v2 协议文档。
- 双端产品文档保持同步。
- HarmonyOS 增加 v2 设计和导出验证脚本，保护 v1 不被替换。
- Mac Reader、Import、Readonly Preview 和 Original Photo Restore 使用 v2 fixture 回归。
- Mac v2 原图复盘包可打开为复盘卡。

未进入当前范围：

- 云同步、自动同步、批量导入、双向同步、远端删除、冲突自动合并。
- RDB 表结构变更。
- Review JSON 字段变更。
- 废弃 v1。
