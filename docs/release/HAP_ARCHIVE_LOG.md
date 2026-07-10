# HAP 归档记录

更新时间：2026-07-10

本文件只记录已经确认的发布归档。当前 0.1.0 已通过华为审核，本轮记录归档并创建正式 tag。

## 归档规则

审核通过后再执行：

```bash
git status --short
git rev-parse --short HEAD
git tag -a v0.1.0 -m "发布 0.1.0"
git push origin v0.1.0
```

创建 tag 前必须确认：

- 当前 commit 就是华为审核通过版本对应的源码。
- HAP 已成功签名并与华为后台审核包一致。
- `AppScope/app.json5` 的 `versionName` 和 `versionCode` 与审核包一致。
- `git status --short` 中没有会影响发布源码的未提交改动。
- HAP 文件名、大小、构建时间、签名状态已经记录在下方表格。

## 0.1.0 归档记录

| 字段 | 内容 |
| --- | --- |
| 状态 | 华为审核通过 |
| versionName | `0.1.0` |
| versionCode | `3` |
| 计划 tag | `v0.1.0` |
| 源码 commit | 以 `v0.1.0` tag 指向的提交为准 |
| HAP 文件名 | 华为后台已通过审核包，本机当前未保留可校验 signed HAP |
| HAP 路径 | 华为后台审核包；本机仅有 `entry/build/default/outputs/default/entry-default-unsigned.hap` |
| HAP 大小 | 本机 unsigned HAP 约 3.6M；signed 审核包大小待从华为后台补齐 |
| 构建时间 | 本机 unsigned HAP：2026-07-09 23:51；signed 审核包构建时间待补齐 |
| 签名状态 | 华为后台审核包已通过；本机当前 `SignHap` 因 keystore / JDK 算法兼容失败，无法重签校验 |
| 华为审核结果 | 通过 |
| 备注 | `v0.1.0` tag 指向包含本归档记录的提交；审核包二进制以华为后台已通过版本为准 |

## 历史归档

暂无。
