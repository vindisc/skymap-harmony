# 签名材料隔离说明

更新时间：2026-07-14

本文说明当前签名隔离与自动切换流程。仓库中的 `build-profile.json5` 是无签名基线；真实签名材料只存在于被忽略的本机配置。

## 1. 当前发布开关

当前签名流程使用两个文件：

- `build-profile.json5`：Git 跟踪的无签名基线，不包含 `signingConfigs`、本机路径或密码。
- `build-profile.local.json5`：本机完整签名配置，已被 `.gitignore` 排除。
- `.gitattributes`：只为 `build-profile.json5` 声明本地 clean/smudge filter；未配置本机签名的克隆仍读取无签名基线。

当前仓库不新增独立 `test` product。`default` product 继续复用同一套 SDK 与模块配置，通过 `buildMode=debug/release` 和临时签名覆盖区分日常构建与发布构建，避免复制一套容易漂移的 product 配置。

## 2. 自动切换命令

查看状态，不读取或输出密码：

```bash
bash scripts/build_hap.sh --status
```

默认无签名构建：

```bash
bash scripts/build_hap.sh
```

本机 debug 签名构建：

```bash
bash scripts/build_hap.sh --signing debug
```

发布签名构建：

```bash
bash scripts/build_hap.sh --signing release
```

debug 模式优先查找名为 `debug` 的 signingConfig，并兼容 DevEco 默认生成的 `default` 名称。release 模式只接受 `release`。

签名构建开始前，脚本会校验 p12、profile、证书和必要字段；随后临时替换根配置。无论构建成功、失败或收到终止信号，脚本都会恢复仓库中的无签名基线。

## 3. 本机配置准备

首次配置时，在 DevEco Studio 中生成或导入 debug / release 签名，然后将完整可用配置保存为仓库根目录的 `build-profile.local.json5`。该文件可以包含 `debug`、`default`、`release` signingConfig，但不能提交。

如果 DevEco 重新生成或重新加密了 Debug 签名，可在完成一次工程同步后迁移其最新本机缓存：

```bash
node scripts/manage_signing_profile.mjs migrate-ide-cache
```

可以单独验证本机材料：

```bash
node scripts/manage_signing_profile.mjs verify-local debug
node scripts/manage_signing_profile.mjs verify-local release
```

需要使用 DevEco Studio 的运行按钮调试真机时，执行一次：

```bash
node scripts/manage_signing_profile.mjs ide-enable
```

该命令把 Debug 签名投影到本机工作树，并在当前仓库的本地 Git 配置中安装 clean
filter：DevEco 能读取签名，`git add` 和提交看到的仍是无签名配置。同时会给本机
DevEco 运行配置写入已经验证兼容当前 p12 的 Zulu 11。执行后重启 DevEco Studio。

停用本机 IDE 签名：

```bash
node scripts/manage_signing_profile.mjs ide-disable
```

## 4. 可以提交的内容

可以进入 Git：

- 发布流程文档
- 审核反馈记录
- HAP 归档记录
- 不含密钥、不含密码、不含本机绝对路径的配置示例
- 已确认可公开的 AppGallery 图标资产

## 5. 禁止提交的内容

以下内容只能保留在本机或受控密钥库，不能提交：

- `.p12`
- `.p7b`
- `.cer`
- `.pem`
- keystore 密码
- key alias 密码
- 华为后台下载的发布 profile
- 从 profile / cert 提取出的中间证书文件
- `release-assets/signing/`
- 临时审核截图目录 `release-assets/appgallery-screenshots/`
- `.DS_Store`
- `build-profile.local.json5`

`.gitignore` 已覆盖以上常见文件和目录。提交前仍必须执行 `git status --short` 人工确认。

## 6. 发布态检查

提审或复提前确认：

- `bash scripts/build_hap.sh --status` 显示本机可用签名包含 `release`。
- `AppScope/app.json5` 中 `versionName` 和 `versionCode` 与华为后台一致。
- `bash scripts/build_hap.sh --signing release` 至少通过 `CompileArkTS` 和 `PackageHap`。
- 如果 `SignHap` 失败，记录错误信息和本机环境，不直接改业务代码绕过。
- 生成的 signed HAP 文件名、大小、构建时间、commit hash 记录到 `HAP_ARCHIVE_LOG.md`。

## 7. 测试态检查

日常测试前确认：

- 不使用发布 p12 / release profile 做普通调试。
- 本机 debug 证书、profile、p12 路径和密码不提交。
- 测试完成无需手工切回；脚本退出时自动恢复无签名基线。

## 8. 凭据处置

本轮扫描了当前仓库全部 Git 提交，没有发现签名密码、本机路径或材料字段进入提交历史。原敏感配置只存在于本机通过 `skip-worktree` 隐藏的工作树文件，当前已迁移到被忽略的 `build-profile.local.json5`。

如果未来门禁发现真实凭据已经进入提交历史，必须先轮换受影响的 keystore 密码、key 密码和发布 profile，再单独评估历史重写；历史重写会改变提交 hash 并要求强制推送，不能与普通功能提交混合。

不得使用 `skip-worktree` 或 `assume-unchanged` 隐藏 `build-profile.json5`。IDE 本地签名只允许通过
仓库声明的 clean filter 投影；工作区门禁会验证过滤后的内容必须与 Git 暂存区无签名基线完全一致。
