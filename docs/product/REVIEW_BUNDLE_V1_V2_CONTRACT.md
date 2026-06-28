# Review Bundle v1 / v2 Contract

日期：2026-06-28

本文是 Mac 与 HarmonyOS 共同遵守的 review bundle 双协议基线。v1 是成品图复盘包，v2 是原图复盘包；v2 不替代 v1，v1 不废弃。Review JSON 字段继续冻结，bundle 级信息只放在 `manifest.json`。

## 一、概览

| 协议 | 产品定位 | 必要资产 | Mac 行为 | HarmonyOS 行为 |
| --- | --- | --- | --- | --- |
| v1 成品图复盘包 | 归档、只读查看、跨端展示 | `review.json`、`exports/review-card.png`、`thumbnails/thumb.jpg`、`manifest.json` | 导入为只读成品图记录，不显示“打开为复盘卡” | 导出复盘内容和成品图到家庭存储 |
| v2 原图复盘包 | 跨端接力、Mac 继续处理 | `review.json`、`assets/original/original.*`、`manifest.json` | 导入为原图复盘包，可显式打开为复盘卡 | 导出复盘内容和原图到家庭存储 |

当前不包含自动同步、批量导入、双向同步、远端删除、冲突合并、云数据库或写回原 bundle。

## 二、v1 结构

```text
review_v1_sample/
├── manifest.json
├── review.json
├── exports/
│   └── review-card.png
├── thumbnails/
│   └── thumb.jpg
└── assets/
    └── README.md
```

v1 规则：

- `bundleVersion` 为 `1`。
- `originalPhoto.included` 为 `false`。
- `exportedImages` 必须包含 `exports/review-card.png`。
- `thumbnailPath` 指向 `thumbnails/thumb.jpg`。
- Mac 只读预览 `review-card.png`，不得把它作为原图进入主编辑器。

## 三、v2 结构

```text
review_v2_original_photo_sample/
├── manifest.json
├── review.json
└── assets/
    ├── README.md
    └── original/
        └── original.*
```

可选：

```text
thumbnails/
└── thumb.jpg
```

v2 规则：

- `bundleVersion` 为 `2`。
- `bundleType` 为 `original-photo-review`。
- `originalPhoto.included` 为 `true`。
- `originalPhoto.path` 指向 `assets/original/original.*`，文件必须存在且 size 大于 0。
- `exportedImages` 必须存在，允许为空数组 `[]`。
- v2 不要求、也不依赖 `exports/review-card.png`。
- 原始文件名只保存在 `manifest.originalPhoto.fileName`；实际路径使用安全文件名。

## 四、Review JSON 冻结原则

`review.json` 只表达复盘内容和模板恢复所需字段。允许字段继续保持当前语义，例如：

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
- `templateId`
- `templateConfig`
- `pixelWidth`
- `pixelHeight`
- `orientation`

禁止写入 `review.json`：

- `bundleId`
- `bundleType`
- `originalPhoto`
- `originalPhoto.path`
- `thumbnailPath`
- `exportedImages`
- `checksum`
- 远端路径
- 本地路径
- HarmonyOS 或 Mac 内部存储字段

`decision` 只接受 `works`、`notWorks`、`uncertain`。

## 五、manifest 职责

`manifest.json` 承担 bundle 级信息：

- `bundleVersion`
- `bundleType`
- `bundleId`
- `reviewJsonPath`
- `originalPhoto`
- `exportedImages`
- `thumbnailPath`
- `review` summary
- 创建与更新时间
- 来源应用和平台

manifest 可以描述资产路径、导出图、缩略图、原图文件名、MIME、像素尺寸和文件大小；这些信息不得回写到 `review.json`。

## 六、Mac 行为

- v1 导入为只读成品图记录。
- v1 中栏显示 `review-card.png`。
- v1 不显示“打开为复盘卡”。
- v1 `review-card.png` 不能进入主编辑器。
- v2 导入为“原图复盘包”记录。
- v2 中栏显示原图，右栏显示 `review.json` 内容。
- v2 只有用户点击“打开为复盘卡”后才进入主编辑器。
- v2 打开后恢复原图、复盘字段、复盘卡模板和 Inspector 可编辑状态。
- v2 打开失败时提示检查原图文件。
- Mac 不自动写回原 bundle，不自动同步，不做双向合并。

## 七、HarmonyOS 行为

- v1 入口继续导出成品图复盘包。
- v1 生成 `review-card.png`，并写入家庭存储。
- v2 入口导出“复盘包（含原图）”。
- v2 必须复制原图到 `assets/original/original.*`，并写入家庭存储。
- v2 原图不可读时失败提示用户重新选择照片。
- v2 不生成 `review-card.png`，`exportedImages=[]` 合法。
- v1 / v2 用户文案必须清楚区分“成品图归档”和“含原图继续处理”。

## 八、当前不包含

- 自动同步
- 批量导入
- 双向同步
- 远端删除
- 冲突合并
- 云数据库
- 写回原 bundle
- 家庭存储远端覆盖
- Review JSON 字段扩展
- manifest v1 / v2 协议语义变更
