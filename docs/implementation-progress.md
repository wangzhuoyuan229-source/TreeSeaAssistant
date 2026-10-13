# 实施记录

计划：docs/superpowers/plans/2026-10-13-ios-screenshot-prediction-planning.md
日期：2026-10-13；本地分支 implementation/ios-v1；基线 cadbec0。

用户最新授权：遇到问题自行解决，持续实现，不按旧文档中的遇错暂停条款停止。

## 前置核查与决定

- Swift 6.4 编译器可用，支持宿主运行纯 Foundation 核心测试。
- 当前开发目录为 CommandLineTools；/Applications 与 Spotlight 没有 Xcode，simctl 和 iOS SDK 不可用。继续完成可验证的核心、iOS 工程和源码；iOS 构建、模拟器、真机及人工验收不能标为通过。遵守既定 iOS 技术栈，不以 macOS/web 代替 App。
- 当前目录无已有代码/仓库，按计划建立本地 Git 并在实施分支工作，保留全部历史文档与素材，无远端、无发布。
- 原计划的所有消费者均引用同一基础模型；预算共享于单次计算，实例库存不合并，候选不确认身份，预测/路线版本校验独立。
- 运行时资料仍区分 researchReference 与已核对状态；源码数值一致不代表游戏实战核实。

## 任务状态

任务 1：进行中。测试日志保存于 .build-evidence，正式汇总见 docs/acceptance。

任务 2：目录转录已实现，55 条来源规则、43 张研究模板及 12 种加工品；未把研究模板标记为实战通过。Catalog 测试通过。
任务 3/4：核心 BFS、独立筛选、Dinic 下界流、离散配额和全局回退已实现。源函数对照 240 个局部输入及 5 个全局输入；独立小图枚举对照通过。
任务 5：确定性动作、逐实例次数、启动门槛、一次性增益和四分之一整数评分已实现；21 个核心测试通过（task5-suite.log）。
工具链处理：CLT 的默认 SwiftPM 构建后端间歇遗漏 TestingMacros；scripts/test-core.sh 使用 native 后端并显式提供 CLT Framework/插件路径，已复现并消除该故障，不修改系统配置。native 弃用警告保留。

任务 6：安全求解、三偏好共享预算搜索、必经与规范化去重已实现；27 个核心测试通过。安全求解使用确定性前向资源支配与循环记忆化适配；仅在无加工品/无增益且正徒步成本时证明最小 AP，其他可达结果不伪造 minimumRequiredAP。
任务 1A/7/7A/8/9：原生界面源码与 Support/Recognition 模块已建立。宿主上 17 个测试通过，包括真实 Image I/O 方向/裁剪/上限与 Core ML 运行输出；这些不等于 iOS 设备验收。71 个原版 sprite（保留偏移）、4 个背景与首次 AppIcon 已集成。
工程：3 个 iOS-only targets、共享 scheme、本地 TreeSeaCore 依赖已生成；PBX plist 校验通过，Swift UI 源码语法解析通过。
当前未通过/未执行：xcodebuild 无完整 Xcode 环境，iOS App 编译、iPhone/iPad UI 自动化、实战截图、真机性能及人工视觉验收。没有以宿主测试替代这些项目。

## 2026-10-14 最终本地核验

- TreeSeaCore：38 项 Swift Testing，通过；Support/Recognition：24 项，通过，共 62 项。来源对照：240 局部/5 全局候选，125 几何/144 资源，以及 24 个固定源 SafetyValueSolver 回调输入；独立小图穷举最佳分对照通过。
- 图片方向/裁剪/限额、原子存储及损坏记录恢复、逐槽位去重、部分合并、旧 generation、保留最后有效路线、收尾预算检查均有真实运行回归。
- ONNX/Core ML 六个合成输入及阈值两侧对照通过，最大记录误差 9.30e-6；未训练模型、未声称实战正确率。
- PBX/共享 scheme/源码资源引用/71 sprite/Swift 语法通过；公共 SwiftUI 宿主类型诊断通过（平台适配与 State wrapper 别名，非 iOS 构建）。
- 重要审查项在同一修复回合内通过失败回归→修复→全套验证。页面层风险已落实取消楼层旧提案、旧路线详情标记及持久外层导航路径；实际 UI 仍待设备验收。
- 本轮明确的实现选择：安全求解采用确定性前向资源支配与语义 memo；仅正徒步无增益时给可证明最小 AP。24 个 MAA 固定源可达输出与 Swift 对齐，未声称移植随机 AND-OR 全量 oracle。
- 整体状态仍未完成：本机只有 CLT，无完整 Xcode/iOS SDK/simctl；iOS build/test 入口退出 2（工具链阻塞），不是测试通过。实战逐层、iPhone/iPad UI、真机性能及人工视觉/无障碍未执行。

用户最新要求覆盖旧计划的遇错暂停条款，开发过程中自行解决了可处理问题，未在单项失败时暂停。没有将剩余验收项删除或改为通过。已保存完整可继续工程、脚本、失败/修复日志与验收文档；需要工具链与实际设备/实战数据后才能完成剩余闭环。
