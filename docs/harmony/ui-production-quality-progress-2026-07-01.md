# UI 生产级品质目标进度盘点

日期：2026-07-01

范围：对照 2026-06-30 的《UI生产级品质提升方案》，盘点 `skymap-HarmonyOS` 当前代码状态。

## 总结

当前进度约为 **65%**。

已完成的核心价值集中在：设计系统基础、共享按钮/卡片反馈、复盘输入焦点态、首页首屏、预览页操作栏、统计页数据呈现、我的页设置层级。

仍未完成的关键差距集中在：骨架屏、页面转场、组件去重、导出复盘卡片渲染 token 统一、首页流程卡片模块、全量视觉回归清单。

## 任务对照

| Task | 目标 | 当前状态 | 完成度 |
| --- | --- | --- | --- |
| 1 | 建立完整设计系统 | 已新增 `SpacingTokens`、`RadiusTokens`、`ElevationTokens`、`MotionTokens`，`AppColors/AppMetrics` 已接入关键 token。 | 90% |
| 2 | 核心组件库升级 | `PrimaryButton`、`SecondaryButton`、`DangerButton`、`SettingsLinkRow`、`ProjectHomeCard`、`RecentReviewCard`、`ProjectReviewCard`、`InfoBlockCard` 已有阴影与按压反馈；`EmptyState` 已升级但未支持 icon prop。 | 80% |
| 3 | 输入组件体验升级 | `ReviewInputForm` 已有 `focusedField`、焦点边框、焦点阴影、背景变化、动画、输入间距优化；`Select` 也接入焦点态。 | 95% |
| 4 | 首页全面打磨 | Hero 图片、渐变、标题、副标题、共享主按钮、tag 阴影已落地；但目标中的流程卡片 `ReviewFlowPanel` 当前未体现，tag 高度/间距也比目标更保守。 | 70% |
| 5 | 编辑页打磨 | 照片区阴影、保存区独立层级、键盘避让与滚动体验已明显加强；页面级常量仍较多，底部区域未做毛玻璃，只做了卡片层级。 | 70% |
| 6 | 预览页打磨 | 浮动操作栏使用 `ElevationTokens.high`，按钮按压动画、导出菜单操作项反馈已落地；未做 `backdropBlur`，导出格式切换的复杂选中态仍有限。 | 75% |
| 7 | 统计页数据可视化升级 | 概览数字、判断分布进度条、最近记录透明度衰减已落地；空状态还没有“去创建第一条复盘” CTA。 | 80% |
| 8 | 我的页面升级 | `SettingsLinkRow` 语义 badge、阴影、按压反馈、诊断高亮卡片已落地；section 背景层级只是局部体现。 | 75% |
| 9 | 复盘卡片渲染组件打磨 | 移动阅读卡仍使用 `ReviewCardStyleTokens` 自己的 shadow 数值，没有统一到 `ElevationTokens`；内部间距也未系统接入 `SpacingTokens`。 | 35% |
| 10 | 组件去重与结构优化 | `RecentReviewCard` 与 `ProjectReviewCard` 仍是近似重复实现；`ReviewPhotoBlock / ReviewPhotoArea` 仍保持薄封装关系，未做职责收口。 | 20% |
| 11 | 页面过渡动画 | 未发现 `pageTransition` / `PageTransitionEnter` / `PageTransitionExit` 落地。 | 0% |
| 12 | 加载态与骨架屏 | 未发现 `SkeletonBlock` 或 shimmer loading 组件；Home/Stats/ProjectDetail 仍未按目标做骨架态。 | 0% |
| 13 | 验证脚本更新与全面验证 | `verify_compact_ui_tokens.mjs`、`verify_editor_writing_experience.mjs`、`verify_stats_feedback.mjs` 已覆盖部分新 token 和页面反馈；还没有覆盖骨架屏、页面转场、复盘卡片 token 统一等目标。 | 55% |

## 已完成

- 设计系统基础已成型：`DesignTokens.ets` 包含字体、行高、布局、间距、圆角、阴影、动效 token。
- 公共视觉语言已开始统一：`AppDesign.ets` 里按钮、设置行、列表卡、信息卡都接入了阴影和按压反馈。
- 输入体验已有生产级基础：`ReviewInputForm.ets` 中标题、TextArea、Select 都有焦点边框、焦点阴影和快速动画。
- 首页首屏完成了第一轮品质提升：Hero 图片化、渐变层次、共享主按钮、feature tags 微阴影已经落地。
- 编辑页已经解决移动端长文本输入的关键体验：键盘出现、字段聚焦、长文本增长时会滚动保持可见。
- 预览页核心操作区已经从“普通按钮”升级为浮动操作栏，并带有按压反馈和高层级阴影。
- 统计页从占位信息升级为真实数据表达，包括概览卡、30 天卡、判断分布、卡点、最近复盘。
- 我的页已从普通列表升级为设置入口矩阵，状态 badge 和开发诊断入口有明确层级。
- 验证脚本已开始固化 UI token、编辑体验、统计反馈、预览操作反馈等回归点。

## 未完成

- `SkeletonBlock` / shimmer 骨架屏未实现，加载态仍是主要短板。
- 页面转场动画未实现，页面切换仍缺少统一动效策略。
- `RecentReviewCard` 与 `ProjectReviewCard` 未合并，公共列表卡仍有重复代码。
- `MobileReadingReviewCard` / `ReviewCardStyleTokens` 未接入 `ElevationTokens` 和 `SpacingTokens`。
- `EmptyState` 未支持 icon，也未内置 CTA 能力。
- 统计页空状态缺少“去创建第一条复盘”的操作闭环。
- 首页目标中的流程卡片模块没有在当前首页继续呈现，需确认是产品方向调整还是遗漏。
- 验证脚本还没覆盖 Task 9-12 的关键目标。

## 风险

- 当前工作区已有 4 个未提交页面文件改动：`HomeStoragePage.ets`、`MyPage.ets`、`ReviewerProfilePage.ets`、`SyncCenterPage.ets`。本盘点未将这些改动提交进结论，应在下一轮确认其来源后再收口。
- 视觉品质提升已覆盖多个页面，但缺少真机截图或设计验收截图，当前判断主要基于代码结构和静态验证。
- 阴影和动画 token 已落地，但如果 ArkUI 不同设备上的阴影表现有差异，仍需要真机回归确认。

## 下一轮优先级

1. 做 Task 12：新增 `SkeletonBlock`，先覆盖 Home / Stats / ProjectDetail 三个加载态。
2. 做 Task 10：合并 `RecentReviewCard` 与 `ProjectReviewCard`，减少后续列表样式漂移。
3. 做 Task 9：让 `MobileReadingReviewCard` 和导出卡片阴影/间距接入统一 token。
4. 做 Task 13：把骨架屏、页面转场、复盘卡片 token 统一写进验证脚本。
5. 最后再做 Task 11：补页面转场动画，避免在基础组件尚未完全收口时扩大动效面。

