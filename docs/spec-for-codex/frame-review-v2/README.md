# Frame + Review v2 · 方案文档索引

本目录是「摄影相框 · 复盘卡 v2」的完整方案交付。产物由 Claude 出，后续编码由 Codex 落地。任何单独文档都不足以理解全貌，Codex 实施前必须**按下方顺序全读一遍**。

## 交付物清单

| # | 文件 | 作用 | 建议阅读时长 |
| --- | --- | --- | --- |
| 0 | `spec-20260716-frame-review-v2-overview.md` | 总览：定位、分工、分阶段、边界、锚点 | 6 min |
| 1 | `spec-20260716-frame-review-v2-data-model.md` | 核心数据结构：TemplateDescriptor / FrameConfig / ExifPayload + Canvas 合成通路 + HarmonyOS API 索引 | 18 min |
| 2 | `spec-20260716-frame-review-v2-schema-alignment.md` | 跨端字段对齐：已对齐 / v2 新增 / 红线 / 允许项 | 8 min |
| 3 | `spec-20260716-frame-review-v2-editor-ux.md` | 编辑器一屏三区交互稿 + 状态机 + 手势 + Motion 分档 | 12 min |
| 4 | `spec-20260716-frame-review-v2-mvp-templates.md` | 四个 MVP 模板完整规格（版式 / 数据绑定 / 相对尺寸 / Canvas 步骤） | 20 min |
| — | `assets/editor-one-screen.svg` | 编辑器一屏三区视觉附件（对应文档 3） | 2 min |
| — | `assets/mvp-templates-overview.svg` | 四模板缩略图总览（对应文档 4） | 2 min |

## 阅读顺序

**用户拍板前**：0 → 4 → 3。总览定方向，模板规格看落地质感，交互稿看用户旅程。

**Codex 实施前**：0 → 1 → 2 → 3 → 4。全流程一遍，然后按第 4 篇末尾的阶段拆分开始 PR。

**架构一致性 review**：以 1 和 2 为准，检查代码是否触碰红线。

## 关键决策清单（按阻塞阶段分组）

**阻塞阶段 A**（PR 1~3 启动前必须由用户回答）

1. **Canvas 合成性能 / 内存 spike**（data-model §8 阻塞 A · 第 1 项）：目标 SDK 6.1.1(24) `OffscreenCanvas` + `context.getPixelMap` API 通路已确认可用，待验证的是原图 7008×4672 尺寸下的内存 / 耗时是否可接受，需一次真机 spike。
2. **老 RDB `raw_document_json` 中的 `config` 是否升级重写**（data-model §8 阻塞 A · 第 2 项）：默认不重写，读取走 fallback 分支。
3. **阶段 A 完成后是否切分支冻结**（data-model §8 阻塞 A · 第 3 项）：建议切，作为回退基线。
4. **思源黑体 CN 资产入口**（data-model §8 阻塞 A · 第 4 项）：`rawfile/` vs `resources/base/font/`。**影响 PR 2 与 PR 3**：PR 2 顺带切 L3 组件族（精确文件清单见 mvp §10 PR 2，13 个文件）的字体到 `NotoSansSC-*`；PR 3 L3 Canvas 通路首次输出用最终字体交人工审查建立回归基线 —— 两者都要字体资产先入库。若无法在 A 阶段引入，则 PR 2/3 用系统字体，未来正式换字体时需重新人工审查并**更新导出图回归基线**（不再是"重跑 diff"，因为首次验收是人工审查而非 pixel diff）。

**阻塞阶段 B**（PR 4~7 启动前必须由用户回答）

5. **EXIF PropertyKey 真机取值兼容测试**（data-model §8 阻塞 B · 第 5 项）：API 已声明，待验证不同品牌相机取值格式（`f/2.8` vs `2.8`、`1/500` vs `0.002`）。影响 PR 5 EXIF 服务的归一化映射表。
6. **品牌前缀清洗表补齐**（mvp-templates §11 · 问题 1）：Sony / Canon / Nikon / Fujifilm / Ricoh / Panasonic 已列，是否要补 Leica / DJI / Apple / Xiaomi？影响 PR 5 §2.5 `cleanCameraModel()`。

**阻塞阶段 C**（PR 8~10 启动前必须由用户回答）

7. **L2 `caption` 是否复用 `content.title`**（mvp-templates §11 · 问题 3）：默认复用，避免新增字段。影响 PR 8。
8. **思源宋体 CN 资产入口**（data-model §8 阻塞 C · 第 6 项）：与思源黑体同目录还是独立目录。影响 PR 8。
9. **思源宋体是否可代替真手写体**（mvp-templates §11 · 问题 2）：MVP 建议接受；若不接受需另采购手写字库。影响 PR 8 是否追加字体采购流程。
10. **`reviews` 表新增冗余列走 migration 还是懒创建**（data-model §8 阻塞 C · 第 7 项）：影响 PR 9。

**不阻塞（影响长期演进，可延后）**

11. **模板缩略图交付**（mvp-templates §5）：设计侧交付时间；未到位走纯色占位。
12. **参数抽屉背景色是否开放自定义 HEX**（mvp-templates §11 · 问题 5）：MVP 建议不开，仅允许 `TemplateDescriptor` 白名单枚举（见 mvp §8）。
13. **Harmony / Mac 复盘字段命名映射表沉淀**（schema-alignment §8）：是否把当前 `ReviewCardExchangeSchema.ets` 里已在做的映射抽出成独立 spec，方便未来跨端同步 converter 复用。
14. **命名调整**（overview §4）：App 定位命名何时开始讨论。

## 本方案生效期

本目录下文档以 **2026-07-16** 为基线。若 Codex 在实施过程中发现锚点行号漂移超过 30 行、或引用的现有文件被删除/重命名，回来找 Claude 重新出对齐版本。

不建议在方案未启动前就修改本目录下的任何文件；决策与讨论走独立 issue / 会议纪要。

## 分工回执

- 方案 / 原型 / 规格：Claude · 见本目录
- 编码 / 单测 / 静态检查：Codex
- 架构一致性 review：Claude · 每 PR 一次
- 根因诊断：Claude · Codex 遇到本方案覆盖不到的场景一律停手交回
- Bug 修复：Claude 出方案，Codex 执行；禁止 Codex 独立止血
- 产品拍板：用户
