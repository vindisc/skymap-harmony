# Skymap Sync System Architecture v1

日期：2026-06-13

## 0. 设计边界

本文件只定义产品与架构设计，不定义客户端业务实现。

本轮禁止进入：

- `review.json` 字段变更。
- `Review Library` 业务逻辑变更。
- `ReviewArchive` 结构变更。
- `TemplateConfig` 结构变更。
- Swift / ArkTS 业务代码变更。

Sync System v1 的目标不是做复杂云同步，而是把现有链路补成可理解、可验证、可逐步实现的家庭存储同步：

```text
Harmony
↓
家庭存储
↓
Mac
↓
Review Library
```

## 1. 同步目标

### 1.1 方案一：只同步 review.json

含义：Harmony 只把复盘内容输出为单个 `review.json`，Mac 从家庭存储导入该 JSON。

优点：

- 文件最小，传输快。
- 与当前跨端交换模型最接近。
- 不需要处理照片二进制、缩略图和大文件失败。
- 对 SMB / WebDAV 都友好。

缺点：

- Mac 只能拿到复盘文字和照片引用，不能保证找到原图。
- 用户看到 Review Library 记录时，可能缺少照片预览。
- 复盘与照片的人工对应成本高。
- 不利于长期归档，几年后只剩 JSON 时可读性弱。

复杂度：低。适合作为 Sync v0 的最低可用交换能力。

### 1.2 方案二：同步 review.json + jpg

含义：Harmony 同步 `review.json` 和一张 jpg，Mac 导入时把两者建立关联。

优点：

- Mac 能展示照片预览，Review Library 体验更完整。
- 用户可以把一次复盘和对应照片作为一组文件迁移。
- 不依赖原手机相册路径。

缺点：

- 如果只靠同名文件关联，容易出现命名冲突。
- 原图、压缩图、导出图三者容易混淆。
- WebDAV 上传大图失败、半传输、重复传输的处理成本上升。
- 删除或移动其中一个文件后，另一端容易变成孤儿文件。

复杂度：中。需要命名规则、导入配对、重复照片识别和失败兜底。

### 1.3 方案三：同步 review bundle

含义：一次复盘作为一个目录级 bundle 同步。bundle 至少包含 `review.json`，可选包含照片副本、预览图和清单文件。

建议产品形态：

```text
review-20260613-091530-<short-id>/
├── review.json
├── manifest.json
├── photo.jpg
└── preview.jpg
```

其中：

- `review.json` 仍是复盘语义核心。
- `manifest.json` 只描述 bundle 文件清单、文件哈希、来源客户端、创建时间和同步状态，不替代 `review.json`。
- `photo.jpg` 是可选照片副本，可先不要求原图级质量。
- `preview.jpg` 是可选轻量预览，便于 Mac 快速列表展示。

优点：

- 一次复盘的文件边界清楚，人工可读、可搬运、可备份。
- 后续增加预览图、导出图、错误日志时不破坏 `review.json`。
- 冲突处理可以以 bundle 为单位做，不需要猜测散落文件的关系。
- 更适合作为家庭存储目录里的长期归档单元。

缺点：

- 比单文件方案多一个清单和目录规范。
- Mac 导入需要识别 bundle 完整性和缺失文件。
- Harmony 导出需要在目录内写多文件，对权限和失败反馈要求更高。

复杂度：中高，但复杂度集中在边界和清单上，可分阶段实现。

### 1.4 推荐方案

推荐 Sync v1 采用 review bundle，且分阶段启用：

- Sync v0：只要求 `review.json` 可手动导出、手动导入。
- Sync v1：以 review bundle 作为家庭存储同步的标准单元，bundle 至少包含 `review.json` 和 `manifest.json`。
- Sync v2：在 bundle 中稳定加入 `photo.jpg` / `preview.jpg`，并增强重复识别和状态反馈。

理由：

- `review.json` 是核心语义，但单独同步无法形成稳定复盘资产。
- `review.json + jpg` 能解决可见性，但缺少边界和清单，长期会变成散文件配对问题。
- review bundle 让用户、Mac、Harmony 和未来工具都能明确知道“一次复盘”的文件范围。

## 2. 同步架构

### 2.1 支持范围

Sync System v1 支持：

- SMB：优先支持家庭 NAS、路由器共享盘、局域网共享目录。
- WebDAV：支持 NAS、私有网盘或自建 WebDAV 目录。
- 本地文件夹：作为 Mac 端测试和手动迁移的等价路径。

Sync System v1 不支持：

- Skymap 自建云服务器。
- Skymap 账号体系。
- 第三方后端托管。
- 社交平台式内容同步。

### 2.2 架构角色

```text
Harmony Client
  └─ Export Review Bundle
      ↓
家庭存储目录（SMB / WebDAV）
      ↓
Mac Client
  └─ Import / Scan Review Bundle
      ↓
Review Library
```

Harmony Client 职责：

- 创建 Review。
- 输出 `review.json`。
- 按规范写入 review bundle。
- 给用户明确的同步目标、成功反馈和失败反馈。

家庭存储职责：

- 作为文件中转与备份位置。
- 不承担业务理解。
- 不承担账号、权限模型或冲突合并。

Mac Client 职责：

- 读取 SMB / WebDAV 挂载目录或本地同步目录。
- 识别 review bundle。
- 导入 Review Library。
- 对重复、缺失、冲突给出简单可理解的处理。

### 2.3 家庭存储优先原则

家庭存储是 v1 的默认同步目标，因为它符合 Skymap 的产品边界：

- 用户拥有自己的数据。
- 不需要注册账号。
- 不依赖 Skymap 后端可用性。
- 可与 NAS、Mac 文件夹和手机文件管理器共存。

## 3. 目录结构

### 3.1 方案一：类型分区

```text
Skymap/
├── Reviews/
└── Photos/
```

优点：

- 结构直观，容易解释。
- Review 和照片可以分别管理。
- Mac 扫描入口固定。

缺点：

- Review 与照片分离后需要额外配对规则。
- 用户手动移动文件时容易打散关系。
- 重复照片和多次复盘的关系不够清楚。

### 3.2 方案二：年月分区

```text
Skymap/
└── 2026/
    └── 06/
        ├── review-20260613-091530-a1b2c3/
        └── review-20260613-095000-d4e5f6/
```

优点：

- 文件量增长后更稳定，不会让单目录过大。
- 用户按时间备份、查找和清理更自然。
- 每个 review bundle 保持完整边界。

缺点：

- 初期层级略深。
- 如果复盘时间和拍摄时间不同，需要定义分区口径。
- 用户手动查找时要知道年份月份。

### 3.3 方案三：按照片分区

```text
Skymap/
└── Photos/
    └── <photo-id-or-hash>/
        ├── photo.jpg
        └── Reviews/
            └── review-20260613-091530-a1b2c3/
```

优点：

- 一张照片多次复盘的关系最清楚。
- 适合未来成长分析和照片资产管理。

缺点：

- v1 需要稳定照片 ID 或哈希，前置成本高。
- Harmony 端可能拿不到足够稳定的文件指纹。
- 对当前“先同步复盘”的目标过重。

### 3.4 推荐结构

推荐 Sync v1 使用年月分区 + review bundle：

```text
Skymap/
└── Reviews/
    └── 2026/
        └── 06/
            └── review-20260613-091530-a1b2c3/
                ├── review.json
                ├── manifest.json
                ├── photo.jpg
                └── preview.jpg
```

规则：

- 分区时间优先使用 Review 创建时间。
- bundle 目录名包含时间和短 ID，不依赖用户照片名。
- `review.json` 必须存在。
- `manifest.json` 在 v1 必须存在，用于描述文件清单和来源。
- `photo.jpg` / `preview.jpg` 在 v1 可选，v2 再提高要求。

## 4. Mac 导入策略

### 4.1 方案 A：手动导入

含义：用户在 Mac 端选择一个 `review.json` 或 review bundle 导入。

实现成本：低。

用户体验：

- 优点：可控、容易理解、失败边界清楚。
- 缺点：需要用户每次手动操作，不像同步。

稳定性：高。适合作为 v1 的基础能力和问题兜底。

### 4.2 方案 B：启动扫描

含义：Mac 启动时扫描指定同步目录，发现新 bundle 后导入。

实现成本：中。

用户体验：

- 优点：用户把家庭存储挂好后，打开 Mac 自动接力。
- 缺点：启动时可能有等待；扫描失败需要清晰反馈。

稳定性：中高。只在启动时跑，状态简单，适合 v1。

### 4.3 方案 C：监听目录

含义：Mac 监听本地同步目录变化，文件出现后自动导入。

实现成本：中高。

用户体验：

- 优点：接近实时。
- 缺点：网络盘事件不稳定，WebDAV 挂载目录可能漏事件或多次触发。

稳定性：中。适合 v2，在文件完整性判断成熟后再做。

### 4.4 方案 D：定时同步

含义：Mac 每隔固定时间扫描同步目录。

实现成本：中。

用户体验：

- 优点：不用依赖目录事件，对网络盘更稳。
- 缺点：会有延迟；需要避免频繁扫描带来的性能和网络压力。

稳定性：中高。适合 v2，用于补足启动扫描。

### 4.5 推荐路线

v1 推荐：

- 手动导入作为必须能力。
- 启动扫描作为默认自动化能力。
- 不做目录监听和复杂后台同步。

v2 推荐：

- 增加定时同步。
- 增加“立即扫描”按钮。
- 增强导入报告和重复处理。

v3 推荐：

- 在本地文件夹场景尝试目录监听。
- 对 SMB / WebDAV 保持扫描优先，不把监听当成唯一入口。

## 5. 冲突处理

Sync System v1 不设计复杂分布式同步，不做自动字段级合并。原则是：能确定重复就跳过，不能确定就保留副本并提示。

### 5.1 同名 review.json

风险：

- 用户手动复制导致文件同名。
- 不同 bundle 内都叫 `review.json`，但内容不同。

处理：

- v1 不以 `review.json` 文件名判断唯一性。
- 以 bundle ID、`reviewId`、创建时间和内容摘要组合判断。
- 同一目录内出现散落同名 `review.json` 时，导入为候选项，不自动覆盖。

### 5.2 重复导入

风险：同一个 bundle 被 Mac 扫描多次。

处理：

- Mac 记录已导入 bundle ID 或 `reviewId`。
- 完全相同内容再次出现时跳过，并在导入报告中显示“已存在”。
- 内容不同但 ID 相同，按冲突处理，不自动覆盖。

### 5.3 重复照片

风险：同一张照片被多个 bundle 携带，或者用户多次导出压缩图。

处理：

- v1 不要求全局照片去重。
- 可使用文件名、文件大小、像素尺寸和可选哈希做弱识别。
- 识别到疑似重复时，只提示，不自动删除。

### 5.4 重复 Review

风险：同一复盘从 Harmony 导出多次，或用户手动复制到多个目录。

处理：

- `reviewId` 相同且内容摘要相同：视为重复，跳过。
- `reviewId` 相同但内容摘要不同：保留两份，标记为冲突副本。
- `reviewId` 缺失：使用内容摘要、标题、复盘时间、照片名做候选重复判断。

### 5.5 删除文件

风险：用户在家庭存储删除 bundle 或照片。

处理：

- v1 不把家庭存储删除同步为 Review Library 删除。
- Mac 已导入记录继续保留。
- 如果照片副本缺失，Review Library 只显示照片不可用状态。

### 5.6 移动文件

风险：用户整理目录后移动 bundle。

处理：

- bundle ID 不变时，Mac 视为同一复盘位置变化。
- 已导入记录不重复创建。
- 如果 Mac 只保存了旧路径，下一次扫描可修正来源路径，但不改变 Review 内容。

## 6. Product Layer 更新

### 6.1 新增领域能力：SyncSystem

SyncSystem 是 Skymap Product Layer 的领域能力，负责定义跨设备、家庭存储和 Review Library 之间的文件流转边界。

SyncSystem 不等于：

- 云服务。
- 账号体系。
- Review Library 内部实现。
- `review.json` 字段扩展。
- 照片资产管理系统。

SyncSystem 负责：

- 定义同步对象：`review.json`、照片副本、预览图和 review bundle。
- 定义同步位置：SMB、WebDAV、本地同步目录。
- 定义导入策略：手动导入、启动扫描、定时扫描、目录监听。
- 定义冲突策略：重复、缺失、移动、删除和同 ID 不同内容。
- 定义用户反馈：成功、失败、已存在、冲突、缺失文件。

### 6.2 FEATURE_MATRIX 更新要求

`FEATURE_MATRIX.md` 必须增加 SyncSystem 能力，并明确：

- Mac：规划中，负责导入、扫描和进入 Review Library。
- Harmony：规划中，负责输出 review bundle 到家庭存储。
- SMB / WebDAV：作为 SyncSystem 的家庭存储入口，不承诺云服务器。

### 6.3 ROADMAP 更新要求

`ROADMAP.md` 必须把家庭存储同步拆入 v1.x 摄影工作流，并把 Sync v0 / v1 / v2 放进阶段路线。

### 6.4 DATA_MODEL 更新要求

`DATA_MODEL.md` 必须增加 SyncSystem 领域对象，至少定义：

- `syncTarget`：SMB、WebDAV 或本地文件夹。
- `reviewBundle`：一次复盘的目录级同步单元。
- `bundleManifest`：bundle 内文件清单和完整性摘要。
- `importRecord`：Mac 已导入记录。
- `conflictRecord`：无法自动判断的冲突记录。

## 7. 实施路线

### 7.1 Sync v0：手动文件交换

目标：

- 保持 `review.json` 为核心交换文件。
- Harmony 可输出，Mac 可手动导入。
- 用户能明确知道文件位置和导入结果。

风险：

- 只有 JSON 时照片不可见。
- 用户需要手动选择文件。
- 重复导入反馈如果不清楚，会降低信任。

进入条件：

- `review.json` 语义稳定。
- Mac Review Library 能接收外部复盘记录。
- 导入失败能提示原因。

### 7.2 Sync v1：家庭存储 review bundle

目标：

- 支持 SMB / WebDAV / 本地同步目录作为家庭存储入口。
- 以 review bundle 作为标准同步单元。
- Mac 支持手动导入和启动扫描。
- 冲突处理遵循“跳过明确重复，保留不确定副本”。

风险：

- WebDAV 上传可能出现半完成目录。
- SMB / WebDAV 的目录可用性和权限差异大。
- 用户手动移动文件可能导致来源路径变化。

进入条件：

- `SYNC_SYSTEM_V1.md` 产品设计已同步两端。
- `DATA_MODEL.md` 已定义 SyncSystem。
- Product Layer 同步检查通过。
- 双端实现 PR 能引用同一份 Product Layer commit。

### 7.3 Sync v2：扫描增强与照片体验

目标：

- 增加定时扫描和立即扫描。
- 稳定支持 `photo.jpg` / `preview.jpg`。
- 增强导入报告、重复照片提示和缺失文件状态。
- 为后续搜索、筛选和成长统计提供稳定来源。

风险：

- 照片文件体积带来性能、网络和存储压力。
- 去重如果过度自动化，可能误删或误合并。
- 实时监听在网络盘上不稳定，不能作为唯一同步机制。

进入条件：

- Sync v1 的 bundle 目录规范稳定。
- 用户能理解导入状态和冲突提示。
- Mac Review Library 对缺失照片、重复记录和来源路径变化已有清晰展示。

## 8. 验证要求

本轮文档设计完成后必须验证：

1. Product Layer 同步检查：两个客户端 `docs/product/` 内容一致。
2. `bash scripts/verify_product_docs_sync.sh`：Mac 与 Harmony 两边都通过。
3. `git diff --check`：两个仓库都无 Markdown 空白错误。

本轮不运行 Swift / ArkTS 业务构建作为功能验收，因为本轮禁止开发业务功能。
