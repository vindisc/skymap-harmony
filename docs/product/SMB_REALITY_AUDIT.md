# SMB Reality Audit

## 审计范围

- 仓库：`skymap-HarmonyOS`
- 分支搜索：`git branch -a`
- 历史关键词：`SMB`、`Smb`、`WebDAV`、`Storage`、`NAS`
- 重点文件：
  - `entry/src/main/ets/services/HomeStorageService.ets`
  - `entry/src/main/ets/services/HomeStorageSecretService.ets`
  - `entry/src/main/ets/services/Smb2Client.ets`
  - `entry/src/main/ets/pages/ReviewSettingsPage.ets`
  - `entry/src/main/ets/pages/PreviewPage.ets`

## 结论先看

当前用户真实设备上已经连续数天在使用的 SMB 能力，最可能不是来自当前 `master`，而是来自仍保留家庭存储代码的历史分支 `codex/audit-review-cleanup`，或来自该分支某个已安装到真机的构建产物。

原因很直接：

- 当前 `master` 不包含 `HomeStorageService.ets`、`HomeStorageSecretService.ets`、`Smb2Client.ets`
- 当前 `master` 的 `PreviewPage.ets` 和 `ReviewSettingsPage.ets` 也不再包含“上传家庭存储”、`SMB`、`WebDAV`、`HomeStorageProtocol` 等入口代码
- 全仓库里，包含这套代码的可恢复分支只查到 `codex/audit-review-cleanup`

## 关键事实

### 1. 当前主线没有 SMB 代码

`master` 分支里：

- 没有 `entry/src/main/ets/services/HomeStorageService.ets`
- 没有 `entry/src/main/ets/services/HomeStorageSecretService.ets`
- 没有 `entry/src/main/ets/services/Smb2Client.ets`
- `PreviewPage.ets` 和 `ReviewSettingsPage.ets` 文件虽然还在，但已不包含家庭存储上传入口和 SMB 设置页代码

### 2. 唯一可恢复分支

以下关键提交都只被 `codex/audit-review-cleanup` 包含：

- `de1a179` `新增家庭存储 WebDAV 上传`
- `8e711b1` `新增 SMB 系统保存模式`
- `a90cea7` `实现 SMB 直连上传`
- `33ba91a` `优化阅读页家庭存储入口`
- `c02e44a` `加固家庭存储安全与设置体验`

`git branch -a --contains` 检查结果表明，这些提交当前只存在于：

- `codex/audit-review-cleanup`
- `origin/codex/audit-review-cleanup`

### 3. 代码实际落点

在 `codex/audit-review-cleanup` 分支尖端 `634edb9` 的 tree 里，仍能找到：

- `entry/src/main/ets/services/HomeStorageService.ets`
- `entry/src/main/ets/services/HomeStorageSecretService.ets`
- `entry/src/main/ets/services/Smb2Client.ets`
- `entry/src/main/ets/pages/ReviewSettingsPage.ets`
- `entry/src/main/ets/pages/PreviewPage.ets`

并且：

- `PreviewPage.ets` 仍包含 `uploadReviewFileToHomeStorage()` 与“上传家庭存储”按钮
- `ReviewSettingsPage.ets` 仍包含 `HomeStorageProtocol.SMB`、SMB 地址、端口、共享名、用户名、密码等输入项

## Commit 审计结果

### 最后一个包含 SMB 能力的 commit

按“commit 的 tree 里仍然包含完整 SMB 能力”判断，最后一个可恢复 commit 是：

- `634edb9` `增强 Harmony 产品文档同步校验`

说明：

- 这个提交本身没有继续改 SMB 协议代码，但它所在的分支尖端 tree 仍然完整保留 SMB 能力
- 如果按“最后一个直接实现 SMB 直连能力的功能提交”判断，则是：
  - `a90cea7` `实现 SMB 直连上传`

### 最后一个包含 SMB 设置页的 commit

按“commit 的 tree 里仍然保留 SMB 设置页”判断，最后一个可恢复 commit 是：

- `634edb9` `增强 Harmony 产品文档同步校验`

按“最后一个直接改动 SMB 设置页代码”判断，是：

- `c4ba1cb` `优化核心页面按钮观感`

按“最后一个完成 SMB 设置页能力收口”的功能提交判断，是：

- `c02e44a` `加固家庭存储安全与设置体验`

### 最后一个包含 SMB 上传入口的 commit

按“commit 的 tree 里仍然保留 SMB 上传入口”判断，最后一个可恢复 commit 是：

- `634edb9` `增强 Harmony 产品文档同步校验`

按“最后一个直接改动上传入口”判断，是：

- `c4ba1cb` `优化核心页面按钮观感`

按“最后一个显式优化上传入口交互”的功能提交判断，是：

- `33ba91a` `优化阅读页家庭存储入口`

## 恢复判断

### A. 当前用户正在使用的 SMB 能力最可能来自哪里

最可能来自：

- `codex/audit-review-cleanup` 分支
- 或者该分支上某个已经安装到真实设备的构建产物

最有可能对应的代码位置：

- 服务层：`entry/src/main/ets/services/HomeStorageService.ets`
- SMB 协议层：`entry/src/main/ets/services/Smb2Client.ets`
- 凭据加固：`entry/src/main/ets/services/HomeStorageSecretService.ets`
- 设置页：`entry/src/main/ets/pages/ReviewSettingsPage.ets`
- 上传入口：`entry/src/main/ets/pages/PreviewPage.ets`

### B. 该能力是否已经存在于某个可恢复分支

是。

当前可确认的可恢复分支是：

- `codex/audit-review-cleanup`

### C. 恢复到当前主线需要哪些 commit

如果目标是恢复“当前真实设备上在用的 SMB 直连上传链路”，建议最小恢复集为：

1. `de1a179` `新增家庭存储 WebDAV 上传`
2. `8e711b1` `新增 SMB 系统保存模式`
3. `a90cea7` `实现 SMB 直连上传`
4. `33ba91a` `优化阅读页家庭存储入口`
5. `c02e44a` `加固家庭存储安全与设置体验`

如果要尽量贴近该分支后续 UI 状态，可再补：

6. `c4ba1cb` `优化核心页面按钮观感`

不建议直接整支 merge `codex/audit-review-cleanup`，因为这条分支还混入了：

- 复盘库
- 产品文档
- 页面按钮观感
- 其他与 SMB 无直接关系的能力演进

更稳的方式是按上面的最小 commit 集合做 `cherry-pick` 或手动摘取。

### D. 恢复成本

- `M`

理由：

- 优点：代码没有丢，分支清晰，关键提交集中在 2026-06-11，恢复路径明确
- 成本点：`Smb2Client.ets` 体量大，涉及协议、认证、NAS 兼容性、异常处理
- 成本点：当前主线页面和导出链路已继续演进，合回时要重新做真机回归

如果只是“把代码重新带回主线”，成本偏 `M`。
如果要求“重新作为对外稳定能力承诺”，那验证成本会接近 `L`。

### E. 是否建议立即恢复

建议立即恢复到主线，但建议采用“最小恢复集 + 真机回归”的方式，而不是整支合并。

原因：

- 用户已经在真实设备上连续使用数天，说明这不是纯概念功能
- 现在这套代码只留在单一历史分支里，继续拖延会增加再次丢失或继续漂移的风险
- 先把能力代码回到主线，后续再决定是否默认对外开放，比继续让真实使用能力游离在主线之外更稳

## 建议的下一步

1. 从 `codex/audit-review-cleanup` 提取最小恢复 commit 集
2. 合到当前主线后先跑构建
3. 在真实设备上回归：
   - SMB 连接测试
   - SMB 上传 review JSON
   - 设置页保存/读取/更新
   - 异常账号、错误目录、网络中断
4. 回归通过后，再决定是否恢复对外入口或先隐藏在灰度开关后
