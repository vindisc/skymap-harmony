# L3 Canvas 导出 fixture 基线

本目录预留 Frame + Review v2 阶段 A 的五张固定导出样本。当前 PR 不提交真实照片或导出 JPEG；待用户提供实拍原图并完成首次人工审查后，再建立正式基线。

## Fixture 清单

| 编号 | 方向 | 原图分辨率 | EXIF Orientation | 数据组合 | 源图 hash（SHA256 前 8 位） |
| --- | --- | --- | :---: | --- | --- |
| fixture-01 | 横图 | 4032×3024 | 1（0°） | WHITE + STANDARD | 待建库时填入 `manifest.json` |
| fixture-02 | 横图 | 7008×4672 | 1（0°） | WHITE + STANDARD | 待填 |
| fixture-03 | 竖图 | 3024×4032 | 1（0°，实拍横图存竖） | WHITE + STANDARD | 待填 |
| fixture-04 | 竖图 | 4672×7008 | 6（90°，验证 orientation 旋转） | LIGHT_GRAY + LARGE | 待填 |
| fixture-05 | 方图 | 4032×4032 | 1（0°） | WHITE + STANDARD | 待填 |

`fixture-04` 必须使用 Orientation=6 的实拍原图，验证分块 `desiredRegion + rotate` 后的方向、尺寸与 strip 顺序。

## 首次验收流程

1. 将五张原图以 `fixture-01.jpg` 至 `fixture-05.jpg` 命名放入本目录的本地验收副本。
2. 用同一版本 HAP 分别执行 L3 原图分辨率导出，保存对应的 `fixture-XX-export.jpg`。
3. 人工检查方向、圆角、留白、文字顺序、换行、字段缺失和 JPEG 解码是否正常。
4. 用户或设计确认后，将通过的导出图写入基线，并生成 `manifest.json`。
5. 后续修改 Canvas 通路时重出五张图；差异像素比例应不超过 5%，单通道 RGB 差异不超过 16/256 时视为一致。

## manifest 格式

```json
{
  "generatedAt": "2026-07-19",
  "appCommit": "<git-commit>",
  "fixtures": [
    {
      "id": "fixture-01",
      "sourceFile": "fixture-01.jpg",
      "exportFile": "fixture-01-export.jpg",
      "sourceWidth": 4032,
      "sourceHeight": 3024,
      "orientation": 1,
      "dataPreset": "WHITE + STANDARD",
      "sourceSha256Prefix": "<8-hex>",
      "approvedAt": "<YYYY-MM-DD>",
      "approvedBy": "<name>"
    }
  ]
}
```
