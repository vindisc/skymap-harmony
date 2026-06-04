# skymap-harmony

skymap-harmony 是一个 HarmonyOS 原生 ArkTS + ArkUI 移动端 MVP，用于快速生成「摄影复盘卡」。

它不是 Mac 端 skymap 的 Swift 代码迁移，也不是完整摄影边框工具复刻。当前版本只迁移已经验证过的复盘卡产品能力：选择示例照片方向、填写观察内容、按照片方向生成复盘卡预览。

## 当前 MVP 能力

- 首页展示产品入口和最近记录占位。
- 支持使用内置示例横图、示例竖图、示例方图创建复盘。
- 编辑页支持填写：
  - 标题
  - 第一眼落点
  - 是否成立
  - 卡点
- 预览页根据照片比例自动选择布局：
  - 横图：上图下文 + 三栏信息卡
  - 竖图：左图右文 + 右侧信息卡
  - 方图：上图下文 + 紧凑信息块
- 保存草稿、导出图片按钮已预留，占位不执行真实持久化或导出。

## 如何运行

1. 使用 DevEco Studio 打开本仓库根目录。
2. 等待工程同步完成。
3. 选择 `entry` 模块和默认设备。
4. 点击 Run 编译运行。

也可以使用 DevEco Studio 自带的 hvigor 命令行构建：

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
--mode module -p module=entry -p product=default assembleHap --no-daemon
```

## 与 Mac 端 skymap 的关系

Mac 端 skymap 只作为产品参考。本项目不会直接迁移 Swift 代码，第一阶段只迁移：

- `ReviewContent` 数据结构
- 横图 / 竖图 / 方图自动布局策略
- 横图上图下文 + 三栏信息卡
- 竖图左图右文 + 右侧信息卡
- 方图上图下文
- 默认标题「这张照片是否成立」
- 第一眼落点 / 是否成立 / 卡点三个核心字段
- 未来 `.photoreview` 文件互通方向

## 当前限制

- 不接系统相册。
- 不实现真实导出图片。
- 不实现本地数据库。
- 不做登录、云同步或 AI。
- 不做完整模板市场。
- 不做完整摄影边框 APP。
