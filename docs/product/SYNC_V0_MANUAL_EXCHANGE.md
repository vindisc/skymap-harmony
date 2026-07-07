# Sync v0：手动文件交换

日期：2026-06-13

## 目标

Sync v0 只解决一件事：

```text
Harmony 导出 review.json
↓
用户手动交换文件
↓
Mac 导入 review.json
↓
写入 Review Library
```

这是一条“可理解、可验证、可手动完成”的最低可用闭环，不等于完整同步系统已经完成。

## 本轮明确不做

- 不做 SMB 自动同步。
- 不做 WebDAV 自动同步。
- 不做 review bundle。
- 不做 manifest。
- 不做照片二进制同步。
- 不做后台扫描。
- 不做定时同步。
- 不做 SMB / WebDAV 自动导入。

## 当前交换对象

- 交换文件名：`review.json`
- 交换内容：保持当前 v1 字段，不新增字段，不改字段名。
- Mac 侧归档结构：不改 `ReviewArchive` 和现有 sidecar 结构。

## 用户路径

### Harmony

1. 用户在阅读页点击「导出 review.json」。
2. 应用把 JSON 写到应用文件目录：`files/review_exchange/`。
3. 页面和 Toast 明确告诉用户导出路径。
4. 用户自行把该文件拷到家庭存储、共享文件夹、AirDrop、聊天工具或其他手动通道。

说明：

- 这一步是手动文件交换，不是自动同步。
- 当前只保证 review.json 落盘，不保证照片一起交换。

### Mac

1. 用户切到摄影复盘模板。
2. 打开「导入摄影复盘」。
3. 选择 Harmony 导出的 `review.json`，或直接粘贴 JSON。
4. Mac 先把复盘内容导入当前复盘卡。
5. 然后把同一份 `review.json` 写入本地 `Review Library`。

当前 `Review Library` 路径：

`~/Library/Application Support/Skymap/Review Library`

## Review Library 写入规则

- 导入成功后，Mac 必须明确提示“已写入 Review Library”。
- 同一份 `review.json` 重复导入时，不重复写入第二份文件。
- 重复导入时，当前照片仍可继续应用这份复盘内容，但 Review Library 要明确提示“已有同一份 review.json”。
- 导入失败时，错误提示必须面向用户可理解，例如 JSON 解析失败、文件无法读取、当前未选中照片或模板不对。

## 重复导入行为

重复判定以同一份 `review.json` 内容摘要为准。

- 首次导入：写入 Review Library。
- 再次导入同一内容：不重复落第二份文件。
- 用户反馈：明确告诉用户 Review Library 已有同一份 review.json。

## 搜索与验证

Sync v0 的“能在 Review Library 搜索到”当前只要求满足以下最低能力：

- 文件真实写入 Review Library。
- Review Library 保留标题、照片文件名、复盘人等检索字段。
- 本地校验和测试可以按标题、照片文件名、复盘人检索到该记录。

这不等于产品级复盘库 UI 已经完成。

## 成功与失败反馈

### Harmony 成功

- 明确告诉用户 `review.json` 已导出。
- 明确告诉用户文件路径。

### Harmony 失败

- 明确提示导出失败。
- 不伪装成已完成同步。

### Mac 成功

- 明确提示当前复盘内容已导入。
- 明确提示已写入 Review Library。

### Mac 失败

- 明确提示是读取失败、解析失败、文件名不一致确认未通过，还是当前上下文不满足导入条件。

## 与 Sync v1 的关系

Sync v0 只是手动文件交换阶段：

- 解决 review.json 从 Harmony 到 Mac 的最低成本接力。
- 不解决家庭存储自动发现。
- 不解决 bundle 完整性。
- 不解决照片预览同步。
- 不解决冲突列表、扫描任务和定时同步。

后续进入 Sync v1 时，标准同步单元仍以 review bundle 为目标，而不是把 v0 的手动文件交换误认为完整同步系统。
