# 文档导航与权威边界

本页是 `docs/` 的唯一总入口，用于区分当前实现、协议契约、验收快照和历史记录。代码与自动校验始终是当前行为的最终事实来源。

## 权威顺序

遇到文档冲突时，按以下顺序判断：

1. 当前代码、数据迁移和自动校验。
2. 当前产品说明与数据模型。
3. 序列化格式和复盘包协议。
4. UI 验收快照与变更规则。
5. 发布记录、审计记录和历史收口总结。

低层级文档不能覆盖高层级事实。发布记录和审计总结只用于追溯，不作为新增需求来源。

## 当前文档地图

| 文档类型 | 权威入口 | 角色 |
| --- | --- | --- |
| 当前产品 | [产品文档索引](./product/README.md) | 当前已落地能力、数据模型和存储边界 |
| 手机主流程 | [手机端主流程](./mobile-main-flow.md) | 当前用户入口和页面流转 |
| Review JSON | [Review JSON 语义说明](./product/REVIEW_JSON_SEMANTICS.md) | `review.json` 的职责与字段语义 |
| 复盘包协议 | [复盘包 v1 / v2 契约](./product/REVIEW_BUNDLE_V1_V2_CONTRACT.md) | v1 / v2 文件结构和兼容规则的唯一权威基线 |
| UI 治理 | [UI 收口规则](./harmony/UI_CLOSURE_RULES.md) | UI 变更准入、验收和重新冻结流程 |
| 历史 UI 快照 | [2026-06-28 四个主 Tab UI 基线](./harmony/main-tabs-ui-baseline-20260628.md) | 验收快照，不是产品需求文档；只追溯当日真机证据 |
| 当前 UI 变更 | [2026-07-13 叙事化动效变更单](./harmony/ui-change-motion-narrative-20260713.md) | 当前候选实现与剩余真机验收项 |
| 发布工程 | [发布文档索引](./release/README.md) | 签名隔离、审核反馈和 HAP 归档 |
| 历史记录 | [文档审计总结](./AUDIT_CLEANUP_SUMMARY.md)、[0.1.0 收口记录](./RELEASE_CLOSURE_20260709.md) | 只追溯当时决策，不定义当前能力 |

## 两条独立版本轴

`Review JSON Schema v1` 与 `Review Bundle v1 / v2` 不是同一个版本号：

| 对象 | 当前版本 | 表达内容 |
| --- | --- | --- |
| `review.json` | Review JSON Schema v1 | 复盘正文字段和字段语义 |
| 成品图复盘包 | Review Bundle v1 | `manifest.json`、Schema v1 的 `review.json`、`thumb.jpg` |
| 原图复盘包 | Review Bundle v2 | `manifest.json`、Schema v1 的 `review.json`、原图文件 |

Bundle 升级不自动升级 Review JSON Schema。应用版本、Bundle 版本和 Review JSON Schema 版本也不得互相代替。

## 跨端边界

本仓库只对 HarmonyOS 当前代码和导出产物负责。协议文档中的 Mac 行为属于跨端兼容约束，用于说明消费者应如何解释产物，不代表本仓库实现或验证了 Mac 端功能。

涉及跨端变化时：

- HarmonyOS 代码与本仓库校验负责保证导出结构。
- 消费端仓库负责验证导入、恢复和兼容行为。
- 双端都验证后，才能修改复盘包契约中的共同语义。

## 维护规则

- 当前产品文档只写已经落地的能力，不写路线图、愿景或阶段计划。
- 自动同步、云同步、AI、标签和多版本复盘等未来能力不得写成当前事实。
- v1 / v2 只用于复盘包协议；Review JSON 字段版本统一写作 `Review JSON Schema v1`。
- UI 截图必须带日期和适用范围。结构变更验收通过后，应新增或替换快照并同步变更记录。
- 日期只标识证据发生时间；测试夹具可使用固定日期，可执行门禁不得用日期文件名承载临时发布预期。
- 历史判断通过 Git 历史和收口记录追溯，不重新进入当前产品入口。

文档边界校验：

```bash
node scripts/verify_product_docs_cleanup.mjs
```
