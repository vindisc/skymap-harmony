# HarmonyOS SDK 6.1.1(24) 流式 JPEG encode 调研

**调研日期**：2026-07-19  
**调研目的**：为 PR 3 分块渲染方向找到“任意时刻不持有 full-size PixelMap”的落地路径

本报告只以本机安装的 HarmonyOS SDK 声明和当前仓库源码为证据。SDK 元数据确认该安装包为 HarmonyOS 6.1.1、API 24、Release 版本：`/Applications/DevEco-Studio.app/Contents/sdk/default/sdk-pkg.json:6`、`:7`、`:10`。下文未查到的能力，均表示在该 SDK 的公开 `.d.ts`、NDK 头文件和公开链接库中未查到，不代表系统私有实现一定不存在。

## 1. ImagePacker 相关能力

### 1.1 API 签名清单（附源码文件路径 + 行号）

ArkTS 声明文件：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/api/@ohos.multimedia.image.d.ts`。

| 能力 | 签名 | 声明位置 | 状态 |
| --- | --- | --- | --- |
| 创建 packer | `createImagePacker(): ImagePacker` | `@ohos.multimedia.image.d.ts:5021` | 当前可用 |
| ImageSource → ArrayBuffer | `packToData(source: ImageSource, options: PackingOption): Promise<ArrayBuffer>` | `@ohos.multimedia.image.d.ts:12449` | 当前可用，单一输入源 |
| PixelMap → ArrayBuffer | `packToData(source: PixelMap, options: PackingOption): Promise<ArrayBuffer>` | `@ohos.multimedia.image.d.ts:12546` | 当前可用，单一 PixelMap |
| ImageSource → fd | `packToFile(source: ImageSource, fd: number, options: PackingOption): Promise<void>` | `@ohos.multimedia.image.d.ts:12605` | 当前可用，单一输入源 |
| PixelMap → fd | `packToFile(source: PixelMap, fd: number, options: PackingOption): Promise<void>` | `@ohos.multimedia.image.d.ts:12651` | 当前可用，单一 PixelMap |
| Picture → ArrayBuffer | `packing(picture: Picture, options: PackingOption): Promise<ArrayBuffer>` | `@ohos.multimedia.image.d.ts:12710` | 当前可用；方法名仍为 `packing` |
| Picture → fd | `packToFile(picture: Picture, fd: number, options: PackingOption): Promise<void>` | `@ohos.multimedia.image.d.ts:12724` | 当前可用 |
| PixelMap 序列 → ArrayBuffer | `packToDataFromPixelmapSequence(pixelmapSequence: Array<PixelMap>, options: PackingOptionsForSequence): Promise<ArrayBuffer>` | `@ohos.multimedia.image.d.ts:12559` | `@since 18`，声明明确限定为 GIF |
| PixelMap 序列 → fd | `packToFileFromPixelmapSequence(pixelmapSequence: Array<PixelMap>, fd: number, options: PackingOptionsForSequence): Promise<void>` | `@ohos.multimedia.image.d.ts:12665` | `@since 18`，声明明确限定为 GIF |
| 释放 | `release(): Promise<void>` | `@ohos.multimedia.image.d.ts:12697` | 当前可用 |

旧的 `packing(ImageSource/PixelMap, ...)` callback 和 Promise 重载均标记为 `@deprecated since 13`，并要求改用 `packToData`，例如 `@ohos.multimedia.image.d.ts:12361`、`:12389`、`:12426`、`:12458`、`:12486`、`:12523`。

`PackingOption` 只有 `format`、`quality`、可选 `bufferSize`、动态范围和 EXIF 属性保留开关。声明位置为 `@ohos.multimedia.image.d.ts:3177`；`format` 在 `:3202`，`quality` 在 `:3227`，`bufferSize` 在 `:3255`。其中 `bufferSize` 的文档只说明“目标图像 BufferSize，小于等于 0 时转为 10 MB”（`:3229`-`:3255`），没有说明它是输入 tile 大小、编码窗口或流式缓存参数，不能据此推断支持分片输入。

Native ImagePacker 的公开接口与 ArkTS 同样是整源编码：

- `OH_ImagePackerNative_PackToFileFromImageSource(..., OH_ImageSourceNative *imageSource, int32_t fd)`：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/multimedia/image_framework/image/image_packer_native.h:483`。
- `OH_ImagePackerNative_PackToFileFromPixelmap(..., OH_PixelmapNative *pixelmap, int32_t fd)`：同文件 `:501`。
- `OH_ImagePackerNative_PackToFileFromPicture(..., OH_PictureNative *picture, int32_t fd)`：同文件 `:518`。
- Native 头文件公开的其余入口也是 `PackToDataFromImageSource/Pixelmap/Picture/PixelmapSequence`，函数清单位于同文件 `:389`-`:549`。

### 1.2 是否支持流式/分片：部分（含证据）

结论为 **部分支持**：

1. `packToFile(..., fd, ...)` 可以直接把最终编码结果写入文件，避免在 ArkTS 层额外持有完整 JPEG `ArrayBuffer`。这是“输出目标为文件”，不是“输入可逐 tile/逐 scan-line 喂入”。
2. 所有 JPEG 相关入口都只接受一个完整 `ImageSource`、`PixelMap` 或 `Picture`。未查到 `startPacking`、`addImage`、`addScanline`、`appendTile`、`finalizePacking`、`packToDataStream` 或用户提供输出 callback 的 API。
3. 唯一的多 PixelMap 入口明确写为“Compresses a Pixelmap sequence into gif”，证据为 `@ohos.multimedia.image.d.ts:12548` 和 `:12653`。它表达的是动画帧序列，不是把空间 tile 拼成一张静态 JPEG。
4. `packToFile`、`packToData` 和 Native ImagePacker 声明均没有给出编码期间的峰值内存、是否整图解码、是否内部创建完整 PixelMap/Bitmap、是否按 scan-line 编码等保证。

### 1.3 结论

HarmonyOS SDK 6.1.1(24) 的公开 ImagePacker **没有可用于静态 JPEG 空间分块输入的流式 API**。`packToFile` 只能减少“编码结果缓冲区”的 ArkTS 内存，不能解决“最终合成图必须作为单一完整源交给编码器”的问题。

因此，仅依赖 ImagePacker，无法证明或实现“任何时刻都不持有 full-size 7008×4672 PixelMap，同时输出一张 7008×4672 JPEG”。

## 2. image 模块 PixelMap 低内存通路

### 2.1 分块加载能力

`ImageSource.createPixelMap(options)` 支持区域解码参数：

- `DecodingOptions.desiredSize?: Size`：`@ohos.multimedia.image.d.ts:3618`。
- `DecodingOptions.desiredRegion?: Region`：`@ohos.multimedia.image.d.ts:3653`，文档定义为 PixelMap 的裁剪区域。
- `DecodingOptions.desiredPixelFormat?: PixelMapFormat`：`@ohos.multimedia.image.d.ts:3688`。
- `ImageSource.createPixelMap(options?: DecodingOptions): Promise<PixelMap>`：`@ohos.multimedia.image.d.ts:11379`。
- 可指定内存类型的 `createPixelMapUsingAllocator(options?, allocatorType?)`：`@ohos.multimedia.image.d.ts:11482`，`AllocatorType` 包含 `AUTO`、`DMA`、`SHARE_MEMORY`，定义在 `:2627`-`:2648`。

图片源可以直接从文件描述符创建，避免先把原始压缩文件整体读入 ArkTS `ArrayBuffer`：

- `createImageSource(fd: number): ImageSource`：`@ohos.multimedia.image.d.ts:4821`。
- `createImageSource(fd: number, options: SourceOptions): ImageSource`：`@ohos.multimedia.image.d.ts:4864`。

因此，公开 API 允许 PR 3 按输出 tile 映射出原图区域，再使用 `desiredRegion` 和 `desiredSize` 只获得 tile 尺寸的 PixelMap。

需要注意：声明只保证“返回裁剪后的 PixelMap”，**没有保证 JPEG/HEIF 解码器内部只解码该区域，也没有峰值内存说明**。对于 JPEG，区域解码是否仍会在 native codec 内部建立整图中间态，必须用真机 spike v2 测量，不能仅凭返回 PixelMap 尺寸判断。

SDK 还提供渐进输入 ImageSource：

- `CreateIncrementalSource(buf: ArrayBuffer): ImageSource`：`@ohos.multimedia.image.d.ts:4976`。
- `CreateIncrementalSource(buf: ArrayBuffer, options?: SourceOptions): ImageSource`：`@ohos.multimedia.image.d.ts:4996`。
- `ImageSource.updateData(buf, isFinished, offset, length): Promise<void>`：`@ohos.multimedia.image.d.ts:12143`。

这些接口用于把尚未完整到达的**压缩源数据**逐段追加给解码器，不是把已渲染 RGBA tile 追加到 JPEG 编码器，也不是最终静态图的拼装 API。关键接口未标记 deprecated、experimental 或 preview；名称 `CreateIncrementalSource` 使用大写 `C`，应严格按声明调用。

### 2.2 分段读写能力

PixelMap 具有区域读写能力：

- `readPixels(area: PositionArea): Promise<void>`：`@ohos.multimedia.image.d.ts:5302`。
- `readPixelsSync(area: PositionArea): void`：`@ohos.multimedia.image.d.ts:5354`。
- `writePixels(area: PositionArea): Promise<void>`：`@ohos.multimedia.image.d.ts:5397`。
- `writePixelsSync(area: PositionArea): void`：`@ohos.multimedia.image.d.ts:5454`。
- `PositionArea` 包含 `pixels: ArrayBuffer`、`offset`、`stride`、`region`，定义在 `@ohos.multimedia.image.d.ts:2825`，字段分别位于 `:2860`、`:2895`、`:2930`、`:2965`。

PixelMap 也有整缓冲区读写：

- `readPixelsToBuffer(dst: ArrayBuffer): Promise<void>`：`@ohos.multimedia.image.d.ts:5206`。
- `readPixelsToBufferSync(dst: ArrayBuffer): void`：`@ohos.multimedia.image.d.ts:5263`。
- `writeBufferToPixels(src: ArrayBuffer): Promise<void>`：`@ohos.multimedia.image.d.ts:5497`。
- `writeBufferToPixelsSync(src: ArrayBuffer): void`：`@ohos.multimedia.image.d.ts:5553`。

区域读写可以用于处理**单个 tile PixelMap**，也可以把多个 tile 写入一个预先存在的完整 PixelMap。但后者仍要求先分配 7008×4672 的目标 PixelMap，正好违反本次约束。PixelMap API 未提供稀疏 PixelMap、文件映射 PixelMap、由多个 tile 组成的虚拟 PixelMap或向 ImagePacker 暴露行回调的能力。

### 2.3 结论

image 模块可以低内存地“读一个 tile、处理一个 tile、释放一个 tile”，但不能靠 PixelMap 自身把多个 tile 无完整目标图地编码成单张 JPEG。

`desiredRegion` 是 PR 3 可采用的原图分块加载入口；其真实解码峰值和重复区域解码性能必须真机验证。`readPixels/writePixels` 只解决 tile 数据搬运，不解决最终 JPEG 流式编码。

## 3. 非拷贝 createPixelMap

### 3.1 现状（是否拷贝）

ArkTS 声明只描述 `createPixelMap(colors: ArrayBuffer, options)` 为“Create pixelmap by data buffer”：

- Promise 版本：`@ohos.multimedia.image.d.ts:4468`。
- 同步版本：`@ohos.multimedia.image.d.ts:4481`。

声明没有说明 PixelMap 与传入 ArrayBuffer 共享存储、转移所有权、保持引用或执行拷贝，因此不能从公开类型定义证明它是 zero-copy。

API 20 新增的 `createPixelMapUsingAllocator(colors, options, allocatorType?)` 可选择 DMA 或共享内存，但异常清单明确包含 `7600302 - Memory copy failed`：`@ohos.multimedia.image.d.ts:4483`-`:4498`，同步版本同样位于 `:4500`-`:4515`。这至少证明该通路存在内存复制阶段；选择 `SHARE_MEMORY` 不等于把调用方 ArrayBuffer 原地包装成 PixelMap。

结合 spike v1 的事实——130 MB ArrayBuffer 创建 PixelMap 时耗时 9.766 秒，ArkTS native 内存膨胀至约 2 GB 并被 RSS killer 杀死——工程上应把 `createPixelMap(fullBuffer, ...)` 视为高风险复制/转换通路。但“内部必然复制几次、2 GB 分别来自哪些组件”无法仅靠公开声明定量归因。

### 3.2 zero-copy 替代

在 ArkTS image API 中未查到 `attachBuffer`、`wrapBuffer`、`createPixelMapFromBuffer`、外部内存 deleter 或 ownership-transfer 形式的 PixelMap 创建 API。

Native PixelMap 提供：

- `OH_PixelmapNative_GetNativeBuffer(...)`：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/multimedia/image_framework/image/pixelmap_native.h:1279`。
- `OH_PixelmapNative_AccessPixels(...)`：同文件 `:1370`。
- `OH_PixelmapNative_UnaccessPixels(...)`：同文件 `:1385`。

这些接口只能访问或暴露**已经存在的 PixelMap**，没有把任意外部 tile buffer 附着为 PixelMap 的公开入口。

DrawingKit 有一个更接近 zero-copy wrapper 的能力：`OH_Drawing_BitmapCreateFromPixels(imageInfo, pixels, rowBytes)`，声明说明它设置 pixel storage 的内存地址，位置为 `/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/native_drawing/drawing_bitmap.h:84`-`:96`。它可用于把一个 tile buffer 包装为 DrawingKit Bitmap，避免再为该 tile 建一个 DrawingKit 内部 Bitmap 副本；但它不是 PixelMap，也没有直接连接到 JPEG scan-line 编码器。若用它包装 full-size buffer，仍然必须持有 full-size backing storage。

### 3.3 结论

SDK 6.1.1(24) 没有公开的 ArkTS PixelMap zero-copy 创建保证，也没有“多块外部 buffer 共同组成一个 PixelMap”的能力。AllocatorType 只能改变 PixelMap 的存储类型，不能消除 full-size 图像本身的存储需求。

DrawingKit `BitmapCreateFromPixels` 可作为**tile 级**原生绘制优化，但不能单独解决最终 JPEG 编码。

## 4. NAPI + libjpeg 路径

### 4.1 SDK 内置 libjpeg 可用性

对以下目录进行了本地检索：

- `/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include`
- `/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/lib`

结果：

- 未查到公开的 `jpeglib.h`、`turbojpeg.h` 或其他 libjpeg/libjpeg-turbo NDK header。
- 未查到可链接的 `libjpeg.so`、`libjpeg.a`、`libturbojpeg.so` 或 `libturbojpeg.a`。
- 只查到 CMake 自带的通用 `FindJPEG.cmake` 文档和模块；它不代表 HarmonyOS sysroot 实际提供 JPEG 开发包或目标库。
- sysroot 提供 `libimage_packer.so`、`libimage_packer_ndk.z.so` 等系统图片框架库，但其公开头文件仍只有整 `ImageSource/PixelMap/Picture` 输入的 PackToData/PackToFile API，见 `image_packer_native.h:407`、`:426`、`:483`、`:501`。

因此，应用不能可靠地“借用 SDK 内置 libjpeg”实现 `jpeg_start_compress` / `jpeg_write_scanlines` / `jpeg_finish_compress`。即使系统内部的 ImagePacker 很可能使用某种 JPEG codec，该实现没有通过公开 NDK ABI 暴露 scan-line 接口，直接链接私有符号也不应作为产品方案。

若允许把一个可移植 JPEG 编码器源码随应用编译进 HAP，则 NAPI 实现 scan-line encoder 在技术上可行：

1. Native 创建编码会话和输出 fd。
2. ArkTS 每次提供一个横向 strip/tile 的 RGB(A) 数据。
3. Native 按输出 y 顺序逐 scan-line 喂给编码器。
4. 最后 finalize 并关闭会话。

这条路不依赖 full-size PixelMap，编码器通常只需若干行缓存和压缩状态；但它是**新增原生模块 + 新增随包编码器实现**，不是 HarmonyOS ImagePacker 的现成功能。必须单独完成依赖许可、安全审查、arm64 构建、NAPI 异常恢复和中断清理验证。

### 4.2 项目已有 NAPI 先例

当前仓库未查到 `CMakeLists.txt`、`.cpp/.cc/.c/.h/.hpp` 原生源码，也未查到 `napi_`、`NAPI_MODULE` 或 native library 注册代码。

`entry/build-profile.json5:3`-`:9` 只有 ArkTS buildOption，没有 `externalNativeOptions` 或 CMake 配置；`entry/oh-package.json5:8` 的 dependencies 为空。因此项目没有可直接复用的 NAPI 构建、模块注册、资源释放或测试先例。

### 4.3 可行性评估

| 路径 | 是否满足无 full-size PixelMap | 评价 |
| --- | --- | --- |
| NAPI 调 HarmonyOS 内置 libjpeg | 无法落地 | SDK 未公开 header/library/ABI |
| NAPI 调 Native ImagePacker | 否 | 仍只接受完整 ImageSource/PixelMap/Picture |
| NAPI + 随包编译的 scan-line JPEG encoder | 是 | 技术可行，但引入新原生架构和外部编码器实现 |
| 直接链接系统私有 JPEG 符号 | 不应采用 | 无公开 ABI，系统升级兼容和上架风险不可接受 |

结论：**NAPI 是可行的桥，但 SDK 没有可借用的公开 libjpeg。** 要实现真正流式 JPEG，必须将 scan-line 编码器实现随应用构建，或改由服务端完成。

## 5. 替代通路

### 5.1 image.Effect / Composer

公开 NDK ImageEffect 支持 PixelMap、NativeBuffer、URI、Picture、纹理和 Surface 等输入输出：

- `OH_ImageEffect_SetInputPixelmap`：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/multimedia/image_effect/image_effect.h:264`。
- `OH_ImageEffect_SetOutputPixelmap`：同文件 `:278`。
- `OH_ImageEffect_SetInputNativeBuffer` / `SetOutputNativeBuffer`：同文件 `:293`、`:307`。
- `OH_ImageEffect_SetInputUri` / `SetOutputUri`：同文件 `:322`、`:336`。
- `OH_ImageEffect_SetInputTextureId` / `SetOutputTextureId`：同文件 `:380`、`:397`。
- 执行入口 `OH_ImageEffect_Start`：同文件 `:414`。

这些接口面向滤镜链和图像效果，不提供任意边框、文字排版、多个空间 tile 合并为静态 JPEG 的 compositor/encoder API。即便 URI 输出可能隐藏内部文件写入，公开声明也没有 scan-line 输入、tile 坐标、最终画布尺寸或内存足印保证，不能替代 PR 3 的合成器。

本地 ETS API 中未查到可用于该需求的 `image.Composer` 模块。`mediaquery` 是媒体查询/设备能力接口，与图片合成无关。

### 5.2 DrawingKit

DrawingKit 可以作为 tile 绘制层：

- 外部 tile 内存包装 Bitmap：`drawing_bitmap.h:95`。
- Canvas 绑定 Bitmap：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/native_drawing/drawing_canvas.h:114`。
- Canvas 绘制 PixelMap：同文件 `:307`。
- Canvas 读取局部像素：同文件 `:973`。

DrawingKit 也能创建 GPU Surface：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/native_drawing/drawing_surface.h:62`，并通过 `SurfaceGetCanvas` 获取画布（`:91`）。但 7008×4672 RGBA GPU surface 本身仍约占 124.9 MiB 原始像素存储，还可能有纹理对齐、双缓冲和 readback；它只是把 full-size raster 从 PixelMap 移到 GPU/NativeBuffer，不满足“任意时刻不持有 full-size 图像”的低内存目标。最终转 JPEG 时仍需 ImagePacker 可接受的完整源或额外 scan-line encoder。

因此 DrawingKit 的合理用途是**256 行左右的横向 strip 合成**，不是创建 full-size Bitmap/Surface。

### 5.3 系统合成 API

在 SDK 6.1.1(24) 公开 ETS/NDK 声明中，未查到系统相册、图片处理服务或媒体服务提供“提交多个带坐标 tile，输出单张指定尺寸 JPEG”的 API。

ImagePacker 的 Picture 输入不是 tile compositor；Picture 的编码入口仍要求一个已构造完成的 Picture。PixelMap sequence 接口仅用于 GIF 动画帧，不可用于静态 JPEG 空间拼接。

## 6. Codex 推荐方案（重点）

基于上述调研，PR 3 分块渲染的**最优技术组合**推荐分成两个前提结论：

### 6.1 若允许新增原生模块并随包编译 JPEG encoder：可行，推荐采用

- 加载原图：通过文件描述符创建 `ImageSource`（`createImageSource(fd)`），按输出 strip 对应的原图采样范围调用 `createPixelMap({ desiredRegion, desiredSize, desiredPixelFormat: RGBA_8888 })`。每次只保留当前 strip 所需 PixelMap；缩放滤波需要在相邻 strip 间增加少量源区域重叠。
- 分块处理：使用横向 strip，而不是二维无序 tile。建议起始尺寸为 `7008×256`，保证最终 JPEG scan-line 顺序天然连续。ArkTS OffscreenCanvas 或 Native DrawingKit 均可；从减少跨层复制和为 NAPI 编码铺路考虑，优先评估 `OH_Drawing_BitmapCreateFromPixels` + `OH_Drawing_CanvasBind` 的 Native strip 画布。
- 边框合成：以最终画布坐标系计算一次布局；对每个 strip 设置 clip/translate，绘制该 strip 覆盖到的照片、纯色边框、文字和装饰。文字跨 strip 时使用相同全局基线，只让 clip 决定当前 strip 输出，避免重新排版。
- 最终编码：新增 NAPI 持久编码会话，随 HAP 编译一个公开、可审计的 scan-line JPEG encoder；按 y 从 0 到 4671 将每个 strip 的行依次写入同一 JPEG，质量 95，直接输出到 fd。HarmonyOS SDK 内置 ImagePacker 不承担最终编码，因为它没有分片输入接口。
- 内存峰值预估：`7008×256×4 ≈ 6.84 MiB`/strip。按“源区域 PixelMap + strip backing buffer + readback/颜色转换 buffer + 解码器/编码器状态”估算，目标峰值应控制在 **32～64 MiB 增量**；如果同时保留三个 RGBA strip，纯像素约 20.5 MiB。实际峰值必须用 hidebug/hilog 真机验证，尤其要确认 `desiredRegion` 解码不会在 codec 内部建立 full-size 中间图。
- 已知风险 / 未验证项：
  - `ImageSource.createPixelMap({ desiredRegion })` 对 7008×4672 JPEG 是否真正低内存，声明没有保证。
  - 相邻 strip 缩放滤波可能产生接缝，需要源区域重叠和统一采样矩阵。
  - 字体绘制、抗锯齿和 ArkUI 现有 L3 导出视觉是否能在 DrawingKit 中一致，需要人工对图。
  - 项目没有 NAPI 先例，需要新增 CMake、模块注册、arm64 链接、fd 生命周期和取消/异常清理。
  - 随包 JPEG encoder 的来源、许可、漏洞响应和体积需由 Claude/用户批准。

### 6.2 若禁止新增随包原生 JPEG encoder：无可行方案，建议 Claude 与用户重新拍板

在“只用 HarmonyOS SDK 6.1.1(24) 公开 API”且“任意时刻不持有 full-size PixelMap/Bitmap/Surface”的双重约束下，**没有可行的单机 7008×4672 静态 JPEG 合成路径**。ImagePacker 只能接收完整源；PixelMap 区域 API只能处理或回写区域；ImageEffect 和 DrawingKit 不提供流式 JPEG 输出。

此时建议产品在以下方向中重新选择：

1. 降低最终输出分辨率，使单张 PixelMap 的峰值进入设备安全范围。
2. 允许引入 NAPI + 随包 scan-line JPEG encoder。
3. 将全分辨率合成放到服务端，客户端只上传原图和结构化模板参数。
4. 等待后续 SDK 提供公开的流式/增量 JPEG encode API。

## 7. 建议下一步

- PR 3 spike v2 先做最小 PoC，不直接实现完整模板：
  1. 从 fd 创建同一张 7008×4672 JPEG 的 ImageSource。
  2. 循环以 `desiredRegion` 解码 `7008×256` 对应区域，立即释放 PixelMap。
  3. 记录每 strip 耗时、PSS/RSS、native heap 和峰值，验证区域解码是否真的低内存。
  4. 用最小 NAPI 模块把人工生成的 RGB strip 按 scan-line 写成 7008×4672 JPEG，校验尺寸、文件完整性和质量 95。
  5. 最后才把 DrawingKit/OffscreenCanvas 的边框与文字合成接入同一 strip 管线。
- PoC 的硬门槛建议为：全流程无 full-size raster；峰值增量低于 96 MiB，目标低于 64 MiB；无 strip 接缝；输出 JPEG 可被 HarmonyOS ImageSource 正常解码回 7008×4672。
- 如果 `desiredRegion` 仍触发接近 full-size 的 native 解码内存，或项目不允许引入随包编码器，则停止 PR 3 客户端全分辨率方案，回到 Claude 与用户重新拍板：降分辨率、服务端合成或等待 SDK 升级。
