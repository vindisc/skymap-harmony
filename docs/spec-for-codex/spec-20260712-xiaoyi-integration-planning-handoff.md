# 交接：小艺接入与 HarmonyOS 7 关系梳理

## 任务性质

这是一份给 Cloud Code 的方案设计任务，不是直接编码任务。

请基于当前仓库和华为最新官方资料，给出可执行的小艺接入方案。在方案经用户确认前，不要修改业务代码、配置文件、签名文件或测试脚本。

## 用户目标

用户希望让当前 HarmonyOS 摄影复盘应用进入小艺生态，优先实现通过小艺直达应用已有能力，并厘清是否需要先升级到 HarmonyOS 7。

首批候选场景：

1. 用户说“开始摄影复盘”，应用直接打开最早一张待复盘照片。
2. 用户说“查看待复盘”，应用进入复盘库的待复盘筛选。
3. 后续可评估在“小艺建议”中展示“还有 N 张待复盘”的场景卡片。

## 已核实结论

### 1. 项目当前没有真正接入小艺

- `entry/src/main/module.json5` 中虽然存在 `skills`，但内容只是：
  - `entity.system.home`
  - `action.system.home`
- 这只是 UIAbility 的系统首页启动声明，从项目初始化提交起就存在，不等于 Intents Kit、小艺 Skill 或小艺智能体接入。
- 仓库中没有找到：
  - `insight_intent.json`
  - `@kit.IntentsKit` 调用
  - `InsightIntentExecutor` 实现
  - 小艺意图共享逻辑
  - 小艺接入或验收文档

### 2. 当前工程具备接入 Intents Kit 的技术基础

- 当前工程模型和 SDK 目标为 HarmonyOS 6.1.1 / API 24。
- 本机 6.1.1 SDK 已包含：
  - `@kit.IntentsKit`
  - `insightIntent.shareIntent()`
  - `InsightIntentExecutor`
  - `insight_intent.json` 的构建校验规则
- `entry/src/main/ets/services/FormLaunchIntentService.ets` 已实现外部 `Want` 参数到应用内部路由的转换。
- `entry/src/main/ets/pages/AppShellPage.ets` 已支持以下路由：
  - `home`
  - `library_pending`
  - `today_review_direct`
- `today_review_direct` 已经能够打开最早一张待复盘照片，因此小艺接入应复用现有路由和业务服务，不应另建第二套路由系统。

### 3. 基础小艺接入不要求先升级 HarmonyOS 7

- 对现有 App 暴露“开始复盘”“查看待复盘”等功能，推荐使用 Intents Kit。
- 华为官方样例使用 `@kit.IntentsKit` 共享意图，使用 `InsightIntentExecutor` 处理意图调用。
- 官方当前样例要求 HarmonyOS、DevEco Studio 和 SDK 5.0.5 Release 或更高版本；当前项目的 6.1.1 环境满足代码开发门槛。
- 因此，不需要为了接入基础小艺能力，先把整个项目升级到 HarmonyOS 7 / API 26。

### 4. 当前应用尚未完成 HarmonyOS 7 适配

- HarmonyOS 7 对应 API 26，目前官方面向开发者提供的是 Developer Beta1。
- 当前项目仍以 6.1.1 / API 24 为目标编译。
- 预计现有应用可以在更高版本系统上运行，但目前没有 HarmonyOS 7 真机安装和主流程回归证据，不能写成“已适配鸿蒙 7”。
- 若要调用 HarmonyOS 7 新增 API，需要单独升级 DevEco Studio、SDK、`compileSdkVersion` 和 `targetSdkVersion`，并建立 API 26 测试分支。

### 5. HarmonyOS 7 与小艺的关系

- Intents Kit：让小艺调用和分发现有 App 功能，属于当前最小可落地路径。
- 小艺智能体：面向多轮对话、内容生成、知识问答等 AI 场景，是独立且更重的产品能力。
- HarmonyOS 7 重点增强了 Agent、Skill、端 A2A，以及视觉和语言 AI 开放能力。
- 因此两者不是“先升级鸿蒙 7，才能接小艺”的关系，而是：
  - 基础服务直达现在即可用 Intents Kit 接入。
  - 若以后要做“摄影复盘教练”“总结近期常见问题”等对话式能力，再评估 HarmonyOS 7 的 Agent / Skill 路线。

## 官方约束

华为官方样例明确说明：意图共享和意图调用的真实测试目前不能完全由开发者独立完成，需要按照 Intents Kit 接入流程联系华为接口人，配合完成测试与验收。

因此方案必须把以下内容视为外部前置条件，而不能只给代码改造清单：

1. 摄影复盘应归属哪个已开放垂域。
2. `开始摄影复盘`、`查看待复盘` 是否允许注册为对应意图。
3. 当前开发者账号是否满足申请和验收要求。
4. 可使用哪些小艺入口：小艺对话、小艺搜索、小艺建议。
5. 测试机、系统版本、华为账号和小艺建议协议要求。

## 推荐的 MVP 边界

方案应优先围绕两个前台意图设计：

### 意图一：开始摄影复盘

- 建议行为：复用 `today_review_direct`。
- 有待复盘照片：打开最早一张待复盘照片的编辑页。
- 没有待复盘照片：回到首页或待复盘空状态，给出明确反馈。
- 不允许在意图执行器中复制待复盘查询和草稿创建逻辑。

### 意图二：查看待复盘

- 建议行为：复用 `library_pending`。
- 打开应用后定位到复盘库，并应用待复盘筛选。

### 可选第二阶段：小艺建议

- 在导入待复盘照片、完成复盘或待复盘数量变化后，评估调用 `insightIntent.shareIntent()`。
- 共享内容只允许包含完成推荐所需的最小数据，例如待复盘数量、受控业务标识和路由参数。
- 不得共享照片文件、照片路径、复盘正文、用户输入标题或家庭存储凭据。
- 必须设计数据撤回、删除或数量清零后的意图删除策略。

## 请 Cloud Code 输出的方案

请先重新阅读仓库真实代码，并给出一份方案文档。方案至少包含：

1. **路线选择**
   - Intents Kit、App Linking、小艺智能体三者的职责对比。
   - 明确推荐哪条路线作为第一版，以及不选择其他路线的原因。
2. **版本策略**
   - 继续使用 API 24 接入 Intents Kit是否可行。
   - 是否需要单独建立 HarmonyOS 7 / API 26 适配分支。
   - 不同系统版本的降级行为。
3. **文件级改造清单**
   - `insight_intent.json` 的建议结构。
   - 意图执行器的目录、类名和职责。
   - `EntryAbility`、`FormLaunchIntentService`、`AppShellPage` 是否需要调整。
   - 是否需要新增意图共享服务，以及它的调用时机。
4. **调用时序**
   - 冷启动调用。
   - 热启动调用。
   - 无待复盘数据。
   - 意图参数非法或未知意图。
5. **数据与隐私边界**
   - 共享到小艺的字段白名单。
   - 不允许共享的数据。
   - 删除、过期与撤回策略。
6. **平台接入与验收清单**
   - 需要向华为确认的问题。
   - 需要准备的申请信息、测试环境和验收材料。
   - 哪些环节无法仅靠本地代码验证。
7. **测试与验收方案**
   - 可在本地自动完成的构建和静态校验。
   - 需要真机验证的行为。
   - 需要华为接口人配合的验收项。
8. **实施拆分**
   - 建议拆成 2 至 4 个可独立提交、可回退的阶段。
   - 每个阶段列出目标、文件范围、验收标准和风险。

## 方案必须回答的问题

1. Intents Kit 的意图名称和 `domain` 应如何确定，哪些内容必须等华为确认后才能定稿？
2. 当前已有的 `FormLaunchIntentService` 是否可以作为小艺与服务卡片共用的路由入口？
3. `InsightIntentExecutor` 应直接发路由事件，还是转换为受控 `Want` 参数后交给现有服务？
4. 如何避免冷启动时意图先到、页面订阅尚未建立导致路由丢失？
5. `shareIntent()` 应在哪些业务事件后触发，如何限频和失败降级？
6. API 24 构建的小艺接入在 HarmonyOS 7 上如何验证，是否需要 API 26 构建作为单独交付物？
7. 当前产品是否有必要做小艺智能体，还是应停留在 Intents Kit 服务直达？

## 不要做的事

- 不要在本轮直接修改代码。
- 不要把 `module.json5` 中现有的系统 `skills` 描述成已接入小艺。
- 不要假设自定义意图一定能通过华为平台验收。
- 不要把“预计能在 HarmonyOS 7 上运行”写成“已完成 HarmonyOS 7 适配”。
- 不要同时推进 API 26 升级、小艺智能体和 Intents Kit 三条实现线。
- 不要修改或提交 `build-profile.json5`，其中可能包含本机签名配置。
- 不要把照片、复盘正文、文件路径或家庭存储凭据共享给小艺。
- 不要重写当前服务卡片路由和待复盘业务链路。

## 当前代码锚点

- `entry/src/main/module.json5`
- `entry/src/main/ets/entryability/EntryAbility.ets`
- `entry/src/main/ets/services/FormLaunchIntentService.ets`
- `entry/src/main/ets/services/LearningProgressFormService.ets`
- `entry/src/main/ets/pages/AppShellPage.ets`
- `entry/src/main/ets/widget/pages/TodayReviewCard.ets`
- `entry/src/main/ets/widget/pages/LearningProgressSummaryMediumCard.ets`
- `entry/src/main/resources/base/profile/form_config.json`

## 官方参考

- HarmonyOS 7 / API 26 Developer Beta1：
  - https://developer.huawei.com/consumer/cn/activity/developerbeta/harmonyos-developer-beta-7-1
- HarmonyOS AI 开放能力总览：
  - https://developer.huawei.com/consumer/cn/harmonyos-ai
- Intents Kit 官方介绍：
  - https://developer.huawei.com/consumer/cn/sdk/intents-kit/
- Intents Kit 官方样例：
  - https://gitee.com/harmonyos_samples/IntentsKitGameRevisit/blob/master/README.en.md
- 官方样例意图配置：
  - https://gitee.com/harmonyos_samples/IntentsKitGameRevisit/blob/master/entry/src/main/resources/base/profile/insight_intent.json
- 官方样例意图执行器：
  - https://gitee.com/harmonyos_samples/IntentsKitGameRevisit/blob/master/entry/src/main/ets/insightintents/IntentExecutorImpl.ets

## 期望交付物

请输出一份新的方案文档，不要覆盖本文件。建议文件名：

`docs/spec-for-codex/plan-xiaoyi-intents-integration.md`

方案应让下一轮开发 Agent 可以在不重新做产品选型的前提下，按阶段直接实现和验证。
