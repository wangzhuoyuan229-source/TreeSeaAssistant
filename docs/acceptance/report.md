# 首版实施与验收记录

实施开始：2026-10-13；最终核验：2026-10-14（Asia/Shanghai）。**总体状态：源码与宿主验证已交付，首版整体验收未完成。** 不将未运行的 iOS/真机项目标记为通过。

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

## 尚未通过的必需验收

| 项目 | 当前事实 / 恢复执行所需条件 |
|---|---|
| iOS App 真正编译 | 本机只有 CommandLineTools，未找到完整 Xcode、iOS SDK 或 simctl。xcodebuild 未能开始编译 App；不能宣称 BUILD SUCCEEDED |
| iPhone/iPad UI 自动化 | 测试源码和 scheme 已建立，尚未运行。需要完整 Xcode 和真实可用的两类模拟器 UUID；scripts/verify-ios.sh 会先列出真实 destinations |
| 每层实战识别与模板核对 | 未取得完成授权/标注核对的每层实战验收集；43 个模板全部 researchReference。实际 ROI/轮廓/OCR、稀疏网格、道路裁剪方向与插值、库存 OCR 尚未实战通过 |
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

宿主测试为算法与适配器验证，产品目标仍仅 iPhone/iPad。安装完整 Xcode 并选择有效 developer directory 后，先执行 iOS build，再按真实 destinations 设置 TREESEA_SIMULATOR_ID / TREESEA_IPAD_SIMULATOR_ID 执行测试。随后补实战与真机矩阵，才可把总体状态改为全部完成。
