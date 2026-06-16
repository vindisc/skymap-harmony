# skymap-harmony v0.2 可用版检查清单

## 主链路

- [ ] 首页显示摄影复盘卡、副标题、开始复盘、复盘概览、最近一次复盘、我的项目。
- [ ] 点击开始复盘后可选择系统相册照片。
- [ ] 编辑页可填写标题和八个复盘字段。
- [ ] 点击保存并进入阅读后，立即进入「复盘记录」详情。
- [ ] 阅读页可编辑、复制复盘数据、导出图片。
- [ ] 回首页后统计、最近一次复盘、我的项目数量立即刷新。
- [ ] 进入「我的摄影复盘」能看到刚保存的记录。
- [ ] 左滑删除记录后，项目页和首页统计同步减少。

## 复盘字段

- [ ] 标题
- [ ] 视觉落点
- [ ] 落点原因
- [ ] 视线路径
- [ ] 画面事实
- [ ] 核心关系
- [ ] 是否成立
- [ ] 延伸理解
- [ ] 当前卡点

## decision 枚举

复制 JSON 的 `decision` 只能输出：

- `works`
- `uncertain`
- `notWorks`

手机端中文状态先归一化：

- 成立 -> `works`
- 待判断 / 不确定 -> `uncertain`
- 不成立 -> `notWorks`

## 首页统计口径

- [ ] 复盘概览统计全项目历史记录。
- [ ] 我的项目卡使用同一份历史记录生成。
- [ ] 当前只有 `default` 项目时，总复盘等于默认项目全部记录数。
- [ ] 成立、待判断、不成立的和等于总复盘。
- [ ] 新建记录后首页总数 +1。
- [ ] 删除记录后首页总数 -1。
- [ ] 最近一次复盘显示最新记录。
- [ ] 首页统计数字直接绑定标量 `@State`，不通过参数化统计项 builder 或嵌套 summary 对象渲染。
- [ ] 历史读取失败时保留上一轮可见统计，不把首页复盘概览清零。
- [ ] 连续天数计算失败时只显示 `—`，不影响总复盘、成立、待判断统计。
- [ ] `node scripts/verify_home_stats.mjs` 覆盖跨项目统计、状态归一化、迟到请求和读取失败保留旧值。
- [ ] `node scripts/verify_review_project_service_tests.mjs` 覆盖复盘服务统计、筛选、汇总和连续天数纯逻辑。

## 导出图规则

- [ ] 导出图是复盘长图，不是页面截图。
- [ ] 导出图包含照片、标题、复盘时间、成立状态和已填写字段。
- [ ] 复盘时间格式为 `YYYY-MM-DD HH:mm`。
- [ ] 复盘时间位于标题下方左侧。
- [ ] 成立状态位于同一行右侧。
- [ ] 空字段不导出，不留空白。
- [ ] 导出图不包含状态栏、返回、编辑、复制复盘数据、导出按钮、已保存、Toast 文案。
- [ ] 权限或保存弹窗出现时，背景阅读页不被导出长图放大覆盖。

## 复制 JSON 协议

- [ ] 阅读页保留「复制复盘数据」入口。
- [ ] 复制内容为 `ReviewCardExchangeSchema v1`。
- [ ] JSON 字段完整，空字段保留 key。
- [ ] `reviewStructure` 固定为 `quickReview`。
- [ ] `decision` 使用英文枚举。
- [ ] `reviewerText` 来自复盘设置。
- [ ] 页面正文不显示复制状态，只显示 Toast。

## 我的与设置

- [ ] 我的页可进入「复盘人」。
- [ ] 复盘人页可保存复盘人名称。
- [ ] 我的页可进入「同步中心」和「家庭存储」。
- [ ] 重启 App 后配置仍保留。
- [ ] 未设置时 `reviewerText` 为空字符串。
- [ ] 设置后复制 JSON 的 `reviewerText` 正确。

## 当前不做

- [ ] 不做多项目创建。
- [ ] 不做云同步。
- [ ] 不做账号登录。
- [ ] 不做 AI 分析。
- [ ] 不改 Mac 端。
- [ ] 不改 icon。
- [ ] 不重做字段名称。
- [ ] 不重做横图 / 竖图 / 方图差异导出。
- [ ] 不把导出做成页面截图。

## 构建验证

推荐命令：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
--mode module -p module=entry -p product=default assembleHap --no-daemon
```

如果当前终端或 DevEco Studio 遗留了错误的 `DEVECO_SDK_HOME`，优先执行：

```bash
bash scripts/build_hap.sh
```

脚本会自动停止旧 daemon，并固定使用：

- `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`
- `JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home`

验收标准：

- `CompileArkTS` 通过。
- `PackageHap` 通过。
- 如果 `SignHap` 因本机签名或 keystore 环境失败，需要记录具体错误；这类失败不等同于代码编译失败。
