# Skymap Product Layer

本目录是 Skymap Product Layer 的镜像副本，用来让 Mac Client 与 Harmony Client 在没有独立产品仓库前共享同一套产品参照。

当前 Product Layer 包含：

- `VISION.md`：产品愿景、核心用户、核心场景、长期目标和不做什么。
- `FEATURE_MATRIX.md`：Mac Client 与 Harmony Client 的能力矩阵。
- `DATA_MODEL.md`：Review、Photo、Template、Preset、Profile、ExportJob 等产品级领域模型。
- `REVIEW_JSON_SEMANTICS.md`：`review.json` v1 字段语义、空值策略和双端责任分工。
- `HARMONYOS_V0_BASELINE.md`：HarmonyOS v0 发布基线、回归清单、存储边界、已知风险和下一阶段路线。
- `REVIEW_LIBRARY_STORAGE_AUDIT.md`：HarmonyOS 端当前复盘库主存储、RDB 主索引、`review_exchange` 备份和删除 / 恢复边界。
- `REVIEW_BUNDLE_V1_DESIGN.md`：review bundle v1 的目录结构、manifest、家庭存储、双端导入导出、删除语义和 v1 不做范围。
- `REVIEW_BUNDLE_V1_E2E_CHECKLIST.md`：Mac / HarmonyOS 单条 review bundle v1 端到端验收清单和发布前真实样本测试债。
- `REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md`：review bundle v2 原图复盘包的 manifest、原图资产、双端识别边界和本轮不做范围。
- `REVIEW_BUNDLE_V1_V2_CONTRACT.md`：review bundle v1/v2 双协议契约、Review JSON 冻结原则、manifest 职责和双端行为边界。
- `REVIEW_BUNDLE_V1_V2_E2E_CHECKLIST.md`：HarmonyOS v1/v2 导出、Mac v1/v2 导入、v2 打开为复盘卡和错误场景的端到端回归清单。
- `REVIEW_BUNDLE_STORAGE_BROWSER.md`：Mac 端浏览家庭存储 `ReviewBundles` 根目录、扫描 v1/v2 候选包、识别已导入状态并手动导入单个 bundle 的产品边界。
- `REVIEW_LIBRARY_V1_1.md`：Review Library v1.1 的可见入口、搜索界面和导入结果闭环。
- `UI_INTERACTION_GUIDE.md`：Skymap UI 交互设计指导，定义按钮、色彩、字体、页面结构和评审清单。
- `SYNC_V0_MANUAL_EXCHANGE.md`：Sync v0 手动文件交换闭环，说明 review.json 如何从 Harmony 落到 Mac Review Library。
- `SYNC_SYSTEM_V1.md`：家庭存储优先的 SMB / WebDAV 同步系统 v1 架构设计。
- `WORKFLOW.md`：跨端核心工作流。
- `ROADMAP.md`：按用户价值组织的阶段路线图。
- `CHANGE_RULES.md`：产品层变更和客户端实现顺序规则。

当前实现备注：

- HarmonyOS 已支持单条复盘导出 review bundle v1 到家庭存储。
- HarmonyOS 已支持原图复盘包 v2 导出到家庭存储。
- Mac 已支持选择单个 review bundle 导入 Review Library。
- Mac 已支持选择家庭存储 `ReviewBundles` 根目录，浏览 v1/v2 候选包并手动导入单个 bundle。
- Mac / HarmonyOS 单条 review bundle v1/v2 已形成端到端验收清单。
- Mac 当前不是批量导入、自动同步、双向同步或冲突合并。
- Review JSON v1 字段继续冻结，bundleId、导出图、缩略图等 bundle 信息不写回 `review.json`。
- Mac 已固化脱敏 v1/v2 bundle fixture，覆盖 Reader、Import、只读预览和 v2 打开为复盘卡；真实隐私照片不得提交到仓库。

## 清理规则

本目录只保留仍可作为当前产品契约、实现边界或验收依据的文档。阶段性 Beta 冻结、已完成迁移设计、历史能力追溯和已经被当前契约吸收的旧 Sync v0.5 文档不再保留在镜像目录中。

如果需要追溯旧决策，应优先查看 Git 历史，而不是把过期快照重新加入当前 Product Layer。

## 镜像副本规则

当前 `docs/product/` 不是某一个客户端的私有文档。它是 Skymap Product Layer 在客户端仓库中的镜像副本。

在独立产品仓库建立前：

- `skymap-mac/docs/product/` 与 `skymap-HarmonyOS/docs/product/` 必须保持一致。
- 修改本目录任意文件时，必须同步另一个客户端仓库的对应文件。
- PR 描述必须列出两个仓库的对应 commit。
- 未完成同步、未列出对应 commit 或同步校验失败时，不得合并。

## 未来唯一来源

理想状态是建立独立的 `skymap-product` 仓库，把 Product Layer 迁移过去，并以它作为唯一来源。

迁移后：

- `skymap-product` 保存产品愿景、领域模型、工作流、能力矩阵、路线图和变更规则。
- Mac Client 与 Harmony Client 只保留链接、快照或生成副本。
- 客户端功能 PR 必须引用对应的 Product Layer commit 或版本。

## 本地同步校验

两个客户端仓库都提供本地校验脚本：

```bash
bash scripts/verify_product_docs_sync.sh
```

脚本会比较当前仓库与另一个客户端仓库的 `docs/product/` 是否一致。若脚本无法自动定位另一个仓库，可以显式传入路径：

```bash
SKymap_OTHER_REPO_PATH=/path/to/other/repo \
bash scripts/verify_product_docs_sync.sh
```

或直接传入另一个 Product Layer 目录：

```bash
SKymap_PRODUCT_DOCS_OTHER_PATH=/path/to/other/repo/docs/product \
bash scripts/verify_product_docs_sync.sh
```

脚本通过后，才可以认为两个客户端的 Product Layer 镜像没有漂移。
