# 发布资产目录

本目录只允许跟踪已经确认可以公开、且需要随源码复现的 AppGallery 图标资产。

## 当前允许跟踪

- `README.md`
- `appgallery-icon-1024.png`
- `appgallery-icon-216.png`
- `appgallery-icon-background-1024.png`
- `appgallery-icon-foreground-1024.png`

新增可跟踪资产时，必须同时更新发布资产门禁和 [`docs/release/ASSET_ARCHIVE_POLICY.md`](../docs/release/ASSET_ARCHIVE_POLICY.md)，不能直接把整个目录加入 Git。

## 仅本机或发布归档保存

以下目录和文件类型已被 `.gitignore` 排除：

- `appgallery-screenshots/`：商店截图和截图草稿
- `signing/`、`private/`：证书、profile、密钥和签名中间文件
- `packages/`：signed / unsigned HAP 及其他安装包
- `submissions/`：提审压缩包、后台导出材料和临时附件
- `*.p12`、`*.p7b`、`*.cer`、`*.pem`、`*.profile`
- `*.jks`、`*.keystore`、`*.key`、`*.csr`、`*.der`
- `*.hap`、`*.hsp`、`*.har`、`*.zip`

这些文件可以保留在本机工作区供发布使用，但不得通过 `git add -f` 绕过忽略规则。正式提审产物只在华为后台或受控发布归档中保存，仓库只记录版本、提交、文件名、时间和签名状态。
