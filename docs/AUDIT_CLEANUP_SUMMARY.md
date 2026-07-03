# 文档审计与收口总结

更新时间：2026-07-04

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

## 7. 当前代码与文档仍有风险点

- 复盘包相关文档仍保留 v1 / v2 命名，因为当前代码确实存在这两条导出链路；如果后续只保留一条，需要再次收口命名。
- `review-card-exchange-schema.md` 仍带有跨端协议语境，虽然当前字段定义有效，但若以后协议层再精简，需同步收口。
- `docs/harmony/main-tabs-ui-baseline-20260628.md` 属于验收基线快照，不是产品需求文档；如果 UI 结构再次调整，需要更新截图或移除。

## 8. 后续建议继续冻结或收回的能力

- 不要把自动同步、云同步、AI、标签、多版本复盘这类未来能力重新写进当前正式文档。
- 不要把 Mac 侧导入、浏览器、扫描器行为写成 Harmony 当前能力。
- 不要再引入按阶段堆积的 `roadmap / audit / progress / freeze` 文档，除非它们直接服务当前代码验收。
