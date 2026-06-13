# Sync v0.5：Review 手动交换可执行闭环

日期：2026-06-13

## 目标

Sync v0.5 只解决最低可用的用户交换链路：

```text
Harmony 导出 review.json 到系统文件
↓
用户通过文件/聊天/发送手动交给 Mac
↓
Mac 独立导入 review.json
↓
写入 Review Library
↓
用户能立即看到结果
```

## 本轮明确不做

- 不做 Sync v1
- 不做 review bundle
- 不做 manifest
- 不做 SMB / WebDAV 自动同步
- 不做标签、收藏、成长统计

## Harmony 用户路径

1. 用户在阅读页点击“导出 review.json”。
2. 应用先生成交换 JSON。
3. 应用拉起系统保存面板，由用户选择系统文件位置。
4. 成功后提示：
   - `review.json` 已保存到系统文件
   - 现在可直接发送给 Mac 导入
5. 如果用户没有完成系统保存：
   - 明确提示未完成导出到文件
   - 不把这次操作当成成功

产品要求：

- 不让用户记应用沙箱路径。
- 不让用户自己去浏览应用私有目录。
- 导出成功必须对应用户可理解的系统文件结果。

## Mac 用户路径

1. 用户打开 Review Library。
2. 用户点击“导入 review.json”。
3. 应用弹出文件选择，读取 Harmony 导出的 `review.json`。
4. 导入成功后，直接写入本地 Review Library。
5. UI 明确提供：
   - 立即查看
   - 定位记录
   - 打开复盘库

产品要求：

- Review 导入是独立能力。
- 不能要求用户先导入照片。
- 不能要求用户先选中照片。
- 不能要求用户先切模板才能看见导入结果。

## 成功反馈

### Harmony

- `review.json` 已保存到系统文件
- 现在可直接发送给 Mac 导入

### Mac

- 已写入 Review Library
- 可以立即查看这条记录

## 失败反馈

### Harmony

- 导出失败，请稍后重试
- 或：未完成导出到文件，请重新选择保存位置

### Mac

- 无法读取 review.json
- 复盘 JSON 解析失败
- 或其他面向用户可理解的导入失败提示

## 本轮验收口径

满足以下条件即可视为 `Sync v0.5` 闭环成立：

1. Harmony 导出的 `review.json` 不再只停留在沙箱路径提示。
2. 用户能把 `review.json` 保存到系统文件，并继续手动发送。
3. Mac 可以在没有当前照片上下文的情况下把 `review.json` 独立写入 Review Library。
4. 导入完成后，用户知道结果已经写到哪里，并能立刻定位到记录。
