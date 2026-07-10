# 产品文档索引

本目录只保留仍然对应当前 HarmonyOS 代码实现的正式文档。全仓文档角色和权威顺序见 [`docs/README.md`](../README.md)。

## 当前必读

- `CURRENT_PRODUCT_SPEC.md`
  - 当前产品定位、主入口、核心能力、统计口径和冻结边界
- `DATA_MODEL.md`
  - 当前真实数据模型：`Review`、`PendingReviewPhoto`、首页图片配置、导出产物
- `REVIEW_LIBRARY_STORAGE_AUDIT.md`
  - 当前本地复盘库主存储、备份、恢复、Pending / Review 分层和删除边界
- `REVIEW_JSON_SEMANTICS.md`
  - `review.json` 字段语义与 Harmony 当前责任
  - 完整字段表见 [`ReviewCardExchangeSchema v1`](../review-card-exchange-schema.md)

## 当前专项文档

- `REVIEW_BUNDLE_V1_V2_CONTRACT.md`
  - 复盘包 v1 / v2 文件结构和兼容规则的唯一权威基线
- `REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md`
  - v2 含原图导出实现的专项补充，不覆盖主契约
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

## 版本与跨端边界

- `Review JSON Schema v1` 定义 `review.json` 正文字段。
- `Review Bundle v1 / v2` 定义复盘包容器，两个版本当前都承载 Schema v1 的 `review.json`。
- 协议文档中的 Mac 行为是消费者兼容约束，不代表 HarmonyOS 仓库实现了 Mac 端能力。
- 应用版本、Bundle 版本和 Review JSON Schema 版本彼此独立。
