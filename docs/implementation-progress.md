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

## 2026-10-14 工具链安装与继续验收

- 用户明确授权自行安装 Xcode / iOS SDK，覆盖旧计划不安装的限制。官方 App Store 已安装 Xcode 27.0（27A266a）；首次启动需要 Apple 协议与系统管理员认证，已打开原生窗口让用户完成，不收集密码。
- 五层公开实战截图已取得并实际运行宿主识别，均未形成可靠网格；记录见 acceptance/screenshot-replay.json，不以诊断测试执行成功当作实战验收通过。原图、OCR、耗时与拒识证据仅留在 .build-evidence/game-replay。
- 截图“作战”未被“普通作战”目录名称识别的问题，新增失败回归后补别名；Support/Recognition 全套 25 项通过。工具链选择脚本改用 xcrun 实际 Swift 路径，兼容 DEVELOPER_DIR 显式选择。
- Xcode 首次启动现已完成，xcodebuild -checkFirstLaunchStatus 返回 0；实际 SDK 列表包含 iOS 27.0 与 iOS Simulator 27.0。模拟器 App Debug build、App/单元/UI build-for-testing、TreeSeaCore build-for-testing，以及无签名 iOS 设备架构 Release build 都已成功。完整 Xcode 工具链下重新运行 38 + 25 = 63 项宿主测试通过。
- 官方 MobileAsset 单连接下载较慢，改为 Apple 元数据指定的 CDN 同一 archive 分段下载；不修改系统安全设置。下载后要求与 Apple 元数据 SHA256 一致，并使用原生 Apple Archive 工具与正常 Simulator 安装入口。原始重复传输已取消，部分缓存保留。
- devicectl list devices 当前未发现连接真机；模拟器结果不得写为旧/新 iPhone 真机性能或人工验收结果。

## 2026-10-14 连接真机后的验证

- 已连接 iPhone 17 Pro（iOS 27.0），完成解锁、配对与开发者模式；开发服务可用。Personal Team 自动创建项目开发描述文件，含 1 台设备；签名 Debug build、严格签名验证与实际安装通过。证书私钥留在本机钥匙串，未导出。
- iPhone 18 Pro 模拟器 25 单元 + 3 UI 全通过（ios-phone-run3.xcresult）；iPad Pro 13-inch（M5）首轮同样 28 项通过（ios-ipad-run1.xcresult）。run2 的 CoreSimulator host_support 服务失败保留，正常重新启动模拟器后恢复。
- Debug ONLY_ACTIVE_ARCH=YES 修复本机 arm64 Swift Package 与 App 同时链接 x86_64 的架构不匹配，Release 架构范围保持原样。
- 截图复核发现首轮规划测试将初值追加为 61 AP，库存未执行。已补强测试为清除旧值后断言 AP=1，并实际保存剩余 2 次的加工品；待复验，不以旧绿灯掩盖测试缺口。
- 真机启动被 iOS 拒绝，提示签名/描述文件尚未被用户信任；签名已在 Mac 验证通过，已请求用户在手机上核对并信任开发者。未将安装成功当作真机运行通过。

## 2026-10-14 真机启动修复与补强测试复验

- 修复真机 dyld 缺少 TreeSeaCore 动态库：显式动态产品、Embed Frameworks 签名复制与 App Frameworks runpath；静态产品尝试触发宿主测试重复链接，失败日志保留，最终采用动态嵌入。
- 加工品次数输入增加键盘“完成”按钮，解决 iPad 数字键盘遮挡确认控件；UI 用例显式关闭键盘并确认保存结果。
- 最终 iPhone 模拟器、iPad 模拟器与 iPhone 17 Pro 真机分别 28 项全通过，结果见 verification.json；此前初值追加、系统无线数据弹窗和键盘遮挡的失败证据保留。
- iPhone Release 签名构建、严格签名校验、安装、启动与运行进程检查通过，并保存真机截图。项目生成器同步框架嵌入设置，并验证重新生成保留六个配置的现有开发团队。
- 用户要求追加 iPad 真机；已连接 iPad Pro 12.9 英寸第六代（iPadOS 27.0.1），开发者模式与开发服务可用，正在执行真机测试。实战识别、完整人工无障碍与性能矩阵仍未通过。

- iPad 首轮测试退出 65，App 与测试 Runner 均被系统拒绝启动，原因是开发证书尚未在本机受信任。日志 ios-physical-ipad-run1.log；未记为通过，等待用户在设备设置核对并信任开发者。

- 用户在 iPad 信任开发者后，ios-physical-ipad-run2.xcresult 28/28 全通过（25 单元 + 3 UI，零失败）；Release 构建、严格签名验证、安装与启动均通过。描述文件现注册 2 台设备。iPad 库存 UI 截图核实“剩余 2 次”，失败的首轮记录保留。

## 2026-10-14 用户验收反馈后的修订

用户指出导入拒识、地图未遵循原版、起点方形贴图和旧美术不合格。本轮修复文字/节点网格与道路裁剪坐标，六张真实图逐格逐边通过；新增完整导入 UI 回归。地图、美术、背景和 AppIcon 更新至 0.2.0 build 2。用户最后明确概率统计先预留接口，未来导入数据后启用，因此撤回所有统计数据/百分比实现，当前仅保留公共 Provider 契约与页面占位。

核心回归最终 38/19；真实截图完整 Support 回归 28/14，均通过。iOS 运行中的两项宿主六图回放因未传 Mac fixture 环境而明确跳过，真实参考图另经 UI 回归实际执行，不能把两项 skip 写成通过。新版最终设备矩阵另见 verification.json。

用户后续指定精确地图比例及数据库预留，已实现 MapBoardMetrics 与两项比例回归、默认不自动叠加首条路线；数字键盘父页/弹窗“完成”冲突使用焦点条件与独立标识修复。数据库识别增加默认 nil 的 Provider、版本、楼层/取消检查与未确认边界，现有六图回放不变。最终宿主71项通过；四平台iOS矩阵各35通过+2宿主回放skip。锁屏等待、一次模拟器kAXErrorServerNotFound、缺Debug fixture、键盘同名冲突均保留原日志，最终复验以 verification.json 为准。

最终同一签名 Release 0.2.0（2）已安装并启动于 iPhone/iPad，严格签名及运行进程检查通过，未包含Debug参考图、调试导入参数或已撤回的统计数据。
