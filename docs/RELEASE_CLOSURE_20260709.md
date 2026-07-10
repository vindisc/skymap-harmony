# 0.1.0 版本收口审计

日期：2026-07-09

当前状态：HarmonyOS 端 `0.1.0` 已通过华为审核。本文件用于记录本轮版本收口结论、发布 / 测试切换要求、待补充文档和下一版本建议优先级。

## 1. 收口边界

本轮只做文档层收口，不调整业务代码、页面结构、数据结构或签名配置。

当前以代码和已跟踪文档为事实来源：

- `README.md`
- `docs/mobile-main-flow.md`
- `docs/product/CURRENT_PRODUCT_SPEC.md`
- `docs/product/DATA_MODEL.md`
- `docs/product/REVIEW_LIBRARY_STORAGE_AUDIT.md`
- `docs/product/REVIEW_BUNDLE_V1_V2_CONTRACT.md`
- `docs/product/REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md`

以下内容不再作为当前版本承诺：

- 自动同步、双向同步、冲突合并
- 账号系统、云端服务、AI 自动分析
- Mac 端未来规划反写成 HarmonyOS 当前能力
- 旧统计口径 `学习概览 / 复盘质量`
- 把 `Pending` 待复盘任务混入已完成 `Review` 模型

## 2. 文档审计结论

当前已跟踪的正式文档基本集中在 `README.md` 和 `docs/` 下，产品层旧路线图、愿景、阶段计划和跨端中间方案已经在上一轮清理出正式入口。

本轮发现并处理：

- `docs/product/REVIEW_BUNDLE_V2_ORIGINAL_PHOTO.md` 仍保留“后续新增入口 / 本阶段暂不要求 HarmonyOS 真实 v2 导出闭环”的旧表述；本轮改为当前已实现导出入口的说明。
- `docs/AUDIT_CLEANUP_SUMMARY.md` 需要补充本轮审核等待期的文档状态和下一步边界。
- 根目录存在若干未跟踪的卡片 UI 草案 Markdown，它们没有进入正式文档索引。本轮不直接删除未跟踪文件，建议后续确认无用后归档或删除。

本轮仍建议清理但未直接改动：

- `.DS_Store` 未跟踪文件：建议从工作区删除或加入忽略规则。
- `release-assets/` 下生成图、截图、签名中间材料：建议建立单独发布资产归档规则，避免误提交。
- 发布证书、profile、签名材料：建议下一版把可公开配置和私有材料彻底分离。

2026-07-10 补充：上述发布资产与工作区卫生项已完成规则化收口。

- 新增 `docs/release/ASSET_ARCHIVE_POLICY.md` 和 `release-assets/README.md`，明确公开资产允许清单与仓库外归档规则。
- `.gitignore` 已覆盖截图、安装包、提审附件、证书、profile、keystore、私钥和签名中间文件。
- `scripts/audit_workspace_hygiene.mjs` 会阻止敏感资产被跟踪、未忽略或本机 `build-profile.json5` 改动混入发布检查。
- 根目录 UI 草案保留原位置，并通过本仓库本机 `.git/info/exclude` 隔离，不进入正式文档或提交范围。

## 3. 发布 / 测试切换说明

当前仓库的 `build-profile.json5` 已净化为无签名基线；本机签名配置保存在被忽略的 `build-profile.local.json5`，由构建脚本临时加载并自动恢复。

### 发布或提审前

发布态必须满足：

- `bash scripts/build_hap.sh --status` 显示本机存在 `release` 签名。
- 本机 `build-profile.local.json5` 的 release 材料文件存在且已完成凭据轮换。
- `AppScope/app.json5` 中 `versionCode`、`versionName` 已确认对应本次提审版本。
- 使用仓库脚本打包：

```bash
bash scripts/build_hap.sh --signing release
```

脚本固定构建 `entry` 模块、`default` product，并按签名模式选择 `debug/release` buildMode 后执行 `assembleHap`。构建产物通常位于：

```text
entry/build/default/outputs/default/entry-default-signed.hap
```

打包后至少确认：

- HAP 是 signed 产物。
- 应用名、图标、版本号与华为后台提交信息一致。
- 首页、复盘库、统计、我的四个主 Tab 可正常进入。
- 复盘卡 JPG 导出、复盘包导出、含原图复盘包导出有明确成功或失败反馈。

### 日常测试或调试前

测试态不要沿用发布签名材料做日常调试。切换时只改签名配置，不改业务代码。

推荐做法：

- 无签名验证直接执行 `bash scripts/build_hap.sh`。
- 真机调试执行 `bash scripts/build_hap.sh --signing debug`，使用本机 debug / default signingConfig。
- 本机 debug 证书、profile、p12 路径和密码只放在 `build-profile.local.json5`，不要提交。
- 发布构建显式执行 `bash scripts/build_hap.sh --signing release`；脚本结束后自动恢复无签名基线。

当前仓库没有独立 `test` product；“测试态”使用 `default` product + `debug` buildMode。签名切换已经脚本化，不再要求人工修改被跟踪配置。

## 4. 待补充文档

以下文档已在 [`docs/release/README.md`](./release/README.md) 中补齐或留出模板：

| 优先级 | 文档 | 目的 |
| --- | --- | --- |
| P0 | [`docs/release/SIGNING_MATERIALS.md`](./release/SIGNING_MATERIALS.md) | 明确哪些文件可提交、哪些只允许本机保存 |
| P0 | [`docs/release/REVIEW_FEEDBACK_TEMPLATE.md`](./release/REVIEW_FEEDBACK_TEMPLATE.md) | 华为审核通过 / 驳回后沉淀问题、修复和复提步骤 |
| P0 | [`docs/release/HAP_ARCHIVE_LOG.md`](./release/HAP_ARCHIVE_LOG.md) | 审核通过后的 HAP 归档记录和 `v0.1.0` tag 步骤 |
| P1 | 家庭存储同步设计 | 区分当前手动导出、下一版同步队列、失败重试和冲突处理 |
| P1 | [`docs/release/ASSET_ARCHIVE_POLICY.md`](./release/ASSET_ARCHIVE_POLICY.md) | 图标、截图、HAP、证书中间文件和审核素材归档规范，已完成 |
| P2 | 复盘包导入回流计划 | 说明 HarmonyOS 端未来是否需要读取 v1 / v2 复盘包 |

## 5. 下一版本建议优先级

### P0：发布工程卫生

- 已完成：发布、调试和无签名构建切换脚本化，仓库配置保持无签名基线。
- 已完成：忽略 `.DS_Store`、发布截图、安装包、提审附件和签名中间文件，并加入自动门禁。
- 审核通过后打 `v0.1.0` 标签，并记录 HAP 文件名、构建时间、版本号和提交 hash。
- 如果审核驳回，优先形成“审核反馈 -> 修复点 -> 验证脚本 -> 复提说明”的闭环。

### P1：家庭存储与导出闭环

- 把家庭存储从“手动导出目标”推进到可恢复、可重试、可诊断的同步队列。
- 给复盘包导出补充更完整的失败分类和用户可理解反馈。
- 明确 v1 成品图复盘包与 v2 含原图复盘包在 HarmonyOS 端是否需要导入入口。

### P1：数据安全与备份恢复

- 增加用户可见的本地备份 / 恢复说明或入口。
- 梳理 RDB `reviews`、`pending_review_photos`、`review_exchange` 的异常恢复策略。
- 给删除、导出失败、原图 URI 失效提供更明确的兜底说明。

### P2：体验打磨

- 继续压实移动端长文本输入、键盘遮挡、底部按钮和滚动体验。
- 继续按横图、竖图、方图验证导出图布局。
- 统计页可以考虑增加更细的时间维度，但不要改变当前 `学习进度 / 复盘结果` 口径。

## 6. 当前风险

- 本机签名配置曾通过 `skip-worktree` 隐藏；全部 Git 提交扫描未发现敏感字段，当前已迁移到忽略文件并禁止再次隐藏索引状态。
- 当前工作区仍有下一版本 UI 改动；它们属于独立工作集，发布资产门禁不会自动提交或删除这些内容。
- 本机仍可保留被忽略的截图、证书和签名中间文件；它们不等于正式归档，发布时仍需写入受控归档并更新 `HAP_ARCHIVE_LOG.md`。
- 当前家庭存储仍是手动配置与导出能力，不是自动同步产品。
- 当前审核通过状态来自人工上下文，仓库无法直接验证华为后台记录；正式归档以 `docs/release/HAP_ARCHIVE_LOG.md` 为准。
