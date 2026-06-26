# Skymap Product Data Model

## 产品模型与客户端实现

本文定义的是 Skymap Product 的领域模型，不是任何客户端的代码类型、页面状态或本地存储结构。

产品模型回答：

- 用户在摄影工作流里真实关心哪些对象。
- 这些对象之间如何关联。
- 跨客户端交换时哪些字段必须保持同一语义。

客户端实现回答：

- 某个平台如何读取照片、保存本地记录、渲染页面、调用系统导出或管理权限。
- 某个平台如何命名内部文件、缓存和 UI 状态。

规则：

- 产品字段可以映射到客户端实现，但不能被某个客户端的内部结构绑架。
- review.json 是产品交换文件，不等于任意客户端的完整内部状态。
- 客户端可以有私有字段，但不得改变产品字段语义。

## 领域关系

```text
Profile
  ├─ owns Preset
  └─ fills Template variables

Photo
  ├─ has Review
  ├─ uses Template
  └─ participates in ExportJob

Review
  ├─ references Photo
  ├─ can be serialized as review.json
  └─ can be rendered by Template

Preset
  ├─ belongs to Template or ExportJob
  └─ reuses Profile information

ExportJob
  ├─ consumes Photo, Review, Template and Preset
  └─ produces exported files and archive records

SyncSystem
  ├─ moves Review through review bundle
  ├─ uses SMB, WebDAV or local folder as SyncTarget
  └─ imports into Review Library through ImportRecord
```

## Review

Review 表示一次针对照片的摄影复盘。

`review.json` 的字段语义以 [`REVIEW_JSON_SEMANTICS.md`](./REVIEW_JSON_SEMANTICS.md) 为准；当前表格只定义 Review 领域对象中必须稳定存在的产品字段。

### HarmonyOS 端复盘库存储说明

HarmonyOS 端当前复盘库主存储详见 [`REVIEW_LIBRARY_STORAGE_AUDIT.md`](./REVIEW_LIBRARY_STORAGE_AUDIT.md)。

当前必须明确：

- HarmonyOS 端复盘库主索引是 RDB `reviews`
- `Preferences(review_card_history.items)` 只作为旧版本数据迁移 / 诊断来源
- 当前历史项结构为 `ReviewCardHistoryItem = document + exportedPath`
- 原图二进制不进入复盘库，`imageUri` 只是原图引用
- `exportedPath` 是导出结果引用，不是原图路径
- `review.json` 可以作为交换和恢复副本存在，但不等于复盘库主查询源

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| reviewId | 标识一次复盘，便于归档、同步和去重。 | 产品模型 |
| photoRef | 关联被复盘的照片。 | 产品模型 |
| titleText | 复盘标题，例如「这张照片是否成立」。 | 产品模型 |
| reviewTimeText | 复盘时间文本，用于阅读页、导出图和跨端回看时的同一时间口径。 | 产品模型 |
| reviewerText | 复盘人文本，用于标记这次复盘由谁完成。 | 产品模型 |
| reviewStructure | 表示复盘框架，例如快速复盘、构图光线、故事表达。 | 产品模型 |
| decision | 表示成立、不成立或不确定。 | 产品模型 |
| firstLookText | 第一眼视觉落点。 | 产品模型 |
| attentionReasonText | 视觉落点原因。 | 产品模型 |
| eyePathText | 视线路径。 | 产品模型 |
| visualFactText | 画面事实。 | 产品模型 |
| strongestRelationText | 核心关系。 | 产品模型 |
| extensionReasonText | 延伸理解。 | 产品模型 |
| blockerText | 当前卡点。 | 产品模型 |
| reviewerRef | 关联复盘人资料。 | 产品模型 |
| createdAt / updatedAt | 支持排序、回看和同步冲突判断。 | 产品模型 |
| sourceClient | 记录首次创建来源，用于排障和产品分析，不改变字段语义。 | 产品模型 |

## Photo

Photo 表示一张进入 Skymap 工作流的照片。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| photoId | 标识照片，便于多次复盘、导出和同步关联。 | 产品模型 |
| fileName | 原始文件名，用于 review.json、导出命名和人工识别。 | 产品模型 |
| sourceLocation | 照片在当前客户端可访问的位置。 | 客户端实现 |
| pixelWidth / pixelHeight | 判断横图、竖图、方图和导出版式。 | 产品模型 |
| orientation | 保存原始方向信息，避免跨端显示不一致。 | 产品模型 |
| capturedAt | 拍摄时间，用于日期模板、搜索和成长统计。 | 产品模型 |
| exifSummary | 相机、镜头、焦段、光圈、快门、ISO 等摘要。 | 产品模型 |
| manualOverrides | 用户手动修正的照片资料或 EXIF 信息。 | 产品模型 |
| linkedReviewIds | 关联该照片的复盘记录。 | 产品模型 |

## Template

Template 表示把照片、复盘和资料渲染成成品的表达方式。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| templateId | 稳定标识模板，供预设、导出、归档和兼容使用。 | 产品模型 |
| displayName | 面向用户的中文名称。 | 产品模型 |
| family | 模板分组，例如极简、参数、日历、色卡、个人、品牌、复盘。 | 产品模型 |
| purpose | 说明模板服务的摄影工作流场景。 | 产品模型 |
| requiredInputs | 标明模板依赖照片、EXIF、资料、复盘字段或品牌信息。 | 产品模型 |
| layoutRules | 描述横图、竖图、方图和长文本的产品级布局约束。 | 产品模型 |
| supportedClients | 标明哪些客户端可以创建、编辑或渲染该模板。 | 产品模型 |
| version | 支持模板演进和旧数据兼容。 | 产品模型 |

## Preset

Preset 表示用户希望重复使用的一组选择。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| presetId | 标识一个用户预设。 | 产品模型 |
| name | 用户可识别的中文名称。 | 产品模型 |
| scope | 区分模板预设、导出预设、资料预设或颜色预设。 | 产品模型 |
| targetTemplateId | 当预设服务某个模板时，关联对应模板。 | 产品模型 |
| parameters | 保存可复用的参数集合，具体落地由客户端转换。 | 产品模型 |
| isDefault | 表示是否作为某个范围的默认选择。 | 产品模型 |
| ownerProfileRef | 关联创建或拥有该预设的资料。 | 产品模型 |
| updatedAt | 支持排序、同步和冲突提示。 | 产品模型 |

## Profile

Profile 表示复用在复盘、模板、署名、品牌和导出命名中的身份资料。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| profileId | 标识一份资料。 | 产品模型 |
| role | 区分个人、品牌、复盘人或当前照片资料。 | 产品模型 |
| displayName | 中文显示名或署名。 | 产品模型 |
| signatureText | 签名文本。 | 产品模型 |
| copyrightText | 版权文本。 | 产品模型 |
| website | 网站或作品集链接。 | 产品模型 |
| socialHandle | 社交账号。 | 产品模型 |
| avatarRef | 头像或标识图片引用。 | 客户端实现 |
| brandStyle | 品牌色、品牌署名等可复用视觉信息。 | 产品模型 |

## ExportJob

ExportJob 表示一次导出动作，不等同于单张导出按钮点击。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| exportJobId | 标识一次导出任务。 | 产品模型 |
| inputPhotoRefs | 本次导出的照片集合。 | 产品模型 |
| inputReviewRefs | 本次导出使用的复盘集合。 | 产品模型 |
| templateRef | 本次导出的模板。 | 产品模型 |
| presetRef | 本次导出使用的预设。 | 产品模型 |
| outputFormat | 输出格式，例如 JPEG。 | 产品模型 |
| canvasRatio | 输出画布比例。 | 产品模型 |
| namingRule | 文件命名规则。 | 产品模型 |
| destination | 保存到本地目录、系统相册、家庭存储或其他位置。 | 产品模型 |
| status | 排队、导出中、成功、部分失败或失败。 | 产品模型 |
| resultRefs | 导出产物引用。 | 客户端实现 |
| errorSummary | 用户可理解的失败原因。 | 产品模型 |

## SyncSystem

SyncSystem 表示 Skymap 在 Harmony、家庭存储、Mac 和 Review Library 之间的同步能力。

SyncSystem 是产品级文件流转模型，不是云服务器、账号系统或客户端内部数据库。SyncSystem v1 优先支持家庭存储：SMB、WebDAV 和本地同步目录。

### SyncTarget

SyncTarget 表示一个可被用户选择或配置的同步位置。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| syncTargetId | 标识一个同步位置。 | 产品模型 |
| kind | 区分 SMB、WebDAV 或本地文件夹。 | 产品模型 |
| displayName | 用户可识别的中文名称。 | 产品模型 |
| rootPath | 指向 `Skymap/` 根目录的位置描述。 | 客户端实现 |
| lastScanAt | Mac 最近一次扫描时间。 | 客户端实现 |
| status | 可用、不可用、权限失败或等待挂载。 | 产品模型 |
| errorSummary | 用户可理解的失败原因。 | 产品模型 |

### ReviewBundle

ReviewBundle 表示一次复盘在家庭存储中的目录级同步单元。

推荐结构：

```text
Skymap/
└── Reviews/
    └── 2026/
        └── 06/
            └── review-20260613-091530-a1b2c3/
                ├── review.json
                ├── manifest.json
                ├── photo.jpg
                └── preview.jpg
```

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| bundleId | 标识一个 review bundle。 | 产品模型 |
| reviewRef | 指向 bundle 内的 `review.json`。 | 产品模型 |
| manifestRef | 指向 bundle 内的 `manifest.json`。 | 产品模型 |
| photoRef | 可选照片副本。 | 产品模型 |
| previewRef | 可选预览图。 | 产品模型 |
| createdAt / updatedAt | 支持排序、扫描和冲突判断。 | 产品模型 |
| sourceClient | 标记 Harmony、Mac 或手动导入来源。 | 产品模型 |

### BundleManifest

BundleManifest 表示 bundle 内的文件清单和完整性摘要，不替代 `review.json`。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| manifestVersion | 清单版本。 | 产品模型 |
| bundleId | 对应 ReviewBundle。 | 产品模型 |
| reviewFile | `review.json` 文件名、大小和可选哈希。 | 产品模型 |
| photoFile | 可选照片文件名、大小、像素尺寸和可选哈希。 | 产品模型 |
| previewFile | 可选预览文件名、大小和可选哈希。 | 产品模型 |
| sourceClient | 首次创建 bundle 的客户端。 | 产品模型 |
| createdAt | bundle 创建时间。 | 产品模型 |

### ImportRecord

ImportRecord 表示 Mac 已经处理过的同步对象。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| importRecordId | 标识一次导入记录。 | 客户端实现 |
| bundleId | 已导入或已跳过的 bundle。 | 产品模型 |
| reviewId | 关联导入后的 Review。 | 产品模型 |
| sourcePath | 导入来源路径。 | 客户端实现 |
| importedAt | 导入时间。 | 客户端实现 |
| result | 已导入、已存在、冲突、失败或缺失文件。 | 产品模型 |
| errorSummary | 用户可理解的失败原因。 | 产品模型 |

### ConflictRecord

ConflictRecord 表示无法自动判断的同步冲突。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| conflictRecordId | 标识一次冲突。 | 客户端实现 |
| conflictType | 同 ID 内容不同、疑似重复照片、缺失文件或来源移动。 | 产品模型 |
| primaryRef | 已存在记录。 | 产品模型 |
| incomingRef | 新发现记录。 | 产品模型 |
| detectedAt | 发现时间。 | 客户端实现 |
| recommendedAction | 跳过、保留副本、手动选择或重新扫描。 | 产品模型 |

## 当前边界

- Harmony Client 当前主要创建 Review、Photo 的轻量记录和单张复盘图 ExportJob。
- Mac Client 当前主要消费 Photo、Template、Preset、Profile，并承担批量 ExportJob。
- Review 与 review.json 是跨端优先级最高的统一模型。
- SyncSystem v1 只设计家庭存储优先的文件同步，不引入云服务器、账号体系或第三方后端。
- 搜索、筛选和成长统计需要基于上述产品模型建立，不能直接依赖某个客户端的页面列表状态。
