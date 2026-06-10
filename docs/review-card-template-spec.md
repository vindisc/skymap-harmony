# 摄影复盘卡模板规格

## 1. 产品目标

摄影复盘卡用于把一张照片和一次简短复盘组合成可分享图片。第一阶段目标是完成移动端 MVP 闭环：从系统相册选择一张真实照片，在看图状态下填写复盘内容，在手机内生成可读的阅读卡，并导出竖向长图复盘笔记，同时在首页沉淀默认项目和最近记录。

## 2. 复盘字段

`ReviewCardDocument` 是第一阶段的文档模型：

- `version`: 文档版本。
- `imageUri`: 图片地址，第一阶段主链路来自系统相册；旧数据或开发辅助路径允许为空。
- `imageWidth`: 图片宽度。
- `imageHeight`: 图片高度。
- `content`: 复盘内容。
- `config`: 复盘卡配置。
- `createdAt`: 创建时间。
- `updatedAt`: 更新时间。

`ReviewContent` 包含：

- `title`: 标题。
- `visualFocus`: 视觉落点。
- `focusReason`: 落点原因。
- `visualPath`: 视线路径。
- `visibleFacts`: 画面事实。
- `coreRelation`: 核心关系。
- `judgement`: 是否成立。
- `extendedUnderstanding`: 延伸理解。
- `currentBlocker`: 当前卡点。

当前复盘框架固定为：

```text
视觉落点 -> 落点原因 -> 视线路径 -> 画面事实 -> 核心关系 -> 是否成立 -> 延伸理解 -> 当前卡点
```

旧数据兼容映射：

- `firstLook` -> `visualFocus`
- `reason` -> `focusReason`
- `visualPath` -> `visualPath`
- `strongestRelation` -> `coreRelation`
- `judgement` -> `judgement`
- `blocker` -> `currentBlocker`

上一版若已把旧 `judgement` 内容写入 `extendedUnderstanding`，读取时会回填到 `judgement`，避免旧记录的“是否成立”判断丢失。

旧记录缺字段时按空字符串处理，不阻塞打开、编辑、阅读和导出。

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

用户取消、空结果、打开选择器失败时，停留在首页并避免崩溃。若图片宽高读取失败，当前版本保留 URI 并用兜底宽高继续流程，同时在预览页明确提示当前仍在使用兜底比例；后续可改为通过媒体资产元数据读取更稳定的宽高。

## 4. 本地记录

当前版本使用 `@ohos.data.preferences` 保存最近复盘记录，最多保留 200 条。记录内容直接序列化 `ReviewCardDocument`，并额外记录导出文件路径。200 条用于支撑默认项目的长期回看沉淀，同时仍保持 preferences 存储体量可控；后续若进入多项目或大量图片元数据阶段，再迁移到数据库。

保存时机：

- 编辑页点击「保存并进入阅读」时自动保存。
- 导出成功后更新记录的导出路径。

首页「我的项目」固定展示默认项目「我的摄影复盘」，`projectId` 为 `default`，点击进入长期回看列表。首页「最近一次」展示最新一条历史记录，点击后进入阅读页查看复盘记录，并可继续编辑、复制复盘数据或导出图片。

## 5. 导出图片

当前版本使用 `@ohos.arkui.componentSnapshot` 对 `exportCard` 渲染结果截图，使用 `@ohos.multimedia.image.createImagePacker()` 编码为 JPG，再通过 `@ohos.file.fs` 写入应用沙箱备份目录：

```text
files/review_exports/skymap-review-card-{timestamp}.jpg
```

随后使用 `@ohos.file.fileuri.getUriFromPath()` 转成沙箱文件 URI，并调用系统保存弹窗创建图库目标文件，再把沙箱 JPG 写入系统返回的媒体 URI。用户完成系统确认后，可在图库最近项目找到导出图；如果系统保存被取消或失败，应用保留沙箱备份并显示兜底提示，避免导出结果丢失。

## 6. 渲染模式

复盘卡统一使用同一份 `ReviewCardDocument`，但渲染职责拆分为两种模式：

- `mobileReading`：用于手机 App 内阅读、确认和编辑后的查看。
- `exportCard`：用于最终导出分享图。

两种模式共享同一套字段：

- 照片
- 标题
- 视觉落点
- 落点原因
- 视线路径
- 画面事实
- 核心关系
- 是否成立
- 延伸理解
- 当前卡点

正文区域高度由内容驱动，不能主动截断、压缩成摘要卡或省略用户输入。

## 7. 方向判断

方向判断统一基于真实显示宽高的比值：

- `imageWidth / imageHeight >= 1.15`：横图
- `imageWidth / imageHeight <= 0.87`：竖图
- 其他情况：方图

如果当前仍在使用兜底尺寸，不把兜底值伪装成真实尺寸；布局会继续兜底渲染，但需要明确提示用户当前比例待确认。

## 8. mobileReading 阅读模式

`mobileReading` 不追求导出成品感，核心目标是手机竖屏可读：

- 横图、竖图、方图都使用统一的纵向阅读结构。
- 结构固定为：照片、标题、字段列表。
- 图片保持原比例，不拉伸、不裁切。
- 竖图在手机内允许缩小展示，但不使用左图右文。
- 字段始终按完整阅读顺序纵向展开。

## 9. exportCard 导出模式

`exportCard` 当前统一走 `LongFormExportReviewCard`，不再按照片方向选择不同成品布局。

- 所有照片统一导出竖向长图。
- 结构固定为：照片、标题、视觉落点、落点原因、视线路径、画面事实、核心关系、是否成立、延伸理解、当前卡点。
- 图片保持原比例，不拉伸，不错误裁切。
- 空字段不导出，避免空白。
- 字段名弱化为小号浅灰，字段内容清晰但不过大。
- 字段间距和行距紧凑但可读。

导出图不是手机预览截图，不包含返回、编辑、导出、保存状态、手机状态栏、页面标题和底部按钮。横图 / 竖图 / 方图差异化导出保留为后续能力。

## 10. 默认文案

默认标题：

```text
这张照片是否成立
```

编辑页占位文案：

- 视觉落点：第一眼先看到哪里？
- 落点原因：为什么它会先被看到？
- 视线路径：视线接着怎么移动？
- 画面事实：画面里有哪些可见事实？
- 核心关系：最重要的 A ↔ B 关系是什么？
- 是否成立：成立、不确定或不成立？
- 延伸理解：这张照片为什么成立或不成立？
- 当前卡点：当前最大问题是什么？

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
    "visualFocus": "",
    "focusReason": "",
    "visualPath": "",
    "visibleFacts": "",
    "coreRelation": "",
    "judgement": "",
    "extendedUnderstanding": "",
    "currentBlocker": ""
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
