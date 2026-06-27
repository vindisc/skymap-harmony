# Review Bundle v1 Design

日期：2026-06-27

本文定义 review bundle v1 的产品与文件格式设计，用于后续 HarmonyOS 导出到家庭存储、Mac 导入复盘库和双端接力实现。本文只做设计，不实现同步代码，不修改业务代码，不修改 Review JSON v1 字段，不修改 RDB 表结构。

## 阶段 1 实现状态

截至 2026-06-27，HarmonyOS 端 review bundle v1 阶段 1 已实现最小闭环：

- 从单条复盘预览页触发“导出复盘包”。
- 生成本地临时 bundle 目录。
- 写入 `manifest.json`、`review.json`、`exports/review-card.png`、`thumbnails/thumb.jpg`、`assets/README.md`。
- 校验 bundle 必要文件和 manifest 最小字段。
- 通过已有 SMB / 家庭存储配置写入家庭存储目录。

阶段 1 仍不是完整同步系统：

- 不做批量同步。
- 不做自动同步。
- 不做双向同步。
- 不做远端删除同步。
- 不做冲突自动合并。
- 不做 Mac 导入实现。
- 不上传 RDB、Preferences 或 `review_exchange` 目录。
- 不打包原图。

## 一、设计目标

review bundle v1 要解决的是“一次摄影复盘如何完整、稳定、可搬运地跨设备交接”：

- HarmonyOS 端把一次复盘打包成目录级 bundle。
- bundle 可以写入家庭存储、NAS、共享目录或本地同步目录。
- Mac 端后续可以从 bundle 导入复盘。
- `review.json`、导出图片、缩略图、`manifest.json` 有清晰职责。
- RDB 主索引、`review_exchange` 备份和 review bundle 三者边界清楚。
- 删除语义不跨端误删用户资产。
- v1 不依赖账号系统、不依赖云服务、不做复杂同步冲突系统。

## 二、核心原则

- review bundle 不是 RDB 主索引。
- review bundle 是跨设备交换、备份和接力格式。
- HarmonyOS 本地复盘库仍以 RDB `reviews` 为主索引。
- Mac 导入 bundle 后，应由 Mac 自己的数据结构接管，不依赖 HarmonyOS 的 RDB、`imageUri` 或沙箱路径。
- `review.json` 是 bundle 的核心复盘元数据，继续沿用当前 Review JSON v1 字段。
- `manifest.json` 是 bundle 级清单，用来描述文件、来源、完整性和接力信息，不替代 `review.json`。
- 导出图片是用户可直接查看的成品，也是 Mac 缺少原图时最可靠的视觉预览来源。
- 缩略图是浏览加速资产，不是主数据。
- 原图默认不进入 bundle v1，除非后续进入 v2 单独设计。
- 家庭存储只是存储位置，不是云数据库。
- v1 不做多端实时同步，只做“导出、导入、接力”。

## 三、bundle 目录结构

推荐家庭存储中的相对结构：

```text
Skymap/
└── ReviewBundles/
    └── 2026/
        └── 06/
            └── review_20260626_093700_a1b2c3/
                ├── manifest.json
                ├── review.json
                ├── exports/
                │   └── review-card.png
                ├── thumbnails/
                │   └── thumb.jpg
                └── assets/
                    └── README.md
```

### 目录规则

- 按年月分目录：避免单目录文件过多，便于用户按时间备份、查找和清理。
- 每个复盘一个独立目录：一次复盘的清单、内容、导出图和缩略图不会和其他复盘混在一起。
- 目录名使用 `review_YYYYMMDD_HHmmss_shortId`：时间提供人工可读排序，`shortId` 避免同秒重复。
- `shortId` 建议从 bundleId、reviewId 或规范化后的 `review.json` 内容哈希生成，取 6 到 8 位小写十六进制或 base32 字符。
- 文件名只使用 ASCII 小写字母、数字、连字符、下划线和点号，避免中文路径、空格和特殊字符带来的跨端兼容问题。
- v1 默认至少包含一张 `exports/review-card.png`。
- 允许后续存在多个导出图，例如 `exports/review-card-square.png`、`exports/review-card-vertical.png`，但 v1 默认只保留最后一次有效导出结果。
- `assets/` 在 v1 可以为空，保留 `README.md` 占位说明“不包含原图”。后续 v2 如果打包原图，再在这里扩展。

### 为什么 v1 不把原图放进 assets

- 原图体积大，家庭存储同步体积会迅速膨胀。
- HarmonyOS 的原图 URI 和权限在 Mac 或其他设备上不可直接复用。
- 当前产品核心是复盘结果接力，不是 DAM 照片库。
- 用户已能通过导出图片看到复盘成品；原图归档应进入单独的 v2 原图策略。

## 四、家庭存储目录规范

推荐根目录：

```text
/Skymap/
├── ReviewBundles/
│   └── 2026/
│       └── 06/
│           └── review_20260626_093700_a1b2c3/
├── Exports/
├── Diagnostics/
└── README.txt
```

- `ReviewBundles/` 是 review bundle 主目录，Mac 扫描和用户备份都以它为主要入口。
- `Exports/` 可用于用户主动导出的散图或临时成品，不作为 Mac 导入 bundle 的主入口。
- `Diagnostics/` 仅用于开发、排障或用户明确导出的诊断文件，不参与常规复盘库扫描。
- 不把 RDB 数据库直接同步到家庭存储。
- 不把 `review_exchange` 原样当作家庭存储目录。
- 家庭存储是 bundle 输出目标，不是应用数据库，也不承担业务合并逻辑。

## 五、manifest.json 设计

`manifest.json` 是 bundle 级清单。它回答“这个目录里有哪些文件、来自哪里、能否安全导入”，不回答“复盘内容是什么”。复盘内容仍由 `review.json` 表达。

字段草案：

```json
{
  "bundleVersion": 1,
  "bundleId": "review-bundle-20260626-093700-a1b2c3",
  "createdAt": "2026-06-26T09:37:00+08:00",
  "updatedAt": "2026-06-26T09:37:00+08:00",
  "sourceApp": "skymap-harmonyos",
  "sourceAppVersion": "0.0.0",
  "platform": "HarmonyOS",
  "reviewJsonPath": "review.json",
  "exportedImages": [
    {
      "path": "exports/review-card.png",
      "type": "review-card",
      "width": 1600,
      "height": 2400,
      "createdAt": "2026-06-26T09:37:00+08:00"
    }
  ],
  "thumbnailPath": "thumbnails/thumb.jpg",
  "originalPhoto": {
    "included": false,
    "uriHint": "file://...",
    "fileName": "IMG_0001.JPG",
    "pixelWidth": 0,
    "pixelHeight": 0
  },
  "review": {
    "decision": "works",
    "titleText": "这张照片是否成立",
    "reviewTimeText": "2026-06-26 09:37",
    "reviewerText": "王博"
  },
  "checksum": {
    "reviewJson": "sha256:...",
    "exportedImages": [
      {
        "path": "exports/review-card.png",
        "sha256": "..."
      }
    ]
  }
}
```

### 字段说明

| 字段 | 用途 | v1 是否必须 |
| --- | --- | --- |
| `bundleVersion` | 标识 bundle 格式版本，Mac 导入时先判断兼容性。 | 必须 |
| `bundleId` | 标识一个 bundle，用于重复导入判断。 | 必须 |
| `createdAt` | bundle 初次生成时间。 | 必须 |
| `updatedAt` | bundle 最近一次生成或更新清单时间。 | 必须 |
| `sourceApp` | 来源应用，例如 `skymap-harmonyos`。 | 必须 |
| `sourceAppVersion` | 来源应用版本，用于排障和兼容判断。 | 推荐 |
| `platform` | 来源平台，例如 `HarmonyOS`、`macOS`。 | 推荐 |
| `reviewJsonPath` | 指向 bundle 内的 `review.json`。 | 必须 |
| `exportedImages` | 导出图片清单，默认至少包含 `review-card.png`。 | 必须，允许空数组仅用于诊断失败包，正式 bundle 不允许为空 |
| `thumbnailPath` | 缩略图路径，用于快速浏览。 | 推荐 |
| `originalPhoto` | 记录原图是否进入 bundle 以及来源提示。 | 必须 |
| `review` | 少量摘要字段，便于 Mac 扫描时快速展示和去重。 | 推荐 |
| `checksum` | 完整性校验摘要。 | 推荐，v1 可以先 best-effort |

正式生成给用户的 bundle 至少必须有：

- `manifest.json`
- `review.json`
- 至少一张有效导出图片

缩略图、校验和、来源版本可以降级缺失，但必须在日志或 manifest 中保留可解释状态。

## 六、review.json 边界

- `review.json` 仍沿用当前 Review JSON v1 字段。
- 本轮不改 Review JSON 字段。
- `review.json` 表达单次复盘内容：标题、复盘时间、复盘人、判断、视觉落点、落点原因、视线路径、画面事实、核心关系、延伸理解和当前卡点。
- `manifest.json` 表达 bundle 文件清单和跨端接力信息。
- 不把 bundle 路径、导出图片列表、家庭存储路径、checksum 等信息塞进 `review.json`。
- 不让 `review.json` 变成远端同步协议。
- Mac / Harmony 双端字段兼容以 `review.json` 为核心边界，bundle 只是承载它的目录级外壳。

## 七、导出图片策略

- 导出图片是用户可直接查看的复盘成品。
- v1 默认至少包含一张 `exports/review-card.png`。
- 横图、竖图、方图应使用当前已经收口的导出结果保存，不重新定义模板。
- 用户多次导出时，v1 建议只保留最后一次有效导出结果，避免多版本管理提前复杂化。
- 后续如果要保留多版本，可以新增 `exports/review-card-20260626-093700.png` 并在 `manifest.json.exportedImages` 中记录多项。
- `exportedPath` 在 RDB 中仍表示“最近一次导出结果引用”。本轮不新增 RDB 字段时，不把 bundle 路径写入新的数据库列。
- 如果后续必须在本地列表展示“已导出 bundle”，应进入单独 RDB 字段设计，避免把图片导出、JSON 导出和 bundle 导出混塞进同一个语义。
- 导出图片生成失败时，不能生成正式 bundle。可以保留临时目录用于诊断，但不能写入家庭存储主目录并提示成功。

## 八、缩略图策略

- `thumbnails/thumb.jpg` 用于 Mac / Harmony 快速浏览。
- 缩略图可以来自原图，也可以来自导出图。
- v1 推荐从导出图生成缩略图，避免依赖原图 URI 或权限仍然可访问。
- 阶段 1 先由导出截图重新打包为 JPEG，暂不做裁剪和降采样；后续再补真正缩略图尺寸控制。
- 缩略图不是主数据。
- 缩略图缺失不应导致 bundle 不可导入；Mac 可退回使用导出图或占位图。
- 如果缩略图生成失败，manifest 可以省略 `thumbnailPath` 或保留空字符串，并在技术日志中记录失败原因。

## 九、原图策略

v1 默认不打包原图。

原因：

- 原图体积大。
- 原图权限和 URI 在不同设备不可直接复用。
- 家庭存储同步体积会迅速膨胀。
- 当前产品核心是复盘结果接力，不是 DAM 照片库。

`manifest.json` 可以记录：

- `originalPhoto.included = false`
- `originalPhoto.uriHint`
- `originalPhoto.fileName`
- `originalPhoto.pixelWidth`
- `originalPhoto.pixelHeight`

这些字段只用于人工识别、排障和未来配对，不保证 Mac 能访问 HarmonyOS 原图。后续 v2 如果支持 `originalPhoto.included = true`，需要单独定义文件大小、权限、压缩策略、EXIF 保留、重复照片识别和用户确认。

## 十、HarmonyOS 导出 bundle 流程

设计流程，不在本轮实现：

1. 用户在复盘详情或预览页点击“导出复盘包”。
2. 读取 RDB 中对应 `ReviewCardHistoryItem`。
3. 从 `ReviewCardDocument` 生成当前 Review JSON v1。
4. 生成或复用最后一次有效导出图片。
5. 从导出图生成 `thumbnails/thumb.jpg`。
6. 生成 `manifest.json`。
7. 写入本地临时 bundle 目录。
8. 校验必要文件存在：`manifest.json`、`review.json`、至少一张导出图。
9. 上传或复制到家庭存储目标路径。
10. 成功后给用户明确反馈，提示 bundle 已写入家庭存储。
11. 失败时清理不完整临时目录，或保留在诊断区并明确提示失败。

阶段 1 当前选择：SMB 写入失败时，本地临时 bundle 会保留在应用文件目录的 `review_bundles/` 下，用于后续排障或重试；界面只提示导出失败原因，不把未成功写入家庭存储的 bundle 宣称为已完成同步。

### 是否新增 RDB 字段

v1 设计阶段不新增 RDB 字段。

在不改 RDB 表结构的前提下：

- bundle 的事实来源是家庭存储目录中的 `manifest.json`。
- 本地是否已导出 bundle 可先通过操作日志、toast 和后续扫描判断。
- RDB 中已有 `exportedPath` 仍保留“最近一次导出结果引用”的宽泛语义，但不建议在本轮把它强行改造成 bundle 专用字段。
- 如果产品需要稳定展示 `bundleExportedPath`、`lastBundleExportedAt` 或同步状态，应进入后续阶段的 RDB 迁移设计。

## 十一、Mac 导入 bundle 流程

设计流程，不在本轮实现：

1. Mac 用户选择 bundle 目录，或 Mac 扫描家庭存储 `ReviewBundles/`。
2. 读取 `manifest.json`。
3. 校验 `bundleVersion` 是否支持。
4. 读取 `review.json`。
5. 校验 Review JSON v1 字段和 `decision` 枚举。
6. 读取导出图和缩略图。
7. 在 Mac 端建立复盘记录。
8. 如果 Mac 端已有同 `bundleId` 或同 `review.json` 内容，提示跳过、覆盖或另存为；v1 默认跳过重复。
9. 导入完成后展示在 Mac 端复盘库。

Mac 导入边界：

- Mac 不依赖 HarmonyOS RDB。
- Mac 不依赖 HarmonyOS `imageUri`。
- Mac 以 `review.json`、导出图片和 `manifest.json` 作为导入边界。
- Mac 导入后由自己的 Review Library 数据结构接管记录。

## 十二、删除语义

### HarmonyOS 本地删除复盘

- 删除 RDB 记录。
- 删除对应 `review_exchange` 应用内备份。
- 不删除原图。
- 不删除用户已导出图片。
- 不删除用户导出的 `review.json`。
- 不删除已经写到家庭存储的 bundle。

### 家庭存储 bundle 删除

- v1 不自动删除家庭存储 bundle。
- 由用户在家庭存储中自行管理。
- 后续如果做“同步删除”，必须单独设计确认策略，不能默默把一端删除传播到另一端。

### Mac 导入后删除

- 删除 Mac 端记录不应反向删除 HarmonyOS 本地记录。
- 删除 Mac 端记录不应自动删除家庭存储 bundle。
- 删除家庭存储 bundle 不应自动删除 Mac 已导入记录。

## 十三、冲突策略 v1

v1 不做复杂冲突系统，只定义最小规则：

- `bundleId` 相同：视为同一个 bundle。
- `review.json` 内容相同：可提示已导入。
- `bundleId` 不同但标题、时间、原文件名接近：不自动合并。
- Mac 导入时默认“跳过重复”，后续再支持覆盖或保留副本。
- HarmonyOS 导出时如果目标目录已存在，v1 建议创建新目录，而不是覆盖旧目录。
- 新目录可以通过重新生成 `shortId` 或附加递增后缀避免误覆盖。
- 不做双向实时同步。
- 不做远端删除同步。

## 十四、失败与恢复

### 阻止正式 bundle 生成的失败

- `review.json` 写入失败。
- `manifest.json` 写入失败。
- 导出图生成失败或缺失。
- 本地临时 bundle 目录创建失败。
- 家庭存储不可用且用户选择的目标就是家庭存储。
- 权限不足导致必要文件无法写入。

用户提示应明确说明“复盘包导出失败”，并尽量给出可执行原因，例如“家庭存储不可用”或“导出图生成失败”。

### 允许降级的失败

- 缩略图生成失败：仍可导入，Mac 可使用导出图生成预览。
- `checksum` 计算失败：仍可导入，但 manifest 应不写 checksum 或标记为空。
- `sourceAppVersion` 获取失败：不阻止导出。
- 原图 URI 信息缺失：`originalPhoto.included` 仍为 false，其他字段可为空。

### 技术日志

技术日志至少记录：

- bundleId
- 本地临时目录
- 目标家庭存储路径
- 失败步骤
- 系统错误码或异常摘要
- 已写入和已清理的文件列表

Mac 导入不完整 bundle 时：

- 缺 `manifest.json`：拒绝作为 bundle 导入，可提示用户选择 `review.json` 走手动导入。
- 缺 `review.json`：拒绝导入。
- 缺导出图：可导入文字，但提示视觉成品缺失；是否允许要由 Mac 导入阶段再定。
- 缺缩略图：允许导入。

## 十五、v1 不做范围

review bundle v1 不做：

- 不同步 RDB 数据库。
- 不同步 Preferences。
- 不直接同步 `review_exchange` 目录。
- 不打包原图。
- 不做多设备实时同步。
- 不做冲突自动合并。
- 不做账号系统。
- 不做云端服务。
- 不做版本历史。
- 不做多人协作。
- 不做摄影边框完整模板系统。
- 不改 Review JSON 字段。
- 不改 RDB 表结构。
- 不实现 Mac 导入。
- 不实现家庭存储上传代码。

## 十六、后续实现入口建议

阶段 1：bundle 本地生成

- 在 HarmonyOS 端增加本地临时 bundle 生成服务。
- 复用现有 Review JSON v1 输出和导出图片结果。
- 先验证文件结构、manifest 和失败清理。

阶段 2：家庭存储写入

- 将完整 bundle 目录复制或上传到 `Skymap/ReviewBundles/YYYY/MM/`。
- 补成功 / 失败反馈和诊断日志。

阶段 3：Mac 导入验证

- Mac 端选择 bundle 目录。
- 校验 manifest、读取 review.json、导入导出图。
- 做重复导入跳过。

阶段 4：双端回归

- HarmonyOS 导出横图、竖图、方图 bundle。
- Mac 导入并展示。
- 验证删除语义、重复导入、缺缩略图和家庭存储断开场景。
