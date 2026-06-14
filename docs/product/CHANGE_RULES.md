# Skymap Product Change Rules

## 核心规则

以后新增功能，必须先改产品文档，再改客户端实现。

产品层文档包括：

- `README.md`
- `VISION.md`
- `FEATURE_MATRIX.md`
- `DATA_MODEL.md`
- `REVIEW_JSON_SEMANTICS.md`
- `SYNC_SYSTEM_V1.md`
- `WORKFLOW.md`
- `ROADMAP.md`
- `CHANGE_RULES.md`

如果功能不影响产品定位、能力矩阵、领域模型、核心工作流或路线图，可以在 PR 中说明“不需要更新产品层”的理由；否则必须先更新对应文档。

## 禁止的开发模式

禁止出现：

```text
Mac 先做
Harmony 后补
```

也禁止反向出现：

```text
Harmony 先做
Mac 后补
```

允许某个客户端先交付一个垂直切片，但必须先在产品层说明：

- 这个能力属于哪个产品工作流。
- 它修改或新增哪些产品模型。
- Mac Client 的职责是什么。
- Harmony Client 的职责是什么。
- 另一端本阶段为什么不做。
- 能力矩阵中另一端应标记为 🚧 规划中 还是 ❌ 不支持。

## 新功能准入清单

新增功能前必须回答：

| 问题 | 要求 |
| --- | --- |
| 用户价值是什么 | 不用技术重构描述功能价值。 |
| 属于哪个工作流 | 对齐 `WORKFLOW.md` 中的节点，必要时先扩展工作流。 |
| 涉及哪些产品模型 | 对齐 `DATA_MODEL.md`，避免只写客户端页面状态。 |
| 影响哪些能力状态 | 更新 `FEATURE_MATRIX.md`。 |
| 是否改变路线图优先级 | 必要时更新 `ROADMAP.md`。 |
| 两个客户端如何分工 | 明确 Mac Client 与 Harmony Client 的职责。 |
| 如何验证 | 写清用户能看到的结果、导出位置、失败反馈和兼容边界。 |

## PR 规则

涉及产品能力的 PR 应包含：

- 产品文档变更，或说明为什么不需要变更。
- 客户端实现变更。
- 验证结果。
- 能力矩阵状态变化。
- 已知限制。
- 如果改动涉及 `docs/product/`，必须列出 Mac Client 与 Harmony Client 两个仓库的对应 commit。
- 如果另一个客户端仓库尚未同步对应 Product Layer commit，本 PR 不得合并。

如果一个功能只在单端落地，PR 描述必须写明另一端状态，不能用“后面再说”代替产品判断。

## review.json 规则

review.json 是产品层交换文件，不是某个客户端的私有备份。

任何字段变更都必须先更新：

- `DATA_MODEL.md`
- `REVIEW_JSON_SEMANTICS.md`
- `WORKFLOW.md`
- `FEATURE_MATRIX.md`

并明确：

- 字段是否必填。
- 缺失字段如何处理。
- 旧字段如何兼容。
- Mac Client 如何读取或写出。
- Harmony Client 如何读取或写出。

## 文档同步规则

当前还没有独立的 Skymap Product 仓库，因此两个客户端仓库各保存一份 `docs/product/` 副本。

在独立产品仓库建立前：

- 两个客户端仓库中的 `docs/product/` 必须保持内容一致。
- 任一端修改 `docs/product/` 任意文件时，必须同步另一个客户端仓库的对应文件。
- PR 描述必须列出两个仓库的对应 commit。
- 未同步另一个客户端仓库、未列出对应 commit 或同步校验失败时，不得合并。
- 合并前必须运行 `bash scripts/verify_product_docs_sync.sh` 并记录结果。
- 如果后续建立独立产品仓库，产品仓库成为唯一来源，客户端仓库只保留链接或快照。

## 本地同步校验

两个客户端仓库都必须保留同步校验脚本：

```bash
bash scripts/verify_product_docs_sync.sh
```

脚本会自动尝试定位另一个客户端仓库。如果无法自动定位，可以传入：

```bash
SKymap_OTHER_REPO_PATH=/path/to/other/repo \
bash scripts/verify_product_docs_sync.sh
```

或：

```bash
SKymap_PRODUCT_DOCS_OTHER_PATH=/path/to/other/repo/docs/product \
bash scripts/verify_product_docs_sync.sh
```

脚本失败时，说明 Product Layer 镜像已经漂移，相关 PR 不得合并。

## 合并顺序建议

当产品文档和客户端实现分开 PR 时：

1. 先合并产品文档 PR。
2. 再合并客户端实现 PR。
3. 最后更新能力矩阵状态，从 🚧 规划中 改为 ✅ 已支持。

不要在客户端实现已经合并后再补产品定义；这会让两个客户端继续按各自理解演进。
