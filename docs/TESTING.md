# 测试指南

## 日常回归

执行稳定冒烟校验，并完成 Debug ArkTS 编译和无签名 HAP 打包：

```bash
bash scripts/test_app.sh
```

只执行校验脚本：

```bash
bash scripts/test_app.sh --quick
```

提交或发版前执行全部发布门禁：

```bash
bash scripts/test_app.sh --all
```

全量门禁会包含工作区卫生、签名基线和历史页面契约，开发中的未提交改动可能让它
失败；默认冒烟套件用于快速判断主干能力是否仍可构建和运行。

## 设备冒烟

先连接 HarmonyOS 真机或启动模拟器，并准备 Debug 签名包，然后执行：

```bash
bash scripts/test_app.sh --device
```

设备模式会先检查设备连接并完成签名，因此需要可用的本机 Debug 签名。随后脚本
通过 `install -r` 覆盖安装应用，不主动卸载、不清理应用数据，再依次覆盖首页、
待复盘、今日复盘、横竖方图
编辑/预览、长文本预览以及六个设置页，并把截图、截图报告和 hilog 放到
`test-artifacts/device-smoke/`。多个设备同时连接时，通过 `SKYMAP_HDC_TARGET` 指定设备。
设备模式固定使用本机 Zulu 11，以兼容当前 Debug p12，不受终端已有 `JAVA_HOME`
影响；如需更换，仅通过 `SKYMAP_DEVICE_JAVA_HOME` 显式指定。设备必须处于
`Connected` 状态，仅能枚举到 `Offline` 设备时会在构建前终止。

`testScenario` 只在 Debug 包中生效，横竖方图和长文本样例只写入内存。Hypium 的
“编辑并保存”用例会在当前测试安装中写入一条标题为“UI 自动化完整链路”的复盘，
建议使用专用测试设备并按需清理应用数据。`today` 场景沿用真实待复盘数据；没有
待复盘照片时会回到首页。

## UI 自动化

Hypium 用例位于 `entry/src/ohosTest/ets/test/`，覆盖根导航、待复盘路由、编辑保存到
预览、预览导出菜单、长文本状态、统计页、我的页和六个设置页面。

`onDeviceTest` 会先卸载主应用，连同 RDB、Preferences 和应用内 JSON 备份一起清空，
禁止在保存了真实数据的日用设备上执行。仅在专用测试设备上显式确认：

```bash
SKYMAP_ALLOW_DATA_RESET=1 bash scripts/test_app.sh --ui-test
```

日常 UI 回归只执行保数据的 `bash scripts/test_app.sh --device`。

## 测试边界

- 本地脚本覆盖源码契约、路由白名单和构建正确性。
- Hypium 覆盖可重复的页面操作，但只允许在可清空数据的专用测试设备执行。
- 云测试覆盖兼容性、稳定性、性能、功耗和安全。
- 小艺、桌面服务卡片、系统相册和家庭局域网仍需指定账号的真实设备验收。
