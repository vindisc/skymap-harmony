# 规格：Frame + Review v2 · MVP 四模板

本文件是 MVP 阶段四个模板的**完整规格**。Codex 在阶段 A/B/C 实施时以本文件为唯一实施依据（L3、TEMPLATE_REGISTRY、PR 3 Canvas 也依赖本文档 §4 与 §7）。任何一处与本文件不符的实现都视为规格 bug，回来找 Claude 出方案。

阅读前置：`spec-20260716-frame-review-v2-data-model.md`。相对尺寸公式定义、Canvas 合成通路、`TemplateDescriptor / FrameConfigSpec` 类型声明在那份文档里，不在本文重复。

## 0. 四模板总览

| # | ID | Level | 中文名 | 定位 | 复盘字段深度 |
| --- | --- | --- | --- | --- | --- |
| 1 | `white_equal` | L0_FRAME | 纯白画廊 | 最通用的等宽白框 | 0 字段 |
| 2 | `meta_bottom` | L1_META | 参数底栏 | 相机 + 光圈快门 ISO | 0 字段 |
| 3 | `signature_overlay` | L2_NOTE | 手写签名 | 一句话签名叠加 | 1 字段（caption） |
| 4 | `adaptive_review_card` | L3_REVIEW | 摄影复盘卡 | 完整 8 字段复盘（自适应布局） | 8 字段 |

第四模板另有兄弟 `review_card`（旧血脉，只用于兼容读取，UI 中不再作为可选模板暴露）。见 §4.6。

四模板在编辑器区 B2 的排列顺序：`white_equal → meta_bottom → signature_overlay → adaptive_review_card`。跨档滑动符合 `spec-20260716-frame-review-v2-editor-ux.md` 第 3.3 节规则。

## 1. 模板 · `white_equal` 纯白画廊 · L0

### 1.1 视觉版式

```
┌────────────────────────────────────────┐  ← 背景 #FFFFFF
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  ← 外留白 outerPaddingRatio × longEdge
│░░┌──────────────────────────────────┐░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░│         照 片 · 原 图            │░░│
│░░│      (fit · 不做裁切 · 不做圆角) │░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░└──────────────────────────────────┘░░│
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│  ← 底部留白 = 外留白（等宽）
└────────────────────────────────────────┘
```

**关键特征**：四边等宽白色留白 · 无文字 · 无 EXIF · 无 logo · 无水印。目标是"体面的、经得起时间考验的默认样式"。

### 1.2 `TemplateDescriptor`

```typescript
{
  id: TemplateId.WHITE_EQUAL,
  level: TemplateLevel.L0_FRAME,
  displayName: '纯白画廊',
  displayNameEn: 'White Equal',
  contentBinding: {
    useTitle: false,
    useCaption: false,
    useExif: false,
    useReviewFields: false,
    useJudgement: false,
    useReviewer: false,
    useDate: false,
    useLogo: false
  },
  defaults: {
    frame: {
      outerPaddingRatio: 0.058,      // 长边的 5.8%（宽厚感）
      innerPaddingRatio: 0,           // 图与画布外边等宽，无内间距
      cornerRadiusRatio: 0,           // 硬边
      backgroundColorHex: '#FFFFFF',
      textColorHex: '#161616',
      secondaryTextColorHex: '#5F6368',
      titleFontRatio: 0.026,
      bodyFontRatio: 0.017,
      labelFontRatio: 0.012,
      lineSpacingRatio: 0.55,
      fieldSpacingRatio: 1.15,
      logoAssetId: '',
      watermarkText: ''
    },
    captionSourceHint: TemplateCaptionSource.NONE
  },
  allowedBackgroundColors: ['#FFFFFF']    // L0 仅纯白
}
```

### 1.3 尺寸公式带入

给定原图 `originalWidth × originalHeight`：

```
longEdge  = max(originalWidth, originalHeight)
shortEdge = min(originalWidth, originalHeight)

outerPaddingPx = round(longEdge × 0.058)

合成画布尺寸：
canvasWidth  = originalWidth  + 2 × outerPaddingPx
canvasHeight = originalHeight + 2 × outerPaddingPx

图片贴合位置：
imageOffsetX = outerPaddingPx
imageOffsetY = outerPaddingPx
```

**典型案例**：索尼 A7M4 全画幅 7008×4672 → outerPaddingPx = round(7008 × 0.058) = **406**；导出画布 7820×5484。

### 1.4 数据绑定

无字段绑定。所有 `content` 字段与 `exif` 字段在本模板中不显示，但**不被删除**（保存在 `document` 中）。

### 1.5 Canvas 合成步骤

```
1. new OffscreenCanvas(canvasWidth, canvasHeight)
2. ctx.fillStyle = '#FFFFFF'; ctx.fillRect(0, 0, canvasWidth, canvasHeight)
3. ctx.drawImage(originalPixelMap, outerPaddingPx, outerPaddingPx, originalWidth, originalHeight)
4. context.getPixelMap(0, 0, canvasWidth, canvasHeight) → image.PixelMap
   → ImagePacker.packToData JPEG 95%
```

### 1.6 排除项

- 不做圆角
- 不做阴影
- 不做水印
- 不做 logo
- 不响应"EXIF"抽屉入口（**EXIF chip 在此形态整体隐藏**，与 editor-ux §3.4 形态 1 一致；不做"灰置显示"）
- **背景色白名单：仅 `#FFFFFF`**。参数抽屉的背景色选项在此模板下**完全禁用**（灰置整行），因为 L0 定位就是"纯白画廊"，允许其他色即破坏语义
- **参数抽屉禁用无效控件**：L0 无文字区，`innerPaddingRatio` slider **禁用（灰置）**；L0 排除圆角，`cornerRadiusRatio` slider **禁用（灰置）**。只保留 `outerPaddingRatio` slider 与背景色行（后者禁用）。见 mvp §8 "参数抽屉可调范围"表末尾的"模板级禁用"注解。
- 不允许背景改成非纯色

## 2. 模板 · `meta_bottom` 参数底栏 · L1

### 2.1 视觉版式

```
┌────────────────────────────────────────┐  ← 背景 #FFFFFF
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░┌──────────────────────────────────┐░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░│         照 片 · 原 图            │░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░└──────────────────────────────────┘░░│
│░░                                    ░░│
│░░  SONY A7M4     35mm f/2.8 1/500 ISO400 │░░│  ← 参数底栏 · 两组
│░░                                    ░░│
└────────────────────────────────────────┘
```

**关键特征**：图片下方水平底栏，左侧相机型号加粗，右侧参数并排。相机品牌名走 `cleanCameraModel()` **精确前缀删除**（大小写严格匹配 6 组品牌前缀，见 §2.5，无自动大小写转换），参数用空格分隔。

### 2.2 `TemplateDescriptor`

```typescript
{
  id: TemplateId.META_BOTTOM,
  level: TemplateLevel.L1_META,
  displayName: '参数底栏',
  displayNameEn: 'Meta Bottom',
  contentBinding: {
    useTitle: false,
    useCaption: false,
    useExif: true,
    useReviewFields: false,
    useJudgement: false,
    useReviewer: false,
    useDate: false,
    useLogo: false
  },
  defaults: {
    frame: {
      outerPaddingRatio: 0.032,      // 长边 3.2%（比 L0 窄）
      innerPaddingRatio: 0.014,       // 图与底栏之间的呼吸
      cornerRadiusRatio: 0,
      backgroundColorHex: '#FFFFFF',
      textColorHex: '#161616',
      secondaryTextColorHex: '#5F6368',
      titleFontRatio: 0.024,          // 相机型号
      bodyFontRatio: 0.017,           // 参数
      labelFontRatio: 0.012,
      lineSpacingRatio: 0.55,
      fieldSpacingRatio: 1.15,
      logoAssetId: '',
      watermarkText: ''
    },
    captionSourceHint: TemplateCaptionSource.NONE
  },
  allowedBackgroundColors: ['#FFFFFF', '#F6F1E8', '#F0F0F0']    // L1 白 / 米白 / 浅灰
}
```

### 2.3 尺寸公式带入

```
outerPaddingPx = round(longEdge × 0.032)
innerPaddingPx = round(longEdge × 0.014)
titleFontPx    = round(shortEdge × 0.024)     // 相机型号
bodyFontPx     = round(shortEdge × 0.017)     // 参数

底栏高度 = titleFontPx × 2.4                  // 单行 + 上下呼吸
                                              // 即 shortEdge × 0.058 左右

canvasWidth  = originalWidth  + 2 × outerPaddingPx
canvasHeight = originalHeight + 2 × outerPaddingPx + innerPaddingPx + 底栏高度
```

### 2.4 数据绑定

底栏文字组织：

```
[左组 · 加粗 title 色]                  [右组 · 常规 secondary 色]
{cameraModel(经品牌前缀清洗)}           {focalLength} {aperture} {shutter} {iso}
```

具体绑定规则：

| 位置 | 来源字段 | 格式化 | 缺失兜底 |
| --- | --- | --- | --- |
| 左组 | `exif.cameraModel` | 走 `cleanCameraModel()` 精确前缀删除（Sony / Canon / Nikon / Fujifilm / Ricoh / Panasonic 六品牌大小写变体），保留后缀 | 显示原始文本；若整体为空，左组隐藏 |
| 右组 焦距 | `exif.focalLength` | 直接展示，含 `mm` 单位 | 隐藏 |
| 右组 光圈 | `exif.aperture` | 直接展示，含 `f/` | 隐藏 |
| 右组 快门 | `exif.shutter` | 直接展示，含 `1/`、`s` | 隐藏 |
| 右组 ISO | `exif.iso` | 直接展示（`exif.iso` 存"ISO400"这种渲染就绪文本，模板层**不**再前置 ISO） | 隐藏 |

**布局规则**：

- 左右组同一水平线，垂直居中于底栏
- 左组左对齐至 `outerPaddingPx + innerPaddingPx`
- 右组右对齐至 `canvasWidth - outerPaddingPx - innerPaddingPx`
- 左右组之间若空间不足（短边过短），**始终保持单行**：右组从右往左裁掉最左侧参数（保留 ISO 优先，其次快门、光圈、焦距），前置以省略号 `⋯`；若右组仅剩 ISO 仍溢出，则左组从右往左截断相机型号，前置省略号。**不换行**。此策略保证与 §2.7 "不做双行分栏"一致。

### 2.5 品牌前缀清洗规则

Codex 实现 `cleanCameraModel(input: string): string`：

```typescript
const brandPrefixes = ['SONY ', 'Sony ', 'CANON ', 'Canon ',
                       'NIKON ', 'Nikon ', 'FUJIFILM ', 'Fujifilm ',
                       'RICOH ', 'Ricoh ', 'PANASONIC ', 'Panasonic '];
for (const prefix of brandPrefixes) {
  if (input.startsWith(prefix)) {
    return input.slice(prefix.length);
  }
}
return input;
```

不处理大小写混用之外的形态。徕卡、大疆等品牌在 MVP 不进这份表，出现即原样展示。

### 2.6 Canvas 合成步骤

```
1. 计算 canvas 尺寸
2. fillRect 背景色
3. drawImage 原图（在顶部区域）
4. ctx.font = `${titleFontPx}px "NotoSansSC-Bold"`; ctx.fillStyle = '#161616'
   ctx.fillText(cleanCameraModel(exif.cameraModel), leftX, textBaselineY)
5. ctx.font = `${bodyFontPx}px "NotoSansSC-Regular"`; ctx.fillStyle = '#5F6368'
   ctx.textAlign = 'right'
   ctx.fillText(rightGroupText, rightX, textBaselineY)
6. context.getPixelMap(0, 0, canvasWidth, canvasHeight) → image.PixelMap
   → ImagePacker.packToData JPEG 95%
```

### 2.7 排除项

- 不做 Leica 红点、富士胶片 logo 等品牌视觉。MVP 只做纯文字底栏。
- 不做双行分栏排版。
- 不做分隔符（`·` `|` `/`）。品牌前缀已经清洗，参数并排靠字体自然区隔。
- 不做日期展示（日期属于 L0 `date_bottom` 或 L2 模板的能力）。

## 3. 模板 · `signature_overlay` 手写签名 · L2

### 3.1 视觉版式

```
┌────────────────────────────────────────┐  ← 背景 #FFFFFF
│░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│
│░░┌──────────────────────────────────┐░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░│         照 片 · 原 图            │░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░│                                  │░░│
│░░└──────────────────────────────────┘░░│
│░░                                    ░░│
│░░       —— 一句话 · 手写签名 ——      ░░│  ← 底部居中签名
│░░                                    ░░│
└────────────────────────────────────────┘
```

**关键特征**：底部居中一句话，思源宋体 Regular 中号，前后带两条短横线作为视觉锚点。签名内容由用户在编辑器区 C 的 `caption` 字段输入，最多 30 汉字。

### 3.2 `TemplateDescriptor`

```typescript
{
  id: TemplateId.SIGNATURE_OVERLAY,
  level: TemplateLevel.L2_NOTE,
  displayName: '手写签名',
  displayNameEn: 'Signature Overlay',
  contentBinding: {
    useTitle: false,
    useCaption: true,
    useExif: false,
    useReviewFields: false,
    useJudgement: false,
    useReviewer: false,
    useDate: false,
    useLogo: false
  },
  defaults: {
    frame: {
      outerPaddingRatio: 0.038,
      innerPaddingRatio: 0.020,
      cornerRadiusRatio: 0,
      backgroundColorHex: '#F6F1E8',    // 米白 · 带一点温度
      textColorHex: '#3A2E1F',           // 暖棕
      secondaryTextColorHex: '#8A7A63',
      titleFontRatio: 0.024,
      bodyFontRatio: 0.020,               // 宋体略大
      labelFontRatio: 0.012,
      lineSpacingRatio: 0.55,
      fieldSpacingRatio: 1.15,
      logoAssetId: '',
      watermarkText: ''
    },
    captionSourceHint: TemplateCaptionSource.CUSTOM
  },
  allowedBackgroundColors: ['#F6F1E8', '#FFFFFF']    // L2 米白 / 白，配色对暖棕文字友好
}
```

### 3.3 尺寸公式带入

```
outerPaddingPx = round(longEdge × 0.038)
innerPaddingPx = round(longEdge × 0.020)
bodyFontPx     = round(shortEdge × 0.020)

底部签名区高度 = bodyFontPx × 3.0        // 单行 + 上下宽呼吸
                                         // 即 shortEdge × 0.06 左右

canvasWidth  = originalWidth  + 2 × outerPaddingPx
canvasHeight = originalHeight + 2 × outerPaddingPx + innerPaddingPx + 签名区高度
```

### 3.4 数据绑定

| 位置 | 来源 | 格式化 | 缺失兜底 |
| --- | --- | --- | --- |
| 底部居中 | 编辑器 `caption` 字段（v2 新增 State） | 前后加 `—— ` 与 ` ——` | 若 `caption` 为空，底部签名区**折叠**（合成画布高度回退为 `imageHeight + 2 × outerPaddingPx`）。此时视觉与 L0 `white_equal` 但配色不同 |

**`caption` 字段落地位置**：

方案在 `ReviewCardModel.ets` 上**不新增 caption 字段**（避免污染主结构），改为**复用 `content.title` 字段**。规则：

- L2 模板时，编辑器区 C 显示的"一句话"输入 → 写入 `content.title`
- L3 模板时，编辑器区 C 显示的"标题"输入 → 也写入 `content.title`
- L0 / L1 模板时，`content.title` 不显示但不删除

**为什么这样简化**：MVP 阶段不希望为一句话再开一个字段。用户在 L2 与 L3 之间切换时，`title` 数据无损保留，语义上"这是这张照片的标题式一句话"是自洽的。

### 3.5 Canvas 合成步骤

```
1. 计算 canvas 尺寸
2. fillStyle = frame.backgroundColorHex; fillRect 全画布
   (**从 config.frame 读**，不是硬编码 '#F6F1E8'；L2 白名单允许 
    #F6F1E8 或 #FFFFFF)
3. drawImage 原图
4. 若 content.title 非空：
   4.1 ctx.font = `${bodyFontPx}px "NotoSerifSC-Regular"`
   4.2 ctx.fillStyle = frame.textColorHex
       (**从 config.frame 读**，不是硬编码 '#3A2E1F')
   4.3 ctx.textAlign = 'center'; ctx.textBaseline = 'middle'
   4.4 ctx.fillText(`—— ${content.title} ——`, canvasWidth / 2, signatureBaselineY)
5. context.getPixelMap(0, 0, canvasWidth, canvasHeight) → image.PixelMap
   → ImagePacker.packToData JPEG 95%
```

### 3.6 排除项

- 不做多行签名（单行 30 汉字上限，Editor 侧校验）
- 不做倾斜、旋转、手写字体（用思源宋体 Regular 代表"手写感"，避免另引入手写体字库）
- 不做签名位置调节（MVP 固定底部居中）
- 不做前后花体符号（只用 `——`）

## 4. 模板 · `adaptive_review_card` 摄影复盘卡 · L3

**这个模板是现有复盘卡的血脉延续**。视觉与字段基本沿用当前 `MobileReadingReviewCard.ets / LongFormExportReviewCard.ets` 的呈现，本节只声明**在 v2 数据结构下如何重新落座**，不重新设计视觉。

### 4.1 视觉版式（MVP 阶段冻结现有 L3 组件行为，不重画版式）

**MVP 阶段 L3 组件不动**（B 方向决策，见 overview §7 阶段 A），因此 L3 视觉版式以现有 `MobileReadingReviewCard.ets` / `LongFormExportReviewCard.ets` 代码为准，本节不重新绘制。**真实现状**（Codex 实施 PR 2 前请对照代码确认；本表已按真实 grep 结果重写，替换 R6 版本里凭想象写的错误描述）：

| 事项 | 现有真实状态 | v2 是否改动 |
| --- | --- | --- |
| 三方向布局函数 | `resolveLayoutMode()` 定义在 `entry/src/main/ets/model/ReviewCardLayout.ets`，**有调用方**（Mobile L21 通过 `ReviewCardStylePreset.resolve` 间接消费，且 Preview / Export 路径都用到 `resolveReviewCardLayoutType`） | 不动 |
| Mobile 阅读页布局 | **按 `layoutType` 选不同 preset**（`MobileReadingReviewCard.ets` L18 `@Prop layoutType`，L21 `ReviewCardStylePreset.resolve(MOBILE_READING, layoutType)`；L37 竖图走 `compact = true` 分支） | 不动 |
| LongForm 导出布局 | **有明确横图/非横图结构分支**（`LongFormExportReviewCard.ets` L502 附近，横图专用 `EXPORT_CARD_HORIZONTAL_TITLE_BAR` + 双栏 Panel，L38~L48 有一批 `EXPORT_CARD_HORIZONTAL_*` 常量） | 不动 |
| 字号来源 | **`ReviewCardStylePreset.ets`**（90 行，通过 `ReviewCardStyleDefinition` 定义 preset 集），**不是 StyleTokens**；`ReviewCardStyleTokens.ets` 只有 34 行，含 `canvasColor` 等固定颜色 | 不动 |
| 背景色 | 硬编码 `#FFFEFC`（`ReviewCardStyleTokens.canvasColor`），不消费 `config.background` | 不动 |
| 字段标签 | Mobile / LongForm 各自维护标签集合，**横图导出遗漏 `focusReason`**，且使用"最强关系 / 卡点 / 复盘信息"等标签，与 mvp §4.3 数据绑定表**不完全一致** | 不动（未来 L3 v2 化时统一） |
| `fontFamily` | 未设置，走系统字体 | **PR 2 顺带切**（见 §10 PR 2 精确文件清单） |
| Canvas 导出通路 | 无（现有走组件截图） | **PR 3 新增 L3 走 Canvas 通路（原图分辨率），使用独立 `L3CanvasSpec`，见 §4.7** |

**v2 抽象覆盖范围**：L3 组件不消费 `config.frame` / `config.templateLevel` / `config.background` / `config.textSize`；这些字段在 L3 数据上写入了 v2 结构（PR 1 数据模型演进），但 L3 渲染代码里 **不读取它们**。v2 抽象只服务 L0/L1/L2 三个新模板。L3 消费 frame 是**方案外后续**（未来独立 PR）。

**数据绑定表（§4.3）与字段标签**：数据绑定表描述 L3 数据模型对应字段（`ReviewContent` 8 字段），不代表所有字段在现有 Mobile/LongForm 里都被同名标签渲染。PR 2 期间**不修正**标签不一致，Codex 实施时按现有组件代码为准；未来 L3 v2 化独立 PR 会统一。

### 4.2 `TemplateDescriptor`

```typescript
{
  id: TemplateId.ADAPTIVE_REVIEW_CARD,
  level: TemplateLevel.L3_REVIEW,
  displayName: '摄影复盘卡',
  displayNameEn: 'Adaptive Review Card',
  contentBinding: {
    useTitle: true,
    useCaption: false,
    useExif: false,
    useReviewFields: true,
    useJudgement: true,
    useReviewer: true,
    useDate: true,
    useLogo: false
  },
  defaults: {
    frame: {
      outerPaddingRatio: 0.032,
      innerPaddingRatio: 0.010,
      cornerRadiusRatio: 0.006,        // 略带圆角，沿用现有卡片风格
      backgroundColorHex: '#FFFFFF',
      textColorHex: '#161616',
      secondaryTextColorHex: '#5F6368',
      titleFontRatio: 0.026,
      bodyFontRatio: 0.017,
      labelFontRatio: 0.012,
      lineSpacingRatio: 0.55,
      fieldSpacingRatio: 1.15,
      logoAssetId: '',
      watermarkText: ''
    },
    captionSourceHint: TemplateCaptionSource.NONE
  },
  allowedBackgroundColors: ['#FFFFFF', '#F6F1E8', '#F0F0F0']    // L3 白 / 米白 / 浅灰
}
```

### 4.3 数据绑定

| 位置 | 来源 | 缺失兜底 |
| --- | --- | --- |
| 标题 | `content.title` | 显示 `DEFAULT_REVIEW_TITLE`（"这张照片是否成立"） |
| 复盘时间 | `document.updatedAt` 格式化 | 显示当前时间 |
| 复盘人 | 复盘设置 `reviewerName` | 空字符串 |
| 判定 | `content.judgement` 归一化后展示 | 隐藏 |
| 视觉落点 | `content.visualFocus` | 该行整体隐藏 |
| 落点原因 | `content.focusReason` | 该行整体隐藏 |
| 视线路径 | `content.visualPath` | 该行整体隐藏 |
| 画面事实 | `content.visibleFacts` | 该行整体隐藏 |
| 核心关系 | `content.coreRelation` | 该行整体隐藏 |
| 延伸理解 | `content.extendedUnderstanding` | 该行整体隐藏 |
| 当前卡点 | `content.currentBlocker` | 该行整体隐藏 |

**这一切与现有实现一致**。**B 方向核心约束**：L3 阅读页与组件截图导出路径**继续以冻结组件常量为权威**（`ReviewCardStylePreset` / `ReviewCardStyleTokens` / 组件内硬编码 fp），**不消费 `document.config.frame`**。L3 走 Canvas 导出（PR 3 新能力）使用独立的 `L3CanvasSpec`（见 §4.7 固定基线宽度 + 缩放系数），也不引用用户可调 frame。R6 之前草案中"L3 唯一改动是让 `document.config.frame` 参与几何计算"的说法已作废。

### 4.4 Canvas 合成步骤

Codex 在实现 L3 的 Canvas 合成通路时，以现有 `LongFormExportReviewCard.ets` 排版为参考蓝本（含 `EXPORT_CARD_HORIZONTAL_*` 横图专用常量与 `resolveLongFormExportCardHeight` 等），按 `L3CanvasSpec`（§4.7）的固定基线缩放到原图分辨率，翻译为 OffscreenCanvas 命令：

1. 计算文字换行（`ctx.measureText` + 手动断行）
2. 逐字段绘制标签 + 正文
3. 图片 + 文字区总高按 `resolveLongFormExportCardHeight` 相同规则计算

阶段 A 的 L3 Canvas 目标是**输出可接受的原图分辨率导出图**（B 方向：L3 组件不动，Canvas 通路是新增能力）。**验收拆两条**（见 overview §7 阶段 A + data-model §5.4）：**验收 1 · L3 视觉零差异**（PR 2 责任，结构性保证 —— 组件文件除字体外未改动，无需 pixel diff）；**验收 2 · Canvas 导出图人工视觉审查**（PR 3 责任），通过 5 张固定 fixture 样本后成为导出图回归基线。

### 4.5 排除项

- 不改字段顺序（已冻结）
- 不改字段标签中文（已冻结）
- 不改判定枚举呈现
- 不引入 EXIF 展示（L3 目的是复盘，不是参数展示）
- 不引入 logo 或水印

### 4.7 L3CanvasSpec（PR 3 新增，独立于 FrameConfig）

L3 走 Canvas 导出使用**独立的固定规格**，不引用用户可调的 `frame` 字段。规格如下：

**基线（对应现有 `LongFormExportReviewCard` 组件截图路径的典型尺寸）**：

```
L3_CANVAS_BASELINE_TOTAL_WIDTH  = 1520 px    // 整卡宽（含左右 padding）
L3_CANVAS_BASELINE_H_PADDING    = 48 px      // 单侧水平 padding
L3_CANVAS_BASELINE_PHOTO_WIDTH  = 1520 - 48*2 = 1424 px   // 照片实际占位宽
```

**缩放系数**（**以照片内容宽为基准反算，保证照片按原分辨率不缩放**）：

```
scale = originalWidth / L3_CANVAS_BASELINE_PHOTO_WIDTH
      = originalWidth / 1424

例：4032×3024 → scale ≈ 2.83
    7008×4672 → scale ≈ 4.92
```

**画布尺寸**（向两侧扩 padding，照片保持原像素不缩放）：

```
canvasWidth  = originalWidth + L3_CANVAS_BASELINE_H_PADDING * 2 * scale
             = originalWidth + 96 * scale
             ≈ originalWidth × (1 + 96/1424)
             ≈ originalWidth × 1.0674

photoOffsetX = round(L3_CANVAS_BASELINE_H_PADDING * scale) = round(48 * scale)
photoOffsetY = round(某个 topPadding * scale)                // 由现有 EXPORT_CARD 常量映射

canvasHeight = photoOffsetY + originalHeight
             + textAreaHeight * scale
             + bottomPadding * scale

其中 textAreaHeight 由字段填充内容按现有 resolveLongFormExportCardHeight 逻辑计算
（在基线宽度 1520 下），然后 × scale 得到 Canvas 上实际像素。
```

**照片贴图**：`ctx.drawImage(rotatedPixelMap, photoOffsetX, photoOffsetY, originalWidth, originalHeight)` —— **1:1 像素**，不做任何插值缩放。

**几何量**：所有现有 `EXPORT_CARD_HORIZONTAL_*` 常量与 `LongFormExportReviewCard.ets` 里的 fp 值 × scale 得到 Canvas 实际像素；例如：
- `titleFontPx = 32 × scale`（Mobile 用 20，导出用 32）
- `bodyFontPx = 22 × scale`
- `cornerRadiusPx = 22 × scale`（导出圆角）
- `panelPaddingPx = EXPORT_CARD_HORIZONTAL_PANEL_PADDING × scale = 28 × scale`
- 其余横图常量（`EXPORT_CARD_HORIZONTAL_BAR_TOP_MARGIN` 等）同理

**横图/非横图判定**（**必须以 Orientation 旋转后的 PixelMap 尺寸决定**）：

```
1. 走完 §5.5 orientation 处理，拿到旋转后的 PixelMap（含 width/height 交换）
2. 用 rotatedPixelMap.width / rotatedPixelMap.height 判定：
   isHorizontal = rotatedPixelMap.width > rotatedPixelMap.height * 1.05
3. 走 LongFormExportReviewCard.ets 现有 isHorizontalExportPhoto(document)
   同款判定阈值（**真实函数**见 L142；不是 resolveReviewCardLayoutType()）
4. isHorizontal ? 双栏 Panel : 单列长图
```

**关键**：**不能用旋转前的 `document.imageWidth/imageHeight`** 判定分支（Orientation=6/8 竖拍原图在 EXIF 里 imageWidth > imageHeight，但视觉上是竖图，走错分支会得到布局灾难）。

**颜色来源**（**按真实来源逐项列**，全部硬编码，Canvas 不读 `config.frame.*ColorHex`）：
- 背景：`ReviewCardStyleTokens.canvasColor = #FFFEFC`
- 判定文字：`ExportCardColors.judgementText`（来自 `AppDesign.ets`）
- 判定背景：`ExportCardColors.judgementBg`
- 判定边框：`ExportCardColors.judgementBorder`
- 元信息文字：`ExportCardColors.metaText`
- 标题面板背景：`ExportCardColors.titlePanelBg`
- 分隔线：`ExportCardColors.dividerColor`
- 其他字段文字色：以 `LongFormExportReviewCard.ets` 里 `.fontColor()` 实际调用值为准（大多来自 `ExportCardColors`；Codex 实施时逐一 grep 抄）
- 字号/尺寸相关：`ReviewCardStylePreset.ets`（主要是尺寸和 divider width，不承载颜色）

**字体**：`NotoSansSC-Bold` / `NotoSansSC-Regular`（PR 2 已切旧组件字体，Canvas 用同一 family 保持一致）

**Codex 实施注意**：`L3CanvasSpec` 是**规格名**，可以落成 `entry/src/main/ets/services/L3CanvasSpec.ets` 独立文件（暴露一批常量 + `resolveL3CanvasGeometry(document, rotatedPixelMapSize)` 函数），也可以内联到 Canvas 服务里 —— 按当前代码风格自行决定，规格只要求"L3 Canvas 几何与用户 frame 解耦，且能通过 5 张 fixture 人工审查"。

### 4.6 兄弟模板 · `review_card`（旧血脉）

`TemplateId.REVIEW_CARD` 保留在枚举中的原因是：老 RDB `raw_document_json` 中可能有 `config.templateId = 'review_card'`。`resolveTemplate('review_card')` 直接返回 `ADAPTIVE_REVIEW_CARD` 描述符即可。`review_exchange/*.review.json` 遵循 Review JSON Schema v1，不携带 `templateId`，不涉及此兼容分支。

**不在 UI 中作为可选模板**。用户切档到 L3 只能选 `adaptive_review_card`。

## 5. 缩略图资产清单

Codex 需要向设计侧申请以下资产：

| 资产 ID | 尺寸 | 内容 |
| --- | --- | --- |
| `template-thumbnail-white-equal.svg` | 112 × 144 dp | 白框 + 内嵌灰色矩形示意图片 |
| `template-thumbnail-meta-bottom.svg` | 112 × 144 dp | 白框 + 内嵌图片 + 底栏文字 mock |
| `template-thumbnail-signature-overlay.svg` | 112 × 144 dp | 米白框 + 内嵌图片 + 底部签名文字 mock |
| `template-thumbnail-adaptive-review.svg` | 112 × 144 dp | 白框 + 内嵌图片 + 底部多行文字块 mock |

放置位置：`entry/src/main/resources/base/media/frame_templates/`。若资产未到位，Codex 用纯色占位 chip（背景色对应模板 `backgroundColorHex`，中心显示模板中文名 12sp），不阻塞主流程。

## 6. 字体资产

四个模板共用两款字体：

- **思源黑体 CN**（Bold + Regular）—— L0 无文字，用不到；L1 用 Bold 显示相机型号 + Regular 显示参数；L3 用 Bold 显示标题 + Regular 显示正文。**阶段 A 引入**（PR 2 顺带切旧路径字体 **+** PR 3 Canvas 通路首用，两者都依赖字体资产先入库），资产入口决策见 data-model §8 **阻塞 A · 第 4 项**（影响 PR 2、PR 3）。
- **思源宋体 CN**（Regular）—— L2 显示签名。**阶段 C 引入**（PR 8），资产入口决策见 data-model §8 **阻塞 C · 第 6 项**（与黑体同目录还是独立目录二选）。

字体放置目录：待上述两项决策确定。字体 family 名注册为：

- `NotoSansSC-Bold`
- `NotoSansSC-Regular`
- `NotoSerifSC-Regular`

Canvas `ctx.font` 中直接使用 family 名（**不要**写"思源黑体 Bold"这种中文名——不是注册的 family 名）。ArkUI 组件用 `Text().fontFamily('NotoSansSC-Regular')`。

字体加载失败兜底：走系统字体（`sans-serif` / `serif`），Toast 提示"字体加载失败，已使用系统字体"（一次会话内只提示一次）。

## 7. 相对尺寸值总表

四模板 `FrameConfigSpec` 的默认值集中在一张表里，方便 Codex 校对：

| 参数 | white_equal | meta_bottom | signature_overlay | adaptive_review_card |
| --- | ---: | ---: | ---: | ---: |
| outerPaddingRatio | 0.058 | 0.032 | 0.038 | 0.032 |
| innerPaddingRatio | 0.000 | 0.014 | 0.020 | 0.010 |
| cornerRadiusRatio | 0.000 | 0.000 | 0.000 | 0.006 |
| backgroundColorHex | #FFFFFF | #FFFFFF | #F6F1E8 | #FFFFFF |
| textColorHex | #161616 | #161616 | #3A2E1F | #161616 |
| secondaryTextColorHex | #5F6368 | #5F6368 | #8A7A63 | #5F6368 |
| titleFontRatio | 0.026 | 0.024 | 0.024 | 0.026 |
| bodyFontRatio | 0.017 | 0.017 | 0.020 | 0.017 |
| labelFontRatio | 0.012 | 0.012 | 0.012 | 0.012 |
| lineSpacingRatio | 0.55 | 0.55 | 0.55 | 0.55 |
| fieldSpacingRatio | 1.15 | 1.15 | 1.15 | 1.15 |

## 8. 参数抽屉 · 用户可调范围

编辑器的"边框参数"抽屉允许用户在以下范围内微调（超出范围滑到边缘不再变化）：

| 参数 | 最小 | 最大 | 步进 |
| --- | ---: | ---: | ---: |
| outerPaddingRatio | 0.010 | 0.100 | 0.002 |
| innerPaddingRatio | 0.000 | 0.030 | 0.002 |
| cornerRadiusRatio | 0.000 | 0.030 | 0.002 |
| backgroundColorHex | 由 `TemplateDescriptor.allowedBackgroundColors` 白名单约束（PR 6 编辑器抽屉从 descriptor 读取），实际值域详见每个模板 §X 的字段 —— L0 `['#FFFFFF']` / L1 `['#FFFFFF','#F6F1E8','#F0F0F0']` / L2 `['#F6F1E8','#FFFFFF']` / L3 同 L1 | — | — |

**模板级禁用规则**：每个 `TemplateDescriptor` 都可能对应一批"在该模板下无效"的抽屉控件。MVP 阶段的禁用矩阵（**B 方向**：L3 组件不消费 frame，因此 L3 的整个"边框参数"抽屉入口 chip 隐藏；用户不会看到任何 L3 上无效的边框参数）：

| 控件 / 入口 | L0 white_equal | L1 meta_bottom | L2 signature_overlay | L3 adaptive_review_card |
| --- | :---: | :---: | :---: | :---: |
| "边框参数" chip 入口 | ✅ | ✅ | ✅ | 🚫（整个入口隐藏 —— L3 不消费 frame） |
| outerPadding slider | ✅ | ✅ | ✅ | — |
| innerPadding slider | 🚫（无文字区） | ✅ | ✅ | — |
| cornerRadius slider | 🚫（排除圆角） | ✅ | ✅ | — |
| background swatch | 🚫（锁 #FFFFFF） | ✅ | ✅ | — |
| EXIF chip | 🚫（隐藏） | ✅ | 🚫（隐藏） | 🚫（隐藏，L3 不展示 EXIF） |
| 判定 chip | 🚫（隐藏） | 🚫（隐藏） | 🚫（隐藏） | ✅ |

🚫 = 参数抽屉里控件整行灰置或整个 chip 隐藏；✅ = 正常可交互；— = 该模板下整个入口不存在，无需讨论内部控件。此矩阵为 PR 6 编辑器实现依据。

**L3 只显示"判定 chip"**（沿用现有 L3 编辑体验），不显示"边框参数 / EXIF"入口。

**S/M/L 字号档 · B 方向下不作为 PR 2 交付**：R5 时代设计的 `resolveTextSizeMultiplier` / `mapLegacyBackground` / `rebuildFrameOnTextSizeChange` 三个函数在 B 方向下都无必要（L3 组件不消费 frame，新模板不写老字段），**不进 PR 2 清单**。未来 L3 v2 化独立 PR 时再补。

`ReviewCardTextSize` 枚举保留（现有代码引用），但**在 v2 方案范围内不接入任何渲染逻辑**。`ReviewCardTheme.ets` 保持现状不改。

字体大小、颜色、行距等**不允许用户在 v2 抽屉中调**（细调不开放）。原因：一动就会打破排版平衡，MVP 不做这个自由度。字号档在 `ReviewCardTextSize` 上有 S/M/L 三档粗调（延续现有枚举）**不接入 v2 任何渲染逻辑**（B 方向：L3 组件不消费 frame，新模板不写老字段）。`rebuildFrameOnTextSizeChange` / `resolveTextSizeMultiplier` / `mapLegacyBackground` 三个函数**不作为 PR 交付**，未来 L3 v2 化独立 PR 时再补。

## 9. Preview 页导出选择

Preview 页顶部保留现有的"导出"入口，改造为下拉菜单：

```
导出 ▾
  ├─ 导出到相册（原图分辨率 · JPEG）        ← v2 新增，默认高亮
  ├─ 导出到相册（屏幕分辨率 · JPEG）        ← 现有组件截图路径降级，Canvas 失败时可手动切
  ├─ 导出复盘包                              ← 现有
  └─ 导出复盘包（含原图）                    ← 现有
```

**共 4 项**，与 mvp §10 PR 7 "Preview 页导出下拉菜单（原图 / 屏幕分辨率 / 复盘包 / 复盘包含原图）"数量一致。

第一项即调用 `ReviewCardExportService.exportOriginalResolution(context, document, reviewerName)`（三参 class 静态方法，reviewerName 由 PreviewPage 加载后传入，返回 `Promise<ReviewCardExportResult>`；唯一契约见 data-model §5.6）。

**第二项（屏幕分辨率降级路径）**：调用现有组件截图路径。**始终显示在菜单中**（不是"Canvas 失败时才动态出现"），给用户在原图路径出问题时的手动降级选项；Canvas 失败时另外在预览页顶部 InlineStatusBanner 提示"原图导出失败，建议使用屏幕分辨率"。

## 10. 阶段拆分建议（与 overview §7 阶段边界严格对应）

以下 10 个 PR 按 overview §7 的 A/B/C 三阶段归属。每个 PR 独立可提交、可回退，附独立回归清单。

**阶段 A · 地基**（硬门槛，验收 1 阅读页零差异 + 验收 2 导出图人工审查是核心，见 overview §7）

- PR 1：`TemplateDescriptor` + `FrameConfigSpec` + `ExifPayload` 三个模型文件落地，`TEMPLATE_REGISTRY` 填表 4 条（照抄本文档 §1.2 / §2.2 / §3.2 / §4.2 完整默认值），`REVIEW_CARD` 与 `ADAPTIVE_REVIEW_CARD` 共享同一 descriptor 实例。**同时交付**：
  - `upgradeVersionOnPersist(doc): ReviewCardDocument` helper（data-model §4.4 定义），供所有 RDB 写入路径调用
  - 把 helper 接入 `ReviewCardHistoryService.saveDocument` 与 `updateDocument`（如存在的话；grep 确认后一并接入 Preview 自动保存路径）
  - 在 `ReviewCardHistoryService.ets` L927~945 沙箱备份逻辑上方加注释警告："`review.json` 沙箱备份遵循 Review JSON Schema v1，不含 `frame / templateLevel / exif` 扩展字段。若 RDB 损坏后从此备份恢复，用户会失去 v2 模板与 EXIF 状态。此降级已在 schema-alignment §5 显式接受。"
- PR 2：`ReviewCardRenderer` 从 `renderMode` 二分升级为 `templateId × renderMode` 分发（B 方向：L3 分发到现有 L3 组件族，**只允许改 `fontFamily`**）。**PR 2 字体切换精确文件清单**（Codex 严格按此清单改，其他文件不动）：
  - `entry/src/main/ets/components/MobileReadingReviewCard.ets`
  - `entry/src/main/ets/components/LongFormExportReviewCard.ets`
  - `entry/src/main/ets/components/ReviewCardTitle.ets`
  - `entry/src/main/ets/components/ReviewInfoGroup.ets`
  - `entry/src/main/ets/components/ReviewInfoItem.ets`
  - `entry/src/main/ets/components/HorizontalReviewCard.ets`
  - `entry/src/main/ets/components/VerticalReviewCard.ets`
  - `entry/src/main/ets/components/SquareReviewCard.ets`
  - `entry/src/main/ets/components/ExportHorizontalReviewCard.ets`
  - `entry/src/main/ets/components/ExportVerticalReviewCard.ets`
  - `entry/src/main/ets/components/ExportSquareReviewCard.ets`
  - `entry/src/main/ets/components/ReadingReviewCard.ets`
  - `entry/src/main/ets/components/ReadingReviewRecord.ets`

上述文件中**所有 `Text(` 组件调用**统一加 `.fontFamily('NotoSansSC-Regular')` 或 `.fontFamily('NotoSansSC-Bold')`（按现有 `.fontWeight` 判断：粗体用 Bold，其他用 Regular）；**除 `fontFamily` 外禁止改任何布局、字号、颜色、字段绑定、字段顺序**。Codex 实施前请 `grep -rn "Text(" entry/src/main/ets/components/ | grep -v fontFamily` 确认覆盖完整。**验收 · L3 布局结构等价 + 字体变化已授权**（见 overview §7 阶段 A 验收 1、data-model §5.4）：不做像素级 pixel diff（字体切换会影响字形/度量/换行/抗锯齿）；三方向阅读页 + 组件截图导出路径的人工冒烟审查。`LIGHT_GRAY / SMALL / LARGE` 老数据打开视觉与升级前一致（L3 组件本就不消费这些字段，不需要 change log）。
- PR 3：Canvas 合成通路打通 + L3 走 Canvas（原图 PixelMap + 边框合成 + JPEG 95%）+ EXIF orientation 处理（见 data-model §5.5，避免竖拍原图侧翻）+ `exportOriginalResolution` 服务契约（见 data-model §5.6：签名/并发锁/资源释放/reviewer 来源）。**依赖思源黑体 CN 资产已入库**，见 data-model §8 阻塞 A · 第 4 项。**验收 · 导出图人工视觉审查**（见 overview §7 阶段 A 验收 2、data-model §5.4）：5 张固定 fixture 样本（见 data-model §5.4 fixture manifest 表：横 4032×3024 / 横 7008×4672 / 竖 3024×4032 / 竖 4672×7008 + LIGHT_GRAY+LARGE / 方 4032×4032），源图与 manifest 落地 `test-artifacts/pixel-diff-baseline/export/`，含 SHA256 hash + 生成参数 + 通过日期。首次交用户/设计视觉确认可接受后成为回归基线；**后续 PR 修改 Canvas 通路时用该基线做 pixel diff（差异像素 ≤ 5%，RGB 差异 ≤ 16/256）**。旧组件截图作为**降级路径**保留。本 PR 提供的路径切换仅为**开发者调试开关**（DEBUG 模式或隐藏手势触发），不面向普通用户，面向用户的正式导出下拉菜单在 PR 7。

**阶段 B · 模板矩阵**

- PR 4：L0 `white_equal` 模板落地（TEMPLATE_REGISTRY 已填，本 PR 补 Canvas 合成实现 + 模板缩略图 chip + 新增 `utils/TemplateApply.ets` 中的 `applyTemplateToDocument(document, templateId): ReviewCardDocument` 工具函数，用于跨页面切模板；本函数不修改入参 document，返回新对象）
- PR 5：L1 `meta_bottom` 模板 + EXIF 读取服务（`ExifReaderService` 基于 `image.ImageSource.getImageProperty`）+ **独立的 `ExifSheet` 组件**（作为可复用组件文件交付，本 PR 不接入编辑器 UI —— 编辑器骨架在 PR 6 才创建）。**明确**：EditorPage `aboutToAppear()` 调用 EXIF 服务、把 payload 合并进 document 状态属**PR 6 责任**，PR 5 不动 EditorPage
- PR 6：编辑器一屏三区改造第一版（区 A 预览 + 区 B1 档位 tab 显示 **L0/L1/L2/L3 四档**（**L2 chip 灰置不可点，PR 8 才启用**）+ 区 B2 模板横滑 + 区 C 抽屉入口 + L0/L1/L3 三档切换 + **接入 PR 5 交付的 `ExifSheet` 组件到抽屉入口** + EditorPage aboutToAppear 内调用 EXIF 服务与状态合并）
- PR 7：Preview 页导出下拉菜单（原图 / 屏幕分辨率 / 复盘包 / 复盘包含原图）+ **我的页面全局默认开关（2026-07-19 追加）**：在"我的页面 · 复盘设置"里加一个开关"默认走原图分辨率导出" ON/OFF。语义：
  - 开关 ON（默认 OFF）：用户点导出按钮**跳过下拉菜单**，直接按原图分辨率合成走 `exportOriginalResolution` 服务
  - 开关 OFF：保留 PR 7 原设计的**下拉菜单**（原图 / 屏幕分辨率 / 复盘包 / 复盘包含原图 四选一）
  - 两种模式并存不冲突：开关 = 全局默认路径，下拉菜单 = 单次临时选择
  - 落位：Preferences 里新增布尔字段 `exportDefaultOriginalResolution`，由"我的页面 · 复盘设置"里读写；PreviewPage 导出按钮 tap handler 里先读该字段决定分支
  - **用户诉求来源**：PR 3 视觉验收后，用户反馈"我需要一个我的页面开关控制原图/压缩"

**阶段 C · 深度扩展**

- PR 8：L2 `signature_overlay` 模板 + 思源宋体资产 + `content.title` 复用为 caption + **启用 PR 6 中灰置的 L2 tab/chip**（编辑器状态机接入 L2 输入区、Canvas 通路补 L2 合成）
- PR 9：复盘库聚合抽屉（按模板 / 相机 / 镜头 / 判定；RDB `reviews` 表新增冗余列 + 回填 task）
- PR 10：每周回顾仪式（沿用 `CeremonyBurst`，每周日推送"本周 X 张、Y 张成立、Z 张待复盘"）

每个 PR 通过后可独立回退。阶段 A 是硬门槛，A 完成前不进入 B。

**PR 依赖拓扑**（真依赖，无伪边）：

```
阶段 A: PR 1 → PR 2 → PR 3         （严格串行）
              ↓
阶段 B:      PR 4                   
             PR 5                   （PR 4、PR 5、PR 7 三者相互独立，可并行）
             PR 7                   
              ↓                      
             PR 6                   （PR 6 依赖 PR 4 + PR 5）

阶段 C:      PR 8                   （PR 8 依赖 PR 6）
             PR 9                   （PR 9、PR 10 独立于 L2，可与 PR 8 并行）
             PR 10                  
```

- **阶段 A**：PR 1 → PR 2 → PR 3 严格串行
- **阶段 B**：
  - PR 4、PR 5、PR 7 相互独立，可并行开发
  - PR 6 依赖 PR 4（`applyTemplateToDocument` utility）与 PR 5（`ExifSheet` 组件）都完成
  - PR 7（Preview 下拉菜单）只依赖阶段 A 的 Canvas 通路，与 PR 6 独立
- **阶段 C**：
  - PR 8 依赖 PR 6（需要编辑器骨架的 L2 灰置 tab）
  - PR 9（复盘库聚合）、PR 10（每周仪式）与 L2 无关，独立于 PR 8

## 11. 待人工确认清单

以下问题也纳入 README 关键决策清单相应阶段分组：

1. **品牌前缀清洗表补齐**（阻塞 B · README 第 6 项）：Sony / Canon / Nikon / Fujifilm / Ricoh / Panasonic 已列，是否要补 Leica / DJI / 苹果 / 小米？影响 §2.5 `cleanCameraModel()` 实现。
2. **思源宋体代替真手写体是否可接受**（阻塞 C · 补入 README）：如果要真手写体，需要另采购或授权字库；MVP 建议接受思源宋体 Regular 作为"手写感"呈现。影响 PR 8 是否需要追加字体采购流程。
3. **L2 `caption` 复用 `content.title` 是否 OK**（阻塞 C · README 第 7 项）：默认复用，避免新增字段。若不 OK，需要在 `ReviewContent` 上新增 `caption?: string` 字段。
4. **模板缩略图交付**（不阻塞 · README 第 11 项）：设计侧交付时间；未到位走纯色占位。
5. **参数抽屉背景色是否开放自定义 HEX**（不阻塞 · 补入 README）：MVP 建议不开，仅允许 `TemplateDescriptor` 白名单内枚举（见 §8）。若开放，需要 PR 6 加 HEX 输入 + 校验 + 对比度告警。
