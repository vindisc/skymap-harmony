# skymap-harmony

skymap-harmony 是一个 HarmonyOS 原生 ArkTS + ArkUI 移动端 MVP，用于快速生成「摄影复盘卡」。

它不是 Mac 端 skymap 的 Swift 代码迁移，也不是完整摄影边框工具复刻。当前版本只保留手机端快速复盘能力：选择真实照片、填写观察内容、生成可阅读的手机复盘卡，并导出成品复盘卡，同时保存项目记录。

## 当前 MVP 能力

- 首页展示「开始复盘」入口、最近一次复盘和默认项目「我的摄影复盘」。
- 支持从系统相册单选真实照片创建复盘。
- 保留内置示例横图、示例竖图、示例方图作为轻量体验入口。
- 编辑页支持填写：
  - 标题
  - 视觉落点
  - 落点原因
  - 视线路径
  - 画面事实
  - 核心关系
  - 是否成立
  - 延伸理解
  - 当前卡点
- 预览页使用 `mobileReading` 阅读模式：
  - 照片
  - 标题
  - 视觉落点 / 落点原因 / 视线路径 / 画面事实 / 核心关系 / 是否成立 / 延伸理解 / 当前卡点
- 导出使用 `exportCard` 成品模式：
  - 横图 / 竖图 / 方图使用差异化导出呈现
  - 导出图会清理 placeholder、页面按钮、重复状态和普通界面噪音
- 保存后写入本地 RDB 复盘库主索引，可在复盘库再次打开查看。
- `review_exchange` 作为应用内备份 / 交换 / 有限恢复来源，`Preferences.items` 只作为旧版本迁移来源。
- 预览页支持把当前复盘卡保存为 JPG，并通过系统保存弹窗写入相册，图库最近项目可见。

## 图片选择

首页主按钮使用 HarmonyOS `@ohos.file.photoAccessHelper.PhotoViewPicker` 打开系统图片选择器，配置为图片单选。

选中后使用 `@ohos.multimedia.image.createImageSource(uri).getImageInfo()` 读取图片宽高，用于判断横图、竖图或方图。若读取失败，当前版本会保留图片 URI，并用兜底宽高继续进入编辑页，避免流程中断；预览页会明确提示当前仍在使用兜底比例。

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

如果 DevEco Studio 或终端里出现：

```text
Invalid value of 'DEVECO_SDK_HOME' in the system environment path.
```

优先使用仓库脚本，它会自动：

- 固定 `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`
- 固定 `JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home`
- 停掉旧的 hvigor daemon
- 使用 `--no-daemon` 重新构建

```bash
bash scripts/build_hap.sh
```

如果脚本继续通过到 `CompileArkTS` / `PackageHap`，但失败在 `SignHap`，那通常是本机 keystore 或 JDK 签名环境问题，不属于当前代码编译失败。

## 与 Mac 端 skymap 的关系

Mac 端 skymap 只作为产品参考。本项目不会直接迁移 Swift 代码，第一阶段只迁移：

- `ReviewContent` 数据结构
- 横图 / 竖图 / 方图轻量识别
- 纵向阅读复盘卡结构
- 标题 + 视觉落点 / 落点原因 / 视线路径 / 画面事实 / 核心关系 / 是否成立 / 延伸理解 / 当前卡点结构
- 默认标题「这张照片是否成立」
- 未来 `.photoreview` 文件互通方向

## 当前限制

- 当前 v0 是 HarmonyOS 单端发布基线，不包含多设备同步、账号系统、云端服务或 AI 自动分析。
- 家庭存储目前是配置入口和连接测试，不是完整自动同步。
- 不做登录、云同步或 AI。
- 不做完整模板市场。
- 不做完整摄影边框 APP。

当前导出图片会先生成 JPG 备份到应用沙箱 `files/review_exports`，再调用系统保存弹窗创建图库目标文件，并把沙箱 JPG 写入系统返回的媒体 URI。用户完成系统确认后，可在图库最近项目中找到导出的复盘卡；如果系统保存被取消或失败，应用会保留沙箱备份并给出失败兜底提示。
