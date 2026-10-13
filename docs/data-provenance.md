# 数据与资源来源

日期 2026-10-13，Asia/Shanghai。本轮为本地开发，不配置远端或发布。

- MAA 固定提交 `59bd4cecf6420f963add79ee005f969a7f5d6131`：取得 Model、CompactStateSpace、StateSpace、SafetyValue、Planner、43 张 map_templates、edge 配置、corridor runtime、ONNX、strategy、perception manifest。哈希见 [upstream-hashes.json](acceptance/upstream-hashes.json)，移植区别见 [maa-porting-notes.md](maa-porting-notes.md)。AGPL-3.0 文本见 Legal；游戏图片/模型许可独立记录，不自动视为代码许可证覆盖。
- hlsh-helper 固定提交 `b81965ba78918d8d6effb0e5006dc3c9b2e617c9`：11 类×5 层距离/数量规则、分类顺序、局部筛选与下界流。运行时全部 researchReference；用户明确勾选已核对后，以 authorizedReviewed 状态使用。源码参照一致不代表游戏官方生成规则已核实。未找到明确 LICENSE，后续分发许可尚待确认。
- 43 个 MAA 模板是研究构造清单，不是 43 个已验收自动识别模板。每层实战回放目前未执行；无独立验证的模板不标 independentlyVerified。
- 原版 UI 图集：图标/manifest.json 原下载字节及 76 个映射；71 个有 sprite 矩形的对象按原偏移导出，另外 5 个是区域背景。导出没有重绘、换色或拉伸。UI 集成校验值见 [integrated-assets.json](acceptance/integrated-assets.json)。展示素材不作为 MAA 识别模板。
- 自建美术：使用已有 iPhone 动物 v2、iPad 动物植物 v3、植物底图、徽记；按显示需求下采样。AppIcon 使用首次三瓣母版，不透明 1024。历史原图和所有失败预览保留。
- 道路模型：保持固定 ONNX 权重，等价转为 Float32 Core ML，无训练。导出参数、配置/文件哈希、六个合成输入的对照与工具版本见 [model-conversion.json](acceptance/model-conversion.json)。阈值上下约 0.02 的两侧判断相同；最大观察误差 <1e-4。真实截图裁剪和像素插值尚待回放。
- 测试地图、图片和库存文本为独立合成，不伪装游戏实战图。候选 fixture 通过执行固定源函数得到；移动 fixture 通过编译固定源函数得到；完整规划最佳分用独立穷举 oracle 比较。

复现脚本位于 scripts/。源仓库研究文件、Python 转换环境和原始运行日志在 git 忽略的 .build-evidence；验收摘要、哈希、导出模型和合成回归 fixture 随项目保留。文件已取得、源码对照通过、资源已集成与游戏/设备已验收是四种不同状态。
