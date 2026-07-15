# 交互动效后续排查与实现清单

> 面向：下一轮实现 Agent（Codex）
> 版本：v5（2026-07-15 追加）
> v1 起源：`docs/spec-for-codex/plan-motion-narrative-upgrade.md` 落地至 `885c357` 后的 code review 结论
> v2 起源：v1 落地至 `31239c8` 后的 code review 结论。新增 P0-V2、P1-V2、P2-V2 三组条目（编号带 `V2-` 前缀），原 P0/P1/P2 保持不变。
> v3 起源：v2 落地至 `be1f978` 后的 code review 结论。新增 V3 组条目（编号带 `V3-` 前缀），原 v1/v2 内容保持不变。
> v4 起源：v3 落地至 `c3ec2be` 后的用户新需求：我的页面收拢、星河效果升级、`consumePending` 冗余 `.slice()`。
> v5 起源：v4 落地后用户真机截图反馈：复盘人卡片样式突兀、二级页内容居中、星河仍差点意思、删除后相邻卡片抖动。

按"可直接派单"的粒度整理。分三档：**P0 排查**、**P1 补齐欠账**、**P2 卫生与决策**。
每条给出：类别 · 动作 · 完成判定 · 文件锚点 · 背景。

---

## v5 追加条目（针对 v4 真机截图反馈）

### V5-P0-1. 二级页 `Scroll > Column` 未设 minHeight 导致内容居中（老坑再犯 · 抽象收口）

- **类别**：修 bug + 防复发抽象
- **问题**：`AppearanceSettingsPage.ets:218-232` 与 `BackupCenterPage.ets:188-202` 的
  `Scroll` 内 `Column` 缺少 `constraintSize({ minHeight: '100%' })`，导致 Column
  按内容高度渲染，被 Scroll 视口居中显示。真机上表现为「标题和卡片挂在屏幕中间」，
  与 StatsPage / HomeStoragePage 的顶对齐行为不一致。
- **根因**：ArkUI 的 `Scroll > Column` 需要子 Column 显式声明 `minHeight: '100%'`，
  否则 `.justifyContent(FlexAlign.Start)` 无效（Column 自身没有多余空间可分配）。
  StatsPage 有这行、Codex 新写的两个页面漏了。**用户反馈这是 recurring 老坑**。
- **动作**：
  1. **立即修 bug**：`AppearanceSettingsPage` 与 `BackupCenterPage` 各自的 build 里，
     在 `Scroll > Column` 上补一行 `.constraintSize({ minHeight: '100%' })`
  2. **防复发抽象**：在 `entry/src/main/ets/components/AppDesign.ets` 抽一个
     `SettingsScrollContainer` 组件：
     ```typescript
     @Component
     export struct SettingsScrollContainer {
       @BuilderParam content: () => void = () => {};
       build() {
         Scroll() {
           Column({ space: AppMetrics.sectionGap }) {
             this.content()
           }
           .alignItems(HorizontalAlign.Start)
           .width('100%')
           .constraintSize({ minHeight: '100%' })
           .padding({
             left: AppMetrics.pagePadding,
             right: AppMetrics.pagePadding,
             top: AppMetrics.pageTopPadding,
             bottom: AppMetrics.pageBottomPadding + AppMetrics.space24
           })
           .justifyContent(FlexAlign.Start)
         }
         .width('100%')
         .height('100%')
         .scrollBar(BarState.Off)
         .edgeEffect(EdgeEffect.Spring)
         .backgroundColor(AppColors.pageBackground)
       }
     }
     ```
  3. **两个页面改用抽象**：AppearanceSettingsPage / BackupCenterPage 的 build 直接
     用 `SettingsScrollContainer({ content: () => { ... } })` 包裹内容
  4. **verify 门禁**：新增或扩展 `scripts/verify_ui_closure.mjs`，断言：
     - 任何 `entry/src/main/ets/pages/*SettingsPage.ets` **不允许**出现裸 `Scroll() {` 结构
       （必须走 `SettingsScrollContainer`）
     - 除非文件内明确注释 `// eslint-disable-next-line settings-scroll`（保留后门）
- **完成判定**：
  - 真机上外观与动效、备份与恢复两页标题从屏幕顶部开始，卡片紧随其下
  - `SettingsScrollContainer` 已抽象，两个页面 build 各自不超过 15 行
  - verify 断言存在，故意在 AppearanceSettingsPage 里写 `Scroll()` 试测能挂
- **锚点**：
  - `entry/src/main/ets/pages/AppearanceSettingsPage.ets:214-243`
  - `entry/src/main/ets/pages/BackupCenterPage.ets:184-213`
  - `entry/src/main/ets/components/AppDesign.ets`（新增 `SettingsScrollContainer`）
  - `scripts/verify_ui_closure.mjs` 或新增 `scripts/verify_settings_scroll_pattern.mjs`
- **背景**：用户明确说"这个问题反反复复很多遍了，只要一改这边它就是这个死样子"。
  抽象组件 + verify 断言组合是唯一能让这个坑不再复发的办法。仅修 bug 不做抽象，
  下次新加设置页仍会踩坑。

### V5-P0-2. MyPage 复盘人卡片改为普通设置行（去除蓝框差异化）

- **类别**：修 UI（信息架构对称）
- **问题**：`MyPage.ets:222-260` 的 `ReviewerCardContent` 自建一套样式——
  `backgroundColor(AppColors.primarySoft)`（淡蓝底）+ `border(AppColors.primary)`
  （蓝框）+ 独立 Row 布局；与下方所有走 `RippleSettingsLinkRow → SettingsLinkRow`
  的白底灰边卡片视觉突兀不一致。用户反馈"这个不需要，和其他的保持一致就可以了"。
- **决策已定**：**去除差异化**，复盘人也走 `RippleSettingsLinkRow`。
- **动作**：
  1. 删除 `MyPage.ets` 中的 `@Builder ReviewerCardContent` 与 `@Builder ReviewerCard`
  2. 在 `SettingsSection` @Builder 顶部（外观与动效之前）插入：
     ```typescript
     this.RippleSettingsLinkRow({
       title: '复盘人',
       status: this.resolveReviewerSummary(),
       tone: this.resolveReviewerSummary() === '未设置' ? SettingsEntryTone.MUTED : SettingsEntryTone.SUCCESS,
       onTap: () => { this.openPage(REVIEWER_PROFILE_PAGE, '打开复盘人设置失败'); }
     })
     ```
  3. build() 里删除对 `this.ReviewerCard()` 的调用
  4. 更新 v4 里加的 `verify_my_page_information_architecture.mjs` 断言：
     - **禁止** `MyPage.ets` 出现 `backgroundColor(AppColors.primarySoft)` 与
       `border({ width: 1, color: AppColors.primary })` 的组合（防止 identity 卡样式
       被恢复）
     - 顶层设置行数应为 5 条（复盘人 + 外观与动效 + 家庭存储 + 同步中心 + 备份与恢复），
       全部走 `RippleSettingsLinkRow`
- **完成判定**：
  - 真机上 MyPage 顶部无蓝框卡片，所有条目统一米白底/灰边
  - MyPage.ets 行数进一步下降约 30 行
- **锚点**：
  - `entry/src/main/ets/pages/MyPage.ets:222-271` `ReviewerCardContent` /
    `ReviewerCard`
  - `entry/src/main/ets/pages/MyPage.ets` `SettingsSection` @Builder
  - `scripts/verify_my_page_information_architecture.mjs`
- **背景**：v4 决策时保留 identity 卡样式是我的判断错误（"用户身份中频高价值需要突出"），
  真机上视觉突兀。设计的一致性 > 想象中的突出。

### V5-P1-1. 删除后相邻卡片抖动 → 加 collapse 阶段

- **类别**：修 bug（观感）
- **问题**：`ProjectDetailPage.ets:387`（`deletePendingPhoto`）与第 442 行附近
  （`deleteHistory`）在粒子 `shatterDurationMs` 播完后**一次性** `pendingItems.filter(...)`
  从数据源移除 item。ArkUI 里 ListItem 硬消失，相邻 item 瞬移到新位置，用户看到
  "抖动"。外层挂的 `.animation({ duration: shatterRippleBackMs })`（第 961 行）
  只能补位剩余 item 的**位置变化**，无法补位**被删 item 高度收缩**（它已从 List 数据里
  移除，animation 挂点已不存在）。
- **动作**：在粒子完成与数据源 splice 之间**插入 `durationStandard` 的 collapse
  动画**——被删 item 高度平滑收到 0 + opacity 淡出，之后再从数据源移除。
  1. **新增 state**：
     ```typescript
     @State collapsingIds: Array<string> = [];
     private isCollapsing(id: string): boolean { return this.collapsingIds.indexOf(id) >= 0; }
     private beginCollapse(id: string): void {
       if (this.collapsingIds.indexOf(id) < 0) {
         this.collapsingIds = this.collapsingIds.concat([id]);
       }
     }
     private endCollapse(id: string): void {
       this.collapsingIds = this.collapsingIds.filter((existing: string): boolean => existing !== id);
     }
     ```
  2. **改造 `deletePendingPhoto` / `deleteHistory` 的流程**（以 pending 为例）：
     ```typescript
     await Promise.all([deleteTask, animationTask]);   // 粒子播完
     await LearningProgressFormService.refreshAllForms(context);
     if (!this.isPageAlive) return;
     if (useShatter) {
       this.beginCollapse(photo.id);
       await new Promise<void>((resolve) =>
         setTimeout(resolve, MotionQualityContext.resolveDuration(MotionTokens.durationStandard)));
       if (!this.isPageAlive) return;
     }
     this.pendingItems = this.pendingItems.filter(...);   // 原来的 splice，现在延后
     this.libraryStats.pendingCount = Math.max(0, this.libraryStats.pendingCount - 1);
     if (useShatter) {
       this.endCollapse(photo.id);
       this.markCardVisible(photo.id);
     }
     ToastService.success(...);
     this.reloadData();
     ```
  3. **改造 `PendingReviewListCardContent` / `HistoryReviewListCardContent` @Builder**，
     在最外层 Stack 上加：
     ```typescript
     .height(this.isCollapsing(photo.id) ? 0 : undefined)
     .opacity(this.isCollapsing(photo.id) ? 0 : 1)
     .animation({
       duration: MotionQualityContext.resolveDuration(MotionTokens.durationStandard),
       curve: MotionQualityContext.resolveCurve(MotionCurveRole.SPRING_SOFT)
     })
     ```
  4. **异常路径 endCollapse 兜底**：如果 deleteTask 抛错，catch 分支里要
     `endCollapse(id)` + `markCardVisible(id)`，否则失败重试后 item 仍处于
     collapse 视觉态
  5. **verify 断言**：`scripts/verify_shatter_animation.mjs` 加断言：
     - `deletePendingPhoto` 与 `deleteHistory` 必须在 splice 前触发 `beginCollapse`
     - 两个方法的 catch 分支必须调 `endCollapse`
- **完成判定**：
  - 真机上删除任意卡片：粒子（1300ms）→ 卡片位置高度平滑收到 0（250ms · spring
    补位）→ 相邻卡片跟随滑上，无一帧跳变
  - 删除失败（模拟 PendingReviewPhotoStore.delete 抛错）时卡片高度恢复，不留
    collapse 残影
- **锚点**：
  - `entry/src/main/ets/pages/ProjectDetailPage.ets:359-410` `deletePendingPhoto`
  - `entry/src/main/ets/pages/ProjectDetailPage.ets:412-460` `deleteHistory`
  - `entry/src/main/ets/pages/ProjectDetailPage.ets:800-880`
    `PendingReviewListCardContent` / `HistoryReviewListCardContent`
  - `scripts/verify_shatter_animation.mjs`
- **背景**：用户反馈"粒子完了之后腾出面会抖动一下，这个不够丝滑"。当前的
  `.animation({ duration: shatterRippleBackMs })` 只对剩余 item 生效，不覆盖
  被删 item 的高度收缩帧。collapse 阶段是标准补法。

### V5-P1-2. 星河再强化：中心闪光 + 暖金主爆 + 椭圆分布 + 密度上调

- **类别**：实现（视觉再迭代）
- **问题**：v4 三层叠加代码落地，但用户真机反馈"还是差点意思，还是不够炫"。
  诊断三个具体缺口：
  1. **缺"爆点"**——三层都是均匀扩散，没有中心亮源；真实爆发第一瞬间应有一个亮闪
  2. **米色背景吃亮度**——`#F5F1E9` 应用背景偏暖偏亮，纯白粒子在上面对比度不够
  3. **粒子分布均匀**——RECTANGLE emitter 全区域均匀发射，像"下雪"不像"炸开"
- **动作**：在 v4 三层基础上**追加以下 5 处改造**：

  **1) 新增中心闪光帧**（在 `ShatterOverlay.build` 的 Stack 里，粒子层之前）：
  ```typescript
  @State flashVisible: boolean = false;
  @State flashScale: number = 0.3;
  @State flashOpacity: number = 0.9;
  // aboutToAppear 里立即触发一次：
  this.flashVisible = true;
  this.flashScale = 1.4;
  this.flashOpacity = 0;
  // build 里：
  if (this.flashVisible) {
    Circle()
      .width('40%').height('40%')
      .fill('#FFFFFF')
      .opacity(this.flashOpacity)
      .scale({ x: this.flashScale, y: this.flashScale })
      .animation({
        duration: MotionTokens.durationInstant * 2 + 20,   // 180ms
        curve: MotionQualityContext.resolveCurve(MotionCurveRole.EMPHASIZED)
      })
  }
  ```
  180ms 内完成 `scale 0.3→1.4 + opacity 0.9→0`，40ms 后主爆粒子接棒。

  **2) 暗化背景 scrim**：在闪光 Circle 之前加一层 Column：
  ```typescript
  Column()
    .width('100%').height('100%')
    .backgroundColor(this.scrimActive ? '#14000000' : '#00000000')
    .animation({ duration: 200, curve: MotionTokens.curveDecelerate })
  ```
  aboutToAppear 后 `scrimActive = true`；粒子完成后设 false 淡出。让白/金粒子在
  略暗背景上更亮。

  **3) 主爆改暖金色**：`ShatterTokens.mainColorRange` 从
  `['#FFFFFF', '#C7D4FF']` 改成 `['#FFFFFF', '#FFD98A']`（白到暖金）。慢漂层
  保留 `['#FFFFFF', '#B8B8FF']` 不改，形成"金爆 + 紫尾"层次感。

  **4) 光晕层 emitter 改 ELLIPSE**：`ParticleEmitterShape.RECTANGLE`
  → `ParticleEmitterShape.ELLIPSE`；ELLIPSE 天然中央密集向外稀疏，粒子分布
  更像"炸开"而非"下雪"。**只改光晕层**，主爆和慢漂保持 RECTANGLE 铺满卡片。

  **5) 密度上调**：光晕层 count 12→24，慢漂层 40→60（低/中/高档等比上调）。
  总粒子数从 124 → 156，观感差别明显。

- **完成判定**：
  - `ShatterOverlay.ets` 内包含闪光帧 Circle + scrim Column + 三层粒子（emitter
    形状按上表）
  - `ShatterTokens` 内 `mainColorRange = ['#FFFFFF', '#FFD98A']`，其他色不变
  - `verify_shatter_layers.mjs` 加断言：
    - 闪光帧存在（regex 匹配 `flashVisible` + `Circle()` + width '40%'）
    - `mainColorRange` 包含 `#FFD98A`
    - 光晕层 emitter 使用 `ParticleEmitterShape.ELLIPSE`
    - 慢漂层 count ≥ 60
  - 真机上再次触发删除，与 v4 版本对比：应能看到明显的"中心闪光→炸开"节奏，
    而非"淡淡一片扩散"
- **锚点**：
  - `entry/src/main/ets/components/ShatterOverlay.ets`
  - `entry/src/main/ets/theme/DesignTokens.ets`（`ShatterTokens.mainColorRange`）
  - `scripts/verify_shatter_layers.mjs`（新增断言）
- **背景**：
  - "中心闪光帧"是各家游戏/影视爆炸镜头的通用手法。一颗爆点先亮再炸，比全域
    均匀扩散有力得多
  - 暖金主爆的取舍：米色背景 (`#F5F1E9`) 上，暖色（金、橙）对比度 > 冷色（白、蓝）。
    冒险星河风被暖金替代**不影响整体审美方向**——慢漂层保留冷紫，仍是"星河"
    但从"清冷星河"变为"星爆 + 星河"
  - 若真机后觉得暖金太"打" 干扰塔伽花米色系，可退回主爆用白到淡蓝金
    `['#FFFFFF', '#FFF5D6']`（近白暖），保留闪光帧与暗化 scrim 的对比感

---

## v5 建议派单顺序

1. **V5-P0-1** 二级页居中（1 分钟修 bug + 抽 `SettingsScrollContainer` + verify
   防复发）——最优先，是**老坑收口**
2. **V5-P0-2** 复盘人卡片对称化（10 行删除 + 换 RippleSettingsLinkRow + verify）
3. **V5-P1-1** 删除 collapse 阶段（中等改动，观感立竿见影）
4. **V5-P1-2** 星河再强化 5 处（最后做，视觉再迭代）

V5-P0-1 与 V5-P0-2 都是 MyPage / 二级设置页范围，可**打一个 commit**；
V5-P1-1 与 V5-P1-2 各自独立提交、独立回退。

---

## Codex v5 执行记录（2026-07-15）

| 条目 | 状态 | 结论 |
| --- | --- | --- |
| V5-P0-1 二级设置页顶部布局 | 代码完成 | 新增共享 `SettingsScrollContainer`，统一声明 `constraintSize({ minHeight: '100%' })` 与顶部对齐；外观、备份和显示与动效三页均已迁移。新增 `verify_settings_scroll_pattern.mjs`，禁止 `*SettingsPage.ets` 恢复裸 `Scroll()`，同时保留显式豁免注释。 |
| V5-P0-2 复盘人设置行 | 代码完成 | 删除独立 `ReviewerCardContent` / `ReviewerCard` 蓝底蓝框身份卡，复盘人改为第 1 条 `RippleSettingsLinkRow`；MyPage 顶层 5 条设置行统一，文件由 500 行降至 456 行，并继续通过 Builder 闭包闪退回归门禁。 |
| V5-P1-1 删除 collapse | 代码完成，待真机 | 待复盘与历史删除均改为“后端删除 + 1300ms 粒子 → 250ms 高度/透明度收缩 → 数据源移除”；收缩时 min/maxHeight 同步归零，异常路径恢复 collapse 与卡片可见状态，页面离开会清理临时视觉状态。 |
| V5-P1-1 删除后二次抖动追加修复 | 代码完成，待真机 | 删除成功后不再 `reloadData()` 重查并替换首屏，历史删除服务也不再额外读取完整资料库；`List` 固定间距迁入各卡片 `ListItem` 并随高度同步收缩，删除事务会取消并拦截并发分页、在 280ms 回位窗口内禁止 `onReachEnd`，历史列表身份改用 `getReviewDocumentKey`，避免幸存卡片重建和入场动画重播。失败链路仍会恢复卡片并重新对账。 |
| V5-P1-2 星河强化 | 代码完成，待真机 | 新增 40ms 中心闪光前导、暗化 scrim、暖金主爆 `['#FFFFFF', '#FFD98A']` 和椭圆光晕；光晕由 `6/12/20` 等比增至 `12/24/40`，慢漂由 `20/40/60` 等比增至 `30/60/90`，中档总粒子数由 124 增至 156。计时器在组件离开时统一清理。 |

本地验证：`bash scripts/test_app.sh --quick` 通过 47/47；
`bash scripts/test_app.sh --all` 通过 64/64，主模块与 `entry@ohosTest` 均完成
ArkTS 编译和 HAP 打包。HDC `--check-only` 只读枚举在保护窗口内超时，未执行安装、
启动、卸载或清空数据；二级页顶对齐、删除后一次性回位与星河观感仍需设备恢复后真机复测。

---

## v4 追加条目（针对用户新反馈）

### V4-P1-1. 我的页面信息架构收拢（档 B：二级聚合页）

- **类别**：实现（信息架构）
- **问题**：MyPage 顶层同级列表 9~10 行，密度过大，"看起来太散"。用户想要
  更清晰的层次。
- **决策已定**：**方案 B（二级聚合页）**。顶层收敛为「复盘人卡片 + 3 条二级入口 +
  关于」，共 4~5 行。
- **动作**：
  1. **新增页面 `AppearanceSettingsPage.ets`**：把 MyPage 里以下条目二级化：
     - `首页图片` → 迁入
     - `卡片背景` → 迁入
     - `显示与动效` → 迁入（保留原 `MotionSettingsPage` 二级页，本页做入口）
     - `删除星河效果` → 迁入（改为 Toggle 行）
     - 页面结构参照 `HomeStoragePage`：AppPageHeader + Column({ space: cardGap })
       + `RippleSettingsLinkRow` 集合。每行仍走 `RippleTouch` + `SettingsLinkRow`
       组合，遵循 V3-P2-2 的 `clipRadius: AppMetrics.cardRadius` 约束。
  2. **新增页面 `BackupCenterPage.ets`**：把 `备份全部复盘` + `从备份恢复` 从
     MyPage 迁入。原 `DataProtectionSection` 里的逻辑（`exportLibraryBackup /
     selectLibraryBackup / backupItemTotal / isBackupActionRunning`）随之搬迁。
  3. **改造 `MyPage.ets`**：顶部保留 `复盘人` **卡片**（比设置行更醒目，因为它
     是用户身份，中频高价值）；下方三条二级入口 + `关于` 卡：
     ```
     [卡片] 复盘人：小李             →
     外观与动效        完整 · 星河开 →   (openAppearanceSettings)
     家庭存储          已连接         →   (openHomeStorage) —— 保留原有直达
     备份与恢复        12 条          →   (openBackupCenter)
     [卡片] 关于（版本 + 诊断入口）
     ```
     `同步中心` 仍保留为独立入口还是并入"家庭存储"页内？—— **默认保留独立入口**
     （用户在 v4 未提及；家庭存储与同步中心在业务逻辑上仍是两回事）。若产品
     后续想合并，另开子任务。
  4. **新增 `AppRouter.ets` 中的两条路由**：`AppearanceSettingsPage`、
     `BackupCenterPage`，遵循现有 `main_pages.json` 注册规范。
  5. **verify 脚本收口**：
     - 新增 `scripts/verify_my_page_information_architecture.mjs` 或扩展现有的：
       断言 `MyPage.ets` 顶层设置行数 ≤ 5 条；断言 `AppearanceSettingsPage.ets`
       必须包含指定 4 类子项；断言 `BackupCenterPage.ets` 必须包含备份+恢复
       两个动作
- **完成判定**：
  - MyPage 编译后行数从当前约 700 行下降至 ≤ 500 行（迁移出去的逻辑不算在
    MyPage 里）
  - 新增两个页面各自可独立编译；`test_app.sh --quick` 全绿
  - 真机上 MyPage 首屏可视区一屏容纳完整设置入口，不再需要滚动
- **锚点**：
  - `entry/src/main/ets/pages/MyPage.ets`（收敛）
  - `entry/src/main/ets/pages/AppearanceSettingsPage.ets`（新增）
  - `entry/src/main/ets/pages/BackupCenterPage.ets`（新增）
  - `entry/src/main/ets/app/AppRouter.ets`
  - `entry/src/main/resources/base/profile/main_pages.json`
- **背景**：
  - 「复盘人」保留在 MyPage 顶层是因为它是**身份类信息**，用户希望"一眼看到自己
    是谁"；把它做成卡片形式而非普通行，突出身份属性
  - 「家庭存储」保留在 MyPage 顶层是因为它是**状态类信息**（"已连接/未配置/失败"），
    用户希望**一眼看到 NAS 是否可用**，不应再深一级
  - 「删除星河效果」从行改成 Toggle 行是因为它是布尔开关，Toggle 比 Link 更贴合

### V4-P1-2. 星河粒子效果升级（档 2：三层叠加 · 冒险星河风）

- **类别**：实现（视觉升级）
- **问题**：当前 `ShatterOverlay` 观感"差点意思"——粒子形态单一、颜色深、消失
  太快、无光晕、运动无层次。诊断五个具体问题：
  1. 只有 `POINT type, radius=2` 的硬边小点
  2. 颜色 `#356F80` + `#B7773E` 太重（原本是应用主色和标签琥珀色）
  3. 500ms 生命周期，200ms 内几乎完全消失
  4. 无光晕（ArkUI Particle 不支持 blur）
  5. 所有粒子速度均匀外扩，缺少"漂"的层次感
- **决策已定**：**方案 2（三层叠加）+ 冒险星河风配色**。
- **动作**：改造 `entry/src/main/ets/components/ShatterOverlay.ets` 为三层
  粒子叠加。**三层参数如下**（所有值可通过 `MotionTokens` / `ShatterTokens`
  抽出，避免 magic number）：

  **主爆层**（现有层的强化版本 · 快速外扩）：
  - `type: POINT, radius: 2`
  - `count: 72`（低 48 / 中 72 / 高 96 —— 略低于原来）
  - `lifetime: 700ms`（比 500ms 长，尾巴更长）
  - `color range: ['#FFFFFF', '#C7D4FF']`（纯白到淡蓝白）
  - `opacity: 1→1 (0-400ms) → 1→0 (400-700ms)`（前段保持满亮度更久）
  - `scale range: [0.4, 1.6]`（比原来 0.6-1.2 更大动态范围）
  - `speed: [24, 72]`，`angle: [0, 360]`

  **光晕层**（新增 · 大颗慢速）：
  - `type: IMAGE`，`src: $r('app.media.particle_halo')`（新增 halo PNG 资源；
    32×32 白色径向渐变到透明的圆点，见后文资源规范）
  - `count: 12`（低 6 / 中 12 / 高 20）
  - `lifetime: 900ms`
  - `color range: ['#FFFFFF', '#FFFFFF']`（IMAGE 类型 color 用作 tint，白色即原色）
  - `opacity: 0.9→0.6 (0-500ms) → 0 (500-900ms)`
  - `scale range: [0.8, 1.4]`（图像本身已经带 halo，不需要再放大很多）
  - `speed: [8, 24]`（比主爆慢 3 倍，感觉"漂"）
  - `angle: [0, 360]`

  **慢漂层**（新增 · 长尾星尘）：
  - `type: POINT, radius: 1`
  - `count: 40`（低 20 / 中 40 / 高 60）
  - `lifetime: 1200ms`（三层里最长）
  - `color range: ['#FFFFFF', '#B8B8FF']`（白到淡紫）
  - `opacity: 0.8→0.8 (0-600ms) → 0 (600-1200ms)`
  - `scale range: [0.3, 0.9]`（最小）
  - `speed: [6, 18]`（最慢）
  - `angle: [0, 360]`

  **总时长**：`MotionTokens.shatterDurationMs` 从 800ms 提高到 **1300ms**（覆盖最长
  的慢漂层 1200ms + 200ms 缓冲）；同步更新 `verify_shatter_animation.mjs` 断言。

- **新增资源**：
  - `entry/src/main/resources/base/media/particle_halo.png`（32×32，白色径向渐变
    从中心 alpha=1.0 到边缘 alpha=0.0；纯 alpha 通道，颜色由 Particle color prop
    tint）
  - 若无法生成 PNG，退化为 SVG（Particle IMAGE 目前应支持 SVG，但需真机验证）

- **完成判定**：
  - `ShatterOverlay.ets` 内包含三个 `emitter`，且每层的 `type / count / color /
    opacity / scale / speed / lifetime` 都从 `ShatterTokens`（新增于 DesignTokens）
    读取，不出现 magic number
  - `MotionTokens.shatterDurationMs` = 1300
  - 新增 `verify_shatter_layers.mjs`：断言三层的 lifetime 关系
    `main < halo < drift` 与 count 关系 `drift > main > halo`
  - 真机上删除卡片时能看到"发光星尘扩散 + 慢漂尾巴"，与之前的"糊一片颜色"有
    肉眼可辨的差异
  - 低端机 jank 若明显，`MotionQuality=CALM` 时**自动降级到只保留主爆层**
    （在 `MotionQualityContext` 里加一个 `resolveShatterLayerCount()` 返回
    1/2/3）；此改造并入本条目一起做

- **锚点**：
  - `entry/src/main/ets/components/ShatterOverlay.ets`
  - `entry/src/main/ets/theme/DesignTokens.ets`（新增 `ShatterTokens` class）
  - `entry/src/main/ets/theme/MotionQualityContext.ets`（新增 `resolveShatterLayerCount`）
  - `entry/src/main/resources/base/media/particle_halo.png`（新增资源）
  - `scripts/verify_shatter_animation.mjs`（时长值更新）
  - `scripts/verify_shatter_layers.mjs`（新增分层校验）

- **背景**：
  - "冒险星河风"配色理由：白色/淡蓝白/淡紫都是**高亮 · 冷调 · 中性**，不与
    应用整体的塔伽花米色 / 花胶质感冲突
  - 三层叠加的物理动机：真实的粒子爆发从来不是同质的。中心点亮度高、外缘
    小星尘慢漂、周围有光晕包裹——这三层分别对应人眼在"看烟花""看星河"时
    捕捉到的三种视觉层次
  - 为什么不做「光流 + 碎裂帧」（档 3）：开发量大 3 倍，低端机风险高，且当前
    产品是照片复盘不是游戏，过度炫技反而突兀

### V4-P2-1. `MotionCeremonyEventService.consumePending` 移除冗余 `.slice()`

- **类别**：卫生
- **问题**：`entry/src/main/ets/services/MotionCeremonyEventService.ets:60`
  第 60 行 `MotionCeremonyEventService.pendingKinds = pendingKinds.slice();`
  是冗余的：右侧 `pendingKinds` 已经是第 56 行 filter 返回的**新数组**，
  再 `.slice()` 一次没有实际效果。局部变量 `pendingKinds` 用于遍历，静态
  字段 `pendingKinds` 用于最终存储；即使两者短暂指向同一数组，第 65 行的
  filter 也会生成新数组重新赋值，不会污染遍历中的局部变量。
- **动作**：把第 60 行改成 `MotionCeremonyEventService.pendingKinds = pendingKinds;`
- **完成判定**：
  - 第 60 行不再出现 `.slice()`
  - `test_app.sh --quick` 全绿
  - 若认为需要 verify 断言防回归（可选），在 `verify_motion_ceremony_hooks.mjs`
    里加一条 `assertNotIncludes(source, 'pendingKinds.slice()', ...)`
- **锚点**：`entry/src/main/ets/services/MotionCeremonyEventService.ets:60`
- **背景**：v3 code review 时发现，当时没派单。现在收口。

---

## v4 建议派单顺序

1. **V4-P2-1** `.slice()` 清理（1 分钟，独立提交）
2. **V4-P1-2** 星河粒子升级（观感立竿见影，用户能立刻反馈）
3. **V4-P1-1** 我的页面收拢（架构调整，需要更多真机验证；等 V4-P1-2 落地后再动
   避免同一次提交里改动过大）

---

## Codex v4 执行记录（2026-07-15）

| 条目 | 状态 | 结论 |
| --- | --- | --- |
| V4-P1-1 我的页面收拢 | 代码完成，待真机观感 | `MyPage` 改为“复盘人身份卡 + 外观与动效 + 家庭存储 + 同步中心 + 备份与恢复 + 关于/开发诊断”，顶层 4 条设置入口；首页图片、卡片背景、显示与动效、星河开关迁入 `AppearanceSettingsPage`，备份与恢复逻辑迁入 `BackupCenterPage`。两个页面均已注册路由，Ripple 使用卡片圆角裁剪。`MyPage.ets` 从 683 行降至 500 行，门禁禁止恢复会撑大行距的顶层 `List`。 |
| V4-P1-2 三层星河 | 代码完成，待真机观感 | `ShatterOverlay` 已拆为主爆 POINT、光晕 IMAGE、慢漂 POINT 三层，全部参数收口到 `ShatterTokens`；FULL 播放三层，CALM/MINIMAL 降级为仅主爆层。新增 32×32 RGBA alpha 光晕资源及分层门禁，总时长改为 1300ms。 |
| V4-P2-1 pending slice | 已完成 | `consumePending` 直接保存 `filter` 产生的新数组，不再做冗余 `.slice()`；`verify_motion_ceremony_hooks.mjs` 已加防回归断言。 |
| 旧发布门禁迁移 | 已完成 | 与旧 MyPage 扁平结构绑定的 smoke/all 断言已迁移到二级页，继续验证功能归属、路由可达、备份完整逻辑、刷新链路、Ripple 圆角和中文文案，没有通过删除能力断言来绕过门禁。 |

规格取舍：三层明确参数为 main 72、drift 40、halo 12（低/高档同样保持该顺序），
因此实现与门禁采用 `main > drift > halo`，不采用完成判定中矛盾的
`drift > main > halo`。总时长采用明确指定的 1300ms；“覆盖 1200ms + 200ms 缓冲”
算术上应为 1400ms，与指定值冲突，当前按指定值执行并保留 100ms 收尾空间。光晕是
简单径向几何资产，使用确定性像素生成而非生成式图片；已验证为 32×32、RGBA、含 alpha。

本地验证：`bash scripts/test_app.sh --quick` 通过 46/46；
`bash scripts/test_app.sh --all` 通过 63/63，主模块与 `entry@ohosTest` 均完成 ArkTS
编译和 HAP 打包，最终 unsigned HAP 为 4.1MB。HDC 设备探测超时，未执行覆盖安装或
会清空数据的 UI 测试；MyPage 一屏容纳效果及“发光星尘扩散 + 慢漂尾巴”仍需设备
恢复连接后做最终真机验收。

### V4 我的页面闪退跟进（2026-07-15）

用户真机反馈切换到“我的”页面闪退。回看 V4 首帧新增路径后，`MyPage` 是全仓唯一
在 `RippleTouch` 的 `@BuilderParam` 闭包内直接创建 `SettingsLinkRow` 的页面；该写法
可以通过 ArkTS 编译，但与项目其余 Ripple 行统一采用的“独立 `@Builder` + 绑定当前
实例的闭包调用”不同。已恢复 `RippleSettingsLinkRowContent` 稳定 Builder，并在
`verify_ripple_layout_contract.mjs` 中禁止再次内联；通过收拢 import 保持
`MyPage.ets` 为 500 行。`test_app.sh --all` 再次通过 63/63，主模块、
`entry@ohosTest` 和 Debug 签名 HAP 均构建成功。HDC 当前枚举结果为 `[Empty]`，尚未
取得设备崩溃栈或完成保数据覆盖安装，最终真机复测状态保持待确认。

---

## v3 追加条目（针对 `be1f978` 复盘）

背景：v2 的 8 条追加条目全部按方向修完，且 Codex 顺手修了一个我漏抓的
RippleTouch 布局 bug（240vp `Circle` 从主流 Stack 撑大 ListItem，改为
`.overlay(...)` 叠加）。剩下 5 条都是**决策 / 观察**，不是回归 bug，但值得
写入清单，防止未来读代码的人一头雾水或踩坑。

### V3-P1-1. StatsPage 与 HomePage 的 `onPageShow` 策略对齐（决策 + 实现）

- **类别**：决策 + 实现
- **问题**：v2 落地时 HomePage 在 `onPageShow` 里删除了 `playIntro`（子页返回不
  重放）；但 **StatsPage 仍然在 `onPageShow` 里 `playIntro`**（子页返回会重放）。
  `verify_motion_lifecycle_guards.mjs` 里只有 HomePage 的"不重放"断言，StatsPage
  没锁——真机路径 Stats → MyPage → 返回 Stats 会重放入场，Home → Editor → 返回
  Home 不会。**两页策略不一致，且都没显式声明**。
- **动作**：产品负责人拍板后二选一：
  - **方案 A（推荐 · 对称）**：StatsPage 也删掉 `onPageShow` 中的 `playIntro`，
    只保留 `aboutToAppear`。verify 脚本加一条断言"StatsPage onPageShow must not
    call playIntro"。
  - **方案 B**：在方案文档里写明"StatsPage 是数据展示页，每次进入重放入场；
    HomePage 是叙事起点，只在 Tab 切换重放"，并给 HomePage 补对称的"是"断言。
- **完成判定**：
  - 方案 A：两页均只在 `aboutToAppear` 触发 playIntro；两条 verify 断言存在
  - 方案 B：`docs/spec-for-codex/plan-motion-narrative-upgrade.md` 有段落
    描述该差异；HomePage / StatsPage 双向 verify 断言存在
- **锚点**：
  - `entry/src/main/ets/pages/StatsPage.ets` `onPageShow`
  - `entry/src/main/ets/pages/HomePage.ets` `onPageShow`
  - `scripts/verify_motion_lifecycle_guards.mjs`

### V3-P1-2. `pendingKinds` 加过期时间戳（防止跨长时段"补播"）

- **类别**：实现
- **问题**：`MotionCeremonyEventService.pendingKinds` 是静态字段（Ability 生命周期
  级），只有在进程被 kill 时才清空。可能的用户路径：
  - 用户完成复盘 → 切后台 15 分钟去做别的事 → 回来点开应用停在 EditorPage → 从
    EditorPage 返回 Home → **一进 Home 就播「完成仪式」**，用户觉得突兀。
  - 连续几天没打开 App 后一进入 Home，也会看到"补播"。
- **动作**：把 `pendingKinds` 从 `Array<MotionCeremonyEventKind>` 改成
  `Array<{ kind: MotionCeremonyEventKind, enqueuedAt: number }>`。`enqueue` 时记
  `Date.now()`；`consumePending` 消费前判断 `Date.now() - enqueuedAt <= 60_000`
  （60 秒过期），过期直接丢弃并不通知。
- **完成判定**：
  - 单元层测试或 verify 脚本断言：`pendingKinds` 元素含 `enqueuedAt` 字段；
    `consumePending` 中出现 `Date.now() - ` 相关计算
  - 60 秒 window 值放到常量（例如 `MOTION_CEREMONY_PENDING_TTL_MS = 60_000`），
    不允许 magic number
- **锚点**：`entry/src/main/ets/services/MotionCeremonyEventService.ets`
- **背景**：v2 pending queue 选方案 A 后的边界收口。60 秒是保守值——
  "用户完成复盘并在 1 分钟内回到 Home"仍能看到仪式；超过 1 分钟意味着用户
  已经分心去做别的事，补播反而突兀。

### V3-P2-1. EditorPage 的 `CeremonyBurst` 死代码清理

- **类别**：卫生
- **问题**：v2 之后 `EditorPage.saveAndPreview` 里的：
  ```typescript
  if (completesPendingReview && pendingReviewCompleted &&
    !ceremonyScheduledElsewhere && MotionQualityContext.shouldPlayCeremony()) {
    keepSavingLockedForCeremony = true;
    this.ceremonyVisible = true;
  }
  ```
  实际上**永远不会成立**——只要 `pendingReviewCompleted=true`，`notifyPendingReviewCompleted`
  就 enqueue 事件、`ceremonyScheduled=true`，`!ceremonyScheduledElsewhere` 为 false；
  只有 `pendingReviewCompleted=false`（marker 更新失败）时才能进这个 if，但此时
  `pendingReviewCompleted && ...` 又为 false。**EditorPage 里的 CeremonyBurst
  组件挂载点现在是死代码**。
- **动作**：二选一：
  - **方案 A（推荐）**：删除 EditorPage 里的 `CeremonyBurst` import、
    `@State ceremonyVisible`、`keepSavingLockedForCeremony` 相关整套逻辑；
    `saveAndPreview` 收到 `ceremonyScheduled=true` 后直接 `openPreview()`；
    `isSaving` 保持在 finally 里释放
  - **方案 B**：保留但在 `saveAndPreview` 的 if 分支上方加一段注释：
    ```
    // 兜底：仅当 pending 归零写入 preferences 失败（pendingReviewCompleted=false）
    // 但业务上确实完成了复盘时才进入。正常路径由 pending queue 派发到 HomePage。
    ```
    并且 verify 脚本加断言"该分支不能被误改为常规路径"
- **推荐**：方案 A，代码更干净；EditorPage 已经很复杂，少一个死状态是好事。
- **完成判定**：
  - 方案 A：`EditorPage.ets` 中不再 import `CeremonyBurst`；`ceremonyVisible`
    字段消失；`scripts/verify_motion_narrative_hooks.mjs` 中原本对 EditorPage
    `kind: 'review-done'` 的断言改为对 HomePage 的断言（因为仪式挂载点已迁移
    到 HomePage）
  - 方案 B：注释存在；verify 脚本有断言
- **锚点**：
  - `entry/src/main/ets/pages/EditorPage.ets` `saveAndPreview` +
    `@Builder` 中的 `CeremonyBurst`
  - `scripts/verify_motion_narrative_hooks.mjs`

### V3-P2-2. `RippleTouch.clipRadius` 业务调用点补齐圆角

- **类别**：卫生（观感优化）
- **问题**：v2 追加时新增了 `@Prop clipRadius: number = 0`，用于配合 `.clip(true)`
  给水波纹裁切圆角。但当前所有业务调用点（ProjectDetailPage 两处、MyPage
  SettingsLinkRow）**都用默认值 0**——意味着点击圆角卡片时，ripple 的裁切边界
  仍是矩形，Circle 溢出到卡片圆角外的部分会被裁掉直角。真机上可能看到"水波纹
  超出圆角边界一小截"的视觉瑕疵。
- **动作**：调用点补齐 `clipRadius`：
  - ProjectDetailPage 的 `PendingReviewListCard` / `HistoryReviewListCard`：
    传 `clipRadius: AppMetrics.cardRadius`（或该卡片实际用的圆角常量）
  - MyPage 的 `RippleSettingsLinkRow`：传 `clipRadius: AppMetrics.cardRadius`
- **完成判定**：
  - 三处调用点均带 `clipRadius`
  - `scripts/verify_ripple_layout_contract.mjs` 加一条断言 "business
    integrations must pass a non-zero clipRadius when the wrapped container
    has borderRadius"
- **锚点**：
  - `entry/src/main/ets/pages/ProjectDetailPage.ets`
  - `entry/src/main/ets/pages/MyPage.ets` `RippleSettingsLinkRow`
  - `entry/src/main/ets/components/motion/RippleTouch.ets` `clipRadius`
- **背景**：v2 的 RippleTouch 布局修复用 `.overlay(...)` 解决了尺寸撑大问题，
  同时 `clipRadius` 已经预留，但只做了 API 未做接入。

### V3-P2-3. `MotionCeremonyEventService.emit` 返回值语义与 pending queue 的关系文档化

- **类别**：文档
- **问题**：v2 落地后 `emit` 的语义**变了**：
  - 之前：`emit` 返回"是否被订阅方 handled"，业务代码据此决定是否让位
  - 之后：`LearningProgressService.notifyPendingReviewCompleted` 已改为**直接
    `enqueue`**，完全不走 `emit` 路径；但 `emit` 方法本身仍存在，且当无人 handled
    时会**自动 enqueue**
  - 结果：`emit` 现在是"发一次事件，如果当场没人接就自动排队"；而对
    `REVIEW_QUEUE_CLEARED` 这条 kind，业务代码根本不用 emit
- **动作**：在 `MotionCeremonyEventService.ets` 顶部注释里补充：
  ```
  // 使用契约（v2 之后）：
  //   - emit(kind)：发一次事件；若无订阅方 handled 则自动入队，等下次
  //     订阅时立即消费。用于「订阅方可能已在场也可能没在场」的通用场景。
  //   - enqueue(kind)：直接入队，不尝试即时派发。用于「明确知道订阅方需要
  //     切换页面后才能接」的场景，例如 REVIEW_QUEUE_CLEARED 在 EditorPage
  //     触发但由 HomePage 消费。
  //   - consumePending(listener)：subscribe 内部自动调用，不建议业务层直接调用。
  ```
  同时把 `LearningProgressService.notifyPendingReviewCompleted` 中的
  `enqueue` 调用上方加一行注释说明"必须用 enqueue 而不是 emit：EditorPage
  触发时 HomePage 不在前台"。
- **完成判定**：注释存在；无代码逻辑改动
- **锚点**：
  - `entry/src/main/ets/services/MotionCeremonyEventService.ets`
  - `entry/src/main/ets/services/LearningProgressService.ets`
    `notifyPendingReviewCompleted`

---

## v3 建议派单顺序

1. **V3-P1-2 pending queue 过期时间**——最高优先级，防止用户在长时间不
   使用后突然被"补播"仪式吓到；60 秒 TTL 一次改到位
2. **V3-P2-1 EditorPage 死代码清理**——推荐方案 A，代码干净是长期红利
3. **V3-P1-1 StatsPage / HomePage onPageShow 对齐**——产品拍板后一次改到位
4. **V3-P2-2 RippleTouch clipRadius 接入**——低优先级观感优化
5. **V3-P2-3 emit / enqueue 语义文档化**——纯注释，卫生工作

---

## Codex v3 执行记录（2026-07-14）

| 条目 | 状态 | 结论 |
| --- | --- | --- |
| V3-P1-1 页面重入策略 | 已完成（A） | `StatsPage.onPageShow` 不再调用 `playIntro`，与首页保持一致；两页都只在组件重新创建时分层入场，从子页返回仅刷新数据和消费事件。生命周期门禁已锁住两页的“不重播”策略。 |
| V3-P1-2 pending 过期 | 已完成 | pending 元素改为 `{ kind, enqueuedAt }`，TTL 固定为 60 秒；消费前静默清理过期事件，同 kind 再次入队会替换旧项并刷新时间戳。 |
| V3-P2-1 编辑页死代码 | 已完成（A） | 删除 `EditorPage` 的 `CeremonyBurst` import、状态、保存锁和不可达分支；保存成功后直接进入预览，待复盘归零仪式统一由首页消费。 |
| V3-P2-2 Ripple 圆角 | 基线已完成 | 指派描述与 `be1f978` 代码不符：复盘库两处及“我的”设置行已传 `AppMetrics.cardRadius`，`verify_ripple_layout_contract.mjs` 也已精确断言三处非零业务参数，本轮无需重复修改。 |
| V3-P2-3 事件契约 | 已完成 | 事件服务已写明 `emit` 即时派发并在未处理时排队、`enqueue` 直接排队、`consumePending` 由订阅流程驱动；待复盘归零调用点补充了必须直接排队的原因。 |

本地验证：聚焦动效门禁通过；`bash scripts/test_app.sh --quick` 通过 45/45；
`bash scripts/test_app.sh --all` 通过 62/62，主模块与 `entry@ohosTest` 均完成 ArkTS
编译和 HAP 打包。HDC 仍返回 `Connect server failed`，Stats 子页返回、60 秒过期和
首页仪式消费仍需设备恢复后做最终真机时序复测。

---



## v2 追加条目（针对 `31239c8` 复盘）

### V2-P0-1. `MotionCeremonyEventService` 缺失订阅时的兜底

- **类别**：排查 + 实现
- **问题**：`EditorPage.saveAndPreview` 里，当 `notifyPendingReviewCompleted` 判定"待复盘归零"
  时，会看 `handledBySubscriber` 决定是否**让位**给 HomePage 播 `review-done` 仪式。但如果
  emit 发生时 HomePage 尚未激活（用户还在 EditorPage，未返回 Home Tab），HomePage 的
  listener 里 `!this.isPageActive` 直接返回 false —— 结果 EditorPage 让位、HomePage 没接，
  用户完成复盘一次仪式都看不到。
- **动作**：二选一：
  - **方案 A（推荐）**：`MotionCeremonyEventService` 加一个"pending event"缓存。若 emit 时
    没有任何 listener 返回 true，把 event 存到内部队列；下次 `subscribe` 完成后立即
    重放最近一次未消费事件（每 kind 只留最新一条，避免堆积）。
  - **方案 B**：EditorPage 不再判断 `handledBySubscriber`，无条件播自己的 CeremonyBurst；
    HomePage listener 收到 `REVIEW_QUEUE_CLEARED` 时检查"最近 1500ms 内是否已经播过"，
    是则跳过。
- **完成判定**：
  - EditorPage 保存完成 → 返回 Home Tab → 一定看到一次 `review-done` 仪式（不多不少）
  - EditorPage 保存完成后直接从桌面 kill 应用再打开 → 不会看到"补播"的仪式（v2 版新
    increment 只服务于同一次进程内的连续场景）
  - `scripts/verify_motion_ceremony_hooks.mjs` 新增断言，锁住选定方案的关键代码位
- **锚点**：
  - `entry/src/main/ets/services/MotionCeremonyEventService.ets`
  - `entry/src/main/ets/pages/EditorPage.ets` `saveAndPreview` 中的
    `ceremonyHandledBySubscriber` 分支
  - `entry/src/main/ets/pages/HomePage.ets` 的 `ceremonyEventListener`
- **背景**：现在双方都用 `isPageActive` 保护，看似安全，实则**双方都可能跳过**。

### V2-P0-2. PreviewPage 导出菜单双重按压反馈冲突

- **类别**：排查 + 实现
- **问题**：`ExportSheetAction` 外层包了 `PressReactive({ intensity: 'firm' })`（做 spring
  scale），`ExportSheetActionContent` 内层保留了自己的 `pressedActionKey` +
  `onTouch(updatePressedAction)` + backgroundColor / shadow tween。两套系统同时跑：
  - PressReactive 触发 scale 0.92 → spring 回弹
  - 内层 pressedActionKey 触发 backgroundColor 立即翻转 + shadow 立即变高
  Cancel 按钮同理（`isPressed('cancel-export')` + `PressReactive` 双套）。
- **动作**：挑一套系统留下。**建议留 PressReactive、删内层**：
  - 删除 `ExportSheetActionContent` 里的 `updatePressedAction` / `isPressed(label)` 相关
    读写；`backgroundColor / shadow` 改为静态色（`AppColors.surfaceElevated` +
    `ElevationTokens.subtle`），保留 disabled 分支
  - Cancel 按钮同处理
- **完成判定**：
  - 真机上按下菜单项只有 spring scale 一种反馈；不再看到"背景色跳变 + 缩放"叠加
  - `pressedActionKey` 相关字段和方法在 PreviewPage 里所有导出菜单调用点被清理干净
  - 导出主按钮（外面那个"导出"按钮）**保留**原有 `pressedActionKey` 反馈——它没被
    `PressReactive` 包，逻辑独立，别误伤
- **锚点**：`entry/src/main/ets/pages/PreviewPage.ets` `ExportSheetAction` /
  `ExportSheetActionContent` / `CancelExportActionContent`
- **背景**：Codex 在 v1 执行记录里说"关闭原有缩放以避免双重反馈"，实际只删了 scale，
  没删背景色/阴影/onTouch 那套——一半没做完。

### V2-P1-1. StatsPage 补齐首屏分层入场（对称化）

- **类别**：实现
- **问题**：HomePage 在 v1 落地里补了 `playIntro` 并在 `onPageShow` 里重放；
  ProjectDetailPage 通过 `StaggeredEnter.aboutToAppear` 天然重放；**StatsPage 完全没做**。
  用户 Tab 切换轮流：Home 有入场、Library 有入场、Stats 突然没入场，观感断裂。
- **动作**：给 StatsPage 加 `playIntro`：
  - 分批：Header（0ms）→ LearningOverviewCard（`durationStagger`）→ OverviewCard
    （`durationStaggerLong`）→ Recent30DaysCard（`durationStaggerLong * 2`）→
    DistributionCard + BlockersCard（`durationStandard - durationStaggerLong`）
  - `aboutToAppear` + `onPageShow` 都触发一次；`aboutToDisappear` 清 timer
  - 每个 Section 外层挂 `opacity` + `translate` + `.animation(SPRING_SOFT)`
- **完成判定**：
  - Tab 切到 Stats 能看到 Section 依次入场
  - `scripts/verify_motion_narrative_hooks.mjs` 加断言 "StatsPage 引用 playIntro"
- **锚点**：`entry/src/main/ets/pages/StatsPage.ets`
- **背景**：方案 5.8 承诺过"骨架 → 内容"的分层入场，只做了 CountUpText，没做 Section
  stagger。

### V2-P1-2. `streak-record` 触发门槛提高到 ≥2 天

- **类别**：实现（小）
- **问题**：`updateReviewStreakRecord` 目前只在 `normalizedStreakDays <= 0` 时返回 false。
  用户**第一次完成复盘**时 `streakDays=1`、`previousRecord=0`，触发条件成立 → 播
  `streak-record` 仪式。**同一次保存**又会触发 `REVIEW_QUEUE_CLEARED`，两个仪式抢
  `ceremonyOccupied` slot，一个赢一个消失。而且"第一次复盘就破纪录"从产品语义上很怪。
- **动作**：把判断改成 `if (normalizedStreakDays < 2) return false;`。第一次复盘不算
  破纪录；从"连续 2 天"开始才算。
- **完成判定**：
  - 首次完成复盘不触发 `STREAK_RECORD` 事件
  - 连续 2 天完成时才会触发一次
  - `entry/ohosTest` 或 verify 脚本里加一条断言 `updateReviewStreakRecord` 有
    `< 2` 门槛
- **锚点**：`entry/src/main/ets/services/ReviewSettingsService.ets`
  `updateReviewStreakRecord`
- **背景**：不算 bug，是产品体验校准。

### V2-P1-3. 明确"从子页返回是否重放入场"的产品意图（决策 + 实现）

- **类别**：决策 + 实现
- **问题**：HomePage `playIntro` 现在会在**每次 `onPageShow`** 跑一遍——不只是 Tab
  切换，从 Editor 保存返回、从 HomeStorage 返回、从 MyPage 深处返回，都会看到入场。
  是想要的"叙事重播"，还是过度动效？
- **动作**：产品负责人拍板后二选一：
  - **方案 A（保持现状）**：每次 onPageShow 都重放；在方案文档里明确"从子页返回也算
    一次新叙事，需要再次入场"
  - **方案 B**：区分 Tab 切换 vs 子页返回。加一个静态标志（例如 `AppShellPage` 里维护
    `lastLeftTab: RootTabKey`），HomePage 在 `onPageShow` 里判断"上一次离开时是我这
    个 Tab 吗？是则不重放，不是则重放"
- **完成判定**：
  - 方案 A：本条目状态改为"维持现状"，写入 v3 追加执行记录
  - 方案 B：Home → Editor → 保存回 Home 不重放；Home → Library → Home 才重放
- **锚点**：`entry/src/main/ets/pages/HomePage.ets` `onPageShow`；如选 B，
  `entry/src/main/ets/pages/AppShellPage.ets`
- **背景**：v1 P1-9 只说"Tab 切换重放"，未定义子页返回；实施时 Codex 选了最宽松策略。

### V2-P2-1. `HomeStorageService.testConnection` 的 context 参数改必需

- **类别**：卫生
- **问题**：`testConnection(settings, context?)` 的可选参数只有 HomeStoragePage 一处调用，
  且**始终**传 context。可选签名带来 `if (context !== undefined)` 分支，读起来像是"有个
  地方不传 context"，实际没有。
- **动作**：把签名改成 `testConnection(settings: HomeStorageSettings, context:
  common.UIAbilityContext)`，删掉 `if` 保护。
- **完成判定**：
  - 全仓库 grep `testConnection(` 只有一处 HomeStoragePage 调用，且传两个参数
  - 编译通过、门禁通过
- **锚点**：`entry/src/main/ets/services/HomeStorageService.ets` `testConnection`；
  `entry/src/main/ets/pages/HomeStoragePage.ets` 调用点
- **背景**：可选参数是防御性写法，但此处没有多态需求。

### V2-P2-2. `MotionQualityContext.shouldPlayShatter` 空壳去留

- **类别**：卫生 + 决策
- **问题**：
  ```typescript
  static shouldPlayShatter(userEnabled: boolean): boolean {
    return userEnabled;
  }
  ```
  完全不看 MotionQuality 档位，等价于 `return userEnabled`。P2-13 决策明确保持独立，
  所以现在这个方法是纯预留位。
- **动作**：二选一：
  - **方案 A**：删掉方法，`ProjectDetailPage` 三处调用点改回直接读 `shatterEnabled`
  - **方案 B**：保留但在方法上方加注释：`// 预留：未来若决定 MotionQuality=MINIMAL
    时自动关闭星河效果，修改这里即可。当前仅镜像用户开关。`
- **推荐**：方案 B，改动最小、语义最清晰。
- **完成判定**：方法带明确注释；或方法被删且调用点全部改直读
- **锚点**：`entry/src/main/ets/theme/MotionQualityContext.ets` `shouldPlayShatter`；
  `entry/src/main/ets/pages/ProjectDetailPage.ets` 三处调用点

### V2-P2-3. `MotionCeremonyEventListener` 的单订阅约束显式化

- **类别**：卫生
- **问题**：当前实现允许同一 EventKind 被多个 listener 订阅，但语义上"handled"是 bool，
  无法区分谁接了。EditorPage 让位逻辑假设"只有唯一订阅方"。若未来 PreviewPage 也想接
  `REVIEW_QUEUE_CLEARED`，让位逻辑会出错。
- **动作**：在 `MotionCeremonyEventService.ets` 顶部加一段注释：
  ```typescript
  // 约束：每种 MotionCeremonyEventKind 只应有唯一订阅方。emit 返回的 handled 语义是
  // "该 kind 的唯一订阅方是否接住了这次事件"；不支持多方共同消费。
  ```
  同时在 `subscribe` 里可以加一个 dev-only 断言：如果同一 listener 引用被订阅两次，
  console.warn（当前的 `indexOf >= 0` 去重逻辑保留，无需改）。
- **完成判定**：注释存在；warn 出现
- **锚点**：`entry/src/main/ets/services/MotionCeremonyEventService.ets`
- **背景**：低概率争议，防御性文档。

### V2-P2-4. `StaggeredEnter` 5+ 批合并策略写入方案

- **类别**：文档
- **问题**：`EnterCoordinator.resolveBatchIndex` 内部用 `Math.min(4, ...)` 把第 5 项以后
  的元素全部塞进 batch 4——ProjectDetailPage 滚动到第 6 张卡片时，第 6 张 stagger
  delay 与第 5 张相同。**这是设计**（避免 100 张卡片入场时间过长），但方案文档没写。
- **动作**：在 `plan-motion-narrative-upgrade.md` §2.5 或 §4.2 章节补一段：
  > `StaggeredEnter` 最多分 5 批入场（batch 0..4）；同一 ForEach 中超过 5 项的元素
  > 会合并进 batch 4，即使 batchSize=1 也是如此。这是为避免超长入场序列，也解释了
  > 长列表滚动加载时"前几张依次入场，后面一批砸下来"的现象。
- **完成判定**：文档段落存在
- **锚点**：`docs/spec-for-codex/plan-motion-narrative-upgrade.md`
- **背景**：属于把已实现的隐含约束显式化。

---

## v2 建议派单顺序

1. **V2-P0-1 双方跳过导致漏播**——最高优先级，用户可能真的看不到复盘完成仪式
2. **V2-P0-2 Preview 双反馈冲突**——观感 bug，用户能立刻感知
3. **V2-P1-2 streak ≥2 天**——一行代码，顺手做掉
4. **V2-P1-3 子页返回重放决策**——需要产品拍板
5. **V2-P1-1 StatsPage 补 playIntro**——对称化
6. **V2-P2-1、V2-P2-2、V2-P2-3、V2-P2-4** 卫生 & 文档，可打包一个提交

---

## Codex v2 执行记录（2026-07-14）

| 条目 | 状态 | 结论 |
| --- | --- | --- |
| 现场列表行高回归 | 代码完成 | 根因是 `RippleTouch` 的 `Circle(240)` 参与父 `Stack` 测量，导致复盘库和“我的”每行被撑到 240vp。已改为 `.overlay(CustomBuilder)`，由业务内容决定行高，并按卡片圆角裁剪水波纹；新增 `verify_ripple_layout_contract.mjs`。真机截图复测待 HDC 恢复。 |
| V2-P0-1 事件兜底 | 代码完成 | 采用进程内 pending kind 缓存，每种事件只保留一条。待复盘归零直接排队，首页恢复或重建时消费；CALM/MINIMAL 会消费但不显示，避免切档后补播过期事件。 |
| V2-P0-2 导出双反馈 | 代码完成 | 导出菜单项和取消按钮删除内层 `pressedActionKey`、动态背景/阴影及原生 state effect，只保留外层 `PressReactive`；底部工具栏原反馈保持不变。 |
| V2-P1-1 统计页入场 | 已完成 | Header、学习进度、结果、最近 30 天、分布与卡点按五阶段入场；页面离开清理 timer，FULL/CALM/MINIMAL 继续服从统一动效上下文。 |
| V2-P1-2 连续纪录门槛 | 已完成 | 连续纪录触发门槛改为 `>= 2` 天，首次复盘不再触发纪录仪式。 |
| V2-P1-3 子页返回重放 | 已完成（B） | Tab 切换依靠 `AppShellPage` 条件重建继续重放；首页 `onPageShow` 不再调用 `playIntro`，从编辑等子页返回只刷新数据和消费待处理仪式。 |
| V2-P2-1 context 必需 | 已完成 | 指派中的“仅一处调用”与主干不符，实际还有 `SyncCenterPage` 和 `checkAvailability`。三处调用均已传入必需 context，成功连通统一记录首次 SMB 事件。 |
| V2-P2-2 星河空壳 | 已完成（B） | 保留 `shouldPlayShatter`，补充“当前仅镜像用户开关、未来在此扩展档位规则”的注释。 |
| V2-P2-3 单订阅约束 | 已完成 | 补充唯一消费方约束，重复 listener 注册会告警并尝试消费 pending 事件。 |
| V2-P2-4 五批策略 | 已完成 | 已在实际动效变更单 `docs/harmony/ui-change-motion-narrative-20260713.md` 写明最多五批及长列表合并策略。原指派锚点文件在当前仓库不存在。 |

本地验证：`bash scripts/test_app.sh --quick` 通过 45/45；`bash scripts/test_app.sh --all`
通过 62/62，主模块与 `entry@ohosTest` 均完成 ArkTS 编译和 HAP 打包。HDC 当前返回
`Connect server failed`，两页列表行高、导出菜单和仪式链路仍需设备恢复后做最终真机复测。

---

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
