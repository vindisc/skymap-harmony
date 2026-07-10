# 发布工程卫生

本目录记录 HarmonyOS 端发布前后必须遵守的工程卫生规则。目标是把发布签名、审核反馈、HAP 归档和版本标签从日常开发改动里隔离出来，避免误提交私有材料或无法追溯审核版本。

## 当前文件

- `SIGNING_MATERIALS.md`
  - 发布 / 测试签名材料隔离规则
  - `build-profile.json5` 切换检查点
  - 哪些文件可以提交、哪些只能本机保存
- `REVIEW_FEEDBACK_TEMPLATE.md`
  - 华为审核通过 / 驳回后的记录模板
  - 复提前验证清单
- `HAP_ARCHIVE_LOG.md`
  - 审核通过后的 HAP 归档记录
  - `v0.1.0` tag 创建和推送步骤
- `ASSET_ARCHIVE_POLICY.md`
  - 图标、截图、HAP、签名材料和提审附件的归档边界
  - Git 可跟踪资产清单和发布前检查流程

## 当前原则

- 当前 `0.1.0` 已通过华为审核。
- 创建 `v0.1.0` tag 前，必须先记录 HAP、提交 hash、构建时间和签名状态。
- 审核驳回时先填写审核反馈记录，再做修复、验证、提交和复提。
- 发布证书、profile、p12、pem、截图草稿和签名中间文件不进入 Git。
- 仓库 `build-profile.json5` 保持无签名；本机签名只放在被忽略的 `build-profile.local.json5`。
- `release-assets/README.md` 与四个已公开 AppGallery 图标是当前唯一允许跟踪的发布资产。
- 新截图、HAP、提审附件和临时发布材料进入本机归档目录后默认不提交。

## 常用检查

提交前至少执行：

```bash
git status --short
node scripts/audit_workspace_hygiene.mjs
node scripts/verify_release_hygiene.mjs
```

日常无签名验证执行：

```bash
bash scripts/build_hap.sh
```

提审发布构建执行：

```bash
bash scripts/build_hap.sh --signing release
```

如果构建通过 `CompileArkTS` 和 `PackageHap`，但失败在 `SignHap`，优先检查本机 keystore、profile、JDK 和 DevEco 签名环境，不把它误判为业务代码编译失败。
