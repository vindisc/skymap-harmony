# 产品文档索引

本目录只保留仍然对应当前 HarmonyOS 代码实现的正式文档。

## 当前必读

- `CURRENT_PRODUCT_SPEC.md`
  - 当前产品定位、主入口、核心能力、统计口径和冻结边界
- `DATA_MODEL.md`
  - 当前真实数据模型：`Review`、`PendingReviewPhoto`、首页图片配置、导出产物
- `REVIEW_LIBRARY_STORAGE_AUDIT.md`
  - 当前本地复盘库主存储、备份、恢复、Pending / Review 分层和删除边界
- `REVIEW_JSON_SEMANTICS.md`
  - `review.json` 字段语义与 Harmony 当前责任

## 当前专项文档

- `REVIEW_BUNDLE_V1_V2_CONTRACT.md`
  - 当前复盘包导出协议边界
- `REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md`
  - 当前含原图复盘包说明
- `HOME_HERO_IMAGE_CONFIG_V1.md`
  - 首页 Hero 图片配置能力说明

## 本轮已移出正式层的文档类型

以下类型已经从当前正式文档中清理掉：

- 路线图
- 愿景文档
- 阶段性进度盘点
- 历史迁移方案
- 中间态验收清单
- 主要描述 Mac 或跨端未来规划的文档

如果需要追溯历史决策，应查看 Git 历史，而不是把旧草案继续保留在当前入口中。
