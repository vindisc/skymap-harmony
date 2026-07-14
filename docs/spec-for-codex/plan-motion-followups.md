# 交互动效后续排查与实现清单

> 面向：下一轮实现 Agent（Codex）
> 版本：v1（2026-07-14 起草）
> 起源：`docs/spec-for-codex/plan-motion-narrative-upgrade.md` 落地至 `885c357` 后的 code review 结论

按"可直接派单"的粒度整理。分三档：**P0 排查**、**P1 补齐欠账**、**P2 卫生与决策**。
每条给出：类别 · 动作 · 完成判定 · 文件锚点 · 背景。

## Codex 执行记录（2026-07-14）

| 条目 | 状态 | 结论 |
| --- | --- | --- |
| P0-1 导出菜单 | 待真机 | HDC 首次枚举设备为 `Offline`，重启 HDC 后为 `[Empty]`；Builder 闭包守卫、ArkTS 编译和预览自动化源码契约通过，未声称真机通过。 |
| P0-2 仪式压力 | 待真机 | 补齐保存锁、页面消失释放、可见宿主消费和同次保存去重；仍需真机执行连点/返回/切后台压力。 |
| P0-3 动效档位 | 待真机 | 三档静态门禁和编译通过；真实观感、立即生效和冷启动耗时仍需真机确认。 |
| P1-4 列表 Stagger | 部分完成 | `ProjectDetailPage` 的待复盘与已完成列表均接入，分页新增项沿用稳定 key 入场。当前 `HomePage` 没有任务描述中的业务列表，且产品规范明确首页不承载完整历史列表，因此未恢复已下线结构。 |
| P1-5 主要 CTA | 已完成 | 首页双入口、编辑保存、预览三个导出菜单项及取消项接入 `PressReactive(firm)`，对应节点关闭原有缩放以避免双重反馈。 |
| P1-6 列表 Ripple | 已完成 | 复盘库两类列表卡片与“我的”设置行接入 `RippleTouch`。 |
| P1-7 首页 CountUp | 不适用 | 当前首页没有学习进度卡片；学习进度位于 `StatsPage` 且已使用 `CountUpText`。本轮不改变首页信息架构。 |
| P1-8 三个仪式点 | 代码完成 | 待复盘归零、连续天数新纪录、首次 SMB 连通均完成业务判定、持久标志、页面订阅与防重复门禁；真机播放待验。 |
| P1-9 Tab 重入场 | 已完成 | 首页在 `onPageShow` 重放分层入场；复盘库列表随 Tab 条件重建由 `StaggeredEnter.aboutToAppear` 重放。 |
| P2-10 SharedHero | 已完成（A） | 删除无调用组件和对应 shape/lifecycle 断言，保留编辑页内联 `geometryTransition`。 |
| P2-11 Builder 闭包 | 已完成（B） | Preview 调用点补充绑定说明，复杂内容统一由闭包调用当前页面的 `@Builder` 方法。 |
| P2-12 删除确认 | 维持现状 | 当前主干提交 `acdd83c` 明确为“简化删除交互”，继续直接删除，不恢复二次确认。 |
| P2-13 星河开关关系 | 已完成 | 明确保持独立：`MotionQualityContext.shouldPlayShatter` 只遵循用户的“删除星河效果”开关。 |
| P2-14 启动超时 | 未触发 | 本轮没有真机冷启动耗时证据，不加入推测性的 100ms 超时。 |

本地验证：`bash scripts/test_app.sh --all` 通过 61/61 校验，主模块与
`entry@ohosTest` 均完成 ArkTS 编译和 HAP 打包。真机项需设备恢复 `Connected` 后执行。

---

## P0 · 必须排查（潜在 crash / 数据风险）

### 1. Preview 导出菜单闭包传法真机验证

- **类别**：排查
- **动作**：在 HarmonyOS 真机上进入 PreviewPage → 点击"导出" → 观察
  `BottomSheetContainer` 是否渲染出「导出当前复盘 / 保存到相册 / 写入家庭
  存储 / 整理原图 / 取消」等菜单项。压测：
  - 快速连点导出按钮 3~5 次
  - 菜单半开时点导出按钮再点关闭
  - 开着菜单切前后台
- **完成判定**：菜单项每次都完整可见、点击每一项都能触发对应流程、无
  `JsError`、无残留 scrim。
- **锚点**：
  - `entry/src/main/ets/pages/PreviewPage.ets` 里
    `content: () => { this.ExportMenuContent(); }`
  - `entry/src/main/ets/components/motion/BottomSheetContainer.ets`
- **背景**：把 `@Builder` 方法用普通箭头闭包包一层再调用是"经验-未文档"的
  用法，SDK 层是否稳仍需实机确认。Codex 已测过"进程存活"，但没具体测
  菜单渲染。

### 2. CeremonyBurst 快速连点与切页压力

- **类别**：排查
- **动作**：真机路径：
  - A：EditorPage 保存进入仪式的 780ms 内快速再点保存按钮 3~5 次
  - B：仪式播放中按系统返回键退出 EditorPage
  - C：仪式播放中触发页面被系统 kill（切 5 个别的 App 触发内存回收）

  每种路径重复 3 次以上。
- **完成判定**：
  - 无 `JsError` 或 `Cannot read property` 类崩溃
  - `MotionQualityContext.ceremonyOccupied` 全局标志最终会释放（下次触发
    仪式仍能起）—— 可以用日志或临时打印验证
  - 不出现 `openPreview` 被调多次或替换到错误路由
- **锚点**：
  - `entry/src/main/ets/components/motion/CeremonyBurst.ets`
  - `entry/src/main/ets/pages/EditorPage.ets` 的 `handleSave` / `onFinish`
  - `entry/src/main/ets/theme/MotionQualityContext.ets` 的
    `tryAcquireCeremonySlot / releaseCeremonySlot`
- **背景**：`ceremonyOccupied` 是静态全局 slot，页面被 kill 时
  `aboutToDisappear` 会释放，但仍需在真机上确认这条路径没死角。

### 3. `MotionQuality` CALM / MINIMAL 档位真机验证

- **类别**：排查
- **动作**：MyPage → 动效强度依次切到 CALM 和 MINIMAL。每个档位：进入
  HomePage / EditorPage / PreviewPage / ProjectDetailPage 主链路一次，
  观察时长/曲线的降级是否符合
  `MotionQualityContext.resolveDuration / resolveCurve` 的定义。
- **完成判定**：
  - CALM 下：里程碑仪式不播、Stagger 保留但曲线换成 EMPHASIZED、时长上限
    250ms
  - MINIMAL 下：Stagger 归零、时长上限 150ms、CountUpText 直接 snap
  - 切档后立即生效，无需重启
- **锚点**：
  - `entry/src/main/ets/theme/MotionQualityContext.ets`
  - `entry/src/main/ets/pages/MotionSettingsPage.ets`
- **背景**：迄今为止所有真机验收都在 FULL 档，其余两档只跑过静态分析。

---

## P1 · 补齐方案欠账（观感提升尚未兑现）

### 4. HomePage / ProjectDetailPage 列表接入 `StaggeredEnter`

- **类别**：实现
- **动作**：把 HomePage 的待复盘/待导入卡片 `ForEach`、ProjectDetailPage
  的复盘列表 `ForEach` 用 `StaggeredEnter` 包裹，
  `batchSize=1 / delayMs=durationStagger`。
- **完成判定**：列表首次加载时能看到卡片依次入场；滚动加载分页时新加入
  卡片同样入场；`scripts/verify_motion_narrative_hooks.mjs` 加一行断言
  "HomePage/ProjectDetailPage 引用了 StaggeredEnter"防回归。
- **锚点**：
  - `entry/src/main/ets/pages/HomePage.ets`
  - `entry/src/main/ets/pages/ProjectDetailPage.ets`
  - `entry/src/main/ets/components/motion/StaggeredEnter.ets`
- **背景**：方案 5.2.1、5.7.2 承诺过；组件已抽好，缺"最后一公里"接入。
  列表 stagger 是激进档观感损失最大的一块。

### 5. `PressReactive` 接入主要 CTA

- **类别**：实现
- **动作**：把 HomePage 的「开始复盘」/「导入待复盘」两个主按钮、
  EditorPage 的「保存」按钮、Preview 的每个导出菜单项包一层
  `PressReactive({ intensity: 'firm' })`，替换现有
  `.scale({...}).animation({ duration: durationInstant })` 手写反馈。
- **完成判定**：真机上按压有 spring 回弹感；
  `scripts/verify_motion_narrative_hooks.mjs` 断言这几个按钮所在文件引用
  了 `PressReactive`。
- **锚点**：
  - `entry/src/main/ets/components/motion/PressReactive.ets`
  - 上述页面
- **背景**：`PressReactive` 组件抽了但零业务使用，是死代码。方案 4.1 要求
  "用于替换现有 scale 反馈"。

### 6. `RippleTouch` 接入列表点击

- **类别**：实现
- **动作**：ProjectDetailPage 的复盘列表项、MyPage 的 `SettingsLinkRow`
  用 `RippleTouch` 包裹。
- **完成判定**：真机上点击列表项能看到水波纹展开；
  `verify_motion_narrative_hooks.mjs` 断言引用。
- **锚点**：
  - `entry/src/main/ets/components/motion/RippleTouch.ets`
  - `entry/src/main/ets/pages/ProjectDetailPage.ets`
  - `entry/src/main/ets/pages/MyPage.ets`

### 7. HomePage 学习进度卡片挂 `CountUpText`

- **类别**：实现
- **动作**：HomePage 底部的"待复盘 / 已完成 / 完成率"数字改成
  `CountUpText`，`durationMs = durationStandard`。
- **完成判定**：待复盘数变化时（导入照片、完成复盘）数字有 tween + 终点
  微冲顶；`verify_motion_narrative_hooks.mjs` 断言 HomePage 引用
  `CountUpText`。
- **锚点**：`entry/src/main/ets/pages/HomePage.ets`（学习进度卡片相关
  Builder）
- **背景**：方案 5.2.3；目前只在 StatsPage 挂了两处。

### 8. CeremonyBurst 剩下 3 个触发点

- **类别**：实现
- **动作**：
  - `待复盘归零`：`LearningProgressService` 里 pendingCount 由 >0 变 0
    时（且此次变化由完成复盘触发，不是被清空数据触发）—— 事件源可以在
    `ReviewCardStore` 或 `LearningProgressFormService.refreshAllForms`
    内部埋点，HomePage 订阅事件后播
    `CeremonyBurst({ kind: 'review-done' })`。**注意与 EditorPage 已有的
    review-done 仪式去重**（同一次完成不能双播）。
  - `streak-record`：连续复盘天数破个人纪录。事件源在
    `LearningProgressService`；StatsPage 订阅后播
    `CeremonyBurst({ kind: 'streak-record' })`。需要 `ReviewSettingsService`
    存"历史最大连续天数"以判定破纪录。
  - `smb-first-connect`：`Smb2Client` 首次校验通过。事件源在
    `HomeStorageService`；HomeStoragePage 订阅后播
    `CeremonyBurst({ kind: 'smb-first-connect' })`。判定"首次"需要一个
    持久标志（存 Preferences）。
- **完成判定**：三个触发点各自有一个 verify 脚本断言（例如
  `verify_motion_ceremony_hooks.mjs`）；真机分别触发一次，确认播放正确、
  不重复、不与其它仪式抢 slot。
- **锚点**：
  - `entry/src/main/ets/services/LearningProgressService.ets`
  - `entry/src/main/ets/services/Smb2Client.ets`
  - `entry/src/main/ets/services/HomeStorageService.ets`
  - 三个宿主页面

### 9. Tab 切换时新 Tab 内容分层入场

- **类别**：实现（小）
- **动作**：AppShellPage 目前只做了 Tab 图标弹跳 + 内容 opacity / translate
  / scale 联动，但**新 Tab 内的 Section 分批入场未做**。让 HomePage /
  ProjectDetailPage 各自的首屏入场逻辑，在 Tab 切换重新触发时也重放
  （当前依赖 `aboutToAppear`，AppShellPage 用 `if/else if` 分派应能触发，
  但真机需确认）。
- **完成判定**：真机上切 Tab 回到 Home 能看到入场重放；否则要在
  `onPageShow` 里补 `playIntro`。
- **锚点**：
  - `entry/src/main/ets/pages/HomePage.ets` `onPageShow`
  - `entry/src/main/ets/pages/ProjectDetailPage.ets`

---

## P2 · 卫生与决策类

### 10. `SharedHero` 死代码去留（决策 + 实现）

- **问题**：EditorPage 已内联 `geometryTransition` 绕开 `@BuilderParam`
  闪退根因，`SharedHero.ets` 全仓库无调用者。
- **两种处理**：
  - **(A)** 删除 `SharedHero.ets` + 移除
    `verify_motion_lifecycle_guards.mjs` 里对它的断言，避免下次有人再踩
    BuilderParam 坑。
  - **(B)** 保留但补一行注释说明「仅在不通过 BuilderParam 传子内容时使用；
    跨组件传 `@Builder` 方法请内联」，同时给
    `verify_motion_components_shape.mjs` 加"如果 SharedHero 被 import，
    import 者不能通过 BuilderParam 传 struct 的 `@Builder` 方法"的正则
    守卫。
- **推荐**：先选 A，简单直接。

### 11. `content: () => { this.method() }` 抽 helper 或补注释（决策 + 实现）

- **问题**：Preview 里这种"闭包包 @Builder 方法"是不常规用法，将来别的
  页面模仿时容易变形（比如漏掉 `this` 或返回值）。
- **动作**：
  - **方案 A**：把这种传法抽成 `wrapBuilder(this.ExportMenuContent)` 之类
    的 helper 并放到 `entry/src/main/ets/components/motion/`。
  - **方案 B**：在 PreviewPage 那一行上方补 3~5 行注释说明「不要改回
    `content: this.method`，会触发
    `Cannot read property bind of undefined`」。
- **推荐**：注释即可，helper 抽象过度。

### 12. `ProjectDetailPage` 删除去掉二次确认（决策）

- **问题**：`acdd83c` 里移除了 `confirmDeleteHistory` 对话框，滑动删除
  按钮直接删。误触代价是靠备份恢复。
- **需要确认**：这是有意的产品决策（配合 ShatterOverlay 星河动画营造
  仪式感）还是顺手删多了？
- **动作**：确认为有意，则不动；确认为误删，恢复 `confirmDeleteHistory`
  调用即可。**这题只有产品负责人能拍板**。
- **锚点**：`entry/src/main/ets/pages/ProjectDetailPage.ets`

### 13. `MotionQuality` 与「删除星河效果」两个开关的关系（决策）

- **问题**：MyPage 目前有两个开关——「动效强度（FULL/CALM/MINIMAL）」和
  「删除星河效果（开/关）」。MINIMAL 档下星河效果是否也应该被关掉？
  当前实现里两者独立。
- **动作**：明确规则并写入 `MotionQualityContext`：例如 MINIMAL/CALM 时
  自动禁用 shatter；或者两个开关始终独立。
- **锚点**：
  - `entry/src/main/ets/services/ReviewSettingsService.ets`
  - `entry/src/main/ets/pages/ProjectDetailPage.ets` 里读取 shatter 开关
    的位置

### 14. `EntryAbility.initializeMotionAndLoadContent` 加超时兜底

- **类别**：实现（可选，观察后决定）
- **动作**：如果第 3 项 CALM/MINIMAL 真机验证时观察到冷启动首屏黑白/加载
  图多停一小段，给 `MotionQualityContext.initialize` 加 100ms
  `Promise.race` 超时，超时按 FULL 默认继续。
- **完成判定**：首启动到 loadContent 之间的间隔 < 200ms。
- **锚点**：`entry/src/main/ets/entryability/EntryAbility.ets`

---

## 建议交付顺序

1. **P0 三条同一次真机测试轮完成**，产出一份 checklist 报告
   （每条 pass/fail + 复现步骤）。
2. **P2 的 10、12、13 是决策题**——由产品负责人先拍板，Codex 再动手。
3. **P1 按 4 → 7 → 5 → 6 → 8 → 9 顺序**（观感回报从大到小），每条
   独立提交、独立回退。

---

## 附录：与前置方案的关系

- `plan-motion-narrative-upgrade.md`：动效激进档方案（v1，2026-07-13）。
  本文列表的 P1 条目是该方案中已抽象但未接入业务的欠账；P0 是落地过程中
  新暴露的观察点；P2 是实施过程中的副作用与遗留决策。
- `spec-for-codex/spec-20260712-xiaoyi-integration-planning-handoff.md`
  与小艺意图接入相关，不在本清单范围。
