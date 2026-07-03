# 摄影复盘卡模板说明

本文只记录当前 HarmonyOS 端复盘卡的真实渲染与导出路径。

## 1. 当前目标

当前复盘卡用于把一张照片和一次摄影判断组织成两种稳定表达：

- 手机阅读卡
- 导出长图卡

它们共用同一份 `ReviewCardDocument`，但不共用同一套页面状态。

## 2. 当前输入来源

当前有两种进入复盘卡的方式：

### 直接复盘

- 首页 `导入照片，开始复盘`
- 系统相册单选
- 进入编辑页

### 待复盘转正式复盘

- 首页 `导入待复盘`
- 系统相册多选并写入待复盘列表
- 从复盘库 `待复盘` 筛选打开某一张照片进入编辑页

当前已经支持待复盘多选导入，不再保留单选限制说法。

## 3. 当前文档模型

当前统一使用 `ReviewCardDocument`：

- 一份文档贯穿编辑、阅读和导出
- 保存后进入 `ReviewCardHistoryItem`
- 导出状态通过 `exportedPath` 附着在历史项上

## 4. 当前阅读路径

- 预览 / 阅读使用 `ReviewCardRenderMode.MOBILE_READING`
- `ReviewCardRenderer` 在该模式下选择 `MobileReadingReviewCard`
- 阅读页展示已填写字段；空字段不显示

## 5. 当前导出路径

- 导出使用 `ReviewCardRenderMode.EXPORT_CARD`
- `ReviewCardRenderer` 在该模式下统一选择 `LongFormExportReviewCard`
- 当前横图、竖图、方图都走同一条导出主链路
- `LongFormExportReviewCard` 再按图片方向决定横向信息面板或单列长图结构

因此当前必须明确：

- 导出主链路不是 `ExportHorizontalReviewCard / ExportVerticalReviewCard / ExportSquareReviewCard`
- 修改导出样式时，应先确认实际截图节点与 `renderMode`

## 6. 当前版式边界

### 手机阅读卡

- 面向手机内阅读
- 强调纵向可读性
- 不要求和导出图完全同构

### 导出长图卡

- 面向相册保存与外部分享
- 清理按钮、占位文案、状态提示和页面噪音
- 横图、竖图、方图按当前导出组件内规则适配

## 7. 当前不做

- 不把页面操作栏截图进导出图
- 不为不同方向维护三条并行导出主链路
- 不把待复盘任务直接渲染成已完成复盘卡
