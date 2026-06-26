# Review JSON Semantics

## 目标

本文把 `review.json` 从“字段名一致”进一步收敛为“产品语义一致”。

约束：

- 不改 v1 字段名。
- 产品字段语义独立于某个客户端当前的内部结构。
- Mac sidecar、Harmony 轻量交换 JSON、未来同步链路都必须复用同一份字段定义。

## 三层边界

同一个 Review 字段会出现在不同层级，但用户看到的含义不能变化：

1. 产品字段：Review 这个对象真正表达什么。
2. 交换表示：当前 `review.json` v1 如何把这些字段写出去。
3. 客户端展示：Mac 和 Harmony 如何把同一字段展示给用户。

当前 v1 的已知表示差异：

- `titleText`、`decision`、`firstLookText` 等字段，既是产品字段，也是 Mac sidecar 顶层摘要字段。
- `reviewTimeText`、`reviewerText` 同样是产品字段，但在 Mac sidecar 中主要依赖 `templateConfig` 承载，不是当前顶层摘要字段。
- Harmony 当前复制 JSON 采用扁平轻量表示，把这 11 个字段都直接写出。

因此，是否出现在某一层级，不等于它是否属于产品字段。

## 通用规则

- 字段名保持 v1 不变。
- 空值不删除 key，除非当前载体根本不承载该层字段。
- 不为缺失字段编造新文案，只做保底归一化。
- `decision` 是唯一必须走枚举归一化的字段；其标准输出值只有 `works`、`notWorks`、`uncertain`。
- Mac 导入时若同时存在顶层摘要字段和 `templateConfig` 同名字段，摘要字段负责覆盖同名复盘正文；`reviewTimeText`、`reviewerText` 仍依赖 `templateConfig` 恢复。
- Harmony 导出时即使阅读页或导出图不展示空字段，复制/导出的 `review.json` 仍要保留对应 key，并使用空字符串表示空值。

## 与 HarmonyOS 复盘库存储的关系

`review.json` 是交换和备份格式，不等于 HarmonyOS 端复盘库主查询源。

当前 HarmonyOS 端需要明确：

- 复盘库主索引是 RDB，`load` 主读 RDB，保存、更新、删除和导出标记主写 RDB
- `Preferences(review_card_history.items)` 只作为旧版本数据迁移来源，不再是复盘库主索引
- `review_exchange/*.review.json` 会作为沙箱备份存在，也是交换和有限恢复来源
- 当前已经存在有限自动恢复逻辑，会在特定条件下扫描 `review_exchange` 并把恢复结果写入 RDB
- 详细存储、删除和恢复语义见 [`REVIEW_LIBRARY_STORAGE_AUDIT.md`](./REVIEW_LIBRARY_STORAGE_AUDIT.md)

## 字段语义矩阵

| 字段 | 用户含义 | 是否必填 | 空值策略 | Mac 展示责任 | Harmony 展示责任 | 导入导出责任 |
| --- | --- | --- | --- | --- | --- | --- |
| `titleText` | 这次复盘想回答的核心问题或标题。 | 产品必填 | 缺失时优先使用模板默认标题；导出时保留 key，不编造新标题。 | 在复盘卡标题区展示；导入旧记录时负责兜底到可读标题。 | 在编辑页、阅读页、导出图展示；允许用户修改。 | Mac sidecar 顶层摘要字段必须写；Harmony 轻量 JSON 必须写。 |
| `reviewTimeText` | 用户看到的这次复盘时间文本，而不是内部时间戳字段名。 | 推荐必填 | 无法可靠生成时写空字符串；不删除 key，不伪造“未知时间”。 | 在复盘卡元信息区展示；完整恢复依赖 `templateConfig`。 | 在阅读页、导出图、复制 JSON 中展示或写出。 | Harmony 导出必须平铺写出；Mac sidecar 需在 `templateConfig` 中保留，导入时按该字段恢复。 |
| `reviewerText` | 这次复盘由谁完成。 | 选填 | 未设置时写空字符串；不要替换成“匿名”“未填写”。 | 在复盘卡元信息区按非空展示；为空时不强行占位。 | 来自已保存的复盘设置；阅读页和导出图按非空展示。 | Harmony 导出必须平铺写出；Mac sidecar 需在 `templateConfig` 中保留，导入时按该字段恢复。 |
| `decision` | 用户对照片是否成立的最终判断。 | 产品必填 | 缺失或旧值不合法时归一化为 `uncertain`。 | 负责展示统一中文判断文案或 badge，不暴露历史别名。 | 负责把中文状态归一化后再展示或导出。 | 两端导出都只能写 `works`、`notWorks`、`uncertain`；导入可兼容历史别名。 |
| `firstLookText` | 第一眼最先被看到的视觉落点。 | 推荐必填 | 缺失时写空字符串，视为该段未完成。 | 在复盘正文中按“视觉落点”展示；空值不编造。 | 在阅读页、导出图按“视觉落点”展示；空值不显示该段。 | Mac 顶层摘要字段应写；Harmony 轻量 JSON 应写。 |
| `attentionReasonText` | 这个落点为什么会先被看到。 | 推荐必填 | 缺失时写空字符串。 | 在复盘正文中按“落点原因”展示。 | 在阅读页、导出图按“落点原因”展示；空值不显示该段。 | Mac 顶层摘要字段应写；Harmony 轻量 JSON 应写。 |
| `eyePathText` | 视线接下来如何在画面中移动。 | 推荐必填 | 缺失时写空字符串。 | 在复盘正文中按“视线路径”展示。 | 在阅读页、导出图按“视线路径”展示；空值不显示该段。 | Mac 顶层摘要字段应写；Harmony 轻量 JSON 应写。 |
| `visualFactText` | 用户确认过的画面可见事实，而不是评价。 | 推荐必填 | 缺失时写空字符串。 | 在复盘正文中按“画面事实”展示，避免与判断字段混淆。 | 在阅读页、导出图按“画面事实”展示；空值不显示该段。 | Mac 顶层摘要字段应写；Harmony 轻量 JSON 应写。 |
| `strongestRelationText` | 当前复盘里最重要的主体关系、主次关系或结构关系。 | 推荐必填 | 缺失时写空字符串；旧 `judgementText` 只作兼容输入，不作为输出字段。 | 在复盘正文中按“核心关系”展示，并负责兼容历史 `judgementText` 恢复。 | 在阅读页、导出图按“核心关系”展示。 | 两端输出统一使用 `strongestRelationText`；导入时可吸收历史 `judgementText`。 |
| `extensionReasonText` | 在当前判断基础上的进一步理解或延伸观察。 | 选填 | 缺失时写空字符串。 | 在复盘正文中按“延伸理解”展示；为空可省略该段。 | 在阅读页、导出图按“延伸理解”展示；为空不显示该段。 | Mac 顶层摘要字段可写空值；Harmony 轻量 JSON 保留 key。 |
| `blockerText` | 当前阻碍照片成立或阻碍判断推进的主要卡点。 | 选填 | 缺失时写空字符串。 | 在复盘正文中按“当前卡点”展示；为空可省略该段。 | 在阅读页、导出图按“当前卡点”展示；为空不显示该段。 | Mac 顶层摘要字段可写空值；Harmony 轻量 JSON 保留 key。 |

## 平台责任补充

### Mac Client

- 负责维护可归档的 sidecar 结构。
- 负责把顶层摘要字段与 `templateConfig` 里的完整复盘卡配置串起来。
- 负责兼容历史别名和旧字段，但新的 v1 输出不得回退成旧命名。

### Harmony Client

- 负责快速创建、阅读和导出同一语义的 Review。
- 负责把手机端中文状态、空字段展示策略和轻量 JSON 输出保持一致。
- 负责在“阅读页可省略空段落”和“导出 JSON 必须保留 key”之间维持清晰边界。

### 导入导出链路

- 导出要保证字段名稳定、值语义稳定、空值策略稳定。
- 导入要优先保护用户已有内容，不因某端缺少展示能力而重写字段含义。
- 未来如果新增 v2 分层协议，只能新增表示层，不能回改本文定义的产品语义。
