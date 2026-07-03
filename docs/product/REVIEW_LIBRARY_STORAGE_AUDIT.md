# 复盘库与待复盘存储审计

更新时间：2026-07-04

本文只描述当前 HarmonyOS 仓库已经落地的本地数据结构与边界。

## 1. 当前主存储分层

### Review 主索引

- 主表：RDB `reviews`
- 主入口：`ReviewCardHistoryService`
- 存储对象：已保存复盘

### Pending 主索引

- 主表：RDB `pending_review_photos`
- 主入口：`PendingReviewPhotoStore`
- 存储对象：待复盘照片

### 当前冻结结论

- `Review` 和 `Pending` 当前是两层模型
- 两者可以在统计上关联
- 但当前主表、读写入口和页面筛选语义都不混用

## 2. ReviewCardStore 的职责

- 在首页、编辑页、阅读页之间暂存当前工作副本
- 创建单张照片草稿
- 创建来自待复盘照片的草稿
- 不负责长期持久化

它不是复盘库主索引，也不是待复盘主索引。

## 3. ReviewCardHistoryService 的职责

- 保存、更新、删除已保存复盘
- 优先从 RDB `reviews` 读取历史
- 维护 `exportedPath`
- 写入 `review_exchange` 沙箱备份
- 在必要时处理旧数据迁移与有限恢复

页面层当前通过它读取已保存复盘，而不是直接读取沙箱 JSON。

## 4. PendingReviewPhotoStore 的职责

- 新增待复盘照片
- 多选导入待复盘照片
- 列出当前待复盘照片
- 删除待复盘照片
- 在正式保存复盘后把对应任务标记为 `reviewed`
- 输出待复盘统计

当前 `待复盘` 视图完全依赖它。

## 5. 当前统计边界

### 学习进度

数据源：

- `PendingReviewPhotoStore.getStats(...)`
- `ReviewCardHistoryService.load(...)`

当前口径：

- `待复盘 = pendingCount`
- `已完成 = Review 总数`
- `累计导入 = pendingCount + Review 总数`

### 复盘结果

只读取已保存 `Review`。

因此当前必须明确：

- `Pending` 不计入判断分布
- `Pending` 不计入最近 30 天复盘结果
- `Pending` 不计入最近卡点

## 6. review_exchange 的职责

`review_exchange/*.review.json` 当前是：

- 沙箱备份
- 交换副本
- 有限恢复来源

当前不是：

- 本地复盘库主索引
- 待复盘主索引

## 7. Preferences 的职责

`Preferences(review_card_history.items)` 当前只保留：

- 旧版本迁移来源
- 诊断用途

当前不再承担：

- 已保存复盘主写
- 已保存复盘主读
- 待复盘主读写

## 8. 删除语义

### 删除已保存复盘

当前删除的是：

- RDB `reviews` 中的对应记录
- 对应沙箱 `review_exchange` 备份

当前不会自动删除：

- 原始照片
- 已导出 JPG
- 用户导出的 `review.json`
- 家庭存储复盘包

### 删除待复盘照片

当前删除的是：

- RDB `pending_review_photos` 中的对应记录

它不会影响：

- 已保存复盘
- 导出的历史文件

## 9. 仍需注意的风险

- `imageUri` 与 `photoUri` 都是引用路径，不是原图归档副本；外部资源失效后可能无法继续显示原图。
- `review_exchange` 仍保留恢复语义，因此清理备份策略要谨慎，不能误删仍有恢复价值的数据。
- 当前 `reviewed` 状态会从待复盘列表退出，但不会额外形成一张“待复盘完成历史表”；后续如果要做学习轨迹，需要新增读模型，不能直接改写现有语义。
