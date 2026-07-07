# Review Library v1.1

## 目标

Review Library v1.1 只解决一个问题：让用户在 Mac / Harmony 两端都能稳定进入复盘库、搜索复盘、查看导入结果。

这一版是产品收口，不是 Sync v1，也不是完整同步系统。

## 范围

- Mac：强化 Review Library 入口、导入成功反馈、搜索、成立判断筛选和空状态。
- Harmony：统一“复盘库”命名，保持复盘库搜索/筛选可用，导出 `review.json` 后明确提示路径和下一步。
- Product Layer：更新矩阵、路线图和本说明文档，确保两端 `docs/product/` 全量同步。

## 明确不做

- 不做 review bundle。
- 不做 manifest。
- 不做照片同步。
- 不做 SMB / WebDAV 自动同步。
- 不改 `review.json` 字段。
- 不改 `ReviewArchive` / sidecar 结构。
- 不做标签、收藏、批注、统计、AI 分析。

## Mac 收口要求

- 工具栏必须有清晰可见的“复盘库”入口。
- 导入 `review.json` 成功后，用户必须能直接：
  - 查看复盘库。
  - 打开刚导入记录。
- 搜索必须支持：
  - 标题
  - 核心关系
  - 卡点
  - 文件名
- 筛选至少支持 `decision`。
- 空状态必须明确提示：
  - 可从 Harmony 导入 `review.json`
  - 或保存当前复盘
- 重复导入同一个 `review.json` 时，必须提示“已存在，不重复添加”，并允许定位到已有记录。
- 导入失败时，必须给出清晰错误提示。

## Harmony 收口要求

- 入口命名统一为“复盘库”。
- 导出 `review.json` 成功后，必须提示：
  - 文件路径
  - 下一步可传到 Mac 导入
- 复盘库搜索必须支持：
  - 标题
  - 核心关系
  - 卡点
  - 文件名
- 筛选至少支持成立判断。
- 空状态必须保留“创建第一条复盘”入口。
- 旧记录缺少 `reviewerText` 时，不显示脏占位。

## 验收口径

- 用户能在 Mac 打开 Review Library，看见导入结果进入库内。
- 用户重复导入同一份 `review.json` 时，看到明确去重反馈，并能定位已有记录。
- 用户能在 Harmony 导出 `review.json` 后知道文件在哪里，也知道下一步是传到 Mac 导入。
- 用户能在两端通过关键词和成立判断找到目标复盘。
- 这套能力只能表述为“Review Library v1.1”与“Sync v0 手动文件交换闭环”，不能表述为“同步系统已完成”。
