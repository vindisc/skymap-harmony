# skymap-harmony

skymap-harmony 是一个 HarmonyOS 原生 ArkTS + ArkUI 移动端 MVP，用于快速生成「摄影复盘卡」。

它不是 Mac 端 skymap 的 Swift 代码迁移，也不是完整摄影边框工具复刻。当前版本只保留手机端快速复盘能力：选择真实照片、填写观察内容、生成可阅读的手机复盘卡，并导出成品复盘卡，同时保存项目记录。

## 当前 MVP 能力

- 首页展示「开始复盘」入口、最近一次复盘和默认项目「我的摄影复盘」。
- 支持从系统相册单选真实照片创建复盘。
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
  - V1 统一导出竖向长图，照片在上、内容在下
  - 横图 / 竖图 / 方图差异化导出保留为后续能力
- 进入预览时自动保存到 `default` 项目，可在项目记录列表中再次打开查看。
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

## 低成本验证

当前仓库提供不依赖真机的 Node 验证脚本，用于覆盖复盘纯逻辑和近期回归点：

```bash
node scripts/verify_review_logic.mjs
node scripts/verify_home_stats.mjs
node scripts/verify_image_layout.mjs
node scripts/verify_button_taste.mjs
node scripts/verify_security_hardening.mjs
bash scripts/verify_product_docs_sync.sh
```

脚本失败会以非 0 状态退出。

## 与 Mac 端 skymap 的关系

Mac 端 skymap 只作为产品参考。本项目不会直接迁移 Swift 代码，第一阶段只迁移：

- `ReviewContent` 数据结构
- 横图 / 竖图 / 方图轻量识别
- 纵向阅读复盘卡结构
- 标题 + 视觉落点 / 落点原因 / 视线路径 / 画面事实 / 核心关系 / 是否成立 / 延伸理解 / 当前卡点结构
- 默认标题「这张照片是否成立」
- 未来 `.photoreview` 文件互通方向

## 当前限制

- 本地记录使用轻量 preferences，最多保留 200 条，不是完整数据库。
- 不做登录、云同步或 AI。
- 不做完整模板市场。
- 不做完整摄影边框 APP。

当前导出图片会先生成 JPG 备份到应用沙箱 `files/review_exports`，再调用系统保存弹窗创建图库目标文件，并把沙箱 JPG 写入系统返回的媒体 URI。用户完成系统确认后，可在图库最近项目中找到导出的复盘卡；如果系统保存被取消或失败，应用会保留沙箱备份并给出失败兜底提示。
