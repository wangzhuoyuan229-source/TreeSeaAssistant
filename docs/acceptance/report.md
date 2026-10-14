# 首版实施与验收记录

实施开始：2026-10-13；最终核验：2026-10-14（Asia/Shanghai）。**总体状态：源码与宿主验证已交付，首版整体验收未完成；2026-10-14 视觉与识别修订见下。** 不将未运行的 iOS/真机项目标记为通过。

## 已实现并验证的部分

| 项目 | 实际证据 |
|---|---|
| 核心模型、规则、BFS、候选、全局上下界流、离散配额、预算与取消 | TreeSeaCore Swift Testing；候选固定源函数 240 个局部 / 5 个全局对照；独立 1–6 节点赋值 oracle |
| 加工品射程、逐实例次数、启动门槛、一次增益、整数评分、必经与三偏好多路线 | MAA 精确 C++ 函数编译输出 125 几何 / 144 资源输入；24 个源 SafetyValueSolver 输入；3–6 节点 / AP≤8 / 物品≤1 独立完整规划穷举对照 |
| 会话修订、异步 generation、导入事务、覆盖与原始身份、部分库存合并、槽位去重、原子保存 | Support 回归；部分/重复/未确认/完整替换、旧 stamp、取消、AP/必经变化、损坏文件保留 |
| Image I/O 解码边界、EXIF、裁剪及坐标逆变换 | 宿主 Apple 框架真实运行；20 MiB / 1600万像素限制、最长边≤1280、裁剪坐标往返误差测试 |
| ONNX→Core ML 等价导出与 Swift 调用 | 六个合成输入（含阈值两侧），最大记录 logit 误差 9.30e-6；Swift Core ML CPU 运行通过；未训练模型 |
| V2 资源、主题与布局阈值 | 71 个原版 sprite、4 个下采样背景、首次 AppIcon；颜色对比度及 679/680/959/960、Compact/辅助功能字号判定测试 |
| SwiftUI 业务页面与工程 | iOS-only App/单元/UI 三个 targets、共享 scheme、local package；PBX/source/resource/71 sprite 引用与 Swift 语法校验通过；宿主共同 SwiftUI 类型诊断通过，平台 API 有替换，不能当 iOS 编译 |
| 独立代码审查 | [审查与修复记录](review.md)；六项重要发现的失败回归→修复→整套验证；楼层、旧详情和导航路径风险已在源码处理 |

最终测试次数及命令退出码见 [verification.json](verification.json)。完整运行日志保存在项目 .build-evidence；iOS 构建失败日志也保留，不混入通过数量。

## 验收矩阵与未完成项

| 项目 | 当前事实 / 恢复执行所需条件 |
|---|---|
| iOS App 真正编译 | 已通过：Xcode 27.0；模拟器 Debug、iPhone/iPad 开发签名 Debug / Release build 均成功。Release 严格签名校验、实际安装、启动与运行进程检查通过，证书/描述文件见 signing.json |
| iPhone/iPad UI 自动化 | 最终 iPhone 17 Pro、iPad Pro 12.9 英寸第六代真机及两类模拟器各 35 通过、2 跳过（仅宿主六图回放，Mac 单独执行通过）。4 项 UI 含真实图片导入与比例/命中、AP=1 实际提交、剩余2次加工品、最大字号与旋转。结果见 verification.json；两台真机均安装并运行最终签名 Release 0.2.0（2） |
| 每层实战识别与模板核对 | 已修复初轮全拒识：用户参考图及五层公开截图均识别成功，节点/道路分别 12/13、12/13、19/20、31/34、32/35、42/44，逐格逐边断言通过，见 screenshot-replay-v2.json。初轮失败记录保留。43 个模板仍为 researchReference；仅六张回归样本，库存 OCR、重遮挡泛化与人工实战闭环不能据此标为通过 |
| 人工视觉 / 无障碍 | iPhone 横竖屏、iPad 单/双/三栏与窄窗口，地图缩放后节点身份/点击，编辑草稿、键盘、VoiceOver、指针/焦点、最大字号、Reduce Motion/Transparency、灰度与增强对比度都未作设备人工验收 |
| 性能 / 20 次导入 | 尚无较旧/近期 iPhone 真机及 Instruments 记录；100/300ms 是设计预算，不是设备成绩。未记录真机 P50/P95、取消延迟、峰值内存或连续导入内存趋势 |

识别失败保留人工模板 / 手动地图 / 手动库存路径；未知凶戾、随机物品、未确认次数和增益不会被冒充已建模或确认安全。来源、复制边界和适配差异见 data-provenance 与 maa-porting-notes。

## 复验入口

```bash
scripts/test-core.sh
scripts/test-support.sh
python3 scripts/validate-project.py
python3 scripts/typecheck-ui-diagnostic.py
scripts/verify-ios.sh
```

宿主测试为算法与适配器验证，产品目标仍仅 iPhone/iPad。完整 Xcode 已安装，iOS build 已通过；按真实 destinations 设置 TREESEA_SIMULATOR_ID / TREESEA_IPAD_SIMULATOR_ID 可复验两类模拟器。仍需补实战与真机矩阵，才可把总体状态改为全部完成。

## 2026-10-14 视觉与识别修订

- 地图改为原版各层背景、圆形节点与流线道路；起点使用透明人物矢量，不再使用不透明方形截图。整体缩放与按钮共用变换，保留命中身份、必经、道路和路线。
- 新版骨兽版画封面、寻路徽记 AppIcon 与统一低对比背景已接入。原版 71 张 sprite 的像素和原文件字节均保留；新增资产与来源见 redesign-assets.json。
- 用户最终要求概率统计暂缓，仅保留 NodeProbabilityProvider 接口；App 不读取统计数据、不提供默认或猜测概率。资料调查只留 node-statistics-research.json。
- 已新增真实输入的 DEBUG 导入 UI 回归，完整调用识别，不以模拟结果替代。参考图仅 Debug 资源，实际 Release 已核实排除，已撤回的统计 JSON 和调试导入参数也不在包内。

最新补充：地图比例按用户新参考图的 1490×894 画布、220px 网格、原点(236,186)统一缩放；比例测试先红后绿，最终真机截图见 ui-previews/redesign-2026-10-14。概率保持纯接口；图像识别新增未来数据库 provider 默认 nil，匹配结果仍强制未确认，校验楼层与取消，无匹配沿用当前路径。

最终宿主 38 核心 + 33 Support/真实回放 = 71 项通过。iPhone/iPad 真机与两类模拟器分别 35 项通过、2 项明确跳过（仅宿主六图回放，Mac 已执行通过）；其中 4 项 UI 包含真实参考图导入、AP 真实提交为1、库存剩余2、字号与旋转。后续仅调整道路波形和空位纹理，再执行 iPhone 真机识别/地图视觉回归通过；iPad 最终全套已包含该调整。

最终 Release 严格签名、测试资源排除、两台设备安装/启动与运行进程验证均通过，见 release-v02.json。iPad 网络安装首试遇旧设备句柄连接错误，改用当前 CoreDevice 标识重建连接后安装和运行成功；原失败日志保留。
