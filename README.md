# 黑流树海 iOS 辅助 App

面向 iPhone/iPad（iOS/iPadOS 17+）的离线截图、节点候选与路线辅助工具。当前已建立 SwiftUI 工程、独立 TreeSeaCore、截图/库存提案与人工确认、本地会话和多路线解释。**源码、宿主测试与 iOS 编译已通过；参考图和五层真实截图回归均识别出逐格节点与道路。新版原版风格地图、透明起点和封面/图标已接入；完整人工无障碍与性能矩阵仍未完成，尚未完成整体验收。**

已实现的核心包括原始节点身份保留、出生点 BFS、11 类未知诡秘按源顺序筛选、全图配额传播、12 种加工品逐实例库存（随机 M07 不进入确定路线）、最多 8 个无序必经节点和最多三条不同推荐。评分采用已确认收益、固定探索分和保守战斗代价，不计算概率。截图仅作为提案，确认后才提交；重复/部分库存不会默默累加或清空，查看方案不扣真实资源。

UI 采用已批准的 V2 美术与原版图标，含会话、导入裁剪、地图编辑、库存确认、候选、规划条件、路线比较和步骤台账，按内容宽度与辅助功能字号组织单/双/三栏。自动识别已通过六张真实截图回归，重度遮挡或过度裁剪仍可能拒识；识别结果需核对后提交。概率统计仅预留接口，未来导入数据后启用；当前不显示百分比。图像识别也预留未来导入数据库的查询接口，默认仍使用当前离线识别。

## 本地验证与运行

```bash
scripts/test-core.sh
scripts/test-support.sh
python3 scripts/validate-project.py
```

Core/Support/Recognition 可在开发宿主运行测试。App 使用完整 Xcode 与 iOS SDK，打开 TreeSeaAssistant.xcodeproj，使用共享 scheme TreeSeaAssistant。当前已安装 Xcode 27.0、iOS 27 SDK 与签名验证通过的模拟器运行时；iOS 构建、最终 iPhone/iPad 模拟器及两类真机各 35 项通过、2 项宿主回放跳过（Mac 已执行通过）。开发证书、项目开发描述文件及 iPhone 17 Pro、iPad Pro 12.9 英寸第六代 Release 版安装与启动已完成；完整验收状态见验收记录。

```bash
scripts/verify-ios.sh
```

该脚本先编译并列出真实 destinations；按输出设置 TREESEA_SIMULATOR_ID 和 TREESEA_IPAD_SIMULATOR_ID 后运行两类模拟器测试。真机、实战图片与人工验收另按验收记录执行。项目只建立本地实施分支，未配置远端或发布。

## 文档

- [验收状态、证据和待完成项](docs/acceptance/report.md)
- [实施记录](docs/implementation-progress.md)
- [独立审查与修复](docs/acceptance/review.md)
- [需求与算法规格](docs/ios-app-spec.md)
- [原开发计划](docs/superpowers/plans/2026-10-13-ios-screenshot-prediction-planning.md)（保留规划时的历史状态，当前进度以实施/验收记录为准）
- [MAA 对照和适配差异](docs/maa-porting-notes.md)、[数据来源与许可状态](docs/data-provenance.md)
- [V2 视觉依据](docs/ui-design-reference-v2.md)、[交互与无障碍规范](docs/ui-design-spec.md)
- [原版素材](图标/README.md)、[自建素材](自建素材/README.md)、[历史预览](docs/ui-previews/reference-v2/README.md)

规则与 43 张模板保留 researchReference，不把公开源码当作游戏实测。用户在设置中明确核对后才启用强规则；普通未知凶戾要求人工确认战斗范围，未建模特殊节点须揭示。MAA、hlsh-helper、路标与自建资源的来源分开记录，后续分发许可另行核对。
