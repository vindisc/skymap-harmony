# 签名材料隔离说明

更新时间：2026-07-10

本文只说明发布工程卫生，不改变当前签名配置。

## 1. 当前发布开关

当前签名切换集中在根目录 `build-profile.json5`：

- `products[0].signingConfig` 决定当前 `default` product 使用哪套签名。
- 提审 / 发布态必须指向 `release`。
- 日常测试态应使用本机 debug / default 签名，不沿用发布签名材料。

当前仓库没有独立 `test` product；“测试态”实际指 DevEco Studio 自动调试签名或本机 debug signingConfig。

## 2. 可以提交的内容

可以进入 Git：

- 发布流程文档
- 审核反馈记录
- HAP 归档记录
- 不含密钥、不含密码、不含本机绝对路径的配置示例
- 已确认可公开的 AppGallery 图标资产

## 3. 禁止提交的内容

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

`.gitignore` 已覆盖以上常见文件和目录。提交前仍必须执行 `git status --short` 人工确认。

## 4. 发布态检查

提审或复提前确认：

- `build-profile.json5` 中 `products[0].signingConfig` 指向 `release`。
- `AppScope/app.json5` 中 `versionName` 和 `versionCode` 与华为后台一致。
- `bash scripts/build_hap.sh` 至少通过 `CompileArkTS` 和 `PackageHap`。
- 如果 `SignHap` 失败，记录错误信息和本机环境，不直接改业务代码绕过。
- 生成的 signed HAP 文件名、大小、构建时间、commit hash 记录到 `HAP_ARCHIVE_LOG.md`。

## 5. 测试态检查

日常测试前确认：

- 不使用发布 p12 / release profile 做普通调试。
- 本机 debug 证书、profile、p12 路径和密码不提交。
- 测试完成准备复提时，切回 release 签名并重新打包。

## 6. 下一步建议

下一版可以把 `debug / release` 切换脚本化，目标是：

- 只允许在本机生成临时 debug 配置。
- release 配置只在发布分支或提审步骤启用。
- 脚本输出明确的当前签名状态和 HAP 路径。
