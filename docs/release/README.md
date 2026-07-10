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

## 当前原则

- 当前审核仍处于等待结果阶段，不提前创建 `v0.1.0` tag。
- 只有华为审核通过后，才记录最终 HAP、提交 hash、构建时间并创建 tag。
- 审核驳回时先填写审核反馈记录，再做修复、验证、提交和复提。
- 发布证书、profile、p12、pem、截图草稿和签名中间文件不进入 Git。
- 已跟踪的 AppGallery 图标资产继续保留；新截图和临时发布材料进入 `release-assets/` 后默认不提交。

## 常用检查

提交前至少执行：

```bash
git status --short
node scripts/verify_release_hygiene.mjs
```

发布打包优先执行：

```bash
bash scripts/build_hap.sh
```

如果构建通过 `CompileArkTS` 和 `PackageHap`，但失败在 `SignHap`，优先检查本机 keystore、profile、JDK 和 DevEco 签名环境，不把它误判为业务代码编译失败。
