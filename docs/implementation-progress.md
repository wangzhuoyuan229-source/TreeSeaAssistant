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
