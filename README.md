# skymap-harmony

skymap-harmony 是一个 HarmonyOS 原生 ArkTS + ArkUI 移动端 MVP，用于快速生成「摄影复盘卡」。

它不是 Mac 端 skymap 的 Swift 代码迁移，也不是完整摄影边框工具复刻。当前版本只迁移已经验证过的复盘卡产品能力：选择真实照片、填写观察内容、按照片方向生成复盘卡预览，并保存最近记录。

## 当前 MVP 能力

- 首页展示正式创建入口、示例体验和真实最近记录。
- 支持从系统相册单选真实照片创建复盘。
- 保留内置示例横图、示例竖图、示例方图作为轻量体验入口。
- 编辑页支持填写：
  - 标题
  - 第一眼落点
  - 是否成立
  - 卡点
- 预览页根据照片比例自动选择布局：
  - 横图：上图下文 + 判断标题 + 轻量复盘信息组
  - 竖图：上图下文 + 稳定文字说明区
  - 方图：上图下文 + 紧凑复盘说明
- 进入预览时自动保存复盘记录，首页最近记录可再次打开查看。
- 预览页支持把当前复盘卡导出为 PNG，当前导出到应用沙箱文件目录。

## 图片选择

首页主按钮使用 HarmonyOS `@ohos.file.photoAccessHelper.PhotoViewPicker` 打开系统图片选择器，配置为图片单选。

选中后使用 `@ohos.multimedia.image.createImageSource(uri).getImageInfo()` 读取图片宽高，用于自动判断横图、竖图、方图。若读取失败，当前版本会保留图片 URI，并用兜底宽高继续进入编辑页，避免流程中断。

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
- 横图上图下文 + 统一作品卡结构
- 竖图上图下文 + 手机端可读文字区
- 方图上图下文
- 默认标题「这张照片是否成立」
- 第一眼落点 / 是否成立 / 卡点三个核心字段
- 未来 `.photoreview` 文件互通方向

## 当前限制

- 暂不把导出图片写入系统相册。
- 本地记录使用轻量 preferences，不是完整数据库。
- 不做登录、云同步或 AI。
- 不做完整模板市场。
- 不做完整摄影边框 APP。

当前导出图片已经能生成 PNG 文件，但文件先保存在应用沙箱 `files/review_exports`，还没有写入系统相册。后续需要接入媒体库写入或分享面板，把导出结果交给用户可见位置。
