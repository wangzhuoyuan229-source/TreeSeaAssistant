# MAA 对照与 iOS 适配

固定提交：59bd4cecf6420f963add79ee005f969a7f5d6131。候选补充来源 hlsh-helper b81965ba78918d8d6effb0e5006dc3c9b2e617c9。所有下述状态以本轮实际验证为准。

| 功能 | Swift 适配 | 已有验证与差异 |
|---|---|---|
| Model/Observation | FloorMap、MapNode、MapEdge、独立修订号 | 原始身份、完成后空地、出生点与当前位置分开；节点按 row×columns+column，位掩码按最多 64 个实际节点的数组索引 |
| map_templates | 43 个固定源码模板、每条边和出口坐标转录 | JSON 校验与层覆盖通过；全部 researchReference，未声称 43 张实战自动识别通过 |
| MovementSpec/CompactStateSpace | 十二项目录、确定性射程、目标资格、启动门槛、逐实例 charges | 精确摘取 source geometry_matches/action_points_after 并编译，125+144 个输出对照；源几何允许当前格，实际 App 动作排除当前格。只确认次数及效果才使用，目录次数不会填入库存 |
| SafetyValue | 确定性前向可达、资源支配、语义 memo、循环处理 | 固定源 SafetyValueSolver 在合成回调图上编译执行，24 个 AP 输入的可达结果与 Swift 对齐；不复制随机 AND-OR oracle；增益状态枚举后处理，临时访问不作为无解。正徒步成本且无增益/物品时给可证明最小 AP，其他情况返回可达结论而不伪造 minimumRequiredAP |
| Planner | best-first 标签、非负收益上界、语义支配、偏好轮转 | 必经 mask、三种偏好及最多三条路线是 App 扩展。安全阶段 ≤60ms，后续仍寻找可行解；整个调用共享 300ms/20,000 展开/40,000 保留标签。池上限 32、每个语义/多样性前缀保留 3；非证明截断明确 heuristicLimited |
| Policy/strategy | 原策略保留 profile/module/floor_window/rank 等来源字段 | 不把 MAA 原策略当 App 统一权重；App 为 balanced-items-v0.4，整数四分之一单位；候选数与顺序不影响未知诡秘探索分 |
| FrameNormalizer | Image I/O 元数据预查、EXIF 缩略图方向、裁剪、1280 工作图与逆变换 | 宿主真实 Image I/O 测试通过；<=20MiB / <=1600万像素，完整解码前预查；保持地图裁剪比例。当前不自动去除游戏完整画布留边，也不启用 MAA 固定像素 ROI |
| GridReconstructor/NodeDetector | 等间距拟合、Vision 中文行 OCR、轮廓中心融合 | 拟合/兼容性合成测试通过，实际截图未验收。当前检测器尚未实现 MAA 原版逐图标模板匹配，稀疏/局部地图走人工模板或手动地图；不能因文字缺失判空地 |
| EdgeDetector | ONNX 等价 Core ML Float32、3×40×160、RGB scale/mean/std、raw logit 阈值 | 源/转换哈希、工具版本与输出对照见 model-conversion.json；Swift Core ML 宿主真实运行通过。另验证阈值上下约 0.02 的源/Core ML 两侧判断；Core Graphics high 插值不宣称与 OpenCV bicubic 像素级一致；实际走廊裁剪/方向仍待实战回放。输出只作道路提案，未人工核对不升级可执行边 |
| TemplateMatcher | 非 absent 观测边子集、唯一模板、仅已识别坐标补出口 | Support 测试通过；不凭自动模板新增未识别移动目标。人工模板建立完整网格是用户显式选择的保底流程 |
| MovementRecognition/InventoryModel | Vision OCR 名称、剩余次数/歧义、部分覆盖、digest 去重、实例匹配与成本提案 | 文本测试通过；不把持有件数、目录初始次数、当前装载方式混用。真实背包/详情/移动预览识别未验收 |
| 自动执行 | 首版排除 | 无自动点击、招募、购买、培育、战斗、录屏或联网识别 |

hlsh-helper 的局部与全图函数在固定源码上直接执行，生成 240+5 个候选对照输入；Swift Dinic 再与独立 1–6 节点赋值枚举 oracle 对照。正常完整并授权核对的规则保持源顺序；不输出类型概率。

基础单边徒步、可达和评分均为已声明模型；未知内容完成后可继续移动是显式假设，战斗/随机事件副作用不在 AP 可执行保证内。未来需要实际截图逐层核对，并补足 MAA 感知链的模板图标、完整画布和道路像素回放；现有源码不能代替这些验收。
