# 方案：摄影相框 · 复盘卡（Frame + Review v2）· 总览

本文是一份**方案设计交接文档**，不是编码任务。这一轮的编码执行方将由用户择机交给 Codex，届时以本目录下的分文档为准。

在方案经用户与产品确认前，不修改业务代码、`review.json` 语义、`ReviewCardExchangeSchema.ets` 字段命名、数据库表结构、复盘包协议或签名文件。

## 1. 背景与本轮定位

skymap-mac 已经落地了一整套摄影模板系统（29 个模板，参见 `Sources/Skymap/Models/Enums.swift` L35~L66 `allCases`；其中 `reviewCard / adaptiveReviewCard` 两个复盘模板由 L144~L145 `isReviewTemplate` 判定），其中 `adaptive_review_card` 与鸿蒙端当前的复盘卡血脉一致，字段名与决策枚举在 `review.json` 层面已经对齐。

skymap-HarmonyOS 当前只承载了这条血脉里"深复盘"这一档，产品定义（见 `docs/product/CURRENT_PRODUCT_SPEC.md`）明确写着：

> 当前不是：完整摄影边框模板产品

本轮的目标是**为鸿蒙端引入一个可扩展的"相框 + 复盘"矩阵**，让同一张照片可以在**从零字段的纯相框、到 1~3 字段的浅记录、再到 7~9 字段的深复盘**之间无损切换。复盘卡不消失，成为该矩阵中"深度最深的那一档"。

本轮**不做**：

- 用户自定义模板（自定义留给未来）
- 双端同步、云端服务、账号系统
- AI 自动分析
- 修改 `review.json` v1 字段名或 `decision` 枚举
- 把 `PendingReviewPhoto` 并入 `Review` 主索引
- 把服务卡片路由和小艺意图接入线程并入

## 2. 分工与产出模式

- 方案、原型（ASCII/Mermaid/SVG）、规格文档：由 Claude 产出（本目录）
- 编码实现：交给 Codex
- 架构一致性 review 与根因诊断：留在 Claude 侧
- 产品拍板：由用户完成
- Bug 修复由 Claude 出方案，Codex 执行；不允许 Codex 独立"止血式"改代码

## 3. 本方案的分文档

| # | 文件 | 作用 |
| --- | --- | --- |
| 1 | `spec-20260716-frame-review-v2-data-model.md` | 核心数据结构（TemplateDescriptor / FrameConfig / ExifPayload / ReviewContent 演进）+ HarmonyOS API 索引 |
| 2 | `spec-20260716-frame-review-v2-schema-alignment.md` | 鸿蒙 vs Mac 字段对齐 diff · 现状盘点 · 未来演进红线 |
| 3 | `spec-20260716-frame-review-v2-editor-ux.md` | 编辑器一屏三区交互稿 · 手势 · 状态机 · 键盘避免继承 |
| 4 | `spec-20260716-frame-review-v2-mvp-templates.md` | MVP 四个模板（L0/L1/L2/L3）版式 · 字段绑定 · 相对尺寸公式 |

阅读顺序建议：**本总览 → 数据结构 → 字段对齐 → 交互稿 → 模板规格**。数据结构决定后续三份能不能落地，模板规格是 Codex 拿去实现的最终单据。

## 4. 已敲定的产品与技术判断

以下判断已经过用户拍板，方案实施阶段不再讨论；如果 Codex 在实现过程中遇到与它们冲突的场景，必须回来找 Claude 出决策，不得自行调整。

1. **命名保留悬置**。当前不改 App 定位命名。所有内部标识仍使用 `review_*` 前缀；只在 UI 文案层面允许出现"相框 / 摄影卡"等新叙事。
2. **跨端契约走分层对齐**。见 `spec-20260716-frame-review-v2-schema-alignment.md`。
   - Layer 1（内容层）：强对齐，走已经冻结的 Review JSON Schema v1，不新增中文命名分支。
   - Layer 2（模板层）：弱对齐，`templateId` 命名空间双端共用，视觉允许差异。
   - Layer 3（呈现层）：各自演化，边框留白、圆角、动效、手势不进 schema。
3. **不做用户自定义模板**。MVP/V1 只提供官方模板，本方案不设计任何模板编辑器路径。
4. **导出必须支持原图分辨率**。默认走「原图 PixelMap + 边框合成图层贴合」的合成路线，MVP 阶段就必须建成这条链路，见数据结构文档第 5 节。
5. **允许接入 Adobe/Google 开源字体**。首选思源黑体 CN + 思源宋体 CN，作为长期字体资产纳入项目（具体入口 `rawfile/` vs `resources/base/font/` 由用户在阻塞 A · 第 4 项拍板，见 data-model §8），包体成本约 6~10 MB 可接受。方正、汉仪等付费字库不进本方案。

## 5. Bug 与失败处理规范

Codex 在实现本方案时，遇到以下情况一律停止编码，把现象、日志、命中的规格锚点交还 Claude 出方案：

- 无法在不修改 `review.json` v1 字段命名的前提下承载新数据
- 无法在不破坏 `ReviewCardExportService` 现有导出通路的前提下加入原图合成
- 组件截图路径与 Canvas 合成路径需要二选一
- 模板扩展与现有 `ReviewCardRenderer.renderMode` 二分模式冲突
- `PendingReviewPhoto` 需要被写入 `Review` 主表才能达成方案
- 家庭存储、备份、Widget、小艺意图链路被本方案影响

对以下"看起来是 bug"的场景，方案侧已经明确不修：

- Layer 1 中缺失字段以空字符串输出——这是既有约束
- 模板缺失的字段在阅读页不显示——这是既有约束
- Mac 端旧字段 `judgementText` 在 Harmony 侧被忽略——这是既有约束

## 6. 代码锚点索引

方案执行时需要经常查阅的关键文件（本目录下每份分文档会重复引用其中的具体行号）：

**数据模型层**：
- `entry/src/main/ets/model/ReviewCardModel.ets`
- `entry/src/main/ets/model/ReviewCardLayout.ets`
- `entry/src/main/ets/model/PendingReviewPhotoModel.ets`
- `entry/src/main/ets/services/ReviewCardExchangeSchema.ets`

**渲染层**：
- `entry/src/main/ets/components/ReviewCardRenderer.ets`
- `entry/src/main/ets/components/MobileReadingReviewCard.ets`
- `entry/src/main/ets/components/LongFormExportReviewCard.ets`
- `entry/src/main/ets/components/ReviewCardStylePreset.ets`
- `entry/src/main/ets/components/ReviewCardStyleTokens.ets`

**编辑器与预览层**：
- `entry/src/main/ets/pages/EditorPage.ets`
- `entry/src/main/ets/pages/PreviewPage.ets`
- `entry/src/main/ets/components/ReviewInputForm.ets`
- `entry/src/main/ets/components/ReviewPhotoBlock.ets`

**导出与存储层**：
- `entry/src/main/ets/services/ReviewCardExportService.ets`
- `entry/src/main/ets/services/ReviewCardHistoryService.ets`
- `entry/src/main/ets/services/ReviewCardStore.ets`
- `entry/src/main/ets/services/ReviewCardRdbModel.ets`
- `entry/src/main/ets/services/ReviewBundleExportService.ets`

**产品与协议基线（不修改，只对齐）**：
- `docs/product/CURRENT_PRODUCT_SPEC.md`
- `docs/product/DATA_MODEL.md`
- `docs/product/REVIEW_JSON_SEMANTICS.md`
- `docs/product/REVIEW_BUNDLE_V1_V2_CONTRACT.md`
- `docs/review-card-template-spec.md`
- `docs/review-card-exchange-schema.md`

**跨端参考（skymap-mac）**：
- `Sources/Skymap/Models/Enums.swift` — 模板 ID 命名空间
- `Sources/Skymap/Models/ConfigTypes.swift` L2356~2593 — `ReviewCardTemplateConfig`
- `docs/review-card-template-spec.md` — Mac 侧规范草案

## 7. 时序节奏建议

方案落地并不是一次性推平，建议按下面顺序切分成可独立提交、可回退的阶段：

**阶段 A · 地基**（B 方向：L3 组件不动，v2 抽象只服务新模板）
- 数据结构演进（新增 `TemplateDescriptor` / `FrameConfig` / `ExifPayload`，不动 `review.json`）
- `ReviewCardRenderer` 从 `renderMode` 二分演进为 `templateId × renderMode` 分发；**L3 分发到现有 `MobileReadingReviewCard` / `LongFormExportReviewCard`，两个组件内部保持不动**（继续硬编码 fp 字号、"图上文下"单布局、现有字段标签），不消费 `config.frame`
- Canvas 合成管线打通（服务于 L0/L1/L2 新模板，也用于 L3 原图导出通路）
- L3 走 Canvas 导出作为**新能力**（原图分辨率），不与旧组件截图对比像素
- 思源黑体 CN（Bold + Regular）资产入口敲定 + 落地（PR 2 顺带把旧 `LongFormExportReviewCard` 里未设 `fontFamily` 的 `Text` 组件切到 `NotoSansSC-*`；具体资产目录 `rawfile/` vs `resources/base/font/` 由用户在阻塞 A · 第 4 项拍板）

**阶段 A 验收硬门槛**：
- **验收 1（PR 2）· L3 布局结构等价 + 字体变化已授权**：`MobileReadingReviewCard` / `LongFormExportReviewCard` 及其共享子组件（精确文件清单见 mvp §10 PR 2）内部**除 `fontFamily` 切到 `NotoSansSC-*` 外不改动**；`ReviewCardRenderer` 分发路径插入 `templateId` 判定。**验收不是"像素级零差异"**（字体切换会影响字形/度量/换行/抗锯齿，结构不变不能证明像素等价）；改为"布局结构与字段绑定等价，字体变化已授权"，配三方向（横/竖/方）阅读页与组件截图导出路径的**冒烟截图审查**（人工确认无版式错乱、无遮挡、无字段丢失即通过）
- **验收 2（PR 3）· L3 Canvas 导出图人工审查**：L3 走 Canvas 输出原图分辨率是**新增能力**（不与旧路径对比像素）。5 张典型样本（3 方向 × 2 分辨率覆盖：4032×3024 / 7008×4672）交用户/设计视觉确认可接受后成为**导出图回归基线**（fixture manifest 见 mvp §10 PR 3），后续 PR 修改 Canvas 通路时用该基线做 diff

**v2 抽象覆盖范围**：`FrameConfig` 权威渲染只对 **L0/L1/L2 新模板生效**；L3 消费 frame 是**方案外后续**（未来独立 PR 处理，届时会有一次授权视觉变化）

**阶段 B · 模板矩阵**
- L0 纯白画廊 + L1 参数底栏两个模板落地（含 EXIF 读取服务与 EXIF 抽屉）
- 编辑器一屏三区改造第一版
- Preview 页导出下拉菜单

**阶段 C · 深度扩展**
- L2 手写便签模板（含思源宋体资产 + `content.title` 复用）
- 复盘库聚合抽屉（按模板 / 相机 / 镜头 / 判定）
- 每周回顾仪式

**方案外后续**（不在本方案 PR 拆分之内，未来单独立项）
- 跨端 Layer 2 联调（如果开始做云同步）
- 用户自定义模板（远期）

阶段 A 是硬门槛（L3 等价落回是核心验收）。阶段 B/C 之间可以按业务优先级调整顺序。PR 级拆分见 `spec-20260716-frame-review-v2-mvp-templates.md` §10，与本节阶段边界严格对应（A = PR 1~3、B = PR 4~7、C = PR 8~10）。

## 8. 期望交付物

Codex 拿到本目录后，第一件事是把「阶段 A · 地基」按 `spec-20260716-frame-review-v2-data-model.md` 的规格拆成 **3 个 PR（PR 1~3）**，每个 PR 附独立回归清单。所有 PR 必须绿灯通过现有 `docs/harmony/UI_CLOSURE_RULES.md` 与 `docs/spec-for-codex/plan-motion-followups.md` 约束的动效审计。

Claude 会在每个阶段完成后做一次架构一致性 review，重点关注：命名是否漂移、边界处理是否遗漏、抽象层次是否错位、Motion Quality 分档是否被绕过。
