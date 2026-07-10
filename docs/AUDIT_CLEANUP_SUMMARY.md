# 文档审计与收口总结

更新时间：2026-07-09

## 1. 本轮审计范围

- `README.md`
- `docs/`
- `docs/product/`
- `docs/harmony/`
- 构建与文档校验脚本说明
- 与首页、待复盘、复盘库、统计、`review.json`、复盘包相关的 Markdown

## 2. 本轮删除的文档

以下文档已删除，原因是它们属于未来规划、历史阶段盘点、跨端中间方案、临时验收清单，或已经不能作为当前 Harmony 代码的正式事实来源：

- `docs/product/CHANGE_RULES.md`
- `docs/product/FEATURE_MATRIX.md`
- `docs/product/HARMONYOS_V0_BASELINE.md`
- `docs/product/REVIEW_BUNDLE_STORAGE_BROWSER.md`
- `docs/product/REVIEW_BUNDLE_V1_DESIGN.md`
- `docs/product/REVIEW_BUNDLE_V1_E2E_CHECKLIST.md`
- `docs/product/REVIEW_BUNDLE_V1_V2_E2E_CHECKLIST.md`
- `docs/product/REVIEW_LIBRARY_V1_1.md`
- `docs/product/ROADMAP.md`
- `docs/product/SYNC_SYSTEM_V1.md`
- `docs/product/SYNC_V0_MANUAL_EXCHANGE.md`
- `docs/product/UI_INTERACTION_GUIDE.md`
- `docs/product/VISION.md`
- `docs/product/WORKFLOW.md`
- `docs/harmony/ui-production-quality-progress-2026-07-01.md`

删除原则：

- 不是当前实现契约，只是阶段记录或未来设想
- 主要描述 Mac 侧或跨端计划，不是本仓库当前运行事实
- 与“代码是唯一事实来源”的收口目标不一致

## 3. 本轮合并与替换

- 用 `docs/product/CURRENT_PRODUCT_SPEC.md` 替代旧的版本阶段说明，统一记录当前产品定位、入口、能力边界和冻结口径。
- 用更新后的 `docs/product/DATA_MODEL.md` 收口当前真实数据模型，不再保留模板、预设、路线图级产品模型噪音。
- 用更新后的 `docs/product/README.md` 作为正式文档索引，不再把已删除文档继续当作当前入口。

## 4. 本轮更新的文档

- `README.md`
- `docs/mobile-main-flow.md`
- `docs/review-card-template-spec.md`
- `docs/product/README.md`
- `docs/product/CURRENT_PRODUCT_SPEC.md`
- `docs/product/DATA_MODEL.md`
- `docs/product/REVIEW_JSON_SEMANTICS.md`
- `docs/product/REVIEW_LIBRARY_STORAGE_AUDIT.md`
- `scripts/verify_product_docs_cleanup.mjs`

## 5. 当前保留的文档结构

正式入口：

- `README.md`
- `docs/AUDIT_CLEANUP_SUMMARY.md`

当前实现说明：

- `docs/mobile-main-flow.md`
- `docs/review-card-template-spec.md`
- `docs/review-card-exchange-schema.md`

正式产品文档：

- `docs/product/README.md`
- `docs/product/CURRENT_PRODUCT_SPEC.md`
- `docs/product/DATA_MODEL.md`
- `docs/product/REVIEW_JSON_SEMANTICS.md`
- `docs/product/REVIEW_LIBRARY_STORAGE_AUDIT.md`
- `docs/product/REVIEW_BUNDLE_V1_V2_CONTRACT.md`
- `docs/product/REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md`
- `docs/product/HOME_HERO_IMAGE_CONFIG_V1.md`

当前设计基线：

- `docs/harmony/main-tabs-ui-baseline-20260628.md`

## 6. 本轮明确冻结的口径

- 统计页正式命名统一为 `学习进度 / 复盘结果`
- `Pending = 待复盘任务`
- `Review = 已保存复盘结果`
- 统计可以关联，但当前模型不混淆
- 首页当前是双入口并行：
  - `导入照片，开始复盘`
  - `导入待复盘`
- 待复盘当前支持多选导入，不再保留“待复盘不支持批量导入”的旧说法

## 7. 文档边界风险（2026-07-10 已闭环）

- v1 / v2 只表示 Review Bundle 容器版本，`review.json` 单独固定为 `Review JSON Schema v1`，两条版本轴已在总索引和主契约中分离。
- `review-card-exchange-schema.md` 已收口为 HarmonyOS 当前生成字段契约；Mac 等消费端行为只作为兼容约束，不再写成当前仓库已实现能力。
- `docs/harmony/main-tabs-ui-baseline-20260628.md` 已明确为带日期的验收快照，并补充结构变更后的替换规则。
- `docs/README.md` 作为唯一总入口，明确当前实现、协议、UI 快照和历史记录的权威顺序。
- `scripts/verify_product_docs_cleanup.mjs` 对上述角色声明和版本关系执行自动校验。

## 8. 后续建议继续冻结或收回的能力

- 不要把自动同步、云同步、AI、标签、多版本复盘这类未来能力重新写进当前正式文档。
- 不要把 Mac 侧导入、浏览器、扫描器行为写成 Harmony 当前能力。
- 不要再引入按阶段堆积的 `roadmap / audit / progress / freeze` 文档，除非它们直接服务当前代码验收。

## 9. 2026-07-09 提审后补充收口

当前 HarmonyOS 端已经提交华为审核，等待审核结果。本轮仅补充文档层收口，不调整代码和签名配置。

本轮新增：

- `docs/RELEASE_CLOSURE_20260709.md`
  - 记录 0.1.0 提审后收口边界
  - 说明发布 / 测试签名切换要求
  - 列出待补充文档
  - 给出下一版本 P0 / P1 / P2 建议优先级

本轮修正：

- `docs/product/REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md`
  - 移除“后续新增入口 / 本阶段暂不要求 HarmonyOS 真实 v2 导出闭环”的旧表述
  - 改为当前已支持 `导出复盘包（含原图）` 的说明

本轮未直接删除：

- 根目录未跟踪的卡片 UI 草案 Markdown
- `.DS_Store`
- `release-assets/` 下未跟踪发布素材和签名中间文件

原因是这些文件不在正式文档入口中，且部分可能属于提审现场素材。本轮只在收口文档中列为建议归档 / 删除项，避免误删用户当前工作区内容。
