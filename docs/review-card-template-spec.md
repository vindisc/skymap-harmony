# 摄影复盘卡模板规格

## 1. 产品目标

摄影复盘卡用于把一张照片和一次简短复盘组合成可分享图片。第一阶段目标是完成移动端 MVP 闭环：从系统相册选择一张真实照片，填写复盘内容，生成统一纵向阅读卡，并在首页沉淀最近记录。示例横图、示例竖图、示例方图保留为轻量体验入口。

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

首页「最近记录」读取本地记录并展示缩略图、标题和更新时间。点击记录后进入预览页查看成品卡，并可继续编辑。

## 5. 导出图片

当前版本使用 `@ohos.arkui.componentSnapshot` 对预览卡组件截图，使用 `@ohos.multimedia.image.createImagePacker()` 编码为 JPG，再通过 `@ohos.file.fs` 写入应用沙箱备份目录：

```text
files/review_exports/skymap-review-card-{timestamp}.jpg
```

随后使用 `@ohos.file.fileuri.getUriFromPath()` 转成沙箱文件 URI，并调用系统保存弹窗创建图库目标文件，再把沙箱 JPG 写入系统返回的媒体 URI。用户完成系统确认后，可在图库最近项目找到导出图；如果系统保存被取消或失败，应用保留沙箱备份并显示兜底提示，避免导出结果丢失。

## 6. 统一信息结构

无论照片是横图、竖图还是方图，复盘卡的信息结构都保持一致：

- 上方展示照片。
- 照片下方展示标题。
- 标题下方按完整阅读顺序展示三段复盘正文：
  - 第一眼落点
  - 是否成立
  - 卡点

每一段都使用字段标题 + 正文内容的纵向结构，字段之间用细分隔线区分。正文区域高度由内容驱动，不能主动截断、压缩成摘要卡或省略用户输入。

## 7. 横图显示规则

当 `imageWidth / imageHeight >= 1.15` 时，照片按横图比例展示。

横图只调整照片显示比例，不改变信息结构：

- 上方展示横图照片。
- 下方仍然按标题 + 三段正文的统一顺序阅读。

## 8. 竖图显示规则

当 `imageWidth / imageHeight <= 0.85` 时，照片按竖图比例展示。

竖图同样为上图下文：

- 上方展示竖图照片，文字保持完整宽度。
- 下方仍然保持标题 + 三段正文的统一结构。
- 长文本完整展开，内容区域随正文自动增长。

## 9. 方图显示规则

当照片比例介于横图和竖图阈值之间时，照片按方图比例展示。

方图同样为上图下文：

- 上方展示照片。
- 下方展示标题和三段正文。
- 只允许照片比例不同，不再为方图单独设计另一套信息摘要结构。

## 10. 默认文案

默认标题：

```text
这张照片是否成立
```

编辑页占位文案：

- 第一眼落点：我第一眼看到了什么？为什么？
- 是否成立：成立 / 不确定 / 不成立，并说明原因
- 卡点：这张照片当前最大的问题是什么？

## 11. 后续与 Mac 端 skymap 的关系

Mac 端 skymap 是产品能力参考，不作为代码迁移来源。鸿蒙端优先保持原生体验和轻量闭环，再逐步与 Mac 端对齐复盘卡规则、导出规格和文档互通。

后续可以对齐的能力：

- 真实照片导入。
- 图片导出。
- 复盘卡视觉细节。
- `.photoreview` 文件互通。
- 多端模板规则版本管理。

## 12. 后续 .photoreview 文件格式草案

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
