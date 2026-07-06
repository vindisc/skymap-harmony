# 服务卡片样式锁定说明

这三张桌面服务卡片样式已按用户确认稿固化：

- `LearningProgressMediumCard.ets`：2*2 左侧小卡，只展示“摄影学习 / 待复盘数量 / 待复盘”。
- `TodayReviewCard.ets`：2*2 右侧小卡，展示“今日待复盘 / 数量 / 继续复盘按钮”。
- `LearningProgressSummaryMediumCard.ets`：2*4 中型卡，保留紧凑指标区和底部按钮留白。

保护规则：

- 没有用户在当前对话里明确要求修改这些卡片样式，不允许改动上述三个文件的视觉结构、尺寸常量、文案、按钮形态和留白。
- 常规功能改动、路由改动、数据刷新改动不得顺手调整这些卡片样式。
- 如果用户明确要求改样式，必须同步更新 `scripts/verify_widget_style_lock.mjs` 里的 SHA-256 快照，并在提交说明里写明“用户明确要求修改卡片样式”。
- 提交前必须运行 `node scripts/verify_widget_style_lock.mjs` 和 `node scripts/verify_learning_progress_widget.mjs`。

这份锁定是为了防止“修一个卡片、带坏另一个卡片”的回归。
