# Review Bundle v1 E2E Checklist

日期：2026-06-27

本文用于 Mac / HarmonyOS 单条 review bundle v1 的端到端验收。当前范围只覆盖 HarmonyOS 单条导出、家庭存储落盘、Mac 单条导入、重复导入和失败提示，不包含自动同步、批量导入、双向同步或远端删除。

## 一、HarmonyOS 导出前置条件

- 家庭存储已配置，且当前设备能写入目标目录。
- HarmonyOS 本地复盘库中已有至少一条复盘记录。
- 复盘记录可进入预览或详情页。
- 用户点击“导出复盘包”。
- 本轮不要求原图进入复盘包。

## 二、HarmonyOS 导出成功检查

家庭存储中应出现类似目录：

```text
Skymap/ReviewBundles/YYYY/MM/review_xxx/
```

目录内应包含：

- `manifest.json`
- `review.json`
- `exports/review-card.png`
- `thumbnails/thumb.jpg`
- `assets/README.md`

文件与字段检查：

- `manifest.json` 可解析。
- `manifest.bundleVersion = 1`。
- `manifest.reviewJsonPath = review.json`。
- `manifest.originalPhoto.included = false`。
- `manifest.exportedImages` 包含 `exports/review-card.png`。
- `review.json` 可按 Review JSON v1 解析。
- `review.json` 字段未被 bundle 信息污染。
- `review.json` 不包含 `bundleId`、`remotePath`、`thumbnailPath`、`exportedImages`、`checksum`。
- `decision` 只允许 `works`、`notWorks`、`uncertain`。
- 导出图是可打开的 PNG。
- 缩略图是可打开的 JPEG。
- `assets/README.md` 说明 v1 默认不打包原图。

## 三、Mac 导入前置条件

- Mac 能访问该 review bundle 目录，可以来自 NAS、SMB、同步目录或本地拷贝。
- 用户打开 Mac 端复盘库。
- 用户点击“导入复盘包”。
- 文件选择说明为“选择从 HarmonyOS 导出的复盘包目录。”。
- 用户选择单个 review bundle 目录，不选择月份目录或 `ReviewBundles` 根目录。

## 四、Mac 导入成功检查

- 复盘库出现一条新记录。
- 复盘字段来自 `review.json`，不是来自 `manifest.json` 摘要。
- `titleText` 显示正确。
- `reviewTimeText` 显示正确。
- `reviewerText` 显示正确。
- `decision` 显示为成立、不成立或待判断。
- `blockerText`、`strongestRelationText`、`visualFactText` 等长文本不丢失，中文和换行保持可读。
- 导出图可显示或可在 Mac 管理目录中定位。
- 缩略图可显示；如果 `thumbnails/thumb.jpg` 缺失，Mac 使用导出图降级。
- `review.json` 原文件不被修改。
- 导入后写入 Mac 复盘库的复盘内容不包含 bundle 字段。
- 再次导入同一 bundle 时提示“该复盘包已导入”，不产生第二条记录。
- 普通用户失败提示统一为“复盘包导入失败，请检查文件”，技术细节只进入日志或 debug 信息。

## 五、失败场景

以下场景必须有稳定结果：

- `bundleVersion` 不支持：拒绝导入。
- 缺 `manifest.json`：拒绝导入。
- 缺 `review.json`：拒绝导入。
- 缺 `exports/review-card.png`：拒绝导入。
- 缺 `thumbnails/thumb.jpg`：允许导入，产生固定 warning，并用导出图降级。
- 缺 `assets/README.md`：允许导入，产生固定 warning。
- 已导入重复 bundle：提示“该复盘包已导入”，不新增记录。
- `review.json` 混入 bundle 字段：拒绝导入。
- `decision` 不是 `works`、`notWorks`、`uncertain`：拒绝导入。
- Mac 写入复盘库失败：拒绝导入并清理本次已复制资产，不能留下半条记录。

## 六、当前不包含

- 不做自动同步。
- 不做批量导入。
- 不做双向同步。
- 不做远端删除。
- 不做冲突自动合并。
- 不打包原图。
- 不修改 Review JSON v1 字段。
- 不修改 manifest v1 字段。
- 不依赖 HarmonyOS RDB。
- 不依赖 HarmonyOS 原图路径。

## 七、当前测试状态

Mac 当前已有模拟 fixture 覆盖：

- bundle 读取与校验。
- Review JSON v1 解析。
- bundle 字段污染拒绝。
- 非标准 `decision` 拒绝。
- 导出图缺失拒绝。
- 缩略图缺失 warning 与导出图降级。
- `assets/README.md` 缺失 warning。
- 单个 bundle 导入 Mac 复盘库。
- 重复 bundleId 跳过，不新增记录。
- 导入不修改源 `review.json`。
- manifest 字段不写回 `review.json`。

真实 HarmonyOS 真机导出的 bundle 样本尚未加入 fixture。发布前必须补充真实样本回归，至少覆盖中文字段、换行、空字段、真实 PNG、真实 JPEG、`assets/README.md`、`manifest.originalPhoto.included=false` 和 `review.json` 字段无污染。
