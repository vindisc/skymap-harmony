# 规格：Frame + Review v2 · 编辑器交互稿

本文件是编辑器（`EditorPage.ets`）改造的**交互规格**。原型使用 ASCII + 状态描述，不出 Figma。视觉稿由 Codex 在实现阶段按现有 `AppDesign / DesignTokens / MotionQualityContext` 组件库上色，无需额外重画。

阅读前置：`spec-20260716-frame-review-v2-overview.md`、`spec-20260716-frame-review-v2-data-model.md`。

## 1. 改造原则

1. **不推翻现有 `EditorPage`**。继承其页面骨架、键盘避免（`disableSystemKeyboardAvoidance` + 手动 scroll）、脏检查（`isDirty`）、intro 分阶入场（`introStage`，当前实现为 0→1→2 三阶）、Toast/Dialog 服务、`PhotoWritingHero` 组件。
2. **只在页面主体做重构**。当前"标题 `TextInput` + 7 字段 `TextArea` + 判定 `Select`"直接铺开的表单被替换为**一屏三区**：顶部预览 · 中部档位 tab + 模板条 · 底部参数抽屉入口。
3. **旧的表单（标题 + 7 文本字段 + 1 判定）**保留，只在**深度为 L3**时展开；L0/L1/L2 时通过参数抽屉切入较轻的文本编辑体验。
4. **不改路由**。仍然是 `HomePage → EditorPage → PreviewPage` 链路，路由常量 `EDITOR_PAGE / PREVIEW_PAGE`（`app/AppRouter.ets` L3/L4）不变。

## 2. 一屏三区骨架

移动端竖屏（375~430 dp 宽）稳定态：

```
┌─────────────────────────────────────────┐  ← PhotoWritingHero 简化保留
│  ⟨返回                          导出⋯ │      顶部条：返回 · 页标 · 更多菜单
│  相框                                  │      新增：页标改为"相框 · 复盘"
├─────────────────────────────────────────┤
│                                         │
│                                         │
│           [ 预  览  卡  片 ]           │  ← 区 A · 预览（占页面 55~62%）
│                                         │      · 按 FrameConfig + 图片实时渲染
│           (等比缩放 · 卡片居中)         │      · 双指捏合 = 图片位移与缩放
│                                         │      · 长按 = 隐藏边框，看原图
│                                         │      · 顶端小字："预览为屏幕缩略"
│                                         │
├─────────────────────────────────────────┤
│  ● 相框   ○ 参数   ○ 一句话   ○ 复盘   │  ← 区 B1 · 档位 tab
│  ─────────────────────────────         │      · 4 档 · TabBar 呈现
│  ┌───┐┌───┐┌───┐┌───┐┌───┐             │  ← 区 B2 · 模板横滑（可左右滚动）
│  │纯 ││极 ││日 ││日 ││…  │             │      · 当前档下的模板缩略图 chip
│  │白 ││简 ││期 ││常 ││   │             │      · 选中态 = 描边 + 主色
│  │等 ││画 ││底 ││片 ││   │             │
│  │宽 ││廊 ││   ││刻 ││   │             │
│  └───┘└───┘└───┘└───┘└───┘             │
├─────────────────────────────────────────┤
│  ✎ 一句话（可选）                       │  ← 区 C · 内容与参数抽屉入口
│  [ …这里放一段照片背后的话…         ]   │      · 若当前模板 useCaption=true 则展开
│                                         │      · 若为 L3 → 展开完整 8 字段表单
│  ⚙ 边框参数    📷 EXIF    💾 保存      │      · 底行是抽屉入口 chip
└─────────────────────────────────────────┘
       ↑ 上滑 = 弹出参数抽屉 sheet
```

区块高度分配（按 iPhone 竖屏 812 pt 视口做参考）：
- 顶部条：56 dp
- 区 A · 预览：~460 dp（55~62%）
- 区 B1 · 档位 tab：44 dp
- 区 B2 · 模板横滑：72 dp
- 区 C · 内容与抽屉入口：**自适应**（若模板不需要文本 = 折叠为 48 dp；若需要 = 拉伸至剩余空间）

高度分配用 `Percentage` 与 `.layoutWeight()`，不硬编码 dp；具体值以 `AppMetrics` 现有 token 为准。

## 3. 关键区块细则

### 3.1 区 A · 预览

- 使用 `ReviewCardRenderer` 组件，`renderMode = MOBILE_READING`（复用现有）。
- 内部按 `templateId` 分发到具体子组件（v2 引入的分发逻辑，见 `spec-20260716-frame-review-v2-data-model.md` §4.1 `resolveTemplate()` + `TEMPLATE_REGISTRY`）。
- 预览容器高度由 `viewportHeight × 0.58` 计算，`viewportWidth - 2×pagePadding` 决定宽度。
- 预览容器**不承担 Canvas 合成**——预览走 ArkUI 组件渲染路径，导出走 Canvas 路径。两者通过共用 `FrameConfig.*Ratio` 保持视觉一致。
- 顶端 hint 文字："预览为屏幕缩略，导出保留原图分辨率。" 字号使用 `AppTypography.caption`（现有 token，无 captionSmall）。

### 3.2 区 B1 · 档位 tab

四档 tab：

```
● 相框   ○ 参数   ○ 一句话   ○ 复盘
  L0      L1       L2         L3
```

- **`SegmentedTabBar` 是 PR 6 新建组件**（现有代码库无 `AppDesign.SegmentedTabBar`，也没有可复用的 tab 风格参考——`PhotoWritingHero` 是首页 hero 组件不是 tab）。命名 `TemplateLevelTabBar`，视觉参考 mvp-templates 缩略图总览 SVG 中 tab 部分。
- 切档动效：文字颜色 tokens 过渡 `MotionTokens.durationQuick`；下划线滑动 `MotionTokens.durationStandard`。
- 切档不改照片、不改内容字段值，通过 `applyTemplateToDocument(document, T.id)` 完成配置替换（见 §5.2 状态机），不直接改三项 config 字段。
- 切档后区 C 内容按新模板的 `contentBinding` 显隐字段（不删数据）。

### 3.3 区 B2 · 模板横滑

- `List` 或 `Scroll + Row`，`scrollable = Horizontal`。
- 每个模板 chip 尺寸 `56×72 dp`，含 12 dp 缩略缩图 + 8 dp 名称。
- 缩略图由静态 SVG/PNG 资产提供（不即时渲染，避免耗性能）。
- 选中态：外框 2 dp `AppColors.primary`，未选中：`AppColors.border` 1 dp（**真实 token**，见 `components/AppDesign.ets` L33；不是 `AppColors.divider` —— 该字段不存在）。
- 未选中 chip 点击：切模板；已选中 chip 点击：无动作。
- 横滑滚动使用 `EdgeEffect.Spring`（贴合现有列表风格）。
- 到达当前档最后一个模板再右滑：进入下一档（隐式跨档切换），伴随档位 tab 高亮动画。

### 3.4 区 C · 内容与参数抽屉

三种展开形态，取决于当前模板 `contentBinding`：

**形态 1 · L0 相框（`useTitle=false, useCaption=false, useExif=false, useReviewFields=false`）**

```
─────────────────────────────────────
[ ⚙ 边框参数 ]                          [ 💾 保存 ]
─────────────────────────────────────
```

只显示边框参数 + 保存两个 chip（此形态无 EXIF 入口，因为 L0 `useExif=false`）。总高 48 dp。

**形态 1.5 · L1 参数框（`useExif=true`, 其他 use* 均 false）**

```
─────────────────────────────────────
[ ⚙ 边框参数 ]  [ 📷 EXIF ]           [ 💾 保存 ]
─────────────────────────────────────
```

三个入口 chip（EXIF 入口在 L1 因 `useExif=true` 展开）。总高 48 dp。**判定入口**：本形态 `useJudgement=false` 故无判定 chip。

**形态 2 · L2 一句话（`useCaption=true` 或 `useTitle=true` 且 `useReviewFields=false`）**

```
─────────────────────────────────────
✎ 一句话（可选，单行 · 最多 30 汉字）
┌───────────────────────────────────┐
│                                   │
└───────────────────────────────────┘

[ ⚙ 边框参数 ]                          [ 💾 保存 ]
─────────────────────────────────────
```

单个 **TextInput**（不是 TextArea，与 mvp-templates §3.6 一致，单行 30 汉字上限，超长即禁止输入并轻震反馈）+ 抽屉入口。

**形态 3 · L3 复盘卡（`useReviewFields=true`）**

延续现有 `ReviewInputForm.ets` 的完整 8 字段布局：

```
─────────────────────────────────────
✎ 标题
┌───────────────────────────────────┐ ← title
└───────────────────────────────────┘

视觉落点
┌───────────────────────────────────┐ ← visualFocus
└───────────────────────────────────┘

落点原因
┌───────────────────────────────────┐ ← focusReason
└───────────────────────────────────┘

…（其余 6 字段同现有）…

[ ⚙ 边框参数 ]  [ ⚖ 判定 ]  [ 💾 保存 ]
─────────────────────────────────────
```

**L3 不显示 EXIF chip**（`adaptive_review_card.contentBinding.useExif = false`，与 mvp-templates §4.5 "不引入 EXIF 展示"一致；L3 的定位是复盘而非参数展示，EXIF 需求用户切到 L1 参数底栏即可）。

判定 chip 在 L3 才出现。其它形态判定隐藏（因为 `useJudgement=false`）。

### 3.5 参数抽屉（sheet）

三个入口：**边框参数 / EXIF / 判定**。每个入口点击后由 `BottomSheetContainer.ets` 呈现半屏 sheet。sheet 内部为纵向列表控件，用现有 `AppDesign` token。

**边框参数 sheet**：

- 外留白（Slider · `outerPaddingRatio ∈ [0.010, 0.100]` · 步进 0.002）
- 内留白（Slider · `innerPaddingRatio ∈ [0.000, 0.030]` · 步进 0.002 · **允许 0**，归一化保留不替换）
- 圆角（Slider · `cornerRadiusRatio ∈ [0.000, 0.030]` · 步进 0.002 · **允许 0**，归一化保留不替换）
- 背景色（`ColorSwatchRow`：现有代码库无此组件，由 PR 6 新建，选值来自 `TemplateDescriptor.allowedBackgroundColors`——**权威源是 descriptor 字段，不是全局 `BorderColorPreset` 枚举**。例如 L0 `white_equal.allowedBackgroundColors = ['#FFFFFF']`，参数抽屉在此模板下**整行灰置不可选**；L1/L3 允许 `['#FFFFFF','#F6F1E8','#F0F0F0']`；L2 允许 `['#F6F1E8','#FFFFFF']`。见 data-model §4.1 `TemplateDescriptor.allowedBackgroundColors` 字段定义、mvp-templates §1.6 / §8）
- 恢复默认（Button · 触发 `applyTemplateToDocument(document, document.config.templateId)` 拿回当前模板的 `defaults.frame`；**不要**调用 `normalizeFrameConfig(undefined)`，那会得到全局 fallback 而非当前模板默认值）

**EXIF sheet**：

- 顶部 chip："自动 / 手动 / 混合"（对应 `ExifSource`，`混合` 只显示不可选）
- 8 字段 TextInput：相机 / 镜头 / 焦距 / 光圈 / 快门 / ISO / 时间 / 地点
- 每个字段右侧有"↻ 重新读取"按钮：调用 `ExifReaderService.read(imageUri)`（**契约固定：只做一次全新 EXIF 读取，不接收 existingPayload，不承担合并**）。返回的新 payload 由 sheet 调用方按 data-model §4.3 "EXIF 合并状态表"处理（含初读/手改/单字段重读/读失败/空新值/全部重读六种场景与对应 source 状态迁移）。**不定义** `readField(uri, key)` 单字段方法，避免 SDK API 差异导致的多种取值路径
- 手动改过的字段自动加入 `manuallyOverridden` 列表
- 底部 chip："导出到 EXIF 一次不再自动读取"（受控 `source = MANUAL`）

**判定 sheet**（仅 L3）：

- 三选一：成立 / 不确定 / 不成立
- 选择即写入 `content.judgement`，无二次确认
- 关闭 sheet 触发预览重渲染

sheet 关闭手势：点遮罩关闭（`BottomSheetContainer` 现状仅支持此）。下滑关闭手势属 **PR 6 新增能力**，Codex 实施时在 `BottomSheetContainer` 上追加 pan gesture 监听即可，注意与其内部 List 竖向滚动的手势冲突（仅在 sheet 顶部 24 dp 拖拽区触发）。

## 4. 关键手势

以下手势在**区 A 预览**内生效，其它区不响应：

| 手势 | 效果 | 冲突处理 |
| --- | --- | --- |
| 双指捏合 | 图片在边框内位移与缩放（**仅临时预览**，不写入 `document`、不影响 Canvas 导出；MVP 阶段不做 transform 持久化） | 与 List 竖向滚动不冲突（区 A 单独） |
| 长按 500 ms+ | 隐藏边框与文字，只显示原图（带模糊→清晰过渡） | 松开 = 恢复；不写入 dirty |
| 上滑区 A 边界 | 弹出参数抽屉 | 与页面滚动分开，仅在预览容器底缘触发 |
| 下滑区 A 顶端 | 关闭当前抽屉 | 抽屉未打开时无动作 |

区 B2 模板横滑不响应竖向手势。区 C 内文本 TextArea 响应默认键盘手势。

## 5. 状态机

### 5.1 页面级状态

```
INIT ─┬─ EMPTY_PHOTO ────────────┐
      │                          │
      ├─ HAS_PHOTO ┬─ CLEAN ─────┼─ RENDER_PREVIEW
      │            │             │        │
      │            └─ DIRTY ─────┤        └─ SAVE_LOOP
      │                          │
      └─ EXPORT_ONLY（预留）    │
                                 ▼
                            LEAVE_PAGE
```

- `EMPTY_PHOTO`：`imageUri` 为空。UI 显示空态卡片 + "从相册选一张" 按钮。
- `HAS_PHOTO`：正常编辑态。
- `CLEAN / DIRTY`：`isDirty` 状态由用户任意字段/参数修改触发（沿用现有）。
- 页面离开检查：若 `DIRTY`，弹 `DialogService`。当前 EditorPage 是"继续编辑 / 放弃"二选（沿用现有）；PR 6 若需要"保存 / 放弃 / 取消"三选，作为**新增交互**在 `DialogService` 上加一个新变体，不算沿用。

### 5.2 模板与档位切换状态机

```
用户点档位 tab (Lx)
    │
    ├─ 若 Lx == 当前档位 → 无动作
    │
    └─ 若 Lx != 当前档位
         │
         ├─ 选定 Lx 档下的第一个模板 T（PR 6 定义每档默认模板）
         ├─ newDocument = applyTemplateToDocument(document, T.id)  [PR 4 utility]
         │  · 内部完成 config.templateId / templateLevel / frame 的原子替换
         ├─ EditorPage 用 newDocument 重置本地 @State
         ├─ isDirty                          ← true
         └─ 区 C 按 T.contentBinding 显隐

用户点某模板 chip T'
    │
    ├─ 若 T'.id == resolveTemplate(document.config.templateId).id → 无动作
    │   （**用 canonical id 比较**，不是 raw templateId；否则老 review_card 数据打开
    │    时会因 raw !== 'adaptive_review_card' 让 L3 chip 无选中态。此约束同样
    │    适用于当前模板 chip 高亮判断）
    │
    └─ 若 T'.id != canonical id
         │
         ├─ newDocument = applyTemplateToDocument(document, T'.id) [PR 4 utility]
         │  · frame 覆盖为 T'.defaults.frame（若用户此前微调过，Toast 一次
         │    提示"已切换模板，边框参数已重置"，见下方 5.2 末尾说明）
         ├─ EditorPage 用 newDocument 重置本地 @State
         ├─ isDirty                          ← true
         └─ 若跨档，档位 tab 高亮位置同步
```

**为什么切模板会覆盖 `frame` 微调**：MVP 简化决策。用户在参数抽屉里改的边框微调值属于"选定模板后的个性化"，切模板时视为"想要另一套默认"。**这条策略在 UI 上以 Toast 提示一次**：切模板时若 `frame` 已经被改过，Toast："已切换模板，边框参数已重置。"

**applyTemplateToDocument 调用约定**（对齐 schema-alignment §3.3 硬约束）：调用时传入的 `templateId` 参数**必须是用户点击 chip 的 raw id**（即模板 chip 上的 `template.id` 原字符串），**不得**先经过 `resolveTemplate` 转换为 canonical id 再传入。别名 raw id 只在渲染分发和 UI 选中态比较时通过 `resolveTemplate(...).id` 解析。

**UI 可见模板清单**（MVP · 4 项）：
- L0 `white_equal` 纯白画廊
- L1 `meta_bottom` 参数底栏
- L2 `signature_overlay` 手写签名
- L3 `adaptive_review_card` 摄影复盘卡

`review_card` 是 L3 的历史别名，**不在 UI 列表中显示**（避免用户看到两个"复盘卡"）。老 `review_card` 数据打开时通过 canonical id（`resolveTemplate('review_card').id === 'adaptive_review_card'`）在 L3 chip 上呈现选中态；用户点击 L3 chip = no-op（因为 canonical 已相同），持久化时**保留原 raw id `'review_card'` 不漂移**。若未来需要更严格的 UI 过滤，可以在 `listVisibleTemplates()` 工具函数里显式排除别名 raw id。

### 5.3 保存与导出

沿用现有：

- 保存 = `ReviewCardHistoryService.saveDocument(context, document)` + `ReviewFlowFeedback` Toast（返回 `Promise<Array<ReviewCardHistoryItem>>`，异步等待）
- 导出 = 跳转 `PreviewPage`，在 Preview 页触发 `ReviewCardExportService.exportOriginalResolution(context, document, reviewerName)`（三参 class 静态方法，reviewerName 由 PreviewPage 加载后传入，返回 `Promise<ReviewCardExportResult>`；唯一契约见 data-model §5.6）

## 6. 键盘避免与滚动策略

沿用现有 `EditorPage` 的键盘避免体系（`aboutToAppear` 关闭系统 avoid + 手动 scroll）。新增两点：

1. **模板横滑区 B2 不响应键盘**。键盘弹起时区 B1/B2 保持固定，只区 C 内文本滚动。
2. **参数抽屉与键盘互斥**。抽屉打开时若键盘弹起，抽屉自动上移；键盘收起后抽屉恢复。抽屉打开时不允许触发区 C 的 TextArea focus。

## 7. 入场动画

在现有 `introStage`（0 → 1 → 2 三阶，见 `EditorPage.playIntro()` L142~151）基础上**新增 stage 3**（属 PR 6 改造项），四阶节奏（时长走 `MotionTokens` 而非硬编码 ms）：

| 阶段 | 时长 token | 元素 |
| --- | --- | --- |
| 0 | 0 ms | 全空 |
| 1 | `MotionTokens.durationQuick`（≈150 ms） | 顶部条 + 区 A 淡入 |
| 2 | `MotionTokens.durationStandard`（≈250 ms） | 区 B1 tab + 区 B2 模板 chip stagger 入场（`StaggeredEnter`） |
| 3 | `MotionTokens.durationSlow`（≈400 ms） | 区 C 抽屉入口 chip 淡入 |

总时长约等于 `durationSlow`，具体毫秒以 `MotionTokens` 现有值为准。若 `MotionQualityContext.getQuality() === MotionQuality.MINIMAL`，全部改为一次 `durationQuick` 淡入。

## 8. Motion Quality 分档影响

- `FULL`：所有动效开启，模板切换有 3D 翻页转场，长按看原图有模糊→清晰过渡
- `CALM`：模板切换用淡入淡出，长按看原图去掉模糊过渡
- `MINIMAL`：模板切换无过渡（instant），长按看原图 instant

Codex 实施时统一走 `MotionQualityContext.resolveCurve(role)`（L41）/ `MotionQualityContext.resolveDuration(fullDuration)`（L31）（真实 API 名，见 `theme/MotionQualityContext.ets`），不硬编码时长。

## 9. 空态与错误态

**空态**（`EMPTY_PHOTO`）：

```
┌─────────────────────────────────────────┐
│  ⟨返回                          导出⋯ │
│  相框                                  │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│                                         │
│           ┌─────────────────┐           │
│           │      +          │           │
│           │  从相册选一张   │           │
│           └─────────────────┘           │
│                                         │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

不显示区 B / C。点击占位卡触发 `pickSinglePhoto()`（自由函数，从 `services/PhotoPickerService.ets` L174 具名 import，**不是** `PhotoPickerService.pickSinglePhoto()` 类静态方法）。

**错误态**：

- 图片加载失败：预览区中央显示"图片无法加载 · 换一张"，配 InlineStatusBanner。
- EXIF 读取失败：EXIF sheet 显示"无法读取 EXIF · 手动填写"，**不改 source、不改字段值**（保留 `document.exif` 现状）。此规则以 data-model §4.3 EXIF 合并状态表为权威（读失败场景），不再强制 `source = MANUAL`。
- Canvas 合成失败：Preview 页 Toast + 保留在 Preview 页，不返回 Editor。

## 10. 待人工确认清单

以下 5 项都是 **UI 细节裁量**，本方案**授权 Codex 按各自建议默认值处理**，不再进 README 决策总表；若 Codex 实施时觉得需要人工拍板，回来单独说明：

- **参数抽屉入口 chip 的图标资源**：现有 `AppDesign` 无 iconfont 系统（尚未确认存在 settings/camera/save 图标），MVP 走**Emoji 兜底**（⚙ 📷 ⚖ 💾），若 PR 6 期间设计侧交付真正的 iconfont 再替换。**不新绘图标**，减少方案成本。
- **长按看原图的手势冲突**：Editor 内长按仅触发"隐藏边框看原图"，与 Preview 页上下文菜单在不同页面无冲突；实施时 Codex 观察一次真机行为，若冲突再回来。
- **L3 表单里"标题"入口位置**：MVP 延续现有 EditorPage 顶部标题输入，不并入抽屉（减少变更面）。
- **空态占位卡片**：新建独立组件而非复用 `HomePage` 的 hero（hero 已有粒子/hero 图动效包袱），命名 `EditorEmptyPlaceholder`，简洁到位即可。
- **模板缩略图资产**：见 README 决策 11（不阻塞），未到位走纯色占位。

## 11. 代码锚点索引（Codex 实施时反复查）

- `entry/src/main/ets/pages/EditorPage.ets` L74~120 —— 现有 State 声明
- `entry/src/main/ets/pages/EditorPage.ets` 后半 —— build 布局与键盘避免
- `entry/src/main/ets/components/ReviewInputForm.ets` —— 现有 8 字段表单
- `entry/src/main/ets/components/AppDesign.ets` —— tab / chip / button 组件基础
- `entry/src/main/ets/components/motion/BottomSheetContainer.ets` —— 抽屉容器
- `entry/src/main/ets/components/motion/StaggeredEnter.ets` —— 入场分阶
- `entry/src/main/ets/theme/DesignTokens.ets` —— MotionTokens / ElevationTokens
- `entry/src/main/ets/theme/MotionQualityContext.ets` —— 动效降级
