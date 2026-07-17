# 规格：Frame + Review v2 · 核心数据结构

本文件是「摄影相框 · 复盘卡 v2」方案的**数据结构规格**。Codex 在阶段 A 实施前，必须先完整阅读本文；本文与 `spec-20260716-frame-review-v2-overview.md`、`spec-20260716-frame-review-v2-schema-alignment.md` 三份文档合起来才是完整的规格。

本文使用 ArkTS 类型声明作为规格载体。**这些声明是规格，不是最终代码**——Codex 落地时可以按现有代码风格调整 import 顺序、命名格式、Codable 兜底策略，但**不得改动字段名、字段语义、枚举值、默认值**。

## 1. 演进原则

1. **`ReviewCardDocument` 不重写，只演进**。当前 `entry/src/main/ets/model/ReviewCardModel.ets` L71~82 定义的对象继续作为主索引记录。本方案允许新增字段，但按语义分层落位：
   - **呈现层扩展**（例如 `FrameConfig`）嵌入 `ReviewCardConfig` 内部，跟 `templateId / layoutMode / background / textSize` 并列；
   - **数据层扩展**（例如 `ExifPayload`）作为可选顶层字段，与 `imageUri / imageWidth / imageHeight` 并列；
   - 两类字段不混放。判断标准：字段值是否与"用户在编辑器里可调的呈现参数"直接相关——是则入 `config`，否则入顶层。
2. **`review.json` v1 字段命名冻结**。任何新数据按 §1 第 1 条的分层原则落位——**呈现层扩展**进 `ReviewCardConfig`，**数据层扩展**作 `ReviewCardDocument` 可选顶层字段，**查询/聚合冗余**进本地 RDB 附属列——但**绝对不进 `review.json`**。
3. **旧文档必须能被无损读取**。所有新字段都要提供 `fallback` 默认值，`cloneReviewCardDocument()` 兼容处理保持现有分支不动，新字段走独立分支。
4. **模板 ID 命名空间与 skymap-mac 共用**。Codex 不得自行发明新 ID，必须使用本文第 4 节列出的枚举。

## 2. 现有结构快照（不要改动）

作为 diff 基准，先记录当前锚点，Codex 在实施时必须**从这里长出去**：

| 现有结构 | 位置 | 关键字段 |
| --- | --- | --- |
| `ReviewContent` | `ReviewCardModel.ets` L48~62 | title / visualFocus / focusReason / visualPath / visibleFacts / coreRelation / judgement / extendedUnderstanding / currentBlocker |
| `ReviewCardConfig` | `ReviewCardModel.ets` L64~69 | templateId / layoutMode / background / textSize |
| `ReviewCardDocument` | `ReviewCardModel.ets` L71~82 | version / projectId / imageUri / imageWidth / imageHeight / imageSizeFallbackUsed / content / config / createdAt / updatedAt |
| `ReviewCardHistoryItem` | `ReviewCardModel.ets` L84~87 | document / exportedPath |
| `ReviewCardLayoutMode` | `ReviewCardModel.ets` L1~6 | AUTO / HORIZONTAL_PHOTO_BOTTOM_TEXT / VERTICAL_PHOTO_RIGHT_TEXT / SQUARE_PHOTO_BOTTOM_TEXT |
| `ReviewCardRenderMode` | `ReviewCardModel.ets` L8~11 | MOBILE_READING / EXPORT_CARD |
| `ReviewCardLayoutType` | `ReviewCardModel.ets` L13~17 | HORIZONTAL / VERTICAL / SQUARE |
| `ReviewCardBackground` | `ReviewCardModel.ets` L26~29 | WHITE / LIGHT_GRAY |
| `ReviewCardTextSize` | `ReviewCardModel.ets` L31~35 | SMALL / STANDARD / LARGE |
| `ReviewJudgementStatus` | `ReviewCardModel.ets` L37~41 | '成立' / '不确定' / '不成立'（中文枚举） |
| `resolveLayoutMode / resolveReviewCardLayoutResolution` | `ReviewCardLayout.ets` L9~59 | layout 解析工具（import 自 ReviewCardModel） |

**关键约束**：`ReviewJudgementStatus` 是中文枚举，仅用于 UI 与本地存储；导出 JSON 时经 `normalizeReviewJudgement` 归一化后再由 `ReviewCardExchangeSchema.ets` 映射为 `works / uncertain / notWorks`。**本方案不动这条链路**。

## 3. 新增结构总览

方案 v2 引入的新结构：

```
TemplateDescriptor           模板骨架（跨端命名空间）
    ├── id            : TemplateId         模板标识
    ├── level         : TemplateLevel      L0/L1/L2/L3
    ├── contentBinding: TemplateContentBinding  该模板需要哪些字段
    └── defaults      : TemplateDefaults   该模板的推荐默认配置

FrameConfig                  边框呈现层（不进 review.json）
    ├── outerPaddingRatio    : number      外留白占图片长边比例
    ├── innerPaddingRatio    : number      图与文字区之间的间距占比
    ├── cornerRadiusRatio    : number      圆角占图片短边比例
    ├── backgroundColorHex   : string      画布背景色
    ├── textColorHex         : string      主文字色
    ├── secondaryTextColorHex: string      次文字色
    ├── titleFontRatio       : number      标题字号占图片短边比例
    ├── bodyFontRatio        : number      正文字号占图片短边比例
    ├── labelFontRatio       : number      标签字号占图片短边比例
    ├── lineSpacingRatio     : number      行距占正文字号比例
    ├── fieldSpacingRatio    : number      字段间距占正文字号比例
    ├── logoAssetId          : string      可选 logo 资产 ID
    └── watermarkText        : string      可选水印文本

ExifPayload                  EXIF 元数据（半结构化，可覆盖）
    ├── cameraMake           : string
    ├── cameraModel          : string
    ├── lensMake             : string
    ├── lensModel            : string
    ├── focalLength          : string      标准化文本，例如 "35mm"
    ├── aperture             : string      例如 "f/2.8"
    ├── shutter              : string      例如 "1/500s"
    ├── iso                  : string      例如 "ISO400"
    ├── captureDate          : string      YYYY-MM-DD HH:mm
    ├── location             : string      短文本，用户可编辑
    ├── source               : ExifSource  auto / manual / mixed
    └── manuallyOverridden   : Array<string>   记录被手动改过的键
```

**关键设计取舍**：

- 所有几何量用**相对比例**（`*Ratio`），不用 dp。原因：屏幕预览是 375~430 pt，导出目标是原图长边（可能 6000+ px），只有相对量才能同时服务两端。相对基准写在 `FrameConfig` 定义里。
- `FrameConfig` 不进 `review.json`。它属于呈现层，跟着本地 RDB 走。跨端时 Layer 2 通过 `templateId` 建立视觉一致性，不搬 `FrameConfig` 值。
- `ExifPayload` 单独一层是因为它既服务模板渲染（L1 参数框需要），又服务复盘库聚合（按相机/镜头/焦段筛选），也服务未来的原图归档。同一份数据不能散落到几个地方。
- 保留 `manuallyOverridden` 字段是因为 EXIF 自动读取 + 用户手动改是并存的，未来重新加载原图时要知道哪些字段"用户已经动过，不要覆盖"。

## 4. 完整 ArkTS 规格

以下声明作为 Codex 的直接实施依据。文件位置建议：

- `entry/src/main/ets/model/TemplateModel.ets` —— 模板骨架与枚举
- `entry/src/main/ets/model/FrameConfigModel.ets` —— 边框呈现层
- `entry/src/main/ets/model/ExifPayloadModel.ets` —— EXIF 结构

`ReviewCardModel.ets` 只做**扩展**：`FrameConfig` 作为呈现层扩展嵌入 `ReviewCardConfig`；`ExifPayload` 作为数据层扩展作为可选顶层字段与 `imageUri` 并列。分层理由见第 1 节第 1 条。

### 4.1 TemplateModel.ets

```typescript
export enum TemplateId {
  // 命名空间与 skymap-mac `Enums.swift` 完全对齐；MVP 只登记 4 个 descriptor（其余成员保留占位，
  // resolveTemplate 兜底到 ADAPTIVE_REVIEW_CARD）。凡纳入本枚举的成员，其 raw value 全量沿用 Mac。
  // L0 · 相框
  WHITE_EQUAL = 'white_equal',
  MINIMAL_GALLERY = 'minimal_gallery',
  DATE_BOTTOM = 'date_bottom',

  // L1 · 参数框
  META_BOTTOM = 'meta_bottom',
  EXIF_CN_BOTTOM = 'exif_cn_bottom',

  // L2 · 一句话
  SIGNATURE_OVERLAY = 'signature_overlay',
  PERSONAL_INFO_BAR = 'personal_info_bar',

  // L3 · 复盘卡（沿用现有）
  REVIEW_CARD = 'review_card',
  ADAPTIVE_REVIEW_CARD = 'adaptive_review_card'
}

export enum TemplateLevel {
  L0_FRAME = 'l0Frame',
  L1_META = 'l1Meta',
  L2_NOTE = 'l2Note',
  L3_REVIEW = 'l3Review'
}

export interface TemplateContentBinding {
  useTitle: boolean;
  useCaption: boolean;
  useExif: boolean;
  useReviewFields: boolean;
  useJudgement: boolean;
  useReviewer: boolean;
  useDate: boolean;
  useLogo: boolean;
}

export interface TemplateDefaults {
  frame: FrameConfigSpec;
  captionSourceHint: TemplateCaptionSource;
}

export enum TemplateCaptionSource {
  NONE = 'none',
  DATE = 'date',
  LOCATION = 'location',
  REVIEWER = 'reviewer',
  CUSTOM = 'custom'
}

export interface TemplateDescriptor {
  id: TemplateId;
  level: TemplateLevel;
  displayName: string;
  displayNameEn: string;
  contentBinding: TemplateContentBinding;
  defaults: TemplateDefaults;
  /**
   * 该模板允许用户在参数抽屉中选择的背景色白名单（#RRGGBB 大写）。
   * L0 仅允许 ['#FFFFFF']（禁改），L1/L3 允许 ['#FFFFFF','#F6F1E8','#F0F0F0']，
   * L2 允许 ['#F6F1E8','#FFFFFF']。editor-ux §3.5 与 mvp §8 共用此契约。
   * 若为空数组，等同于"背景色选项灰置整行不可选"（例如未来某模板要求锁定）。
   */
  allowedBackgroundColors: Array<string>;
}

export const TEMPLATE_REGISTRY: Partial<Record<TemplateId, TemplateDescriptor>> = {
  // 具体表内容在 `spec-20260716-frame-review-v2-mvp-templates.md` 中给出。
  // MVP 阶段仅登记 4 份 descriptor：WHITE_EQUAL / META_BOTTOM / SIGNATURE_OVERLAY / ADAPTIVE_REVIEW_CARD
  // 加上 REVIEW_CARD → ADAPTIVE_REVIEW_CARD 别名共享，共 5 个键指向 4 个对象。
  // 其余 TemplateId 枚举成员（MINIMAL_GALLERY / DATE_BOTTOM / EXIF_CN_BOTTOM / PERSONAL_INFO_BAR）
  // 保留在枚举中但不注册 descriptor，resolveTemplate() 遇到时兜底到 ADAPTIVE_REVIEW_CARD。
  //
  // 关键约定：REVIEW_CARD 与 ADAPTIVE_REVIEW_CARD 显式共享同一份 TemplateDescriptor
  // 对象（别名模式），即 TEMPLATE_REGISTRY[REVIEW_CARD] === TEMPLATE_REGISTRY[ADAPTIVE_REVIEW_CARD]。
  // 这不是合并、不是破坏 Layer 2 对齐，是显式允许的 —— 见
  // spec-20260716-frame-review-v2-schema-alignment.md §3.3 显式允许段落。
};

export function resolveTemplate(id: string): TemplateDescriptor {
  const known: TemplateDescriptor | undefined =
    (TEMPLATE_REGISTRY as Record<string, TemplateDescriptor | undefined>)[id];
  if (known !== undefined) {
    return known;
  }
  const fallback = TEMPLATE_REGISTRY[TemplateId.ADAPTIVE_REVIEW_CARD];
  if (fallback === undefined) {
    throw new Error('TEMPLATE_REGISTRY 缺失 ADAPTIVE_REVIEW_CARD descriptor，属于配置错误');
  }
  return fallback;
}
```

**要点**：

- `TemplateId` 使用 **snake_case 字符串常量**，与 skymap-mac 的 raw value 完全对齐。Codex 不得改成 camelCase。
- `resolveTemplate` 兜底策略是回退到 `ADAPTIVE_REVIEW_CARD`。这是**有意与 Mac 不同**的行为：Mac 端 `Enums.swift` L122~124 未知 raw 回退到 `.whiteEqual`；Harmony 因为老数据全是复盘卡血脉、`createDefaultReviewCardDocument()` 默认 `templateId = 'review_card'`，兜底到 L3 才能让老用户与老 JSON 无缝落回。理由与红线声明见 `spec-20260716-frame-review-v2-schema-alignment.md` §3.4。
- `TEMPLATE_REGISTRY` 的具体填表内容由 MVP 模板规格文档提供，本文件不重复。

### 4.2 FrameConfigModel.ets

```typescript
export interface FrameConfigSpec {
  outerPaddingRatio: number;
  innerPaddingRatio: number;
  cornerRadiusRatio: number;
  backgroundColorHex: string;
  textColorHex: string;
  secondaryTextColorHex: string;
  titleFontRatio: number;
  bodyFontRatio: number;
  labelFontRatio: number;
  lineSpacingRatio: number;
  fieldSpacingRatio: number;
  logoAssetId: string;
  watermarkText: string;
}

export const FRAME_CONFIG_FALLBACK: FrameConfigSpec = {
  outerPaddingRatio: 0.032,      // 相对图片长边
  innerPaddingRatio: 0.006,      // 相对图片长边
  cornerRadiusRatio: 0.006,      // 相对图片短边
  backgroundColorHex: '#FFFFFF',
  textColorHex: '#161616',
  secondaryTextColorHex: '#5F6368',
  titleFontRatio: 0.026,         // 相对图片短边
  bodyFontRatio: 0.017,
  labelFontRatio: 0.012,
  lineSpacingRatio: 0.55,        // 相对正文字号
  fieldSpacingRatio: 1.15,       // 相对正文字号
  logoAssetId: '',
  watermarkText: ''
};

export function normalizeFrameConfig(
  input: FrameConfigSpec | undefined,
  fallback: FrameConfigSpec = FRAME_CONFIG_FALLBACK
): FrameConfigSpec {
  if (input === undefined) {
    return { ...fallback };
  }
  // 每个字段用 pick*，fallback 参数作为兜底源
```

**fallback 参数与调用约定**：`normalizeFrameConfig` 接收可选 `fallback` 参数。正常路径应传入**当前模板的 defaults.frame**（通过 `resolveTemplate(templateId).defaults.frame` 拿到），这样单字段损坏时也从模板默认值补而不是从全局 fallback，避免 L0/L1/L2 单字段脏时错回到 L3 fallback 值。全局 `FRAME_CONFIG_FALLBACK` 仅作为参数缺省，用于极端场景（例如模板 id 完全无法解析且 REGISTRY 里连 L3 兜底也拿不到）。

具体伪代码见下方"S/M/L multiplier 应用点"两条独立路径。

**S/M/L multiplier 与 legacy 映射 · 不作为 PR 交付**（B 方向决策）：

R5 时代的 `resolveTextSizeMultiplier` / `mapLegacyBackground` / `rebuildFrameOnTextSizeChange` 函数**均不作为 PR 交付**。因为 B 方向下：

- **L3 数据**：老 `background / textSize` 字段继续被忽略（L3 组件不消费 frame，不消费这两字段），无需映射到 frame
- **L0/L1/L2 新数据**：v2 UI 直接写 `frame`，不写老字段，无需 multiplier

因此 clone 老数据只需要"缺 frame 就深拷贝 descriptor 默认值"，不做任何字段迁移：

```typescript
// cloneReviewCardDocument 里 frame 的完整回填路径（B 方向 · 极简版）：
const template = resolveTemplate(config.templateId);

// 缺 frame → 直接深拷贝 descriptor 默认值
// 有 frame → 走 normalizeFrameConfig 字段级健壮性归一化
config.frame = config.frame !== undefined
  ? normalizeFrameConfig(config.frame, template.defaults.frame)
  : { ...template.defaults.frame };

config.templateLevel = template.level;   // 派生，不信任 JSON 里的老值
```

**`normalizeFrameConfig(input, fallback)` 职责**：只做字段级健壮性归一化（脏字段 fallback 到传入的 baseline），不烘焙 multiplier、不做 legacy 映射。

**未来 L3 v2 化时**：届时可能需要 `resolveTextSizeMultiplier` / `mapLegacyBackground` / `rebuildFrameOnTextSizeChange` 三个函数，届时独立 PR 补齐。本 v2 方案范围内**不实现**。
```

**MVP UI 入口**：v2 抽屉**不提供 S/M/L 切换控件**（编辑器 §3.5 抽屉只有边框参数与 EXIF / 判定）。**MVP 阶段 S/M/L 仅是保留枚举**，不接入任何渲染或迁移逻辑（B 方向下 L3 组件不消费 frame，`background/textSize` 在 L3 上继续被忽略）。相关函数如未来接入需另开 PR。

```typescript
// pickRatio 分支实现（fallback 使用参数而非全局常量）
return {
    outerPaddingRatio: pickRatio(input.outerPaddingRatio, fallback.outerPaddingRatio),
    innerPaddingRatio: pickRatioAllowZero(input.innerPaddingRatio, fallback.innerPaddingRatio),
    cornerRadiusRatio: pickRatioAllowZero(input.cornerRadiusRatio, fallback.cornerRadiusRatio),
    backgroundColorHex: pickHex(input.backgroundColorHex, fallback.backgroundColorHex),
    textColorHex: pickHex(input.textColorHex, fallback.textColorHex),
    secondaryTextColorHex: pickHex(input.secondaryTextColorHex, fallback.secondaryTextColorHex),
    titleFontRatio: pickRatio(input.titleFontRatio, fallback.titleFontRatio),
    bodyFontRatio: pickRatio(input.bodyFontRatio, fallback.bodyFontRatio),
    labelFontRatio: pickRatio(input.labelFontRatio, fallback.labelFontRatio),
    lineSpacingRatio: pickRatio(input.lineSpacingRatio, fallback.lineSpacingRatio),
    fieldSpacingRatio: pickRatio(input.fieldSpacingRatio, fallback.fieldSpacingRatio),
    logoAssetId: typeof input.logoAssetId === 'string' ? input.logoAssetId : '',
    watermarkText: typeof input.watermarkText === 'string' ? input.watermarkText : ''
  };
}

// 用于必须非零的比例字段（外留白、所有字号、行距、字段间距）。
// 零值视为脏数据回退到 fallback，因为这些字段的模板默认值和 UI 允许区间都不含 0。
function pickRatio(value: number | undefined, fallback: number): number {
  if (typeof value === 'number' && value > 0 && value < 1.5) {
    return value;
  }
  return fallback;
}

// 用于合法零值字段（内留白 innerPaddingRatio、圆角 cornerRadiusRatio）。
// 零值必须保留：模板默认值本身就有 0（例如 white_equal 的 innerPaddingRatio、
// L0/L1/L2 的 cornerRadiusRatio 全为 0），UI 参数抽屉也允许 slider 拖到 0。
// 校验条件仅拒绝负数、NaN、超过 1.5 的错单位输入。
function pickRatioAllowZero(value: number | undefined, fallback: number): number {
  if (typeof value === 'number' && value >= 0 && value < 1.5 && Number.isFinite(value)) {
    return value;
  }
  return fallback;
}

function pickHex(value: string | undefined, fallback: string): string {
  if (typeof value === 'string' && /^#[0-9A-Fa-f]{6}$/.test(value)) {
    return value.toUpperCase();
  }
  return fallback;
}
```

**要点**：

- 相对比例的取值窗口分两档：`innerPaddingRatio / cornerRadiusRatio` 走 `[0, 1.5)`（允许 0，因为模板默认值就有 0），其他字段走 `(0, 1.5)`（禁止 0，因为字号/行距/外留白为 0 不成立）。超出即视为脏数据，回退默认值。这可以在渲染阶段之前挡住 NaN、负数、错单位。
- 颜色统一为 `#RRGGBB` 大写。不接受带 alpha 或简写形式，避免 Canvas 侧 parseColor 分支。
- `logoAssetId` 与 `watermarkText` 现在留空。MVP 四模板均**不使用** logo / watermark，先占位不实现。

### 4.3 ExifPayloadModel.ets

```typescript
export enum ExifSource {
  AUTO = 'auto',
  MANUAL = 'manual',
  MIXED = 'mixed'
}

export interface ExifPayload {
  cameraMake: string;
  cameraModel: string;
  lensMake: string;
  lensModel: string;
  focalLength: string;
  aperture: string;
  shutter: string;
  iso: string;
  captureDate: string;
  location: string;
  source: ExifSource;
  manuallyOverridden: Array<string>;
}

export const EXIF_PAYLOAD_EMPTY: ExifPayload = {
  cameraMake: '',
  cameraModel: '',
  lensMake: '',
  lensModel: '',
  focalLength: '',
  aperture: '',
  shutter: '',
  iso: '',
  captureDate: '',
  location: '',
  source: ExifSource.AUTO,
  manuallyOverridden: []
};

export function isExifPayloadEmpty(payload: ExifPayload): boolean {
  return payload.cameraMake.length === 0
    && payload.cameraModel.length === 0
    && payload.lensMake.length === 0
    && payload.lensModel.length === 0
    && payload.focalLength.length === 0
    && payload.aperture.length === 0
    && payload.shutter.length === 0
    && payload.iso.length === 0
    && payload.captureDate.length === 0
    && payload.location.length === 0;
}

export function normalizeExifPayload(input: ExifPayload | undefined): ExifPayload {
  if (input === undefined) {
    return { ...EXIF_PAYLOAD_EMPTY, manuallyOverridden: [] };
  }
  const overrides: Array<string> = Array.isArray(input.manuallyOverridden)
    ? input.manuallyOverridden.filter((key): key is string => typeof key === 'string')
    : [];
  return {
    cameraMake: typeof input.cameraMake === 'string' ? input.cameraMake : '',
    cameraModel: typeof input.cameraModel === 'string' ? input.cameraModel : '',
    lensMake: typeof input.lensMake === 'string' ? input.lensMake : '',
    lensModel: typeof input.lensModel === 'string' ? input.lensModel : '',
    focalLength: typeof input.focalLength === 'string' ? input.focalLength : '',
    aperture: typeof input.aperture === 'string' ? input.aperture : '',
    shutter: typeof input.shutter === 'string' ? input.shutter : '',
    iso: typeof input.iso === 'string' ? input.iso : '',
    captureDate: typeof input.captureDate === 'string' ? input.captureDate : '',
    location: typeof input.location === 'string' ? input.location : '',
    source: input.source === ExifSource.MANUAL || input.source === ExifSource.MIXED
      ? input.source
      : ExifSource.AUTO,
    manuallyOverridden: overrides
  };
}
```

**要点**：

- 所有 EXIF 字段都是**文本**，不是数字。原因：光圈会带 `f/`，快门会带 `1/`，焦距会带 `mm`，ISO 会带 `ISO`。渲染层要能直接贴。
- `location` 由用户手工填，不做 GPS 反查。GPS 属于隐私边界，超出 MVP。
- `source = MIXED` 表示"自动读了一部分 + 用户手动改了一部分"，用于展示"已手动"角标。

**EXIF 合并状态表**（editor §3.5 EXIF sheet 实现依据；由 sheet 调用方按此表处理 `ExifReaderService.read()` 返回值）：

| 场景 | 触发时机 | 合并逻辑 | 结果 source |
| --- | --- | --- | --- |
| 初次自动读取 | EditorPage `aboutToAppear`（首次进入） | 用 `read(uri)` 返回值全量覆盖 `document.exif`；`manuallyOverridden` 保持空 | `AUTO` |
| 用户手改单字段 | EXIF sheet 内某字段 blur / 提交 | 只写该字段到 `document.exif[field]`；把 field 加入 `manuallyOverridden` | 若原为 `AUTO` → `MIXED`；若已 `MANUAL` → 保持 `MANUAL` |
| 单字段重读（"↻" 按钮） | EXIF sheet 内单字段的重读按钮 | 调用 `read(uri)` 拿新 payload；**只**用新值覆盖当前字段（其他字段保持 `document.exif` 中原值）；把 field 从 `manuallyOverridden` 移除 | 若移除后 `manuallyOverridden` 为空 → `AUTO`；否则 → 保持 `MIXED` |
| 读取失败（`read` throw / 返回 empty） | 初读或单字段重读 | **不覆盖**任何已有值，保留 `document.exif` 现状；sheet 顶部显示 "无法读取 EXIF · 手动填写" | 不改 source |
| 空新值（read 成功但字段是空字符串） | 单字段重读发现新值为空 | **不覆盖**当前字段（用户可能已手改过有意义的值），保留 `document.exif[field]` | 不改 source |
| 用户点"全部重读" | EXIF sheet 底部按钮（PR 5 可选交付） | 调用 `read(uri)` 全量覆盖 `document.exif`；`manuallyOverridden` 清空 | `AUTO` |

**注意**：`source` 是**结果状态**，不是"用户选择"。sheet 顶部的三档 chip（`AUTO / MANUAL / MIXED`）**只读展示**当前 source，`MIXED` 状态用户不可点选（因为它是合并产物），`AUTO` 和 `MANUAL` 用户可主动切换（切到 `MANUAL` 意味着"锁定当前值，禁止后续自动读取"，切到 `AUTO` 意味着"清空 manuallyOverridden + 触发全部重读"）。

### 4.4 对 ReviewCardModel.ets 的分层扩展

```typescript
// 现有 ReviewCardConfig 保留字段不变，新增 frame 与 templateLevel 引用（均为呈现层扩展）：
// 注意：background / textSize 保持 required（否则会破坏现有 createDefaultReviewCardDocument
// 和所有已保存文档的 JSON 兼容性）。B 方向下，L0/L1/L2 新模板"从不主动写入"这两字段的含义是：
//   · v2 UI（编辑器抽屉、模板切换 utility）不更新这两字段
//   · 新建 document 时仍由 createDefaultReviewCardDocument() 填默认值（WHITE / STANDARD）
//   · 新模板渲染层直接读 frame，忽略这两字段
//   · 序列化时这两字段仍随 config 写入 raw_document_json（保持兼容）
export interface ReviewCardConfig {
  templateId: string;
  layoutMode: ReviewCardLayoutMode;
  background: ReviewCardBackground;    // required；新模板忽略且 UI 不更新
  textSize: ReviewCardTextSize;        // required；新模板忽略且 UI 不更新
  // 新增 ↓（呈现层扩展）
  frame?: FrameConfigSpec;
  templateLevel?: TemplateLevel;
}

// 现有 ReviewCardDocument 保留字段不变，新增 exif 顶层（数据层扩展，见 §1 第 1 条分层原则）：
export interface ReviewCardDocument {
  version: string;
  projectId: string;
  imageUri: string;
  imageWidth: number;
  imageHeight: number;
  imageSizeFallbackUsed: boolean;
  content: ReviewContent;
  config: ReviewCardConfig;
  createdAt: number;
  updatedAt: number;
  // 新增 ↓（数据层扩展，顶层字段）
  exif?: ExifPayload;
}
```

**为什么用可选字段而不是 required**：

- 旧 RDB 中已存的 `raw_document_json`（承载 `ReviewCardDocument` 序列化结果）在读取时不需要迁移。`review_exchange/*.review.json` 遵循独立的 Review JSON Schema v1，不含 `config/exif`，本方案的 fallback 逻辑不作用于它，不涉及其迁移。
- `cloneReviewCardDocument()` 里对新字段的回填规则（**关键：不能直接用全局 fallback，否则破坏模板默认值**）：
  - `config.frame` 缺失 → 取 `resolveTemplate(config.templateId).defaults.frame` 深拷贝（保证 L3 老数据落回时几何等价，而不是错回全局 fallback）
  - `config.frame` 存在但字段脏 → 走 `normalizeFrameConfig` 字段级 pick
  - `config.templateLevel` 缺失 → 派生自 `resolveTemplate(config.templateId).level`（不信任 JSON 里的老值，因为老 JSON 根本没这个字段，读到就是 undefined）
  - `exif` 缺失 → `EXIF_PAYLOAD_EMPTY` 深拷贝
- 版本字符串 `version` 定义为**落盘 schema 版本**（记录 raw_document_json 实际写入的字段布局），从 `'0.1.0'` 升到 `'0.2.0'` 表示"含 frame/templateLevel/exif 扩展字段"。**升级规则**（所有写入路径共用同一个 helper `upgradeVersionOnPersist(doc): ReviewCardDocument`，PR 1 交付）：
  - **新建 document**（`createDefaultReviewCardDocument()`）→ 直接写 `'0.2.0'`
  - **只读 clone**（读入 → 内存展示）→ 不改 version，保留原值。clone 内部补齐 frame/exif 只影响内存对象，不落盘
  - **任何写入路径**（`saveDocument` / `updateDocument` / Preview 自动保存 / 其他未来 helper）→ 在真正 `INSERT/UPDATE raw_document_json` 之前统一调用 `upgradeVersionOnPersist(doc)`，把 version 升到 `'0.2.0'`（若原本更低）
  - **RDB 不主动批量重写**：v2 上线后旧记录只在其被用户打开并触发任一写入路径时才升级；从未打开的记录保持 `'0.1.0'`，读取时靠 clone fallback 兼容
  - **自动保存是否触发升级**：是（自动保存也是写入路径，走同一个 helper）；若产品不希望自动保存升级 version，Codex 回来找 Claude，不要在 helper 里加分支

**`config.background` / `config.textSize` 与 `config.frame` 的双重来源权威**（B 方向）：

老数据里 `config.background`（`WHITE / LIGHT_GRAY`）和 `config.textSize`（`SMALL / STANDARD / LARGE`）是 v1 遗留字段。**关键事实**：当前 L3 渲染链**根本没消费**这两个字段 —— 阅读页/导出图的背景色实际来自 `ReviewCardStyleTokens.canvasColor = #FFFEFC`（固定值），字号来自各 `ReviewCard*.ets` 组件里的硬编码 fp 值；`ReviewCardTheme.ets` 虽定义了字号但没有渲染调用方。

**B 方向下的权威规则**：

- **L3 数据**：`background / textSize` 在 L3 上**继续被忽略**（L3 组件不动），也**不映射到 frame**（因为 L3 组件不消费 frame）。L3 数据的 `background / textSize` 字段保留在 config 里作为"未来 v2 化时的输入"，但 v2 阶段完全不参与渲染
- **L0/L1/L2 新数据**：从不写入 `background / textSize`（v2 UI 直接写 `frame`），也不读老字段
- **`mapLegacyBackground` / `resolveTextSizeMultiplier` 函数**：**不作为 PR 2 交付**（无调用方）。若未来 L3 v2 化独立 PR 需要，届时再实现

**这意味着**：L3 老数据 `LIGHT_GRAY / SMALL / LARGE` 组合打开视觉与升级前完全一致（因为 L3 组件本就不消费这两字段），**不需要 change log 也不需要"授权视觉变化"验收样本**。PR 2 只需要回归测试三方向阅读页 + 组件截图导出路径正常渲染即可。

**未来 L3 v2 化时**（不在本方案范围）：届时需要设计 `background / textSize` → `frame` 的迁移策略，可能涉及一次授权视觉变化 + 用户提示。本方案不预设该策略。

### 4.5 RDB 表结构演进

现有 `reviews` 表参见 `docs/product/DATA_MODEL.md`。本方案在**不删列、不改列类型**的前提下新增：

| 新列 | 类型 | 允许 NULL | 索引 | 说明 |
| --- | --- | --- | --- | --- |
| `template_id` | TEXT | 是 | 单列索引 | 冗余存 `document.config.templateId`，供聚合查询 |
| `template_level` | TEXT | 是 | 单列索引 | 冗余存 `document.config.templateLevel`，供 L0/L1/L2/L3 聚合 |
| `camera_model` | TEXT | 是 | 单列索引 | 冗余存 `document.exif.cameraModel`，供相机聚合 |
| `lens_model` | TEXT | 是 | 单列索引 | 冗余存 `document.exif.lensModel`，供镜头聚合 |

**为什么冗余**：`raw_document_json` 已经保存全量，但按模板 / 相机聚合的查询不能扫全表 JSON。冗余列只用于查询与聚合，写入时以 JSON 为准；两者不一致时以 JSON 为唯一真实来源，冗余列可以由后台重建。

**迁移策略**：

- 老记录读出时冗余列全为 NULL，聚合抽屉展示为"未记录"分组。
- 后台任务批量回填一次（低频、可失败）。
- 保存新记录时在 `ReviewCardHistoryService` 的写入路径同步更新冗余列。

## 5. Canvas 合成管线（原图导出通路）

阶段 A 硬门槛。本节给 Codex 一份**通路骨架**，具体错误处理与色彩空间选择留在实施时按 HarmonyOS API 现实行为敲定。

### 5.1 现有导出通路

当前 `ReviewCardExportService.ets` 走的是"ArkUI 组件截图 → PixelMap → JPEG"：

1. `LongFormExportReviewCard` 组件在离屏挂载，赋予 `exportComponentId`
2. `componentSnapshot.get(exportComponentId)` 得到 PixelMap
3. `image.createImagePacker().packToData(pixelMap, { format: 'image/jpeg', quality: 95 })` 编码 JPEG（真实签名，见 `ReviewCardExportService.ets` L164）
4. `photoAccessHelper.showAssetsCreationDialog` 保存到相册

**这条通路的物理上限**：组件截图受 UI 分辨率约束，无法输出到原图尺寸（例如 7008×4672）。

### 5.2 新导出通路（三层合成）

**下方图示表达"三个概念图层"，不是绘制顺序**。Canvas 实际绘制顺序必须是"背景 → save/圆角 clip → 原图 → restore → 文字"（见图示下方明细）。**注意**：原图必须在 clip 生效后 drawImage，才能被圆角裁掉四角；先画原图再 clip 会导致原图被覆盖或裁剪失效。

```
┌────────────────────────────────────────────────────────────┐
│ Layer A · 原图层（概念层）                                  │
│   image.createImageSource(imageUri) → ImageSource          │
│   ImageSource.createPixelMap()                             │
│   保持原图分辨率与色彩空间，不做插值缩放                    │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│ Layer B · 边框图层（概念层）                                │
│   · 背景色                                                  │
│   · 圆角遮罩（若 cornerRadiusRatio > 0）                    │
└────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────┐
│ Layer C · 文字与信息图层（概念层）                          │
│   · 标题 / 复盘正文 / EXIF 参数 / 日期 / logo 位置          │
│   · 全部用 FrameConfig 的 *Ratio 值 × 原图短边计算实际字号  │
│   · 中文字体走本地 asset（family 名 NotoSansSC-Bold /       │
│     NotoSansSC-Regular / NotoSerifSC-Regular，见 mvp §6）   │
└────────────────────────────────────────────────────────────┘
```

**实际 Canvas 绘制顺序**（**必须严格按此顺序执行**，否则背景覆盖原图或圆角失效）：

```
1. context.fillStyle = frame.backgroundColorHex
   context.fillRect(0, 0, canvasWidth, canvasHeight)             ← 先铺满背景
2. 若 cornerRadiusRatio > 0：context.save() + roundRect + clip  ← 圆角 clip（用于图片区）
   context.drawImage(originalPixelMap, imgX, imgY, imgW, imgH)   ← 再贴原图
   若 clip 生效：context.restore()
3. context.font = ...; context.fillText(...)                     ← 最后画文字（不受 clip 影响）
4. context.getPixelMap(0, 0, canvasWidth, canvasHeight) → PixelMap
5. createImagePacker + packToData → JPEG bytes
6. showAssetsCreationDialog → 系统相册
```

**关键**：Layer B 的"图片留白区（透明矩形）"是概念表达，Canvas 上并没有"挖洞"操作 —— 通过"先铺背景、再在图片区域 drawImage 覆盖"实现相同视觉。绘制顺序不能反。

### 5.3 关键 HarmonyOS API 索引

Codex 落地本管线时必须使用以下 API，不允许自行发明；如以下 API 在目标 SDK 版本上行为异常，回来找 Claude 出替代方案。

**图片解码**：
- `@ohos.multimedia.image` · `image.createImageSource(uri)` → `ImageSource`
- `ImageSource.getImageInfo()` → 返回 `ImageInfo`，字段含**宽高、密度、格式等**，**不返回方向**（这是常见误用）
- `ImageSource.createPixelMap({ desiredSize: undefined })` → 拿到原图 PixelMap
- `ImageSource.getImageProperty(PropertyKey.ORIENTATION)` → **专门读取方向**（`ImageInfo` 无此字段，必须走 PropertyKey）

**EXIF 读取**（阶段 A 只需要 `ExifPayload` 类型定义 + 以下 API 索引作为参考；实际的 `ExifReaderService` 服务实现属于阶段 B / PR 5）：
- `ImageSource.getImageProperty(PropertyKey.MODEL)` 相机型号
- `ImageSource.getImageProperty(PropertyKey.MAKE)` 相机厂商
- `ImageSource.getImageProperty(PropertyKey.LENS_MODEL)` 镜头
- `ImageSource.getImageProperty(PropertyKey.FOCAL_LENGTH)` 焦距
- `ImageSource.getImageProperty(PropertyKey.F_NUMBER)` 光圈
- `ImageSource.getImageProperty(PropertyKey.EXPOSURE_TIME)` 快门
- `ImageSource.getImageProperty(PropertyKey.ISO_SPEED_RATINGS)` ISO
- `ImageSource.getImageProperty(PropertyKey.DATE_TIME_ORIGINAL)` 拍摄时间

以上 PropertyKey 常量需要按运行时 SDK 现况核对，缺失走空字符串兜底。**不要引入原生 CGImageSource 类比 API 名**，鸿蒙侧使用 `PropertyKey`。

**Canvas 合成**（目标 SDK 6.1.1 / API 24 事实：`OffscreenCanvas` 是 ArkUI 全局声明，**无** `@ohos.arkui.canvas` 模块导入；**无** `OffscreenCanvas.toPixelMap`）：
- `new OffscreenCanvas(width: number, height: number)` → 建原图尺寸离屏画布
- `canvas.getContext('2d', settings?)` → `OffscreenCanvasRenderingContext2D`
- `context.drawImage(pixelMap, dx, dy, dWidth, dHeight)` → 贴原图
- `context.fillRect / roundRect / fillText` → 绘边框与文字
- `context.getPixelMap(0, 0, width, height)` → 取回 `image.PixelMap`（本方案统一走此 API，不用 `transferToImageBitmap`）

**图片编码**：
- `image.createImagePacker()` → `ImagePacker`
- `packer.packToData(pixelMap, { format: 'image/jpeg', quality: 95 })` → `Promise<ArrayBuffer>`（**真实 API**，`packing` 在目标 SDK 已弃用；不存在 `packToDataWithOptions`）

**保存到相册**：
- `@ohos.file.photoAccessHelper` · `photoAccessHelper.getPhotoAccessHelper(context)` → `PhotoAccessHelper`
- `PhotoAccessHelper.showAssetsCreationDialog([sandboxUri], [{ title, fileNameExtension, photoType }])` → `Promise<Array<string>>`（**真实返回数组**，见 `ReviewCardExportService.ets` L112；调用方取 `mediaUris[0]` 后写入 —— 现有代码即此模式）

### 5.4 阶段 A 验收方案（PR 2/3 硬门槛 · B 方向简化）

**核心决策（B 方向）**：v2 抽象只服务 L0/L1/L2 新模板；L3 组件（`MobileReadingReviewCard` / `LongFormExportReviewCard`）**内部不动**（继续硬编码 fp/单布局/现有标签），不消费 `config.frame`。因此不存在"L3 消费 frame 视觉必然变化 vs 承诺零差异"的冲突。L3 视觉零差异从"承诺"降级为"事实"（组件没动 → 天然零差异）。

**验收 1 · L3 布局结构等价 + 字体变化已授权**（硬门槛 · 人工冒烟审查）
- `MobileReadingReviewCard.ets` / `LongFormExportReviewCard.ets` 及其共享子组件（精确文件清单见 mvp §10 PR 2）在 PR 2 中**只允许改动 `fontFamily`**（切到 `NotoSansSC-*`），任何布局、字号、颜色、字段绑定、字段顺序的改动都视为违规
- Renderer 分发路径：`ReviewCardRenderer` 按 `templateId` 判定分发目标，L3 分发到上述未改组件；其他 templateId 分发到新模板（阶段 B 才有）
- **验收方式**：三方向（横/竖/方）阅读页 + 组件截图导出路径的**截图冒烟审查**（人工确认无版式错乱、无遮挡、无字段丢失、字体切换后的字宽变化在可接受范围内）。**不做像素级 pixel diff** —— 字体切换会影响字形/度量/换行/抗锯齿，结构不变不能证明像素等价
- `background=LIGHT_GRAY / textSize=SMALL/LARGE` 老数据打开视觉与升级前一致（L3 组件本就不消费这些字段）

**验收 2 · L3 Canvas 导出图人工审查**（硬门槛 · 无历史基线）
- L3 走 Canvas 是**新增能力**（原图分辨率），与旧组件截图路径（屏幕分辨率）在尺寸、分辨率、字体（切了 NotoSansSC）三方面都不同，**没有历史基线可做 pixel diff**
- **5 张固定 fixture manifest**（放置 `test-artifacts/pixel-diff-baseline/export/`）：
  | 编号 | 方向 | 原图分辨率 | EXIF Orientation | 数据组合 | 源图 hash（SHA256 前 8 位） |
  | --- | --- | --- | :---: | --- | --- |
  | fixture-01 | 横图 | 4032×3024 | 1（0°） | WHITE + STANDARD | 待建库时填入 manifest.json |
  | fixture-02 | 横图 | 7008×4672 | 1（0°） | WHITE + STANDARD | 待填 |
  | fixture-03 | 竖图 | 3024×4032 | 1（0°，实拍横图存竖） | WHITE + STANDARD | 待填 |
  | fixture-04 | 竖图 | 4672×7008 | **6（90°，验证 orientation 旋转）** | LIGHT_GRAY + LARGE | 待填 |
  | fixture-05 | 方图 | 4032×4032 | 1（0°） | WHITE + STANDARD | 待填 |
  fixture-04 **必须**选 Orientation=6 的实拍原图（iPhone 竖持拍摄的典型样本），验证 §5.5 orientation 旋转逻辑正确。manifest.json 里需记录每张 fixture 的 Orientation 值供 Codex 验收对照。
- **首次审查**：5 张导出图打包提交，用户/设计视觉确认可接受后写入基线目录并生成 manifest（含源图 hash / 生成参数 / 通过日期）
- **后续回归**（后续 PR 修改 Canvas 通路时）：重出 5 张与基线做 pixel diff，指标为**差异像素比例 ≤ 5%（RGB 差异 ≤ 16/256 视为一致）**；SSIM 与连通区域不作单独门槛，因为回归而非等价判定
- **不做**"新旧路径像素对比"

**L3 v2 化推迟到方案外**：L0/L1/L2 消费 frame 是 v2 抽象的初次落地；L3 消费 frame 是未来重构，届时会有一次显式的授权视觉变化 + 完整迁移方案，不在本 v2 范围内。

**（R6 时代的"字体区域豁免/mask/Lanczos-3 1080×N raster/三主指标/SSIM"段落已删除）** —— B 方向下 L3 验收改为"人工冒烟审查 + 5 张 fixture 首次人工审查"，不再走"新旧路径 pixel diff + mask 豁免"。若未来回归仍需要 mask，届时围绕"差异像素 ≤ 5% + RGB ≤ 16/256"这一指标重新定义。

### 5.5 相对尺寸落地公式

Codex 在 **L0/L1/L2 新模板** Canvas 合成层的每一处几何计算，都使用以下公式，不允许出现 dp / vp / 硬编码 px（**L3 组件不动**，继续硬编码 fp，不适用本公式）：

```
imageLongEdge  = max(originalWidth, originalHeight)
imageShortEdge = min(originalWidth, originalHeight)

outerPaddingPx = round(imageLongEdge  * frame.outerPaddingRatio)
innerPaddingPx = round(imageLongEdge  * frame.innerPaddingRatio)
cornerRadiusPx = round(imageShortEdge * frame.cornerRadiusRatio)

titleFontPx    = round(imageShortEdge * frame.titleFontRatio)
bodyFontPx     = round(imageShortEdge * frame.bodyFontRatio)
labelFontPx    = round(imageShortEdge * frame.labelFontRatio)

lineSpacingPx  = round(bodyFontPx * frame.lineSpacingRatio)
fieldSpacingPx = round(bodyFontPx * frame.fieldSpacingRatio)
```

**预览层**（编辑器区 A 的 L0/L1/L2 预览）复用同一套公式，把 `imageLongEdge / imageShortEdge` 替换为**预览容器的等价量**（`previewContainerLongEdge / previewContainerShortEdge`）。这样保证预览与导出视觉一致 —— 用户在预览里看到的相对比例，就是导出图上的相对比例。

**EXIF orientation 处理**（Canvas 通路必须做，否则竖拍原图会侧翻）：

```
1. 用 image.createImageSource(uri) 拿到 ImageSource
2. 读 ImageSource.getImageProperty(PropertyKey.ORIENTATION) → orientation 值（1~8）
3. 用 ImageSource.createPixelMap({ rotate: orientationToDegrees(orientation) }) 得到已旋转的 PixelMap
   · orientation=1 → 0°
   · orientation=3 → 180°
   · orientation=6 → 90°  （竖拍最常见，需要顺时针 90°）
   · orientation=8 → 270°
   · orientation=2/4/5/7 涉及镜像，MVP 阶段先只处理 1/3/6/8，其他走 fallback 0°
4. 从旋转后的 PixelMap 读 width/height（此时已交换过），作为 Canvas 合成的原图尺寸
5. drawImage 直接贴旋转后的 PixelMap，不再需要 Canvas transform
```

**注意**：`ImageSource.createPixelMap({ rotate })` 的 rotate 单位是度数（number）；若目标 SDK 支持此参数则用它，否则退化方案是 `context.rotate()` + 矩阵变换（PR 3 实施时按真机行为选一条）。

**EXIF orientation 支持范围（R7 澄清）**：MVP 阶段**仅支持旋转方向 1/3/6/8**（0°/180°/顺时针 90°/顺时针 270°），**不支持镜像方向 2/4/5/7**（镜像方向直接 fallback 到 0°，视觉上会与预期不符 —— 但这类照片在实际拍摄中占比 < 1%，MVP 接受此降级）。fixture-06（预留槽位）需要引入至少一张 Orientation=6 或 Orientation=8 的竖拍原图，验证旋转+尺寸交换正确。若要支持完整八方向的旋转+镜像矩阵，回来找 Claude 出方案。

### 5.6 `exportOriginalResolution` 服务契约

**签名**（**唯一权威**，所有调用点必须按此形态使用）：

```typescript
class ReviewCardExportService {
  private static isExporting: boolean = false;    // 复用现有静态锁

  static async exportOriginalResolution(
    context: common.UIAbilityContext,
    document: ReviewCardDocument,
    reviewerName: string          // 由 PreviewPage 从复盘设置加载后传入，服务不主动加载
  ): Promise<ReviewCardExportResult>
}
```

**关键约束**：

- **class 静态方法**（不是自由函数），与现有 `ReviewCardExportService.saveJpgToPhotoLibrary` 等方法归属同一 class
- **返回类型固定 `ReviewCardExportResult`**（现有类型，见 `ReviewCardExportService.ets` L7~L14），**所有返回路径必须包含全部六字段**：`success / cancelled / savedToPhotoLibrary / path / backupPath / message`（缺任何一字段 = 违规）
- **`reviewerName` 由调用方（PreviewPage）加载后传入**，服务不再重复加载复盘设置（与现有 `saveJpgToPhotoLibrary` 由 PreviewPage 提前拿好 title 的模式一致）
- **并发锁**：**复用现有 `ReviewCardExportService.isExporting` 静态字段**（不是新建"模块级 flag"），并发调用时后来者立即返回 `{ success: false, cancelled: false, savedToPhotoLibrary: false, path: '', backupPath: '', message: '导出进行中' }`
- **沙箱备份**：与现有一致，先写沙箱（`${filesDir}/review_exports/`）再由用户走 `showAssetsCreationDialog` 保存到相册；沙箱备份路径写回 `ReviewCardExportResult.backupPath`
- **资源释放**（必做，否则原图 PixelMap 内存泄漏）：`try { ... } finally { ... }` 结构里显式释放
  - `ImageSource.release()` — 关闭源
  - `PixelMap.release()` — 释放原图 PixelMap 与 Canvas 输出 PixelMap
  - `ImagePacker.release()` — 关闭编码器
  - OffscreenCanvas 对象让 GC 回收即可
  - `finally` 块末尾释放 `isExporting` 锁（`ReviewCardExportService.isExporting = false`）
- **异常路径**：所有底层 API 抛错走 `{ success: false, cancelled: false, savedToPhotoLibrary: false, path: '', backupPath: '', message: error.message }` 返回，不再向上抛（沿用现有服务模式）；用户点相册对话框"取消"走 `{ success: false, cancelled: true, savedToPhotoLibrary: false, path: '', backupPath: sandboxPath, message: '已取消' }`

**所有调用点必须按三参调用**（`context, document, reviewerName`）：PreviewPage 导出下拉菜单、数据流示例 §6、editor §5.3、mvp §9 全部同步。

## 6. 数据流示例（阶段 C 完成后的全链路）

以下走一次"用户新拍一张 → 选模板 → 保存 → 导出"，验证结构是否闭环。每个环节右侧标注该能力所属的 PR，便于对照 `spec-20260716-frame-review-v2-mvp-templates.md` §10：

```
用户拍摄 / 导入
    ↓
photoAccessHelper.PhotoViewPicker 返回 imageUri                        [既有]
    ↓
EditorPage.aboutToAppear()
    ├─ 读取 imageWidth / imageHeight                                    [既有]
    └─ 调用 ExifReaderService.read(imageUri) → ExifPayload              [服务 PR 5；
       契约：read 只做全新一次 EXIF 读取，不接收 existingPayload；        Editor 调用与状态合并 PR 6]
       合并规则由调用方按 manuallyOverridden 处理（editor §3.5 EXIF sheet）
    ↓
默认模板：L3 复盘卡（老用户心智延续，createDefaultReviewCardDocument
默认 templateId = 'review_card' 解析为 ADAPTIVE_REVIEW_CARD descriptor）
    ↓
用户改标题 → EditorPage 内部 @State: title 更新                         [沿用既有 @State 路径]
             保存时组装 document 时写入 content.title                    [不新增 store 方法]
    ↓
（可选）用户切模板："L0 纯白画廊"                                       [PR 6 编辑器区 B2]
    ↓
applyTemplateToDocument(document, TemplateId.WHITE_EQUAL)               [PR 4 · utility 函数]
    · **纯函数硬约束**：不修改入参 document；返回新对象
    · **深拷贝硬约束**：frame 必须 `{ ...descriptor.defaults.frame }` 展开，
      不得直接把 REGISTRY 内 descriptor.defaults.frame 引用暴露给外部，
      否则 Slider 微调会污染全局模板默认值
    ├─ config.templateId       ← 'white_equal'                          [PR 1 数据结构]
    ├─ config.templateLevel    ← TemplateLevel.L0_FRAME                 [PR 1]
    ├─ config.frame            ← TEMPLATE_REGISTRY.white_equal.defaults [PR 1 REGISTRY]
    └─ 返回新 document；EditorPage 用它重置本地 @State                  [PR 6]
       content 字段按 contentBinding 显隐（此模板 useTitle=false，
       标题输入折叠但 content.title 不删除）
    ↓
预览：ReviewCardRenderer 按 templateId 分发到对应组件                   [PR 2 分发]
    ↓
用户点保存
    ↓
ReviewCardHistoryService.saveDocument(context, document)                [既有签名]
    ├─ 写 raw_document_json                                             [既有]
    ├─ 更新冗余列 template_id / template_level / camera / lens          [PR 9]
    └─ 同步写 review_exchange/*.review.json（走 Schema v1）             [既有，不变]
    ↓
用户点导出（Preview 页下拉菜单选"原图分辨率"）                          [PR 7 用户可见入口]
    ↓
ReviewCardExportService.exportOriginalResolution(                       [PR 3 服务打通]
    context, document, reviewerName                                     契约见 §5.6
    ├─ image.createImageSource(document.imageUri).createPixelMap()      [PR 3]
    ├─ 计算合成尺寸 = 原图尺寸 + outer/inner padding                    [PR 3]
    ├─ OffscreenCanvas 三层合成                                         [PR 3 L3；PR 4/5/8 各档模板]
    ├─ ImagePacker → JPEG 95%                                           [PR 3]
    └─ photoAccessHelper.showAssetsCreationDialog                        [既有]
```

**阶段 A 完成后**（PR 1~3）的最小可用形态：新数据结构 + Renderer 分发 + Canvas 合成通路 + L3 复盘卡在新结构下正常运行。此时用户能像 v2 之前一样使用 L3 复盘卡，**阅读页视觉完全不变**（B 方向：L3 组件不动，全 L3 数据零差异），**导出图新增原图 Canvas 通路选项**（通过 5 张 fixture 样本人工审查确认可接受）。**尚不能**选其他模板、尚不能编辑 EXIF、尚无聚合抽屉。

**阶段 B 完成后**（PR 1~7）用户能选 L0 / L1 / L3 三档、编辑 EXIF、用一屏三区编辑器、走原图导出下拉。

**阶段 C 完成后**（PR 1~10）即上图全链路。

## 7. 边界与不做

- 不改 `review.json` 字段名、字段数、`decision` 枚举
- 不改 `ReviewCardExchangeSchema.ets` 序列化逻辑
- 不修改 `ReviewCardHistoryService` 主键、`reviews` 表主键、`review_exchange` 命名
- 不引入 GPS 反查、AI 分析、自动标签
- 不引入模板编辑器、模板导入导出
- 不引入云同步与账号
- 不引入水印上传、logo 上传界面（`logoAssetId` 保留空槽，MVP 用不上）
- 不允许在 `FrameConfig` 里出现颜色 alpha、渐变、材质图，MVP 只支持纯色边框

## 8. 待人工确认清单（按阻塞阶段分组）

**阻塞阶段 A**（PR 1~3，编码启动前必须确认）：

1. **Canvas 合成性能 / 内存 spike**（影响 PR 3）：目标 SDK 6.1.1(24) 上 `OffscreenCanvas` + `context.getPixelMap(0, 0, w, h)` 的 API 通路已确认可用（无需再问 `toPixelMap` 是否存在）。真正待验证的是**性能与内存**：原图 7008×4672 尺寸的 OffscreenCanvas 在中端机上的内存占用、`getPixelMap` 耗时、JPEG 编码耗时是否可接受？需要一个可跑通的 spike，跑一次后再决定是否需要分块渲染。
2. **老 RDB `raw_document_json` 中的 `config` 是否要跟着 v2 升级重写一次**（影响 PR 2 读取路径）？默认不重写，读取时走 fallback 分支即可。`review_exchange/*.review.json` 本身不携带 `config` 字段，不在本决策范围。
3. **阶段 A 完成后是否切一次分支冻结，作为回退基线**？
4. **思源黑体 CN（Bold + Regular）资产入口**（影响 **PR 2 与 PR 3**）：`resources/rawfile/` 下作为 rawfile，还是 `resources/base/font/` 下作为 font asset？授权文本要不要放在 `docs/` 里？PR 2 需要把 L3 组件族（13 个文件，见 mvp §10 PR 2 精确清单）的 `Text` 组件切到 `NotoSansSC-*` family；PR 3 L3 Canvas 通路首次输出用最终字体交人工审查建立回归基线 —— 两者都依赖字体资产先入库。**如果无法在 A 阶段引入**，则 PR 2/3 用系统字体，未来正式换字体时需重新人工审查并**更新导出图回归基线**（次选，代价是人工审查要重跑一次）。

   **已拍板（2026-07-18 真机构建修正）**：资产入口 = `resources/rawfile/font/`，`EntryAbility.onCreate` 用 `@ohos.font` API 注册 family。原假设 `resources/base/font/` 在真机构建时被 SDK 以 `Resource Pack Error 11211104: Invalid resource directory name 'font'` 拒收（`resources/base/` 仅允许 `element / media / profile` 三个子目录）。这不是 R8 授权清单里的规格与代码事实偏差，而是 spec 原始假设未经真机验证的跨端断言错误 —— Codex 停手回报后由 Claude 出根因和修复方案，用户拍板走标准方案。

**阻塞阶段 B**（PR 4~7）：

5. **EXIF PropertyKey 真机取值兼容测试**（影响 PR 5 EXIF 服务）：目标 SDK 6.1.1(24) 已声明 `LENS_MODEL / FOCAL_LENGTH / F_NUMBER / EXPOSURE_TIME`，无需再问 API 是否存在。真正待验证的是**不同品牌相机 EXIF 取值格式**（Sony 光圈是 `2.8` 还是 `f/2.8`，iPhone 快门是 `1/500` 还是 `0.002`），Codex 在 PR 5 实施前需跑一次真机采样，出一份归一化映射表交 Claude review。

**阻塞阶段 C**（PR 8~10）：

6. **思源宋体 CN Regular 资产入口**（影响 PR 8 L2 手写签名）：与思源黑体同目录下加载，还是走独立目录？授权文本汇总位置？
7. **`reviews` 表新增冗余列走 RDB migration script 还是随首次访问懒创建**（影响 PR 9）？现有代码风格倾向哪种？

阻塞阶段 A 的 1~4 项确认完毕即可进入 PR 1；阶段 B/C 相关项在对应 PR 启动前再补。
