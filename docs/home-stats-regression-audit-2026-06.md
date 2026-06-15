# 首页统计回归审计 2026-06

## 审计范围

本审计记录 Harmony 首页「复盘概览」曾经出现的数据不显示、显示为 0 或刷新后不稳定的问题，并把已修复版本与防回归要求固定下来。

重点文件：

- `entry/src/main/ets/pages/HomePage.ets`
- `entry/src/main/ets/pages/AppShellPage.ets`
- `entry/src/main/ets/services/ReviewCardHistoryService.ets`
- `entry/src/main/ets/services/HomeDashboardPresenter.ets`
- `entry/src/main/ets/services/ReviewProjectService.ets`
- `scripts/verify_home_stats.mjs`
- `scripts/verify_review_project_service_tests.mjs`

## 版本链路

| commit | 作用 | 审计结论 |
| --- | --- | --- |
| `f14b728` | 修复首页统计渲染缓存 | 将首页可见统计从参数化 `StatItem(...)` 改为直接绑定标量 `@State`，避免 ArkUI 对 builder 参数缓存导致数字不刷新。 |
| `5619888` | 移除首页统计诊断面板 | 诊断面板只用于定位问题，不应进入正式首页；移除后必须由脚本测试承接防回归责任。 |
| `6d1e8c8` | 收敛家庭存储页视觉噪音 | 与首页统计无直接耦合，但属于同一轮 Beta 收口后的 UI 清理；不应影响首页统计链路。 |
| 本轮 | 收口首页统计 Presenter 与服务测试 | 首页页面不再直接承载统计计算和 reload 竞态判断，改由 `HomeDashboardPresenter` 负责纯状态投影；`ReviewProjectService` 增加脚本级服务测试覆盖。 |

## 根因复盘

当时首页数据不是服务层完全没有数据，而是首页可见统计链路里混入了几个容易互相掩盖的问题：

1. 首页统计一度通过参数化 `@Builder StatItem(value, label)` 渲染动态数字。ArkUI 对 builder 参数和组件刷新存在缓存行为时，服务层 summary 已更新，但可见数字可能停留在旧值。
2. 首页曾经保留嵌套统计对象或项目 summary 的渲染路径，导致首页、我的页、项目页的统计来源不够单一。
3. 诊断期为了定位问题加入了「诊断信息」面板，但这只能暴露现象，不能作为产品状态长期存在。
4. 首页从编辑页、阅读页、我的页返回时必须重新读取 `ReviewCardHistoryService.load`，否则已保存历史不会立刻反映到首页。

当前稳定口径是：

- 首页可见数字只允许来自 `reviewCount`、`validReviewCount`、`unsureReviewCount` 这几个标量 `@State`。
- 首页统计、我的页身份卡统计都使用 `ReviewProjectService.buildHomeSummary(historyItems)`。
- 首页统计只使用持久化历史，不混入 `ReviewCardStore.getCurrentDocument()` 里的当前草稿。
- 首页统计状态投影隔离在 `HomeDashboardPresenter`，页面只负责读取历史、发起 reload、同步标量 `@State`。
- 连续天数计算隔离在 `resolveHomeDashboardStreakDays()`，失败时只回退连续天数，不得重置可见复盘数量。
- 历史读取失败时展示错误提示，但保留上一轮已经可见的统计数字，避免首页突然清零。
- 新旧 reload 请求并发时，迟到的旧请求不得覆盖新请求的统计结果。

## 防回归测试

`scripts/verify_home_stats.mjs` 现在承担两层责任：

1. 结构约束：禁止恢复 `StatItem(...)`、嵌套 `dashboardStats`、旧配置状态卡和诊断面板，并要求首页统计逻辑留在 `HomeDashboardPresenter`。
2. 行为单测：用 JS 模拟首页统计状态流，覆盖跨项目统计、状态归一化、迟到请求保护、读取失败保留旧值。
3. 服务单测：`verify_review_project_service_tests.mjs` 覆盖统计分桶、首页/默认项目汇总、筛选、照片文件名解析和连续天数。

必须通过：

```bash
node scripts/verify_home_stats.mjs
node scripts/verify_review_project_service_tests.mjs
node scripts/verify_compact_ui_tokens.mjs
node scripts/verify_home_information_architecture.mjs
```

打包验证仍以 `bash scripts/build_hap.sh` 为准；若失败停在 `SignHap` 且错误是本机 keystore/JDK 签名问题，不等同于 ArkTS 编译失败。

## 后续规则

- 不要为了复用 UI 把首页统计数字重新抽成带动态参数的 `@Builder`。
- 不要把诊断面板放回正式首页；需要排查时应短期加日志或脚本测试，修完即删。
- 首页统计新增字段时，先补 `ReviewProjectService` / `HomeDashboardPresenter` 的纯数据口径，再补服务测试和 `verify_home_stats.mjs` 的行为用例，最后改 UI。
- 任何保存、删除、导出标记、家庭存储上传标记相关改动，都必须跑首页统计验证脚本。
