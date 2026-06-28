# skymap-harmony 0.2.0 Beta Candidate 检查清单

## Beta 对外承诺

- [x] 创建摄影复盘。
- [x] 本地保存历史。
- [x] 复盘库查看、搜索、筛选、删除。
- [x] 统计轻量看板。
- [x] 导出复盘长图。
- [x] 导出 `review.json`。
- [x] 复制复盘数据。
- [x] 复盘人设置。
- [x] 首页图片设置。

## Beta 不对外承诺

- [x] 不承诺 Review Bundle。
- [x] 不承诺含原图复盘包。
- [x] 不承诺 SMB 自动同步。
- [x] 不承诺 WebDAV。
- [x] 不承诺 Sync v1。
- [x] 不承诺成长统计。
- [x] 不承诺 AI 分析。

## 自动验证

- [x] `scripts/verify_*.mjs` 全部通过。
- [x] 校验导出菜单只保留「导出图片」「导出 review.json」「复制复盘数据」。
- [x] 校验普通用户路径隐藏 Review Bundle、含原图复盘包、家庭存储和同步中心入口。
- [x] 校验 `review.json` 字段完整，空字段保留 key。
- [x] 校验 `decision` 只输出 `works`、`uncertain`、`notWorks`。
- [x] 校验 `reviewerText` 来自复盘人设置，未设置时为空字符串。
- [x] 校验 `review.json` 文件名稳定，不生成泛化的 `review.review.json` fallback。
- [x] 校验 RDB 开发诊断入口默认不对普通用户展示。
- [x] 校验版本口径为 `0.2.0 Beta` / `Harmony Beta 0.2`。

## 需真机验证

- [ ] 从系统相册选择真实照片创建复盘。
- [ ] 编辑页长文本输入时键盘不遮挡当前输入框。
- [ ] 保存后进入阅读页，返回复盘库可看到记录。
- [ ] 复盘库搜索、筛选、删除后首页和统计同步刷新。
- [ ] 导出复盘长图后，图库最近项目可见。
- [ ] 导出 `review.json` 时，系统保存弹窗成功、取消、失败三态文案准确。
- [ ] 复制复盘数据后，粘贴内容是 `ReviewCardExchangeSchema v1` JSON。
- [ ] 复盘人设置后，导出和复制的 `reviewerText` 正确。
- [ ] 首页图片设置后，首页展示和轮播状态正确。

## 构建验证

推荐命令：

```bash
bash scripts/build_hap.sh
```

等价 hvigor 命令：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
--mode module -p module=entry -p product=default assembleHap --no-daemon
```

验收标准：

- `CompileArkTS` 通过。
- `PackageHap` 通过。
- 如果 `SignHap` 因本机签名或 keystore 环境失败，只记录签名错误；这类失败不等同于代码编译失败。
