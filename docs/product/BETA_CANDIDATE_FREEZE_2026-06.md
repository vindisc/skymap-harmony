# Skymap Beta Candidate Freeze 2026-06

日期：2026-06-13

结论：**已进入 Beta 范围**

当前 Freeze 目标不是继续扩功能，而是把 Beta 范围锁定为一条可理解、可完成、可验证的摄影工作流：

```text
Harmony 创建复盘
↓
导出 review.json
↓
Mac 导入 Review Library
↓
继续编辑与导出边框
```

从本文件起，Skymap 不再无限继续开发。后续如果不是：

- 阻塞性缺陷修复
- 文案澄清
- 必要验证补强

则不进入本轮 Beta Candidate。

## 1. Freeze 检查结论

### 1.1 Product Layer

- 当前 `docs/product/` 已能清楚区分：
  - 当前 Beta 基线
  - Beta 后能力
  - 明确不进入本轮的未来方案
- `BETA_READINESS_AUDIT_2026-06.md` 已确认 P0 修复完成。
- `SYNC_V0_5.md` 已把用户交换链路收口为可执行闭环。

结论：**通过**

### 1.2 Review Domain

- `review.json` v1 字段语义已稳定。
- 双端围绕同一份 `REVIEW_JSON_SEMANTICS.md` 工作。
- 当前 Beta 可以把 `review.json` 当成稳定交换文件，但不能把它当成完整同步系统。

结论：**通过**

### 1.3 Review Library

- Mac 已支持：
  - 打开 Review Library
  - 独立导入 `review.json`
  - 搜索
  - 成立判断筛选
  - 重复导入去重提示
  - 定位导入记录
- Harmony 已支持：
  - 复盘库入口
  - 搜索
  - 成立判断筛选
  - 查看本地历史记录

结论：**通过**

### 1.4 Sync v0.5

- Harmony 已能把 `review.json` 导出到用户可理解的系统文件位置。
- Mac 已能把 `review.json` 独立导入到 Review Library。
- 用户不再需要理解应用沙箱路径，也不再需要先导入照片、先选照片、先切模板才能完成导入。

结论：**通过**

### 1.5 Mac Client

- 已具备 Beta 需要的主流程能力：
  - 导入照片
  - 选择模板
  - 调整参数
  - 保存当前复盘
  - 导入 `review.json`
  - 查看 Review Library
  - 继续编辑
  - 单张导出
  - 批量导出

结论：**通过**

### 1.6 Harmony Client

- 已具备 Beta 需要的主流程能力：
  - 选择照片
  - 创建复盘
  - 保存到历史
  - 阅读页查看
  - 导出复盘长图
  - 导出 `review.json`
  - 查看复盘库

结论：**通过**

## 2. 当前允许进入 Beta 的能力

以下能力允许作为 Beta 用户测试范围：

### 2.1 Product Layer

- 清晰的双端职责：
  - Harmony 负责快速复盘与移动端阅读
  - Mac 负责 Review Library、模板精修与边框导出
- `review.json` 作为稳定交换文件
- `Sync v0.5` 作为最低可用手动交换闭环

### 2.2 Review Domain

- 标题
- 复盘时间
- 复盘人
- 成立判断
- 第一眼落点
- 落点原因
- 视线路径
- 画面事实
- 核心关系
- 延伸理解
- 当前卡点

### 2.3 Review Library

- Mac Review Library 独立导入 `review.json`
- Mac Review Library 搜索与成立判断筛选
- Mac 重复导入去重与定位
- Harmony 复盘库查看、搜索与筛选

### 2.4 Sync v0.5

- Harmony 导出 `review.json` 到系统文件
- 用户通过文件、聊天或手动发送把 `review.json` 交给 Mac
- Mac 导入到 Review Library

### 2.5 Mac Client

- 导入照片
- 选择模板
- 调整模板参数
- 使用资料中心与预设
- 保存当前复盘
- 继续编辑导入后的复盘
- 单张导出
- 批量导出

### 2.6 Harmony Client

- 创建复盘
- 保存本地历史
- 阅读页查看
- 导出复盘长图
- 导出 `review.json`

## 3. Beta 后能力

以下能力属于 Beta 后推进，不进入当前 Candidate：

- 更完整的产品级复盘库浏览与管理
- 家庭存储接力增强
- 更完整的导入报告、扫描、重复检测增强
- 更丰富的统计、趋势与成长系统
- AI 辅助分析与建议

## 4. 明确延期

以下能力明确延期，不允许在本轮以“顺手做一点”的方式继续扩：

- Sync v1
- Review Bundle
- 标签
- 收藏
- 批注
- 成长统计
- AI 分析

补充说明：

- `manifest`
- SMB 自动同步
- WebDAV 自动同步

同样不进入本轮 Beta Candidate。

## 5. Beta 用户测试任务

面向摄影用户的测试清单建议如下：

1. 任务1：在 Harmony 创建一条复盘  
   目标：用户能选照片、填写标题和核心复盘字段，并保存记录。

2. 任务2：在 Harmony 导出 `review.json`  
   目标：用户知道文件已经保存到系统文件，且知道下一步是交给 Mac。

3. 任务3：在 Mac 导入 `review.json`  
   目标：用户不需要先导入照片，也能把记录写进 Review Library。

4. 任务4：在 Mac 查看 Review Library  
   目标：用户能找到刚导入的记录，并理解它已经进入复盘库。

5. 任务5：在 Mac 继续编辑  
   目标：用户能在 Mac 打开照片、切到摄影复盘模板，继续补充或修改复盘内容。

6. 任务6：在 Mac 导出边框  
   目标：用户能完成模板调整与导出，拿到最终交付图片。

## 6. Beta 成功标准

建议采用以下 Beta 成功标准：

1. 邀请 10 名真实摄影用户完成测试。
2. 80% 以上用户能完成主流程：
   - Harmony 创建复盘
   - 导出 `review.json`
   - Mac 导入
   - 查看 Review Library
   - 继续编辑或导出边框
3. 不出现阻塞性缺陷：
   - 导出后拿不到文件
   - Mac 无法导入
   - Review Library 找不到记录
   - 导出结果不可用
4. 用户在测试后能回答：
   - Harmony 负责什么
   - Mac 负责什么
   - `review.json` 怎么交换
   - 导入后的结果在哪里

## 7. Freeze 规则

从当前 Candidate 起，只允许继续做以下类型改动：

- P0 / P1 阻塞缺陷修复
- 用户无法完成主流程的明确修复
- 文档与测试补强
- 低风险文案澄清

以下类型改动默认禁止进入本轮：

- 新系统
- 新对象模型
- 新同步层
- 新收藏/标签/批注能力
- 新成长统计
- 新 AI 分析链路

## 8. 合并建议

当前 Beta Candidate 应按以下顺序收口：

1. 先保持 `review.json` 和 Review Library 基线稳定。
2. 再只处理真实用户测试中暴露的阻塞问题。
3. Beta 后再进入 `Sync v1`、Review Bundle 和成长系统。
