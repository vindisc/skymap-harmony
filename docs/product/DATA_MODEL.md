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
```

## Review

Review 表示一次针对照片的摄影复盘。

| 字段 | 职责 | 归属 |
| --- | --- | --- |
| reviewId | 标识一次复盘，便于归档、同步和去重。 | 产品模型 |
| photoRef | 关联被复盘的照片。 | 产品模型 |
| titleText | 复盘标题，例如「这张照片是否成立」。 | 产品模型 |
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

## 当前边界

- Harmony Client 当前主要创建 Review、Photo 的轻量记录和单张复盘图 ExportJob。
- Mac Client 当前主要消费 Photo、Template、Preset、Profile，并承担批量 ExportJob。
- Review 与 review.json 是跨端优先级最高的统一模型。
- 搜索、筛选和成长统计需要基于上述产品模型建立，不能直接依赖某个客户端的页面列表状态。
