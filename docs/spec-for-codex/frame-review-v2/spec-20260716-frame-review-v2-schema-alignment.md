# 规格：Frame + Review v2 · 跨端字段对齐现状与红线

本文件是「摄影相框 · 复盘卡 v2」方案的**跨端契约盘点**。目标不是"设计新对齐"，而是**说清哪些已经对齐、v2 会引入哪些新差异、哪条红线一旦踩过就退不回来了**。

阅读前置：`spec-20260716-frame-review-v2-overview.md`、`spec-20260716-frame-review-v2-data-model.md`。

## 1. 结论先行

- **Layer 1（内容层）已经强对齐**。当前 `docs/review-card-exchange-schema.md` 定义的 Review JSON Schema v1 完全采用 skymap-mac 命名，本方案不动。
- **Layer 2（模板层）需要按本方案落地对齐**。`TemplateId` 命名空间由 skymap-mac 定义，凡纳入 Harmony 的 `TemplateId` 枚举成员其 raw value 全量沿用 Mac（**不代表**要实现 Mac 全部 29 个模板 —— MVP 只落 4 个 descriptor + 若干占位枚举，见 data-model §4.1 REGISTRY 说明），视觉允许各自演化。
- **Layer 3（呈现层）保持各自演化**。`FrameConfig`、`ExifPayload`、动效、手势不进 `review.json`，两端各自负责。
- **本方案不会触发任何跨端会议**。已对齐的部分不改；未来可选沉淀（Harmony/Mac 字段命名映射 spec、共享 spec 主版本）留在方案外，以本方案不产生阻塞为红线。

## 2. Layer 1 · 内容层对齐现状（不改）

现状代码事实来源：
- Harmony：`entry/src/main/ets/services/ReviewCardExchangeSchema.ets`
- Harmony：`entry/src/main/ets/model/ReviewCardModel.ets` L48~62
- Mac：`Sources/Skymap/Models/ConfigTypes.swift` L2356~2593
- 两端共通规范：`docs/review-card-exchange-schema.md`、`docs/review-card-template-spec.md`

### 2.1 字段名映射

| Review JSON v1 字段 | Harmony 内部字段 | Mac 内部字段 | 状态 |
| --- | --- | --- | --- |
| `fileName` | 从 `imageUri` 解析 | 从 `sourceFile.url` 解析 | 已对齐 |
| `titleText` | `content.title` | `titleText` | 已对齐 |
| `reviewTimeText` | 保存时格式化 `updatedAt` | `reviewTimeText` | 已对齐 |
| `reviewerText` | 复盘设置 `reviewerName` | `reviewerText` | 已对齐 |
| `reviewStructure` | 固定 `quickReview` | `reviewStructure` | 已对齐（Harmony 恒定值） |
| `decision` | `content.judgement` 归一化后映射 | `decision` | 已对齐 |
| `firstLookText` | `content.visualFocus` | `firstLookText` | 已对齐 |
| `attentionReasonText` | `content.focusReason` | `attentionReasonText` | 已对齐 |
| `eyePathText` | `content.visualPath` | `eyePathText` | 已对齐 |
| `visualFactText` | `content.visibleFacts` | `visualFactText` | 已对齐 |
| `strongestRelationText` | `content.coreRelation` | `strongestRelationText` | 已对齐（Mac 仍保留 `judgementText` 用于旧数据 fallback 解码到 `strongestRelationText`，但不再作为独立输出字段编码/渲染） |
| `extensionReasonText` | `content.extendedUnderstanding` | `extensionReasonText` | 已对齐 |
| `blockerText` | `content.currentBlocker` | `blockerText` | 已对齐 |

### 2.2 decision 枚举映射

| Harmony 中文 | JSON 值 | Mac 内部 | 状态 |
| --- | --- | --- | --- |
| 成立 | `works` | `.works` | 已对齐 |
| 不确定 / 待判断 | `uncertain` | `.uncertain` | 已对齐 |
| 不成立 | `notWorks` | `.notWorking`（编码时输出 `notWorks`） | 已对齐（Mac 内部 raw 与协议 raw 有差异，编码层已经磨平） |

### 2.3 本方案对 Layer 1 的态度

- **不新增字段**。任何"边框相关"参数不能进 v1。
- **不改字段命名**。`review.json` 字段名冻结。
- **不改归一化规则**。`normalizeReviewJudgement` 在 Harmony 侧继续处理"待判断 / 不确定"合并到 `uncertain`。
- **不改独立导出屏蔽状态**。`review.json` 独立文件导出入口继续保持屏蔽（`docs/product/REVIEW_JSON_SEMANTICS.md` 第 5 节）。

## 3. Layer 2 · 模板层对齐（v2 引入）

### 3.1 命名空间对齐

方案在 `spec-20260716-frame-review-v2-data-model.md` 第 4.1 节引入的 `TemplateId` 常量必须使用 skymap-mac 的字符串 raw value。以下是 Mac 端已经存在的常量对照表（来源：`Sources/Skymap/Models/Enums.swift` L3~68）：

| Mac 常量 | 字符串 raw | 是否进 Harmony v2 MVP |
| --- | --- | --- |
| `whiteEqual` | `white_equal` | ✅ MVP L0 |
| `minimalGallery` | `minimal_gallery` | ⏸ 后续 |
| `dateBottom` | `date_bottom` | ⏸ 后续 |
| `dailyMoment` | `daily_moment` | ⏸ 后续 |
| `poemFrame` | `poem_frame` | ⏸ 后续 |
| `metaBottom` | `meta_bottom` | ✅ MVP L1 |
| `exifCnBottom` | `exif_cn_bottom` | ⏸ 后续 |
| `exifMetricGrid` | `exif_metric_grid` | ⏸ 后续 |
| `cameraSignatureCenter` | `camera_signature_center` | ⏸ 后续 |
| `softFocusParameterFrame` | `soft_focus_parameter_frame` | ⏸ 后续 |
| `customSignatureFrame` | `custom_signature_frame` | ⏸ 后续 |
| `dualInfo` | `dual_info` | ⏸ 后续 |
| `calendarBottom` | `calendar_bottom` | ⏸ 后续 |
| `calendarSidebar` | `calendar_sidebar` | ⏸ 后续 |
| `calendarOverlay` | `calendar_overlay` | ⏸ 后续 |
| `paletteStrip` | `palette_strip` | ⏸ 后续 |
| `editorialPoster` | `editorial_poster` | ⏸ 后续 |
| `posterTitleOverlay` | `poster_title_overlay` | ⏸ 后续 |
| `paletteGalleryCard` | `palette_gallery_card` | ⏸ 后续 |
| `horizontalPaletteCard` | `horizontal_palette_card` | ⏸ 后续 |
| `brandDeliveryFrame` | `brand_delivery_frame` | ⏸ 后续 |
| `avatarSignature` | `avatar_signature` | ⏸ 后续 |
| `signatureOverlay` | `signature_overlay` | ✅ MVP L2 |
| `personalInfoBar` | `personal_info_bar` | ⏸ 后续 |
| `parameterSignature` | `parameter_signature` | ⏸ 后续 |
| `copyrightNotice` | `copyright_notice` | ⏸ 后续 |
| `socialCard` | `social_card` | ⏸ 后续 |
| `personalCover` | `personal_cover` | ⏸ 后续 |
| `reviewCard` | `review_card` | ✅ MVP 兼容读取（别名到 `adaptive_review_card`，UI 不暴露） |
| `adaptiveReviewCard` | `adaptive_review_card` | ✅ MVP L3（唯一 L3 实现，UI 默认入口） |

### 3.2 视觉允许的差异

模板层弱对齐 = "id 一致，视觉允许各自演化"。以下差异允许存在：

- Mac 端 `metaBottom` 默认是 `layoutMode = .singleLine` + `separator = .doubleSpace`（`ConfigTypes.swift` L1147~L1148 精确落到默认值；`.fromStoredValue` 解码在 L1187，可切换 layout 与 separator）；Harmony 端 v2 采用**始终单行 + 无分隔符**（品牌前缀已清洗，参数并排靠字体自然区隔），空间不足从右往左截断，见 mvp-templates §2.4。视觉允许差异但语义（相机 + 参数分组）一致。
- Mac 端 `whiteEqual` 使用独立 `WhiteBorderConfig`（`ConfigTypes.swift` L277 类型定义，L292~L304 `defaultConfig(width:height:)` 默认值 `borderWidth: 80`）；Harmony 用相对比例 `outerPaddingRatio=0.058`（相对图片长边，见 mvp-templates §1.2），实际像素值随原图变化。字段命名与数值体系均不同，Layer 3 呈现层不映射。
- Mac 端 `signatureOverlay` 支持 3 种叠加位置（`Enums.swift` L196~L200 `PersonalOverlayPosition` 枚举：`leftBottom / bottomCenter / rightBottom`）；Harmony MVP 只做"底部居中"一种。

### 3.3 视觉不允许的差异

以下差异一旦引入，即视为**破坏 Layer 2 对齐**，Codex 遇到必须回来找 Claude 出方案：

- 引入 Mac 端没有的新 `TemplateId`（除非 Mac 端同时补齐）
- 把 `TemplateId.WHITE_EQUAL` 渲染成"深色底黑框"（语义已经跟 raw value 强绑定）

**关于 `REVIEW_CARD` 与 `ADAPTIVE_REVIEW_CARD` 的显式允许**：Mac 端 `TemplateSpec.swift` L668 (`case .reviewCard`) 与 L690 (`case .adaptiveReviewCard`) 是**两个独立 switch case**，但**都调用同一组 blocks / frameLayout / infoBlocks 生成函数**（同文件 L668~L710 区块，两个 case 分支体共享子函数调用；配置结构 `ReviewCardTemplateConfig` 在 `ConfigTypes.swift` L2356~L2593 定义），本质是"两个 ID 共享一份渲染实现"；Harmony 侧从未存在过两份独立的 L3 实现，MVP 也不打算做。因此**允许**在 `TEMPLATE_REGISTRY` 中让两个枚举键指向同一份 `TemplateDescriptor` 对象（别名模式），`resolveTemplate('review_card')` 与 `resolveTemplate('adaptive_review_card')` 返回结果等价。这属于 Layer 2 弱对齐允许的"同一实现服务多个共用 id"，不算破坏对齐；但**保留 `TemplateId.REVIEW_CARD` 枚举成员本身不得删除**（因为老 RDB `raw_document_json` 中存在 `config.templateId = 'review_card'`，读回时必须能识别为合法枚举值、原样写回，避免 templateId 静默漂移到 `adaptive_review_card`）。

**`applyTemplateToDocument` 写入 templateId 的硬约束**：函数写入 `config.templateId` 时**必须使用调用方传入的 raw id**（即 `applyTemplateToDocument(doc, requestedId)` 中的 `requestedId`），**不得**使用 `resolveTemplate(requestedId).id`（canonical id）。示例：
- `applyTemplateToDocument(doc, 'review_card')` → `config.templateId = 'review_card'`（保留别名）
- `applyTemplateToDocument(doc, 'adaptive_review_card')` → `config.templateId = 'adaptive_review_card'`
- "恢复默认"按钮调用 `applyTemplateToDocument(doc, doc.config.templateId)` → 保留原 raw id 不漂移

**canonical id 只用于渲染分发和 UI 选中态比较**（见 editor §5.2）；持久化路径永远保留 raw id，直到用户主动切换到不同模板。

### 3.4 fallback 兼容

Mac 端 `Enums.swift` L106~125 定义了一批"旧 raw value → 新 TemplateId"的兜底映射（例如 `date_cn_bottom → dateBottom`）。Harmony v2 的 `resolveTemplate()` 实现**只需要**兼容以下最小集：

| 旧 raw | 兼容映射到 |
| --- | --- |
| `review_card` | `TemplateId.REVIEW_CARD`（保留旧血脉；descriptor 共享 `ADAPTIVE_REVIEW_CARD`） |
| 未知 raw | `TemplateId.ADAPTIVE_REVIEW_CARD` |

Mac 端的其他遗留映射（`portrait_card / clean_exif_cn / travel_note` 等）不进 Harmony，因为这些模板本身不进 MVP。

**跨端行为分歧声明**：Mac 端未知 raw 实际回退到 `whiteEqual`（`Enums.swift` L122~124），Harmony 有意回退到 `adaptive_review_card`。这是双端有意分歧，不是笔误：

- Harmony 现有 `createDefaultReviewCardDocument()` 默认 `templateId = 'review_card'`（`ReviewCardModel.ets` L176）；老 RDB 的 `raw_document_json`（含 `ReviewCardDocument.config.templateId`）全部是复盘卡血脉。若统一到 `whiteEqual`，老数据打开会从"完整复盘卡"降级为"白框空卡"，破坏"最小侵入"原则。`review_exchange/*.review.json` 遵循 Review JSON Schema v1，本身不携带 `templateId` 字段，此处不作为兜底判断依据。
- Layer 2 弱对齐的定义本身允许双端行为差异；此处的分歧落在允许范围内。
- 未来若需要开云同步或双端流通，在 converter 层做一次映射即可（"Mac 未知 → whiteEqual"、"Harmony 未知 → adaptive_review_card"两条独立规则）。

Codex 实施时**不得**擅自把 Harmony 兜底改成 `whiteEqual` 以求"跨端一致"。语义纯粹性在这里让位于"老数据无缝落回"。

## 4. Layer 3 · 本地扩展层（各自演化，跨端不映射）

**命名说明**：本层原名"呈现层"易与 data-model §1 的"呈现层 vs 数据层"分层混淆 —— 后者是 Harmony 内部数据结构分层，前者是"跨端映射视角下的本地扩展"。二者概念正交，本节仅表示"以下结构不参与跨端映射"，不改变数据层归属。

以下结构、行为、状态**只在 Harmony 侧存在**，Mac 端有类似概念但字段不同，双端不做同步：

- `FrameConfig`（Harmony 数据层归属：呈现层扩展，嵌入 `ReviewCardConfig`）：Harmony 用 `*Ratio` 相对比例，Mac 用 `outerPadding` 等绝对值。语义相同但数值体系不同，不映射。
- `ExifPayload`（Harmony 数据层归属：**数据层扩展**，作 `ReviewCardDocument` 顶层字段，见 data-model §1 第 1 条 + §4.4）；`source` 的 `AUTO / MANUAL / MIXED`：Mac 侧用 `ExifOverride` 结构（`Sources/Skymap/Models/ExifOverride.swift` L19），语义相近但字段布局不同，跨端不映射。
- `MotionQualityContext` 分档：Harmony 特有的粒子/动效降级机制，Mac 无对应概念。
- 复盘库聚合抽屉、每周仪式、粒子删除动效：Harmony 特有。
- 键盘避免（`disableSystemKeyboardAvoidance` + 手动 scroll）：Harmony 特有。

Mac 端也有一批 Harmony 无对应的结构（`TemplatePreset` 组合模板、Inspector schema、`BatchExportService`），本方案同样不映射。

## 5. `review.json` 语义扩展的**红线**

**权威源优先级**：`docs/review-card-exchange-schema.md` 是 `review.json` 内容层的**唯一权威**，`docs/product/REVIEW_BUNDLE_V1_V2_CONTRACT.md` 里若出现与之冲突的字段列表（例如提到 `templateId / templateConfig / pixelWidth / pixelHeight / orientation` 等字段进入 `review.json`），以 exchange schema 为准 —— Bundle 合同这部分描述是历史残留，与代码事实（`ReviewCardExchangeSchema.ets` 完全不含这些字段）和本方案红线均冲突，需要在方案外单独修 Bundle 合同。**本方案实施期间，Codex 遇到两文档冲突一律按 exchange schema 处理**，不改 Bundle 合同也不新增字段到 `review.json`。

**已知降级 · 灾难恢复备份不包含 v2 扩展字段**：`ReviewCardHistoryService.ets` L927~945 的沙箱备份（`review_exchange/*.review.json`）遵循 Review JSON Schema v1，**不含 `frame / templateLevel / exif`**。这意味着：**若 RDB 损坏后从沙箱 JSON 恢复，用户会失去所有 v2 模板与 EXIF 状态**（复盘正文可恢复，但相框选择、边框微调、EXIF 手改会退回默认）。

**方案的选择**：**接受此降级**，不新增本地专用 raw-document 恢复载体。理由：
- 保持 `review.json` 冻结是本方案红线，不动
- v2 扩展字段主要是"用户偏好"而非"内容资产"，丢失后用户重新选择即可
- 新增二级备份增加复杂度且不解决核心问题（RDB 损坏本身是极小概率事件）
- **PR 1 交付时必须在 `ReviewCardHistoryService.ets` 加一条注释警告**：说明 v2 扩展字段仅存在于 RDB `raw_document_json`，沙箱 JSON 备份是 v1 内容层，不承担 v2 恢复责任

**未来选项**（不在 v2 范围）：如果用户投诉 v2 状态丢失，可以另开 spec 讨论"RDB 定期导出到独立 raw-document backup 文件"，与 `review.json` 并行存在。

以下动作一旦执行，就构成"内容层脱钩"，会直接破坏跨端可读性。Codex 在实施本方案时**任何情况下都不允许触发**：

1. 在 `review.json` 里新增边框字段（例如 `borderColor / borderWidth`）
2. 在 `review.json` 里新增 EXIF 字段（例如 `cameraModel / lensModel`）
3. 在 `review.json` 里新增模板配置（例如 `templateConfig: { ... }`）
4. 改变 `decision` 的输出枚举字符串
5. 删除某个空字段的 key
6. 引入新的 `reviewStructure` 枚举值
7. 允许 `review.json` 携带非 UTF-8 字符集或 BOM
8. 把 `review.json` 从 pretty print 改成 minified

**为什么这么硬**：`review.json` 已经是复盘包正文格式（`REVIEW_BUNDLE_V1_V2_CONTRACT.md`），已经作为沙箱备份格式，未来也是 Mac / 云端消费源。任何字段变更都会污染整条链路，成本高且不可逆。

如果 v2 需要携带跨设备可恢复的模板/边框信息，正确的做法是**开一个 v2 schema，走独立文件名**（例如 `layout.json`），与 `review.json` 并列存放在复盘包里，而不是把新字段塞进 `review.json`。这个动作不在本方案范围内，需要单独立项。

## 6. 数据结构演进的**允许项**

以下动作在本方案内允许发生，且不会破坏跨端契约：

1. 在 `ReviewCardConfig` 上新增可选字段 `frame` / `templateLevel`（本地渲染层，不入 JSON）
2. 在 `ReviewCardDocument` 上新增可选字段 `exif`（本地元数据层，不入 JSON）
3. 在 `reviews` RDB 表上新增冗余列 `template_id / template_level / camera_model / lens_model`（本地索引，不入 JSON）
4. `version` 字段从 `'0.1.0'` 升至 `'0.2.0'`（**落盘 schema 版本**，权威定义与升级规则见 data-model §4.4；不影响 `review.json` JSON schema 号 —— `review.json` 内容层由独立的 exchange schema 定义）
5. 在 `cloneReviewCardDocument()` 里对新字段增加 fallback 分支
6. 在 `ReviewCardExchangeSchema.ets` 里保持既有序列化路径不变，新增字段在这里被**主动丢弃**（不写入 JSON）

第 6 条是本方案的关键护栏：**`ReviewCardExchangeSchema.ets` 是 Layer 1 的唯一序列化出口**，它必须在演进后仍然只序列化 v1 字段。Codex 实施时要在这个文件里加一条断言注释：

```typescript
// Layer 1 契约冻结点：本文件只序列化 Review JSON Schema v1 字段。
// 任何新增的 config.frame / exif / templateLevel 字段都不能出现在输出 JSON 中。
// 修改前请阅读 docs/spec-for-codex/frame-review-v2/spec-20260716-frame-review-v2-schema-alignment.md 第 5 节。
```

## 7. 未来若走跨端同步的准备度评估

本方案落地后，**如果未来产品决定做双端同步**，可复用度评估：

| 复用度 | 项 | 说明 |
| --- | --- | --- |
| ✅ 直接可用 | Review JSON Schema v1 | 已经对齐 |
| ✅ 直接可用 | `TemplateId` 字符串命名空间 | 双端一致 |
| ⚠️ 需要转换 | `FrameConfig` 相对比例 vs Mac 绝对值 | 需要 converter |
| ⚠️ 需要新协议 | 模板配置传输格式 | 未定义，需要新开 spec |
| ⚠️ 需要新协议 | `ExifPayload` 传输格式 | 未定义，需要新开 spec |
| ❌ 不复用 | 动效、手势、粒子、Motion Quality | 呈现层各自演化 |

评估结论：**如果未来做同步，Layer 1 + Layer 2 已经省了约 50% 的对齐工作**。Layer 3 的差异是正常的、不需要弥合的。

## 8. 待人工确认清单

以下问题**不阻塞本方案实施**，但影响 v2 之后是否要开新一轮跨端对齐：

1. **Harmony 与 Mac 的复盘字段命名映射表**：Mac 端 `titleText / attentionReasonText / blockerText` 等已是 first-class 字段且 Inspector UI 已暴露；Harmony 端使用 `content.title / focusReason / currentBlocker` 等语义等价字段。两侧字段名不同，但 `ReviewCardExchangeSchema.ets` 已在序列化时做了映射（对齐到 Mac 命名）。是否要把这份映射表沉淀成独立 spec 文档，方便未来跨端同步 converter 复用？
2. 是否要推动 Mac 端把 `reviewStructure` 常量集扩展？目前 Harmony 恒定 `quickReview`，Mac 支持三种，双端演进方向不同。
3. 未来复盘包若要携带模板视觉信息，走 `layout.json` 独立文件的方式是否可以先在 Harmony 端预留结构，不影响当前 bundle 协议？
4. 复盘包 v2 的原图携带能力（`REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md`）与本方案的"原图导出"是否需要归口到同一份原图缓存策略？

以上问题的答案不在本方案交付物内，允许 Codex 在阶段 A/B 完成后再回头讨论。
