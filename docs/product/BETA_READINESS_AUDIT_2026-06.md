# Skymap Beta Readiness Audit 2026-06

日期：2026-06-13

结论：**NO**

当前基线不建议直接进入跨端 Beta。主要原因不是模板、导出或页面样式问题，而是跨端最关键的 `Harmony -> review.json -> Mac 导入 -> Review Library` 链路对真实用户仍然不够可执行。

## 1. 产品现状

当前产品已经形成两条相对清晰的主线：

- Mac：照片导入、模板排版、资料中心、预设、单张导出、批量导出。
- Harmony：手机端快速复盘、历史记录、阅读页、复盘长图导出、`review.json` 手动导出。

当前产品层也已明确收口：

- 已完成的是 `Review Library v1.1` 与 `Sync v0 手动文件交换`。
- 未完成的是 `SMB / WebDAV`、`review bundle`、`manifest`、自动扫描、家庭存储连接。

## 2. 已完成能力

- `review.json` v1 字段在双端保持同名输出，`decision` 也已稳定为 `works / uncertain / notWorks`。
- Mac 已有可见的 Review Library 入口、搜索、成立判断筛选、重复导入去重提示。
- Harmony 已有复盘库入口、标题/核心关系/卡点/文件名搜索，以及成立判断筛选。
- Harmony 阅读页已能导出 `review.json`，并在页面与 Toast 中提示导出路径。
- 双端 `docs/product/` 当前镜像一致，可通过同步校验脚本验证。

## 3. Product Audit Findings

- `REVIEW_STORAGE_STRATEGY.md` 当前不存在，但本轮审计要求中把它列为 Product Layer 必查项。这说明产品层文档目录和审计入口已经漂移，文档覆盖边界不清。
- `FEATURE_MATRIX.md` 与当前实现大体一致，但 `SyncSystem / SMB / WebDAV` 仍停留在“规划中”与“不可视为稳定支持”。如果外部 Beta 说明里仍使用“家庭存储接力”之类表述，用户很容易误解为已经可连接家庭存储。
- `SYNC_SYSTEM_V1.md` 是未来架构文档，不是当前基线实现说明。它保留在 `docs/product/` 是合理的，但缺少一个更强的“未来方案 / 未落地”提醒，容易被误读为现有功能说明。
- `WORKFLOW.md`、`VISION.md`、`ROADMAP.md` 当前对 Mac / Harmony 职责描述基本清楚：Harmony 负责快速记录，Mac 负责精修导出。职责冲突不严重。

## 4. Review Domain Findings

- `review.json` 主字段当前仍稳定，双端都围绕同一组字段工作，没有出现字段改名或额外协议分叉。
- Mac 本地 `ReviewArchive` / sidecar 仍是工程恢复结构，没有被直接当成跨端协议输出，这一点是健康的。
- `Review Library` 当前仍以索引和导入记录为主，没有扩成标签、收藏、批注或统计容器，职责边界仍然干净。
- 但 Mac 的 `ReviewCardImportPayload` 在缺失 `reviewTimeText` / `reviewerText` 时会自动填入当前时间和 `{name}`，与 `REVIEW_JSON_SEMANTICS.md` 中“缺失字段不编造新文案”的规则不完全一致。这是语义层漂移风险。见 [ReviewCardImportPayload.swift](/Users/wangbo/Documents/Codex/codexPro/skymap-mac/Sources/Skymap/Models/ReviewCardImportPayload.swift:84) 和 [ConfigTypes.swift](/Users/wangbo/Documents/Codex/codexPro/skymap-mac/Sources/Skymap/Models/ConfigTypes.swift:2449)。

## 5. Mac Audit Findings

- 已闭环：
  - 导入照片 -> 选择模板 -> 调整参数 -> 导出单张图片
  - 多图导入 -> 批量导出
  - 资料中心、模板预设、导出设置的基础入口
  - Review Library 查看、搜索、成立判断筛选、重复导入提示
- 存在断点：
  - 从 Review Library 直接“导入 review.json”并不是独立导入链路，它仍然要求当前必须先有一张被选中的照片，并且已经切到摄影复盘模板。见 [AppModel.swift](/Users/wangbo/Documents/Codex/codexPro/skymap-mac/Sources/Skymap/AppModel.swift:533)。
  - 但 Review Library 空状态和操作区又明确提供了“导入 review.json”按钮，容易让用户以为这是不依赖当前照片的全局导入。见 [ReviewLibrarySheet.swift](/Users/wangbo/Documents/Codex/codexPro/skymap-mac/Sources/Skymap/Views/ReviewLibrarySheet.swift:94) 与 [ReviewLibrarySheet.swift](/Users/wangbo/Documents/Codex/codexPro/skymap-mac/Sources/Skymap/Views/ReviewLibrarySheet.swift:123)。
- 虽然存在但难发现：
  - Review Library 入口是工具栏图标 `books.vertical`，没有文字标签。对熟悉图标的人问题不大，但首次 Beta 用户仍有一定发现成本。
  - “导入摄影复盘”入口只在当前已切到摄影复盘模板时出现，且前置条件没有在主界面讲清。
- Beta 用户会立即遇到的问题：
  - 如果用户还没导入照片，只是想把 Harmony 的 `review.json` 落进 Mac 复盘库，会先看到入口，再在导入时收到“请先导入并选中一张照片 / 请先切换到摄影复盘模板”的错误，任务心智会断掉。

## 6. Harmony Audit Findings

- 已闭环：
  - 选择照片 -> 填写复盘 -> 保存进入历史 -> 阅读页查看 -> 导出复盘长图
  - 阅读页导出 `review.json`
  - 复盘库搜索与成立判断筛选
- 导出可发现性：
  - “导出 review.json” 已出现在阅读页操作区，路径提示也比之前明确。
  - 但导出后的下一步仍然是用户自己处理文件，系统没有提供“分享 / 打开导出位置 / 发送到 Mac”的直接动作。
- 历史记录可靠性：
  - 本地历史基于 Preferences，可用，但当前硬上限只有 20 条。见 [ReviewCardHistoryService.ets](/Users/wangbo/Documents/Codex/codexPro/skymap-HarmonyOS/entry/src/main/ets/services/ReviewCardHistoryService.ets:12)。
  - 超过 20 条后的行为是静默截断旧记录，对 Beta 用户来说属于“能用，但不可靠说明不足”。
- 用户下一步指引：
  - 页面会告诉用户导出了 `review.json`，也说了“可传到 Mac 导入”。
  - 但导出目录是应用沙箱 `files/review_exchange/`，普通用户未必知道如何进入这个路径。见 [ReviewJsonExportService.ets](/Users/wangbo/Documents/Codex/codexPro/skymap-HarmonyOS/entry/src/main/ets/services/ReviewJsonExportService.ets:61) 与 [mobile-main-flow.md](/Users/wangbo/Documents/Codex/codexPro/skymap-HarmonyOS/docs/mobile-main-flow.md:116)。

## 7. Sync Audit Findings

- 链路理论上可验证，但对真实用户还不够可执行。
- 重复导入：
  - Mac 已按内容摘要去重，并明确提示“已存在，不重复添加”。
- 失败提示：
  - Mac 导入失败有明确 Alert，Harmony 导出失败有明确 Toast。
- 用户是否知道文件在哪里：
  - 技术上知道，因为路径会显示出来。
  - 真实使用上仍不够，因为显示的是应用沙箱路径，不是大多数摄影用户能够自然打开的位置。
- 用户是否知道如何导入：
  - 部分知道。文案已经说“可传到 Mac 导入”。
  - 但 Mac 的真实导入前置条件没有在产品层或 UI 中被清楚说明，导致“知道要导入”不等于“知道怎么成功导入”。

## 8. P0 问题

- **P0：Harmony 导出的 `review.json` 路径对普通用户不够可操作，Sync v0 在真实设备上的第一步就容易卡住。**
  - 当前只把文件写到应用沙箱 `files/review_exchange/`，并把绝对路径展示出来。
  - 对开发者这是清楚的；对 10 个摄影 Beta 用户，大概率不是。
  - 他们最可能问的是“文件在哪里，我怎么拿出来传给 Mac？”

- **P0：Mac 的 `review.json` 导入链路不是独立导入，而是隐藏依赖“先导入并选中一张照片 + 先切到摄影复盘模板”。**
  - 这和 Review Library 中看起来像“全局导入”的入口不一致。
  - 真实结果是：用户从 Harmony 拿到 `review.json` 后，来到 Mac 仍然可能被拦在错误提示里。

## 9. P1 问题

- **P1：Product Layer 文档覆盖不完整。**
  - `REVIEW_STORAGE_STRATEGY.md` 缺失，说明产品层目录和审计要求已经不完全对齐。

- **P1：Mac 导入语义对缺失字段存在“自动编造默认值”的风险。**
  - 缺失 `reviewTimeText` 会被替换成当前时间。
  - 缺失 `reviewerText` 会被替换成 `{name}`。
  - 这不符合“缺失字段不编造新文案”的产品规则。

- **P1：Harmony 历史记录上限只有 20 条，且没有显式产品提示。**
  - 对短期 Beta 不是立刻爆炸的问题，但会在重度测试用户中造成“旧记录怎么没了”的可信度伤害。

- **P1：Mac Review Library 入口与导入入口的发现成本仍偏高。**
  - 图标式入口、模板条件式入口、隐式前置条件，会提高首轮上手成本。

## 10. P2 问题

- **P2：`SYNC_SYSTEM_V1.md` 与当前基线混放，未来方案和当前可用能力之间的边界还可以再强化。**
- **P2：Harmony README 和部分非 Product Layer 文档仍保留旧命名或旧阶段描述，容易让内部协作理解偏移。**
- **P2：Review Library 目前仍是最低可用 UI，尚不支持更完整的浏览、排序和跨记录操作。**

## 11. Beta 建议

- 不建议现在直接把“跨端接力”作为 Beta 主卖点发给摄影用户。
- 如果今天就发 Beta，建议只强调：
  - Harmony 端快速复盘
  - Mac 端模板与导出
  - Review Library 的最低可用查看
- 不要强调：
  - 家庭存储
  - SMB / WebDAV
  - 自动同步
  - 无门槛跨端导入

## 12. 如果今天发给 10 个摄影用户试用，他们最可能卡在哪里？

优先级最高的卡点有两个：

1. **Harmony 用户导出完 `review.json` 后，不知道怎么把这个文件真正拿出来。**
   - 他们会看到一个路径，但这个路径是应用沙箱路径，不是普通摄影用户熟悉的“文件 App / 分享 / 发到电脑”路径。

2. **Mac 用户拿到 `review.json` 后，以为可以直接导入复盘库，结果被“请先导入并选中一张照片 / 请先切换到摄影复盘模板”挡住。**
   - 这会让用户怀疑自己是不是操作错了，也会让“复盘库导入”看起来像坏掉了，而不是一个完整产品链路。

这两个问题都发生在用户最早的跨端体验节点，所以它们比模板细节、UI 美观、历史命名或未来同步设计都更像 Beta 阻塞项。
