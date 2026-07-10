# skymap-photoreview

`skymap-photoreview` 是一款 HarmonyOS 原生 ArkTS + ArkUI 摄影复盘应用，当前聚焦手机端单机闭环：导入照片、写复盘、保存回看、导出成品，以及把照片先收进待复盘列表。

代码是当前事实来源；本文只描述已经落地的实现。

## 当前定位

- 首页、复盘库、统计、我的四个主 Tab 已接到同一条本地数据链路。
- `Review` 表示已经完成并保存的复盘结果。
- `Pending` 表示尚未开始或尚未完成的待复盘照片。
- 两者可以在统计上关联，但当前数据模型不混用。

## 当前核心能力

- 首页提供两个并行入口：
  - `导入照片，开始复盘`：从系统相册单选一张照片，直接进入编辑页。
  - `导入待复盘`：从系统相册多选照片，批量写入待复盘列表，当前上限 30 张。
- 编辑页支持填写固定复盘字段：
  - 标题
  - 视觉落点
  - 落点原因
  - 视线路径
  - 画面事实
  - 核心关系
  - 是否成立
  - 延伸理解
  - 当前卡点
- 保存后写入本地 RDB `reviews` 主索引，并写入 `review_exchange` 沙箱备份。
- 从待复盘照片进入编辑并保存后，会把该照片状态标记为 `reviewed`，不再留在待复盘列表。
- 复盘库支持：
  - 搜索标题、关系、卡点、文件名
  - 筛选 `全部 / 待复盘 / 成立 / 待判断 / 不成立`
  - 删除已保存复盘或待复盘照片
- 统计页正式口径已经统一为：
  - `学习进度`
  - `复盘结果`
- 导出能力包括：
  - 导出 JPG 复盘卡，并通过系统保存弹窗写入相册
  - 导出复盘包
  - 导出含原图的复盘包

## 当前数据口径

- `Pending` 是待复盘任务，不属于已完成复盘。
- `Review` 是已保存的复盘结果，判断分布只统计这里的记录。
- 统计页 `学习进度`：
  - `待复盘 = pendingCount`
  - `已完成 = Review 总数`
  - `累计导入 = pendingCount + Review 总数`
- 统计页 `复盘结果`：
  - 只基于已保存复盘
  - `成立 + 待判断 + 不成立 = 累计复盘`

## 运行与构建

1. 使用 DevEco Studio 打开仓库根目录。
2. 等待工程同步完成。
3. 选择 `entry` 模块和默认设备后运行。

命令行构建优先使用仓库脚本：

```bash
bash scripts/build_hap.sh
```

脚本会固定当前仓库使用的 `DEVECO_SDK_HOME` 和 `JAVA_HOME`。如果构建通过到 `CompileArkTS` 或 `PackageHap`，但失败在 `SignHap`，通常属于本机签名环境问题，不代表当前代码编译失败。

## 当前文档入口

- [docs/mobile-main-flow.md](./docs/mobile-main-flow.md)：当前手机端主流程
- [docs/product/README.md](./docs/product/README.md)：当前保留的正式产品文档索引
- [docs/AUDIT_CLEANUP_SUMMARY.md](./docs/AUDIT_CLEANUP_SUMMARY.md)：本轮文档审计与收口记录
- [docs/RELEASE_CLOSURE_20260709.md](./docs/RELEASE_CLOSURE_20260709.md)：0.1.0 提审后版本收口、发布 / 测试切换和下一版优先级
- [docs/release/README.md](./docs/release/README.md)：发布工程卫生、签名材料隔离、审核反馈模板和 HAP 归档记录
- [docs/harmony/UI_CLOSURE_RULES.md](./docs/harmony/UI_CLOSURE_RULES.md)：UI 冻结边界、变更准入、真机验收矩阵和统一门禁

## 当前不承诺

- 自动同步、双向同步、冲突合并
- 账号系统、云端服务、AI 自动分析
- 把待复盘数据混入已完成复盘模型
- 用旧口径 `学习概览 / 复盘质量` 表述统计页
