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

设备模式会继续执行签名，因此需要可用的本机 Debug 签名。脚本会安装应用，依次
启动 `home`、`pending`、`today` 三个 Debug 测试场景，
并把截图和 hilog 放到 `test-artifacts/device-smoke/`。多个设备同时连接时，通过
`SKYMAP_HDC_TARGET` 指定设备。

`testScenario` 只在 Debug 包中生效，不清理或写入用户业务数据。`today` 场景沿用
真实待复盘数据；没有待复盘照片时会回到首页。

## UI 自动化

首批 Hypium 用例位于 `entry/src/ohosTest/ets/test/`，覆盖根导航、统计页和我的页。
在 DevEco Studio 中选择对应测试文件或目录后运行 `Run Tests`。设备接入后，可将
该测试包接入 DevEco Testing 或 CI 的 on-device test 流程。

## 测试边界

- 本地脚本覆盖源码契约、路由白名单和构建正确性。
- Hypium 覆盖可重复的页面操作。
- 云测试覆盖兼容性、稳定性、性能、功耗和安全。
- 小艺、桌面服务卡片、系统相册和家庭局域网仍需指定账号的真实设备验收。
