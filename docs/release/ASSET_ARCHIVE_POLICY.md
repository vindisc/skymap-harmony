# 发布资产归档规范

本文定义 AppGallery 图标、商店截图、HAP、签名材料和提审附件的归档边界。目标是让公开资产可追溯、私有材料不进入 Git、审核产物能够通过元数据定位。

## 资产分层

| 资产 | Git | 保存位置 | 仓库记录 |
| --- | --- | --- | --- |
| 已公开 AppGallery 图标 | 跟踪 | `release-assets/` 根目录 | 文件本身和提交历史 |
| 商店截图、截图草稿 | 不跟踪 | 华为后台或受控发布归档 | 版本、用途和提交日期 |
| signed / unsigned HAP | 不跟踪 | 华为后台或受控发布归档 | `HAP_ARCHIVE_LOG.md` |
| 证书、profile、keystore、私钥 | 禁止跟踪 | 本机安全存储或团队密钥系统 | 只记录用途和有效期，不记录密码 |
| 提审压缩包和临时附件 | 不跟踪 | 受控发布归档 | 对应版本和审核批次 |

`release-assets/README.md` 与四个已公开图标是当前唯一允许跟踪的发布资产。其他文件即使不含密码，也不能因为“提审时用过”直接进入 Git。

## 归档目录建议

仓库外的受控发布归档按以下结构保存：

```text
skymap-harmony/
└── 0.1.0/
    ├── packages/
    ├── appgallery-screenshots/
    ├── submissions/
    └── checksums.txt
```

签名材料不要与普通发布资产放在同一个目录；证书、profile、keystore 和密码必须使用单独的安全存储。

## 发布前流程

1. 确认 `git status --short` 中没有本轮范围外文件。
2. 运行工作区与发布资产门禁：

```bash
node scripts/audit_workspace_hygiene.mjs
node scripts/verify_release_hygiene.mjs
```

3. 构建并区分 ArkTS 编译、HAP 打包和签名结果。
4. 将最终产物、截图和提审附件复制到仓库外的受控发布归档。
5. 在 `HAP_ARCHIVE_LOG.md` 记录版本、提交 hash、HAP 文件名、构建时间、签名状态和华为审核结果。
6. 提交前再次运行 `git status --short`，确认私有材料和发布产物没有进入暂存区。

## 禁止事项

- 不提交证书、profile、keystore、密码、私钥和签名中间文件。
- 不提交 signed / unsigned HAP、提审压缩包或商店截图草稿。
- 不用 `git add -f` 绕过发布资产忽略规则。
- 不把 `build-profile.json5` 的本机签名切换混入业务或文档提交。
- 不以本机文件仍然存在为“已归档”；正式归档必须有明确版本目录和 `HAP_ARCHIVE_LOG.md` 记录。
