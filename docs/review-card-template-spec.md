# 摄影复盘卡模板规格

## 1. 产品目标

摄影复盘卡用于把一张照片和一次简短复盘组合成可分享图片。第一阶段目标是完成移动端 MVP 闭环：从系统相册选择一张真实照片，填写复盘内容，按照片方向自动生成预览，并在首页沉淀最近记录。示例横图、示例竖图、示例方图保留为轻量体验入口。

## 2. 复盘字段

`ReviewCardDocument` 是第一阶段的文档模型：

- `version`: 文档版本。
- `imageUri`: 图片地址，第一阶段允许为空或使用示例 URI。
- `imageWidth`: 图片宽度。
- `imageHeight`: 图片高度。
- `content`: 复盘内容。
- `config`: 复盘卡配置。
- `createdAt`: 创建时间。
- `updatedAt`: 更新时间。

`ReviewContent` 包含：

- `title`: 标题。
- `firstLook`: 第一眼落点。
- `judgement`: 是否成立。
- `blocker`: 卡点。

`ReviewCardConfig` 包含：

- `templateId`: 模板标识。
- `layoutMode`: 布局模式。
- `background`: 背景。
- `textSize`: 文字大小。

默认配置：

- `templateId`: `review_card`
- `layoutMode`: `auto`
- `background`: `white`
- `textSize`: `standard`

## 3. 图片选择与尺寸读取

首页主入口使用 `@ohos.file.photoAccessHelper.PhotoViewPicker` 打开系统图片选择器，只允许单选图片。

选择成功后：

1. 从 `PhotoSelectResult.photoUris[0]` 获取图片 URI。
2. 使用 `@ohos.multimedia.image.createImageSource(uri).getImageInfo()` 读取 `ImageInfo.size.width` 和 `ImageInfo.size.height`。
3. 创建 `ReviewCardDocument`，并进入编辑页。

用户取消、空结果、打开选择器失败时，停留在首页并避免崩溃。若图片宽高读取失败，当前版本保留 URI 并用兜底宽高继续流程；后续可改为通过媒体资产元数据读取更稳定的宽高。

## 4. 本地记录

当前版本使用 `@ohos.data.preferences` 保存最近复盘记录，最多保留 20 条。记录内容直接序列化 `ReviewCardDocument`，并额外记录导出文件路径。

保存时机：

- 编辑页点击「生成复盘卡」时自动保存。
- 预览页点击「保存」时保存。
- 导出成功后更新记录的导出路径。

首页「最近记录」读取本地记录并展示缩略图、标题、照片方向、更新时间和导出状态。点击记录后进入预览页查看成品卡，并可继续编辑。

## 5. 导出图片

当前版本使用 `@ohos.arkui.componentSnapshot` 对预览卡组件截图，使用 `@ohos.multimedia.image.createImagePacker()` 编码为 PNG，再通过 `@ohos.file.fs` 写入应用沙箱目录：

```text
files/review_exports/review-card-{timestamp}.png
```

这是 MVP 阶段最接近可用的导出路径。后续需要继续接入系统相册写入或分享能力，让用户能在图库、文件管理器或分享面板中直接使用导出图。

## 6. 横图布局规则

当 `layoutMode` 为 `auto` 且 `imageWidth / imageHeight >= 1.15` 时，使用横图布局。

横图布局为上图下文：

- 上方展示照片。
- 标题紧跟照片下方，作为照片的解释标题。
- 标题下方展示轻量三栏复盘信息组：
  - 第一眼落点
  - 是否成立
  - 卡点
- 照片、标题和信息组共享同一套内边距、圆角和左边缘对齐规则。

## 7. 竖图布局规则

当 `layoutMode` 为 `auto` 且 `imageWidth / imageHeight <= 0.85` 时，使用竖图布局。

竖图布局为左图右文：

- 左侧展示照片。
- 右侧展示标题和轻量复盘信息组。
- 右侧内部顺序为：
  - 标题
  - 第一眼落点字段块
  - 是否成立字段块
  - 卡点字段块

字段块高度由内容驱动，不平均拉满整个右侧高度。移动端预览仍保留同一水平卡片系统，避免右侧文字区脱离照片。

## 8. 方图布局规则

当照片比例介于横图和竖图阈值之间时，使用方图布局。

方图布局为上图下文：

- 上方展示照片。
- 下方展示标题。
- 标题下方展示轻量复盘信息组。
- 照片区使用稍扁的主视觉裁切，给文字区留出足够比例；整体比例比横图布局更紧凑。

## 9. 默认文案

默认标题：

```text
这张照片是否成立
```

编辑页占位文案：

- 第一眼落点：我第一眼看到了什么？为什么？
- 是否成立：成立 / 不确定 / 不成立，并说明原因
- 卡点：这张照片当前最大的问题是什么？

## 10. 后续与 Mac 端 skymap 的关系

Mac 端 skymap 是产品能力参考，不作为代码迁移来源。鸿蒙端优先保持原生体验和轻量闭环，再逐步与 Mac 端对齐复盘卡规则、导出规格和文档互通。

后续可以对齐的能力：

- 真实照片导入。
- 图片导出。
- 复盘卡视觉细节。
- `.photoreview` 文件互通。
- 多端模板规则版本管理。

## 11. 后续 .photoreview 文件格式草案

`.photoreview` 可以采用 JSON 文档格式，字段草案如下：

```json
{
  "version": "0.1.0",
  "image": {
    "uri": "",
    "width": 1600,
    "height": 1000,
    "assetId": ""
  },
  "content": {
    "title": "这张照片是否成立",
    "firstLook": "",
    "judgement": "",
    "blocker": ""
  },
  "config": {
    "templateId": "review_card",
    "layoutMode": "auto",
    "background": "white",
    "textSize": "standard"
  },
  "createdAt": 0,
  "updatedAt": 0
}
```

后续若需要与 Mac 端互通，应保持字段向后兼容：新增字段必须可选，删除字段需要版本迁移策略。
