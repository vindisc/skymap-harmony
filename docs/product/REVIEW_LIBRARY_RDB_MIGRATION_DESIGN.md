# HarmonyOS 复盘库 RDB 迁移设计

更新时间：2026-06-25

本文为 HarmonyOS 端复盘库从 `Preferences + JSON` 升级到 ArkData RDB / RelationalStore 的落地设计。当前代码已完成阶段 1 的旁路 RDB 基础服务和迁移验证脚本，但页面主链路仍未切换到 RDB。

当前存储基线见 [`REVIEW_LIBRARY_STORAGE_AUDIT.md`](./REVIEW_LIBRARY_STORAGE_AUDIT.md)。

## 一、设计原则

- 本轮是设计，不是实现。
- RDB 是 HarmonyOS 端本地数据库，不需要服务器。
- 第一阶段只解决“复盘库主索引和查询能力”问题。
- 第一阶段不实装摄影边框模板系统。
- 第一阶段不拆复杂的 `photo_assets` / `templates` / `export_records` 四表全量模型。
- 第一阶段优先使用一张 `reviews` 主表承接复盘库索引。
- `review_exchange/*.review.json` 继续作为备份 / 交换 / 有限恢复来源。
- `Preferences(review_card_history.items)` 后续降级为迁移来源，不再长期作为主索引。
- 页面层继续只调用 `ReviewCardHistoryService`，不要让页面直接依赖 RDB。
- 保留 `raw_document_json`，降低 `ReviewCardDocument` 演进带来的迁移成本。

## 二、为什么选择 ArkData RDB

ArkData RDB / RelationalStore 是 HarmonyOS 端提供的本地关系型数据库能力。它运行在用户设备和应用沙箱内，不需要服务器、不需要联网，也不需要账号体系。

它适合承载本地结构化记录，尤其是复盘库后续会自然增长的列表、分页、筛选、搜索和统计场景。相比 `Preferences + JSON 数组`，RDB 可以把“整库读写”拆成单条记录更新和索引查询，更适合作为复盘库长期主索引。

RDB 不负责以下问题：

- 云同步
- 多设备冲突合并
- 远端备份
- 账号体系
- SMB / WebDAV / 云端服务写入

这些能力后续需要通过家庭存储、WebDAV、云端服务或独立同步系统另行设计，不应混入第一阶段本地索引迁移。

## 三、当前方案要解决的问题

当前复盘库主数据源是 `Preferences(review_card_history.items)`，其值是一段序列化后的 `ReviewCardHistoryItem[]` JSON。这个方案适合 v0 快速落地，但不适合作为长期主索引。

主要问题：

- 整库 JSON 读写，不适合大量记录。
- 保存、更新、删除可能都需要整体反序列化和整体写回。
- 搜索、筛选、统计都依赖内存遍历。
- 缺少分页能力。
- 记录变多后，复盘库首屏加载和筛选性能可能下降。
- `Preferences` 与 `review_exchange` 存在一致性风险。
- 后续统计页、按时间排序、按状态筛选、导出状态查询都会越来越别扭。

## 四、第一阶段 RDB 表结构设计

第一阶段只建议落地一张主表：`reviews`。

SQL 草案：

```sql
CREATE TABLE IF NOT EXISTS reviews (
  id TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  title TEXT,
  decision TEXT,
  image_uri TEXT,
  image_width INTEGER,
  image_height INTEGER,
  exported_path TEXT,
  reviewer_name TEXT,
  focus_text TEXT,
  reason_text TEXT,
  path_text TEXT,
  facts_text TEXT,
  strongest_relation_text TEXT,
  blocker_text TEXT,
  raw_document_json TEXT NOT NULL,
  backup_json_path TEXT,
  is_deleted INTEGER DEFAULT 0
);
```

字段说明：

| 字段 | 含义 |
| --- | --- |
| `id` | 复盘记录唯一 ID。 |
| `created_at` | 创建时间。 |
| `updated_at` | 更新时间，用于列表倒序和最近记录。 |
| `title` | 复盘标题。 |
| `decision` | 判断结果，例如成立、不成立、待判断。 |
| `image_uri` | 原图 URI / 路径引用，不保存原图二进制。 |
| `image_width` / `image_height` | 图片尺寸，用于导出和方向判断。 |
| `exported_path` | 最近一次导出结果引用，兼容当前 `ReviewCardHistoryItem.exportedPath`。 |
| `reviewer_name` | 复盘人名称。 |
| `focus_text` | 视觉落点。 |
| `reason_text` | 落点原因 / 注意原因。 |
| `path_text` | 视线路径。 |
| `facts_text` | 画面事实。 |
| `strongest_relation_text` | 最强关系。 |
| `blocker_text` | 卡点。 |
| `raw_document_json` | 完整 `ReviewCardDocument` JSON 快照。 |
| `backup_json_path` | 对应沙箱 `review_exchange/*.review.json` 备份路径。 |
| `is_deleted` | 软删除预留标记，第一阶段不启用。 |

注意：`image_uri` 只是原图引用，不代表原图已经归档进数据库。`exported_path` 只是导出结果引用，不等于原图路径。

## 五、Review ID 生成策略

当前 `ReviewCardDocument` 没有稳定 `id` / `review_id` 字段。v0 代码实际使用 `getReviewDocumentKey(document)` 作为历史记录匹配 key，而该函数当前返回的是 `createdAt` 字符串。

这意味着：`createdAt` 在 v0 阶段承担了“临时记录 key”的职责，但它本质上是时间，不是长期可靠的业务 ID。RDB 迁移时不能把这个状态固化成长期设计。

第一阶段策略：

- 迁移旧数据时，可以临时使用 `getReviewDocumentKey(document)` 作为 `reviews.id`。
- 如果迁移时发现 `id` 冲突，需要追加短 hash 或恢复序号，例如 `${createdAt}-${shortHash}` 或 `${createdAt}-recovered-${index}`。
- 新创建的 RDB 记录应生成稳定 `review_id`，不再依赖 `createdAt` 充当业务 ID。
- 后续应考虑把 `review_id` 写回 `ReviewCardDocument` / `raw_document_json`，避免长期依赖 `createdAt`。
- 在 `ReviewCardDocument` 字段正式扩展前，RDB 的 `reviews.id` 可以先作为数据库层稳定 ID 存在。

建议生成规则：

- 新记录使用本地生成的稳定字符串 ID，例如 `review_${timestamp}_${random}` 或 UUID。
- ID 生成必须在保存新复盘记录时一次性完成，后续更新、导出和删除都复用同一个 ID。
- 迁移旧数据时要记录来源：来自 `Preferences.items` 的数据优先沿用 `createdAt` 临时 key；来自 `review_exchange` 恢复的数据如果缺少稳定 key，需要做冲突兜底。

后续如果把 `review_id` 写回 `ReviewCardDocument`，必须作为独立数据模型变更设计，不混入第一阶段 RDB 接入。

## 六、索引设计

第一阶段建议索引：

```sql
CREATE INDEX IF NOT EXISTS idx_reviews_updated_at ON reviews(updated_at);
CREATE INDEX IF NOT EXISTS idx_reviews_decision ON reviews(decision);
CREATE INDEX IF NOT EXISTS idx_reviews_is_deleted ON reviews(is_deleted);
```

可选索引：

```sql
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at);
```

索引用途：

- `updated_at` 支撑复盘库倒序列表。
- `decision` 支撑成立 / 不成立 / 待判断筛选。
- `is_deleted` 支撑软删除过滤。
- `created_at` 可用于未来按创建时间筛选或统计。

关键词搜索第一阶段可以先使用 SQL `LIKE` 或内存二次过滤，不必一开始做全文索引。

## 七、为什么保留 raw_document_json

第一阶段数据库不是为了彻底范式化 `ReviewCardDocument`，而是先解决索引和查询问题。

保留 `raw_document_json` 的原因：

- 降低迁移成本。
- 避免 `ReviewCardDocument` 字段频繁变化导致表结构频繁迁移。
- 便于导出 `review.json`。
- 便于兼容旧字段。
- 允许页面和导出链路继续恢复完整文档。
- 数据库字段只抽取高频查询字段，例如标题、时间、判断状态、图片引用、关键复盘文本。

因此，`reviews` 表不是产品领域模型的最终范式化结果，而是“完整文档快照 + 高频索引字段”的本地索引表。

## 八、服务拆分设计

### 1. ReviewCardHistoryService

`ReviewCardHistoryService` 继续作为页面层唯一入口。

职责：

- 对页面暴露 `load` / `saveDocument` / `updateDocument` / `deleteDocument` / `markExported` 等稳定接口。
- 屏蔽底层到底是 `Preferences` 还是 RDB。
- 后续切换 RDB 后，页面层不需要大改。
- 继续负责与 `review_exchange` 备份逻辑协同。

页面、首页摘要、复盘库列表和预览页不应直接引入 `ReviewCardRdbService`。

### 2. ReviewCardRdbService

新增服务，负责 RDB 具体能力。

职责：

- 初始化 RDB Store。
- 创建表和索引。
- 插入复盘记录。
- 更新复盘记录。
- 删除复盘记录。
- 按 ID 查询。
- 按更新时间倒序分页查询。
- 按 `decision` 筛选。
- 关键词搜索。
- 统计总复盘数、成立数、不成立数、待判断数。
- 维护 `exported_path`。
- 读写 `raw_document_json`。

建议接口草案：

```ts
class ReviewCardRdbService {
  init(context: Context): Promise<void>;
  upsertReview(item: ReviewCardHistoryItem): Promise<void>;
  getReview(id: string): Promise<ReviewCardHistoryItem | undefined>;
  listReviews(query: ReviewListQuery): Promise<ReviewCardHistoryItem[]>;
  countReviews(query?: ReviewListQuery): Promise<number>;
  deleteReview(id: string): Promise<void>;
  markExported(id: string, exportedPath: string): Promise<void>;
  getStats(): Promise<ReviewLibraryStats>;
}
```

`ReviewCardRdbService` 的输入输出仍优先贴近 `ReviewCardHistoryItem`，避免把 RDB 行模型泄漏到页面层。

### 3. ReviewCardMigrationService

新增服务，负责迁移和恢复。

职责：

- 检查 RDB 是否已经初始化。
- 检查是否已经完成从 `Preferences.items` 到 RDB 的迁移。
- 从 `Preferences(review_card_history.items)` 读取旧历史项。
- 将旧历史项写入 `reviews` 表。
- 如果 RDB 和 `Preferences` 都为空，再尝试扫描 `review_exchange/*.review.json`。
- 将恢复结果写入 RDB。
- 记录迁移完成标记。
- 避免重复迁移导致重复数据。

建议接口草案：

```ts
class ReviewCardMigrationService {
  migrateIfNeeded(context: Context): Promise<MigrationResult>;
  migrateFromPreferences(context: Context): Promise<number>;
  recoverFromReviewExchange(context: Context): Promise<number>;
  markMigrationDone(context: Context): Promise<void>;
  isMigrationDone(context: Context): Promise<boolean>;
}
```

迁移完成标记可以继续放在轻量 `Preferences` 中，但它只表示迁移状态，不再承担复盘库主索引职责。

## 九、迁移阶段设计

迁移必须分阶段，不允许一次性重构。

### 阶段 0：文档设计阶段

- 只写设计文档。
- 不改业务代码。
- 不改数据结构。
- 不接入 RDB。

### 阶段 1：新增 RDB 服务，但不切主链路

阶段 1 已新增以下文件：

- `entry/src/main/ets/services/ReviewCardRdbModel.ets`
- `entry/src/main/ets/services/ReviewCardRdbService.ets`
- `entry/src/main/ets/services/ReviewCardMigrationService.ets`
- `scripts/verify_review_library_rdb_migration.mjs`

本阶段实际边界：

- `ReviewCardRdbService` 负责初始化 `review_library.db`、创建 `reviews` 表和索引，并提供 upsert / get / list / count / delete / mark exported / stats / clear all 能力。
- `ReviewCardRdbModel` 负责 `ReviewCardHistoryItem`、`ReviewCardDocument` 与 `reviews` 行模型之间的映射。
- `raw_document_json` 保存完整 `ReviewCardDocument` JSON，结构化列只抽取标题、判断、图片引用、尺寸、导出路径和复盘关键文本。
- `ReviewCardMigrationService` 提供手动迁移和验证函数，可从 `Preferences(review_card_history.items)` 迁移到 RDB。
- 阶段 3 后，迁移服务只读取 `Preferences(review_card_history.items)` 作为迁移源，不再反向调用 `ReviewCardHistoryService.load(context)`，避免主读切到 RDB 后出现递归。
- 当 RDB 与 Preferences 都为空时，`ReviewCardHistoryService.load(...)` 会回退旧链路，由旧链路保留有限 `review_exchange` 恢复能力；这只是恢复来源，不代表 `review_exchange` 变成主查询源。
- `backup_json_path` 第一阶段无法从 Preferences 历史项稳定反推出对应备份文件，当前默认留空，后续可在切主写或专门重建索引时补齐。
- 验证脚本是 Node 层映射与迁移语义验证，不代表真机 RDB 已执行；ArkData RDB API 的可编译性由 HAP 构建验证。

本阶段仍未做：

- 未让页面直接调用 RDB。
- 未把 `ReviewCardHistoryService.load` 主读切到 RDB。
- 未把 `saveDocument` / `updateDocument` / `deleteDocument` / `markExported` 主写切到 RDB。
- 未停止写 `Preferences`。
- 未停止写 `review_exchange`。
- 未修改 Review JSON 字段。
- 未修改 UI。
- 未实现摄影边框模板系统。

- 新增 `ReviewCardRdbService`。
- 新增 `ReviewCardMigrationService`。
- 建表和基础 CRUD。
- 编写迁移验证脚本。
- 页面仍然走旧 `ReviewCardHistoryService` 逻辑。
- 不影响现有复盘库。

### 阶段 2：设备侧旁路验证

阶段 2 新增开发期诊断服务：

- `entry/src/main/ets/services/ReviewCardRdbDiagnosticsService.ets`
- `entry/src/main/ets/pages/MyPage.ets` 中临时增加“RDB开发诊断”入口

诊断服务只作为 DevEco / 真机侧手动调用入口，不接入正式页面，不作为用户可见功能。它用于验证设备侧 ArkData RDB 实际运行结果：

- `runRdbDiagnostics(context)`：初始化 RDB、创建表、写入两条诊断记录、按 id 读取、验证 `raw_document_json` 可恢复、验证关键字段映射、验证倒序列表、判断筛选、关键词搜索、导出路径更新、统计增量和硬删除。
- `runMigrationDiagnostics(context)`：读取当前 `Preferences(review_card_history.items)` 数量，手动调用 `migrateFromPreferencesToRdb(context)`，再调用 `verifyRdbMigration(context)`，输出 `sourceCount` / `insertedCount` / `skippedCount` / `failedCount`、RDB 数量和 `raw_document_json` 校验结果。
- `formatDiagnosticsResult(result)`：把诊断结果格式化成多行文本，便于临时 `console.info(...)`、断点查看或 DevEco 日志检查。

临时调用示例：

```ts
import { ReviewCardRdbDiagnosticsService } from '../services/ReviewCardRdbDiagnosticsService';

const result = await ReviewCardRdbDiagnosticsService.runRdbDiagnostics(this.context);
console.info(ReviewCardRdbDiagnosticsService.formatDiagnosticsResult(result));

const migrationResult = await ReviewCardRdbDiagnosticsService.runMigrationDiagnostics(this.context);
console.info(ReviewCardRdbDiagnosticsService.formatDiagnosticsResult(migrationResult));
```

当前真机触发方式：

- 打开“我的”页底部的“RDB开发诊断”。
- 点击后会连续执行 `runRdbDiagnostics(context)` 和 `runMigrationDiagnostics(context)`。
- 页面只显示轻量的通过 / 失败、步骤数量和错误数量。
- 完整结果通过 `console.info` 输出，前缀分别为 `[RDB开发诊断]` 和 `[Preferences迁移诊断]`。

注意：

- 诊断写入的记录使用 `diagnostic_review_rdb_` 前缀，验证结束后只删除自己的诊断记录，不调用 `clearAll`，避免误删真实复盘库数据。
- 迁移诊断会真实写入 RDB 旁路库，但不会改变当前页面读取来源。
- “RDB开发诊断”是临时开发入口，不放在首页，不进入普通复盘流程；阶段 3 切主读前或发布前可直接删除该入口。
- 当前仍未切主读写，`ReviewCardHistoryService` 仍然是页面入口。
- 真机旁路验证通过后，才评估阶段 3：切 `ReviewCardHistoryService.load` 主读。

阶段 2 仍需验证：

- 从 `Preferences.items` 迁移到 RDB。
- 验证迁移数量、字段完整性、`raw_document_json` 可恢复。
- 验证 `imageUri` / `exportedPath` / `decision` / `updatedAt` 等关键字段。
- 验证 `review_exchange` 恢复兜底。
- 此阶段仍不切页面主读。

### 阶段 3：切换 ReviewCardHistoryService 主读

阶段 3 当前边界：

- `ReviewCardHistoryService.load(...)` / `loadWithDiagnostics(...)` 优先初始化并查询 RDB。
- 如果 RDB 有可解析记录，直接返回 RDB 记录，不再把 `Preferences.items` 当作主列表。
- 如果 RDB 为空，会先检查 `Preferences(review_card_history.items)` 数量；只有 Preferences 有记录时才触发 `Preferences -> RDB` 迁移。
- 迁移成功后再次查询 RDB，并返回迁移后的 RDB 记录。
- 如果 RDB 仍为空，回退旧 `Preferences + review_exchange` 读取链路。
- 如果 RDB 初始化、查询、`raw_document_json` 解析或迁移发生异常，会记录诊断日志并回退旧链路，避免用户看到空库误判。
- `Preferences` 在本阶段降级为迁移来源和失败回退来源，但仍保留旧主写职责。
- `review_exchange` 继续作为备份 / 交换 / 有限恢复来源，只在旧链路回退或旧主写备份中发挥作用。
- 页面层仍然只调用 `ReviewCardHistoryService`，不直接依赖 `ReviewCardRdbService`。

阶段 3 明确不做：

- 不切 `saveDocument` 主写。
- 不切 `updateDocument` 主写。
- 不切 `deleteDocument` 主写。
- 不切 `markExported` 主写。
- 不停止写 `Preferences`。
- 不停止写 `review_exchange`。
- 不修改 Review JSON 字段。
- 不修改 UI。

阶段 3 的一致性风险：

- 本阶段只验证 RDB 主读，不做复杂增量同步。
- 旧链路保存、更新、删除、导出标记仍写入 Preferences / `review_exchange`，RDB 不一定立刻拥有最新变更。
- 为避免旧主写误用 RDB 快照，`saveDocument` / `updateDocument` / `deleteDocument` / `markExported` 内部仍使用旧 Preferences 链路作为写入基准。
- 真正解决“新写入立刻进入 RDB 主索引”的一致性问题，放到阶段 4 主写切换或明确的旁路同步设计中。

### 阶段 4：切换主写

阶段 4 当前边界：

- `saveDocument` 主写 RDB：新保存记录写入 `reviews`，`raw_document_json` 保留完整 `ReviewCardDocument` 快照，保存成功后主读立刻从 RDB 读到新记录。
- `updateDocument` 主写 RDB：按现有 `createdAt` key 更新同一条 RDB 记录，刷新 `raw_document_json` 和标题、判断、关系、卡点等索引字段，并保留原有 `exported_path`。
- `deleteDocument` 主写 RDB：调用 `deleteReview(id)` 硬删除记录，不启用 `is_deleted` 软删除。
- `markExported` 主写 RDB：更新 `exported_path`，不把 `exportedPath` 理解为原图路径。
- `review_exchange` 继续作为备份 / 交换 / 有限恢复来源：保存和更新继续写沙箱备份，删除继续删除对应沙箱备份。
- 删除语义继续沿用 v0：删除 RDB 索引和沙箱 `review_exchange` 备份，不删除原图、不删除用户已经导出的图片、不删除用户导出的 `review.json`、不删除家庭存储远端文件。
- `Preferences.items` 降级为迁移 / 失败回退来源，不再作为复盘库长期主索引。
- 为了 RDB 写失败时不丢用户数据，当前会 best-effort 维护一份 `Preferences.items` 回退镜像；这只是短期兼容和故障回退，不是 RDB + Preferences 双主存储。
- 新增轻量 `rdb_main_index_ready` 标记，用来区分“RDB 主索引已接管后的真实空库”和“尚未迁移的空 RDB”，避免删除最后一条记录后被旧 Preferences 再次迁回。
- RDB 写入失败时记录诊断日志，并回退旧 Preferences 写入链路，避免保存、更新、删除或导出标记失败导致用户数据丢失。

阶段 4 明确不做：

- 不修改 Review JSON 字段。
- 不修改 `ReviewCardDocument` 字段。
- 不修改 UI。
- 不让页面直接调用 `ReviewCardRdbService`。
- 不引入 `photo_assets` / `templates` / `export_records`。
- 不实现摄影边框模板系统。

### 阶段 5：Preferences 退场

- 保留一次性迁移逻辑。
- 不再把 `Preferences` 作为主索引。
- 不再依赖 `Preferences` 做列表查询。
- 文档更新存储边界。

## 十、关于双写策略

不建议长期“三方双写”：

- RDB
- `Preferences.items`
- `review_exchange`

原因：

- 三方写入容易不一致。
- 删除语义会变复杂。
- 恢复语义会变混乱。
- 故障定位困难。

可接受的短期策略：

- 切换前，可以短期验证 RDB 写入。
- 切换后，RDB 是主索引。
- `review_exchange` 继续作为备份 / 交换 / 有限恢复来源。
- `Preferences.items` 只作为迁移来源，不再作为持续写入目标。

## 十一、第一阶段删除策略

数据库化后删除语义仍然沿用当前 v0 边界。

第一阶段采用硬删除，不启用软删除。

删除复盘记录时：

- `deleteReview(id)` 删除 RDB 中对应记录。
- 删除对应沙箱 `review_exchange` 备份。
- 不删除原始照片。
- 不删除用户已经导出的图片。
- 不删除用户已经导出的 `review.json`。
- 不删除家庭存储远端文件。
- `is_deleted` 字段仅作为预留，本阶段不启用。

未来可以新增“彻底清理”能力，但必须独立设计，不要混入普通删除。

如果未来要做回收站 / 最近删除 / 彻底清理，再启用软删除并单独设计：

- 回收站列表如何展示。
- 最近删除保留多久。
- 恢复时如何重建 `review_exchange` 备份。
- 彻底清理是否删除导出物或远端文件。

这些都不属于第一阶段 RDB 主索引迁移范围。

## 十二、恢复语义设计

数据库化后恢复链路：

1. App 启动或首次进入复盘库。
2. 检查 RDB 是否存在有效记录。
3. 如果 RDB 为空，先尝试从 `Preferences.items` 迁移。
4. 如果 `Preferences` 也为空，再尝试扫描 `review_exchange/*.review.json`。
5. 恢复成功后写入 RDB。
6. RDB 成为主索引。
7. 后续列表查询不直接扫描 `review_exchange`。

必须明确：

- `review_exchange` 不是主查询源。
- `review_exchange` 是恢复和交换来源。
- 自动恢复应避免重复导入。
- 后续可以设计用户可见的“重建复盘库索引”入口，但第一阶段不实现。

恢复去重优先使用复盘记录 `id`。当旧备份缺少稳定 `id` 时，可结合标题、时间、图片引用和内容摘要生成兼容判断，但这属于迁移实现阶段的细节，不在本文阶段落代码。

## 十三、摄影边框扩展预留

长期方向可以保留更完整的对象模型：

- `photo_assets`
- `reviews`
- `templates`
- `export_records`

长期关系：

- 一张照片可以有多条复盘。
- 一张照片可以直接导出摄影边框。
- 一条复盘可以导出多个版本。
- 一个模板可以被多次使用。
- 摄影边框属于模板 / 导出层，不是复盘字段。

后续当启动摄影边框能力时，再考虑引入：

- `photo_assets`
- `templates`
- `export_records`

第一阶段只落地 `reviews`。如果导出查询压力提前出现，最多再评估极简 `export_records`，但不应把四表全量模型作为第一阶段实现要求。

## 十四、不推荐现在做的事

第一阶段不推荐：

- 直接上四表全量模型。
- 直接实现摄影边框模板系统。
- 把 `review_exchange` 当主查询源。
- 长期维护 RDB + `Preferences` 双主存储。
- 修改 `Review JSON` 字段。
- 修改复盘业务流程。
- 让页面直接依赖 RDB。
- 保存原图二进制到数据库。
- 引入服务器或账号体系。

## 十五、验收标准

本文完成后必须满足：

- 明确 RDB 是本地数据库，不需要服务器。
- 明确第一阶段只解决复盘库主索引。
- 明确第一阶段只建议落地 `reviews` 主表。
- 明确 `ReviewCardDocument` 当前没有稳定 ID，旧数据迁移可临时使用 `createdAt` key，但新 RDB 记录应生成稳定 `review_id`。
- 明确保留 `raw_document_json`。
- 明确 `review_exchange` 继续作为备份 / 交换 / 有限恢复来源。
- 明确 `Preferences.items` 后续降级为迁移来源。
- 明确 `ReviewCardHistoryService` 仍是页面层唯一入口。
- 明确摄影边框只做架构预留，不在第一阶段实装。
- 明确第一阶段采用硬删除，`is_deleted` 只作为预留。
- 明确恢复语义。
- 不改业务代码。
- 不改 `Review JSON` 字段。
- 不引入数据库实现代码。
