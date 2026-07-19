# skymap-HarmonyOS · 项目协作规则

## Frame + Review v2 方案

方案完整交付物在 `docs/spec-for-codex/frame-review-v2/`（README 是入口）。当前处于**编码执行阶段**（2026-07-17 用户拍板阶性收尾，进入 PR 1）。R8 编码期发现即修清单在最新交付话术里，Codex 遇到 spec 与代码事实不符时先查此清单。

## Claude ↔ Codex 自动协作规则

### 分工不变
- Claude：方案 / 规格 / 原型 / 架构一致性 review / 根因诊断
- Codex：编码 / 单测 / 静态检查
- 用户：关键决策拍板（分叉、验收）

### MCP 调用授权触发条件（Claude 可自动调，不等用户）
- 用户说"派活给 Codex"、"让 Codex 实施 PR N"、"让 Codex 修 R8-X 遗留"
- Claude 已完成方案 review 且用户拍板后
- Codex 停手回报的问题属于"R8 编码期清单已授权项" → Claude 直接生成修改指令回送

### Codex 停手回报规则（MCP 调用 arguments 必须包含此完整文本）

Codex 发现以下任一情况立即停手回报，不自主继续：

1. 锚点漂移超过 30 行
2. 规格内部矛盾（原则句被后文推翻）
3. 跨端断言未核实（"与 Mac 一致"类）
4. 规格引用不存在的字段 / API / 表列
5. 需要修改 review.json v1 字段命名或 decision 枚举
6. 遇到规格未覆盖的场景

**非编码阶段**（阅读方案）用批量模式：Codex 通读完一次性输出所有问题清单，不逐条停手。
**编码阶段**（写代码）恢复"发现即停"规则。

### Push 通知规则（关键决策点手机响铃）

以下情况 Claude 必须用 `PushNotification` 工具通知用户：
1. Codex 停手报"R8 清单外"的规格问题
2. Codex 完成一个 PR，请求用户 review
3. Codex 遇到架构判断的选择（例如 R6 A/B 方向类）
4. Codex 连续 3 轮修同一处仍未收敛
5. Canvas 性能 spike 结果出来后（阻塞 A 决策 1 的后续动作）

以下情况 Claude 静默继续，不打扰用户：
1. R8 清单内已授权问题 → 直接回送 Codex 修改指令
2. 小型代码风格问题 / 单测红了 → 直接指令修复
3. lint 类修复

### AskUserQuestion 使用纪律（用户偏好：不要频繁卡确认）

**默认自主推进**。仅在以下情况才用 AskUserQuestion 卡用户：
1. 不可逆破坏性动作（rm -rf / force push / drop table / 删除本地工作区未提交内容）
2. 真正的架构分叉（多条平等技术路径无法从 memory / spec / 调研报告推断唯一解）
3. 跟规格 / memory 明确冲突需要修改产品基线
4. Codex 连续 3 轮修同处不收敛

**不要问的场景**：
- Commit 范围 → 默认"代码文件独立 commit，文档/spec 修正另起一个 commit"
- 派活流程 / MCP 调用方式 → Claude 自己判断
- 已在 memory 或调研报告里拍过板的方向重复确认
- 明显只有一条路的技术方案
- "接下来做 X 好不好" → 按合理默认直接做，做完汇报

用户的原话："很多东西都没有必要让我去确认，不要卡这个流程"（2026-07-19）。宁可事后被用户 revert 一个小决策，也不要事前问 4 个低价值问题打断流程。

### 会话日志
每次 Codex MCP 调用 input/output 追加到：
`.ai/codex-session-YYYYMMDD.md`

作为审计日志，用户可选查看，不主动看不用清理。

### Bug 修复原则
Bug 出现时：Claude 出根因分析和修复方案 → Codex 执行。**禁止 Codex 独立止血**（不许直接加 try/catch/nullcheck 遮盖问题）。

## 阻塞 A 4 项决策（2026-07-17 已拍板）

1. **Canvas 性能 spike**：先跑 7008×4672 尺寸的 OffscreenCanvas + `context.getPixelMap` 内存/耗时验证，Codex 出结果后 Claude review
2. **老 RDB `raw_document_json` 中的 `config` 不重写**，走 fallback 分支
3. **阶段 A 完成后切分支冻结**作为回退基线
4. **思源黑体资产入口：`resources/rawfile/font/`** + `EntryAbility.onCreate` 用 `@ohos.font` API 注册（2026-07-18 真机构建修正：`resources/base/` 仅允许 `element / media / profile` 三个子目录，`font/` 会被 Resource Pack Error 11211104 拒收；改走 rawfile 官方原始文件目录 + 应用启动注册字体的标准通路）

## 语言与代码规范
- 默认使用简体中文回复
- 代码标识符 / API / 变量名保持英文
- 错误信息保留英文原文，附中文解释

## 参考基线文档（不修改，只对齐）
- `docs/product/CURRENT_PRODUCT_SPEC.md` — 当前产品能力冻结
- `docs/product/DATA_MODEL.md` — 数据模型冻结
- `docs/product/REVIEW_JSON_SEMANTICS.md` — review.json 契约冻结
- `docs/review-card-exchange-schema.md` — Review JSON Schema v1 唯一权威
- `docs/harmony/UI_CLOSURE_RULES.md` — 动效审计约束
