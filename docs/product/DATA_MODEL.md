# 当前数据模型

本文只保留当前 HarmonyOS 代码已经落地的数据对象，不再保留模板系统、预设系统、路线图级同步模型等未来概念。

## 1. Review

`Review` 表示一条已经完成并保存的摄影复盘。

当前真实承载对象：

- `ReviewCardDocument`
- `ReviewCardHistoryItem`
- RDB `reviews`

### 当前稳定字段语义

| 字段 | 说明 |
| --- | --- |
| `imageUri` | 被复盘照片的引用路径，不是原图归档副本 |
| `imageWidth / imageHeight` | 当前照片尺寸，用于阅读和导出布局 |
| `content.title` | 复盘标题 |
| `content.visualFocus` | 视觉落点 |
| `content.focusReason` | 落点原因 |
| `content.visualPath` | 视线路径 |
| `content.visibleFacts` | 画面事实 |
| `content.coreRelation` | 核心关系 |
| `content.judgement` | 是否成立，当前归一化到成立 / 待判断 / 不成立 |
| `content.extendedUnderstanding` | 延伸理解 |
| `content.currentBlocker` | 当前卡点 |
| `createdAt / updatedAt` | 创建与最近更新时间 |
| `exportedPath` | 最近一次导出结果引用，不等于原图路径 |

### 当前边界

- `Review` 是已保存复盘，不是待复盘任务。
- `Review` 主索引在 RDB `reviews`。
- `review.json` 可以表达同一条复盘，但不是本地复盘库主查询源。

## 2. PendingReviewPhoto

`PendingReviewPhoto` 表示一张已经导入、但尚未完成正式复盘的照片。

当前真实承载对象：

- `PendingReviewPhoto`
- RDB `pending_review_photos`

### 当前稳定字段语义

| 字段 | 说明 |
| --- | --- |
| `id` | 待复盘任务标识 |
| `photoUri` | 待复盘照片引用 |
| `fileName` | 文件名 |
| `width / height` | 读取到的图片尺寸 |
| `orientation` | 横图 / 竖图 / 方图 / unknown |
| `importTime` | 导入时间 |
| `status` | `pending` 或 `reviewed` |
| `linkedReviewId` | 完成正式复盘后关联的 Review 标识 |

### 当前边界

- `PendingReviewPhoto` 不参与 `复盘结果` 判断分布。
- 从待复盘进入编辑并保存后，会标记为 `reviewed`。
- 当前库内 `待复盘` 筛选读取的是这张表，不是 `reviews` 表。

## 3. LearningStats

统计页的 `学习进度` 不是一张独立表，而是由两个真实数据源组合出来的读模型：

- `PendingReviewPhotoStore.getStats(...)`
- `ReviewCardHistoryService.load(...)`

当前口径：

| 指标 | 计算方式 |
| --- | --- |
| 待复盘 | `pendingCount` |
| 已完成 | `Review` 总数 |
| 累计导入 | `pendingCount + Review 总数` |
| 完成率 | `已完成 / 累计导入` |

## 4. ReviewResultStats

统计页 `复盘结果` 只基于已保存 `Review` 构建。

当前输出包括：

- 累计复盘
- 成立
- 待判断
- 不成立
- 最近 30 天分布
- 最近卡点

当前必须冻结：

- 不再使用 `学习概览 / 复盘质量`
- 不把 `Pending` 混入 `复盘结果`

## 5. ReviewJsonBackup

`review_exchange/*.review.json` 是当前应用沙箱中的备份与交换副本。

当前职责：

- 保存或更新复盘时额外生成一份 JSON 备份
- 作为有限恢复来源
- 作为导出 `review.json` 的一致字段来源

当前边界：

- 不是本地复盘库主索引
- 不替代 `reviews`

## 6. ReviewBundle

当前代码已经支持两类外部复盘包导出：

- 复盘包
- 含原图的复盘包

它们都是导出产物，不是本地复盘库主模型。

当前共同边界：

- 承载 `review.json` 和相关导出文件
- 写入家庭存储配置目标
- 不回写进本地 `Review` 数据结构

协议边界见：

- [`REVIEW_BUNDLE_V1_V2_CONTRACT.md`](./REVIEW_BUNDLE_V1_V2_CONTRACT.md)
- [`REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md`](./REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md)

## 7. HomeHeroImageConfig

首页图片配置是当前独立的小型配置模型，不属于复盘主索引。

当前职责：

- 保存首页 Hero 图片列表
- 控制是否自动轮播
- 控制轮播间隔

当前边界：

- 不写入 `Review`
- 不写入 `PendingReviewPhoto`
- 不影响统计口径
