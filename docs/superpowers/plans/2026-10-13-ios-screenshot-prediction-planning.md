# iOS 截图预测与路线规划 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** 交付以 MAA 为主要功能和算法来源、采用已有 V2 美术风格并适配 iPhone/iPad 的离线截图辅助 App，补用 hlsh-helper 候选集合及其他项目交互，支持加工品增益、必经节点和多路线推荐。

**Architecture:** SwiftUI App 管导入、预览、纠错和会话；TreeSeaCore 优先移植 MAA 的状态、确定性动作、安全检查和有限预算规划核心，补接 hlsh-helper 候选与配额。视觉层将 MAA 的地图感知流水线适配到 Apple 图像/OCR/Core ML 框架；路标和羽瞰点补充交互。不可变快照与版本检查贯穿全部计算，必经、多路线和评分差异作为明确的 App 适配。

**Tech Stack:** Swift 6 语言模式、Swift 6.2+ 编译器、iOS/iPadOS 17.0+、SwiftUI、Observation、Vision、Core Image、Core ML、Accelerate、PhotosUI、Swift Testing；UI 自动化采用 XCTest。

**Spec:** 业务依据为 [需求与算法规格](../../ios-app-spec.md)；前端视觉依据为 [四张截图参考版 UI 规划 V2](../../ui-design-reference-v2.md)，交互、状态与无障碍依据为 [UI 设计规范](../../ui-design-spec.md)。执行者必须先读三份文档；规则表与权重以业务规格第 6、7 节为准。V2 优先于旧规范的色彩、展示标题、面板外形和装饰；静态预览状态以 [V2 索引](../../ui-previews/reference-v2/README.md) 和 [旧版索引](../../ui-previews/README.md) 的真实记录为准。

## Global Constraints

- 首版支持 iOS 17.0、iPadOS 17.0 及更新版本，中文客户端，第一至第五层。产品不包含 macOS 客户端。
- 本轮不开发：节点概率估算及百分比显示、实时录屏、后台识别、PiP 小窗、分享扩展、云端识别、账号同步、自动操作游戏、训练模型、随机落点加工品、多层联合最优规划、第六层和树洞自动识别。
- 独立 Swift Package：TreeSeaCore，只依赖 Foundation，不直接依赖 UIKit、Vision、OpenCV 或其他参考项目。
- MAA 固定提交为主要源码与资源参照；移植对应机制并建立对照数据，不搬入自动点击、招募、购物、培育和战斗执行模块。模型转换不代表新增训练需求。
- 候选模块只移植 hlsh-helper 固定提交的 unknown_mystery 分类、距离/上限筛选与全图配额机制；结果保持源顺序，不含概率、出现权重或似然排名。
- 核心最多接受 64 个节点；首次支持最多 8 个无序必经节点，按实际经过/落点判断，不要求未知节点类型已揭示。
- 候选预算：100 ms 和 1000 次可行性检查，覆盖输入检查、BFS、局部筛选与全图传播。
- 首版规划预算：整个 plan 调用 300 ms、最多 20,000 次状态展开、最多 40,000 个保留标签。
- 所有性能数字是设计目标；只有设备测试后才可记录为达到。
- 收益权重 balanced-items-v0.4 使用已确认类型收益、未知诡秘固定探索分 4 和普通未知凶戾保守代价 8；不计算期望收益、信息熵或混合风险。
- 最多三条实际不同的推荐：综合收益、节省加工品、较低战斗风险；三种偏好共享同一规划预算，不降低必经条件、不用重复路线凑数。
- 默认动作启动门槛 minimumAPToStart=1；零 AP 消耗不能自动推导为可在 AP=0 时启动。
- 仅暗色，采用 V2 的异色自然史拼贴风格；功能文字为实时系统文本，支持 Dynamic Type，点击区至少 44×44 pt，主要操作默认高 52 pt。
- 游戏专有节点、道具、加工品、区域、路径及标记使用路标对应原版素材，不自创、不重绘、不换色；自建动物版画仅作背景装饰，通用 SVG / SF Symbols 不替代游戏图标。根目录「图标」与「自建素材」分别保存来源与实际文件。
- 按可用内容宽和 Size Class 适配；Compact 或可用内容宽不足 680 pt 为单栏，Regular 达到 680 pt 为双栏，达到 960 pt 为三栏；辅助功能字号降为单栏。旋转、窗口缩放和栏位变化保留选择与未提交输入。
- 正文对比度至少 4.5:1，必要控件边界/大文本至少 3:1；支持 VoiceOver、Reduce Motion、Reduce Transparency，并以文字/图标补充颜色语义。
- 用户要求项目执行出现实际问题时立即汇报并暂停，只允许必要停止、清理与保存证据，等待明确继续。不得把未执行项目写成通过。

## Review Focus

- 已完成节点变空后原始类型仍须消耗生成配额：任务 4 固定测试。
- 裁剪不完整、出生点不确定或资料冲突时，候选约束降级须解释；未知凶戾不扩展自编候选预测：任务 3、4、7 固定测试。
- 零行动力到出口、启动门槛、加工品增益与逐实例次数的边界不能产生负资源或无限收益：任务 5、6 固定测试。
- 预算耗尽未找到路线不等于无解；推断道路和未知成本不能显示为确认安全：任务 6 固定测试。
- MAA 的源码参数、逻辑坐标和策略适用条件须保留来源；安全检查不能脱离总预算，模型导出不得跳过输出对照：任务 2、5、6、7 固定测试。
- 导入取消、解码失败与异步旧结果不得覆盖用户新修改：任务 7、9 固定测试。
- 候选顺序不表示出现倾向；单候选不能充当商店身份、可支付 AP 或硬目标确认：任务 3、5、6 固定测试。
- 背包未显示次数、同名多件与重叠截图不得虚增库存；多路线均须覆盖必经节点，飞行掠过不算：任务 7A、6 固定测试。
- iPhone 横屏、iPad 窄窗口、键盘与最大辅助字号不得遮挡确认/取消或丢失编辑；视图重排不能触发旧结果提交：任务 1A、8、9、10 固定测试。
- 同一节点在缩放地图、节点列表和 VoiceOver 中的身份/必经状态一致；装饰线不能被误认为道路：任务 8、9、10 固定测试。

---

## 0 执行条件与当前状态

截至 2026-10-13，项目包含功能规格、开发计划、UI 文档、历史预览和两类素材：11 张路标原始 PNG/76 个映射，8 张自建 PNG/6 个通用 SVG。素材已保存，不表示 App 集成完成。保留 MAA 主来源、不计算节点概率及 iPhone/iPad 适配；尚未创建 Xcode 工程、实现代码、安装依赖或运行产品测试。

MAA 的地图、资源、移动、安全和搜索核心按固定提交逐项移植并对照；候选算法补用 hlsh-helper，不搬入其桌面/Android UI 或添加自编概率模型。现有 App 权重、必经硬约束、三偏好推荐和截图人工确认是适配差异，不能当作 MAA 原生配置。优先整理现有公开资料与合成回放，不能声称已经支持全部 43 个构造。

执行方式尚未由用户选择。本轮不开始实现。用户后续授权执行时，使用上方对应执行技能，并先核实本地 Xcode、Swift 与 iOS SDK。遇到缺失工具链按全局约束报告暂停，不自行下载安装或改用未约定技术栈。

版本控制：本轮不初始化 Git 或提交文档。实现阶段如已存在 Git 仓库，只提交本任务批准路径；尚无仓库时在得到实现授权后建立本地 Git，禁止配置远端或发布。每个任务完成后做一个包含相关测试的提交。

命令均在项目根目录执行。Swift Package 核心测试可运行在开发宿主，这不代表开发 macOS 客户端。App 构建、界面与性能验收必须使用 iOS 模拟器或真机。

首次 UI 测试前通过 xcodebuild -showdestinations 选择真实可用的 iPhone 模拟器 UUID，保存到任务变量 TREESEA_SIMULATOR_ID；iPad 另选 UUID 保存为 TREESEA_IPAD_SIMULATOR_ID。下面命令中的变量不得留空，不以不存在的设备名替代。

## 0.1 前端设计要求与设备适配

### 视觉与组件基线

沿用 V2「异色自然史拼贴」：深青自然场景、黑色不规则墨迹面板、骨兽/解剖版画母题、紫蓝笔触、赭金几何线和多色光核。场景与拼贴只放在边缘、封面及留白；地图、表单和正文用稳定深色承托。会话与路线采用青绿边缘的宽胶囊，加工品采用选中物件＋逐实例列表。功能文案与数值必须是真实文本，不将整张效果图当运行界面。

ThemeTokens 采用 V2 已有参数，不另起配色：

素材基线见 [原版图标](../../../图标/README.md) 与 [自建素材](../../../自建素材/README.md)。iPhone 封面选动物骨骼版画 v2；iPad 封面选动物与植物合并 v3，保留第二版上部动物、结合第一版下部植物装饰；App 图标按用户要求选首次三瓣徽记 v1。数据页使用安静植物底图与近实色面板。动物与装饰弧线不能进入真实地图关系或点击/辅助功能节点；专有对象图标取原版图集，保留颜色、比例和对齐。未知节点用原版未知图标，素材缺失保留文字说明而非自创替代。

| Token | 色值 | 用途 |
|---|---|---|
| background | #060A08 | 深黑底 |
| inkSurface | #0B1210 | 文本与数据承托 |
| forest | #173B31 | 场景 |
| capsuleRim | #79BCAF | 胶囊边缘与选择 |
| ultramarine | #3348D6 | 插图笔触 |
| violet | #7146B5 | 异色光核 |
| ochre | #B99551 | 装饰图谱 |
| burgundy | #6B2938 | 封面局部异色 |
| textPrimary | #E8E5D9 | 标题与正文 |
| textSecondary | #B7BBAF | 次要文字 |
| warning | #E5C177 | 待确认提示 |
| error | #EF9D9D | 错误文字 |

- 展示标题采用宋体/系统衬线气质，默认 28–34 pt；操作及正文为系统无衬线。正文 17、次要 15、辅助 13 pt，数值等宽，全部支持动态字号；地图中放不下的内容进入详情/节点列表，不缩小正文硬塞。
- 间距 4/8/12/16/20/24/32/48 pt；iPhone 页面左右默认 20 pt，窄窗口 16 pt，iPad 24–32 pt；阅读正文最大宽 720 pt。列表最小高 60 pt，主要胶囊高至少 52 pt，点击区至少 44×44 pt，随字号增长。
- 墨迹外缘与规则内边距分开，命中区和焦点框保持规则。骨兽、光核和装饰线不遮挡数据，不作为道路或可点击节点；借用素材与原参考图的来源记录沿用现有文档。
- 返回、Sheet、输入、菜单、键盘避让用原生交互；内容承托近实色，不叠加多层透明面板。按钮、状态标签、表单错误和加载/取消状态跨页面共用，具体变体见 UI 规范第 4 节。
- 既有反馈值：按下缩放 0.98/100 ms，释放约 180 ms；选中光域 180 ms，面板 240 ms，封面首次 420 ms 后静止，状态替换约 160 ms。操作不等待动画，动画可打断；Reduce Motion 改静态/短淡入淡出，Reduce Transparency 改实色。

### iPhone 与 iPad 布局规则

可用内容宽定义为当前视图容器宽扣除左右安全区及页面内边距，不使用设备型号或启动时屏幕宽；布局由同一 AdaptiveLayout 判定。辅助功能字号优先单栏滚动。分栏宽不足时折叠，不裁掉详情或强制保持横屏。

| 空间条件 | 页面组织 | 必须保留 |
|---|---|---|
| Compact、可用宽 <680 pt，或辅助功能字号 | 单栏；主入口地图/会话/设置，详情用原生导航或 Sheet | iPhone 横竖屏、iPad 窄窗口都能导入、纠错和查看完整步骤；确认/取消避开键盘与底部安全区 |
| Regular 且可用宽 680–959 pt | 双栏，列表基准 280 pt，详情至少 360 pt | 地图与检查区或原图与提案并排；当前选择、未提交表单和地图视口不因重排丢失 |
| Regular 且可用宽 >=960 pt | 三栏，导航侧栏基准 240 pt，列表/地图与检查区各保留所需空间 | iPad 地图工作台同时展示导航、地图与节点/路线详情；输入、指针及键盘焦点明确 |

AppNavigationState 保存主入口、所选节点/路线与导航位置；MapViewport 保存缩放/平移。旋转、分屏及窗口缩放只重排视图，不修改地图、资源或必经条件，不重新导入截图。滚动和编辑草稿保留。地图缩放、平移、重置均有操作入口，另提供可访问节点列表；触摸地图的坐标换算随当前视口更新。

### 页面覆盖与业务语义

必须实现会话首页、导入裁剪、地图确认/编辑、加工品确认、候选详情、规划条件、路线比较、步骤详情；iPad 的地图和导入工作台复用同一会话与业务组件。地图/会话/设置导航不新增账号、剧情、收藏图鉴、实时或小窗入口。首版本地会话能力按已实现存储显示，不把参考图的六个存档槽写成固定 UI。

候选标题为「可能类型」，单候选为「按当前规则唯一」，身份仍未揭示；无百分比。路线显示「推荐路线」及 App 适配分、必经覆盖、AP 与加工品台账；徒步实线和飞行箭头有图例。待确认、计算中、已过期、无可行路线、暂未求得和只找到 N 条各有真实状态文案，取消保留最近有效结果。用文字、图标和线型区分状态，不能只用颜色。

按当前索引使用实际已有预览核对构图，未生成、未审阅或未通过的页面不记为验收通过；新版视觉覆盖旧版装饰，旧图和失败证据保留。静态图只指导视觉，不替代原生交互、动态字号和真机验收。本轮只将已有要求加入计划，不继续生成或修改预览图片。

## 1 文件与依赖结构

    README.md
    docs/ios-app-spec.md
    docs/ui-design-spec.md
    docs/ui-design-reference-v2.md
    docs/superpowers/plans/2026-10-13-ios-screenshot-prediction-planning.md
    docs/data-provenance.md
    docs/maa-porting-notes.md
    docs/acceptance/ios-v0.1.md
    TreeSeaAssistant.xcodeproj/
    App/TreeSeaAssistant/
      TreeSeaAssistantApp.swift
      Design/ThemeTokens.swift
      Components/ActionCapsule.swift
      Components/StatusLabel.swift
      Navigation/AdaptiveLayout.swift
      Navigation/AppNavigationState.swift
      Navigation/AppShellView.swift
      Session/SessionStore.swift
      Session/SessionRepository.swift
      Session/ComputationWorker.swift
      Session/SessionHomeView.swift
      Session/SessionListView.swift
      Import/ScreenshotImportView.swift
      Import/ImagePreprocessor.swift
      Inventory/InventoryImportView.swift
      Inventory/InventoryRecognizer.swift
      Inventory/InventoryReviewView.swift
      Recognition/ScreenshotRecognizer.swift
      Recognition/NodeCenterDetector.swift
      Recognition/GridFitter.swift
      Recognition/TemplateMatcher.swift
      Recognition/CorridorClassifier.swift
      Recognition/Models/BlackFlowCorridor.mlpackage
      Recognition/Models/corridor-runtime.json
      Recognition/RecognitionReviewView.swift
      Map/MapEditorView.swift
      Map/MapCanvasView.swift
      Prediction/CandidateDetailView.swift
      Planning/PlanRequestView.swift
      Planning/RouteDetailView.swift
    Packages/TreeSeaCore/
      Package.swift
      Sources/TreeSeaCore/
        Map/MapModels.swift
        Map/MapValidator.swift
        Map/MapGraph.swift
        Data/CatalogModels.swift
        Data/CatalogLoader.swift
        Data/Resources/catalog.json
        Data/Resources/movement-catalog.json
        Prediction/PredictionModels.swift
        Prediction/PredictionEngine.swift
        Prediction/QuotaFlow.swift
        Planning/PlanModels.swift
        Planning/MovementModels.swift
        Planning/MovementModel.swift
        Planning/SafetySolver.swift
        Planning/RouteScorer.swift
        Planning/RoutePlanner.swift
        Planning/RouteSelector.swift
      Tests/TreeSeaCoreTests/
        Fixtures/
        MapModelTests.swift
        CatalogTests.swift
        MapGraphTests.swift
        LocalPredictionTests.swift
        QuotaFlowTests.swift
        PredictionIntegrationTests.swift
        MovementTests.swift
        SafetySolverTests.swift
        RouteScorerTests.swift
        RoutePlannerTests.swift
        RouteSelectorTests.swift
    Tests/TreeSeaAssistantTests/
      AdaptiveLayoutTests.swift
      ThemeContrastTests.swift
      ImagePreprocessorTests.swift
      GridFitterTests.swift
      CorridorClassifierTests.swift
      RecognitionImportTests.swift
      InventoryRecognitionTests.swift
      SessionStoreTests.swift
      Fixtures/
    Tests/TreeSeaAssistantUITests/
      ScreenshotWorkflowTests.swift
      AdaptiveShellTests.swift
      AccessibilityWorkflowTests.swift

每个文件只负责一个实际职责；不要因表中目录而创建空架构、通用服务容器或额外协议。上述是预计最终文件清单，并非本轮已创建文件。

## 2 接口约定

所有下列数据类型在对应任务创建，public 跨模块值类型显式 Sendable。NodeID 是 Int 别名。

| 类型或签名 | 定义位置与职责 |
|---|---|
| FloorMap、MapNode、MapEdge、NodeKind、Evidence、BattleScope、RunResources、ItemInstance、RevisionStamp | 任务 1，基础值类型；BattleScope 为 unconfirmed/ordinaryConfirmed，默认 unconfirmed；ItemInstance 先定义 instanceID、typeID、remainingCharges 与证据，后续目录扩展不阻碍任务 1 编译 |
| MapValidator.validate(_ map: FloorMap) throws | 任务 1，验证 ID、坐标、边、节点数 |
| ThemeTokens、LayoutMode、AdaptiveLayout.resolve(availableContentWidth: CGFloat, isCompact: Bool, isAccessibilityTextSize: Bool) -> LayoutMode | 任务 1A，App 层视觉参数与单/双/三栏判定；可用宽扣除安全区和页面左右内边距，阈值 680/960 pt |
| AppSection、AppNavigationState、AppShellView | 任务 1A，主入口地图/会话/设置、所选节点/路线和页面导航；仅属于 App UI，不进入 TreeSeaCore |
| MapViewport、MapCanvasView | 任务 8，缩放/平移与逻辑节点坐标到视图坐标的映射；viewport 与选择由会话 UI 持有，重排不重置；有节点列表替代入口 |
| RuleCatalog、TemplateCatalog、CatalogBundle、ValidationStatus | 任务 2，版本化规则和拓扑 |
| CatalogLoader.decode(_ data: Data) throws -> CatalogBundle | 任务 2，JSON 加载与数据校验 |
| MovementCatalog、MovementSpec、MovementRange、ItemEffects | 任务 2，加工品目录、启动门槛和效果；使用任务 1 的 ItemInstance，剩余次数不来自目录初始次数 |
| CatalogLoader.decodeMovements(_ data: Data) throws -> MovementCatalog | 任务 2，独立目录与来源状态校验 |
| MapGraph.distances(from: NodeID, in: FloorMap) -> [NodeID: Int] | 任务 3，普通无向 BFS |
| PredictionResult、CandidateReason、PropagationStatus | 任务 3，结果和警告；PredictionResult 带 predictionID、mapRevision、ruleVersion；候选为按源顺序排列的 [NodeKind] |
| PredictionEngine.localCandidates(map: FloorMap, rules: RuleCatalog) -> PredictionResult | 任务 3，独立筛选 |
| PredictionEngine.predict(map: FloorMap, rules: RuleCatalog, budget: PredictionBudget, shouldCancel: () -> Bool, nowNanoseconds: () -> UInt64) -> PredictionResult | 任务 4，局部加配额传播，时钟可注入 |
| QuotaFlow.isFeasible(domains: [NodeID: Set<NodeKind>], quotas: [NodeKind: CountRule], knownCounts: [NodeKind: Int], control: SearchControl) -> FeasibilityResult | 任务 4，possible、impossible、interrupted |
| SearchControl | 任务 4，内部 final class，单次同步运算内共享截止时间和计数；注入 nowNanoseconds 与 shouldCancel，不跨任务共享 |
| PredictionBudget(milliseconds: Int, maxChecks: Int) | 任务 4，默认 100、1000 |
| PlanningSnapshot、PlannerState、MoveAction、PlanStep、ScoreProfile、ScoreDelta、PlanRequest、RouteRecommendation、RouteSetResult、RoutePreference、PlanningBudget | 任务 5，包含 PredictionResult、库存、mustPassNodeIDs、goalRevision；每条路线资源与覆盖明细，Int 四分之一分单位 |
| MovementModel.actions(from: PlannerState, in: PlanningSnapshot, control: SearchControl) -> [MoveAction] | 任务 5，确定性动作生成 |
| MovementModel.apply(_ action: MoveAction, to: PlannerState, in: PlanningSnapshot) throws -> PlannerState | 任务 5，成本、增益与资源转移 |
| SafetyResult、SafetySolver.check(state: PlannerState, snapshot: PlanningSnapshot, control: SearchControl) -> SafetyResult | 任务 6，MAA 确定性安全子集，reachable/unreachable/unresolved 与可证明的 minimumRequiredAP；必经位进入终局和状态键 |
| RouteScorer.delta(for: MoveAction, before: PlannerState, after: PlannerState, in: PlanningSnapshot, profile: ScoreProfile) -> ScoreDelta | 任务 5，固定整数权重、确认收益与保守战斗代价明细 |
| RoutePlanner.plan(_ request: PlanRequest, shouldCancel: () -> Bool, nowNanoseconds: () -> UInt64) -> RouteSetResult | 任务 6，共享预算，0–3 条不同推荐，默认 maximumRecommendations=3 |
| RouteSelector.select(_ candidates: [RouteRecommendation], maximum: Int) -> [RouteRecommendation] | 任务 6，规范化签名、偏好选择与去重，不以同名实例 UUID 制造差异 |
| ImagePreprocessor.prepare(_ data: Data, crop: CGRect?) throws -> PreparedScreenshot | 任务 7，方向、裁剪、缩放与坐标变换 |
| NodeCenterDetector.detect(in: PreparedScreenshot, texts: [TextObservation]) -> [DetectedCenter] | 任务 7，候选节点中心，合并视觉与文本证据 |
| GridFitter.fit(centers: [DetectedCenter], rows: Int, columns: Int) -> GridFit? | 任务 7，等间距轴、变换、残差与占用格 |
| TemplateMatcher.match(occupied: Set<NodeID>, grid: GridFit, catalog: TemplateCatalog, floor: Int) -> TemplateMatchResult | 任务 7，候选分差、覆盖校验与拒识 |
| TemplateMatcher.compatible(observedEdges: [MapEdge], recognizedNodeIDs: Set<NodeID>, catalog: TemplateCatalog, floor: Int) -> TemplateMatchResult | 任务 7，对照 MAA 非 absent 边子集匹配，只为已有坐标节点提出出口身份补充 |
| CorridorTensor、EdgeScore、CorridorClassifier.classify(_ crops: [CorridorTensor]) throws -> [EdgeScore] | 任务 7，Core ML 道路模型适配；RGB Float32 3×40×160，输出 raw logit 与边判断，不进入未知类型候选 |
| ScreenshotRecognizer.recognize(_ screenshot: PreparedScreenshot, floor: Int, catalog: TemplateCatalog) async throws -> RecognitionProposal | 任务 7，提案，不直接改会话 |
| InventoryProposal、MovementPreviewProposal、InventoryObservationCoverage | 任务 7A，识别提案、目标/方式成本提案和覆盖范围 |
| InventoryRecognizer.recognize(_ screenshot: PreparedScreenshot, catalog: MovementCatalog) async throws -> InventoryProposal | 任务 7A，背包/详情 OCR 与目录匹配、剩余次数歧义 |
| InventoryRecognizer.recognizeMovePreview(_ screenshot: PreparedScreenshot, target: NodeID, itemInstanceID: UUID?) async throws -> MovementPreviewProposal | 任务 7A，目标和方式由用户指定，AP 消耗保留待确认状态 |
| SessionStore.apply(_ edit: SessionEdit) throws | 任务 8，会话同步修改与修订号 |
| SessionStore.commit(_ proposal: RecognitionProposal, expected: RevisionStamp) throws | 任务 8，预览确认后的提交 |
| SessionStore.acceptPrediction(_ result: PredictionResult)、acceptPlan(_ result: RouteSetResult) | 任务 9，只接受当前依赖版本、必经与库存条件 |
| SessionStore.commitInventory(_ proposal: InventoryProposal, expected: RevisionStamp) throws | 任务 8，确认后合并/替换库存与去重 |
| SessionRepository.save(_ session: MapSession) throws、load() throws -> MapSession? | 任务 9，本地原子持久化 |

SearchControl 的时钟用 ContinuousClock 或单调计时实现；测试注入确定性时钟，不能用 Date 或睡眠测试预算。内部不储存非 Sendable UI 对象。核心函数是同步纯计算，任务 9 在后台入口调用，不将 UIKit 图片跨线程随意共享。

## Task 1 建立核心模型与可手动查看的 App

**Files:** 创建工程、TreeSeaAssistantApp.swift、MapModels.swift、MapValidator.swift、Package.swift、MapModelTests.swift。

**Interfaces:** 产出 FloorMap、RunResources、RevisionStamp、MapValidator；App 初始显示一张自建 3×3 合成地图，不捆绑未授权游戏资源。

- [ ] 写 MapModelTests：图 JSON 往返相等；重复 ID、越界边端点与 65 节点被拒绝；完成节点仍保留 originalKind；改变 currentNodeID 不改变 initialStartID；未知凶戾默认 battleScope=unconfirmed，OCR 不自动升级。对照 MAA Model/Observation 的节点身份、进度与边状态，差异记录为 iOS 适配。
- [ ] 运行 swift test --package-path Packages/TreeSeaCore --filter MapModelTests，先确认新行为失败，而非编译环境缺失。
- [ ] 实现值类型与验证器；建立仅 iPhone/iPad 的 Xcode target、iOS 17 deployment target、local package 依赖、App 单元测试与 UI 测试 targets 及共享 scheme TreeSeaAssistant，将测试 targets 加入 scheme 的 Test action。
- [ ] 重跑核心测试；运行 xcodebuild -project TreeSeaAssistant.xcodeproj -scheme TreeSeaAssistant -destination 'generic/platform=iOS Simulator' build，预期 BUILD SUCCEEDED。
- [ ] 提交本任务文件。验证：模拟器可查看合成地图，不出现实时、小窗、联网入口。

## Task 1A 主题组件与 iPhone/iPad 自适应外壳

**Files:** Design/ThemeTokens.swift、Components/ActionCapsule.swift、Components/StatusLabel.swift、Navigation/AdaptiveLayout.swift、Navigation/AppNavigationState.swift、Navigation/AppShellView.swift、TreeSeaAssistantApp.swift、AdaptiveLayoutTests.swift、ThemeContrastTests.swift、AdaptiveShellTests.swift。

**Interfaces:** 消费任务 1 的合成地图和基础模型；产出 ThemeTokens、LayoutMode（singleColumn/twoColumns/threeColumns）、AdaptiveLayout.resolve、AppSection（map/sessions/settings）、AppNavigationState 与 AppShellView。导航状态由 MainActor 持有 selectedSection、selectedNodeID、selectedRouteSignature 和 NavigationPath；布局变化不重新创建该状态。业务页面由任务 8、9接入，不建立第二套会话或资源模型。

- [ ] 写 AdaptiveLayoutTests：Regular 的可用内容宽 679→singleColumn、680→twoColumns、959→twoColumns、960→threeColumns；Compact 即使 1100 仍单栏；辅助功能字号即使 1100 仍单栏。测试输入是扣完安全区和页面内边距的内容宽，不能用屏幕型号判定。
- [ ] 写 ThemeContrastTests：V2 textPrimary/textSecondary/warning/error 在 background/inkSurface 承托上满足正文 >=4.5:1，capsuleRim 对承托面的必要边界 >=3:1；装饰色不作为小字默认色。主题仅包含 V2 语义色，原生系统控件保留平台行为。
- [ ] 写 AdaptiveShellTests：主入口可以切换；选中合成节点后旋转仍选中同一 NodeID；测试注入窄 Regular 容器时不缺导航和返回；切换辅助功能字号仍能找到主要操作及取消。测试注入只在测试配置存在，不提供产品调试开关。
- [ ] 运行新增 App 单元/界面测试，确认新布局与导航行为先失败；实现共享主题、胶囊按钮/状态标签和原生导航，按第 0.1 节落实样式、动态文字、安全区和布局选择。
- [ ] 让 App 使用仅暗色主题；展示标题衬线、正文系统无衬线与等宽数字。主题装饰使用本地素材和低干扰边缘，不嵌入整张预览作为功能页面；加载/禁用/按下都有真实状态。
- [ ] 将选定自建背景、首次应用图标与透明装饰导入 App 资源；AppIcon 从 1254×1254 母版导出 1024×1024 不透明版本，保持原设计。原版图集按 manifest 像素矩形与偏移渲染/缓存，建立节点和 M01–M12 的明确映射；展示图标与识别模板分开。通用控件使用 SVG 或 SF Symbols，不能替代游戏图形。按显示尺寸解码，核对 iPhone/iPad 安全区、窄窗口动物裁切与中央可读性；素材来源/校验值记录入 data-provenance，不把文件已下载记为 App 集成完成。
- [ ] 接入系统减少动态效果/透明度设置：去掉缩放位移和长显现，改短淡入淡出或静态；材料变实色。原生导航动画保持系统行为，动作不等动画结束。
- [ ] 分别以 TREESEA_SIMULATOR_ID 与 TREESEA_IPAD_SIMULATOR_ID 运行 xcodebuild test；人工核对单/双/三栏外壳、默认字号与辅助功能字号。预期测试通过；运行结果及静态预览分别记录，不把外壳完成记为所有业务页面完成。
- [ ] 提交本任务文件。后续全部业务页面复用主题与导航；首版整体验收前不得保留未实现功能入口。

## Task 2 规则与模板目录及数据来源

**Files:** CatalogModels.swift、CatalogLoader.swift、MovementModels.swift、Resources/catalog.json、Resources/movement-catalog.json、CatalogTests.swift、Fixtures/catalog-synthetic.json、Fixtures/maa-movements.json、Fixtures/maa-strategy-reference.json、docs/data-provenance.md、docs/maa-porting-notes.md。

**Interfaces:** 消费任务 1 模型；产出 CatalogBundle、RuleCatalog、TemplateCatalog、DistanceRule、CountRule、ValidationStatus 与独立 MovementCatalog。

- [ ] 写 CatalogTests：forbidden 与缺失不同；unrestricted 保留；闭区间端点含内；离散 {0,2} 不允许 1；图模板含 sourceURL、版本和审核状态。
- [ ] 运行 swift test --package-path Packages/TreeSeaCore --filter CatalogTests，预期新增解析和校验断言失败。
- [ ] 实现 decode，严格分开 researchReference、independentlyVerified、authorizedReviewed；生产强规则只允许后两种，不把仓库公开等同授权。
- [ ] 建立 MAA 固定提交文件清单：map_templates.json、edge.json、corridor_net.runtime.json、ONNX 道路模型、节点/加工品模板、Model/Planner/SafetyValue/Policy 和 strategy.json；记录哈希、许可、schema 映射与是否完整取得。模型训练数据不列为首版必需输入。
- [ ] 优先将 MAA 拓扑与视觉配置转录为 iOS 目录，记录源字段与网格坐标；不从零重绘所有已有模板。未知诡秘距离和数量继续用 hlsh-helper 固定表；两个来源的距离语义不能混用。先逐层以至少一份模板完成实战回放，未验证的构造不标识别通过。
- [ ] 从 MAA MovementSpec 移植规格第 5.4 节十二种加工品及来源，建立源输入/输出 fixture；initialCharges 只说明新物品初始次数。M07 保留 randomTarget=true，不进入确定路线；M04/M12 不假定已有图标识别样例。
- [ ] 提取 MAA 策略 fixture 时保留 profile/module、floor_window、rank、kind、count、selector、weight 及前提，不将 ending_development 和其他任务的同名节点权重混在一起；当前 balanced-items-v0.4 标记为 App 适配配置，不称 MAA 默认权重。
- [ ] 写 CatalogTests：M12 参考 AP cost=0/gain=3/initialCharges=1、M11 cost=1/initialCharges=3、M10 ingotGain=4、M09 hopeGain=2、默认 minimumAPToStart=1；相同名称多个实例保留独立剩余次数。
- [ ] 运行 CatalogTests，验证来源字段、网格、起点、出口和边完整性；对所有运行时条目生成 provenance 审核记录。maa-porting-notes 按规格来源表记录每项移植、替换、保留和首版排除的功能。
- [ ] 提交本任务文件。不得在缺少模板时伪造全 43 模板已支持。

## Task 3 BFS 与独立候选预测

**Files:** MapGraph.swift、PredictionModels.swift、PredictionEngine.swift、MapGraphTests.swift、LocalPredictionTests.swift、Fixtures/hlsh-local-candidates.json。

**Interfaces:** 消费 FloorMap、RuleCatalog；产出 distances、localCandidates、PredictionResult、CandidateReason、PropagationStatus。

- [ ] 写 MapGraphTests：S-A-B 距离 S=0、A=1、B=2；当前位置改 B 仍从 S 计算；断开格不返回伪距离；险路尽头没有隐式邻居补边。
- [ ] 写 LocalPredictionTests：II 层秘境行商可靠距离 3 在 [2,6] 内保留，距离 7 排除；已确认数量达到或超过 1 的上限时排除，超过时另报 conflict；规则缺失、拓扑不完整及起点未确认时不强排除；未知凶戾不生成候选并显示待揭示。
- [ ] 运行上述两个测试集合，确认失败后实现 BFS、可信 originalKind 计数和独立过滤。
- [ ] 每条 exclusion 输出可读证据；只剩一个候选标按当前规则唯一，仍不标已揭示；保持源分类顺序，不添加类型概率字段。将固定提交源 filter_candidates 的完整输入与输出录为对照 fixture，验证 Swift 候选集合与顺序一致。
- [ ] 重跑测试，验证更新当前位置不改变候选；提交本任务文件。

## Task 4 带上下界流与全图传播

**Files:** QuotaFlow.swift、PredictionEngine.swift、QuotaFlowTests.swift、PredictionIntegrationTests.swift、Fixtures/quota-small-graphs.json、Fixtures/hlsh-global-candidates.json。

**Interfaces:** 消费任务 3 独立候选；产出 QuotaFlow、SearchControl、PredictionBudget、FeasibilityResult 及完整 predict。

- [ ] 写 QuotaFlowTests：v1={商店}、v2={商店,事件}，各类型总数恰好 1 时，v2 商店不可能；两节点均只有商店但上限 1 时整体 impossible；离散配额 {0,2} 与单节点赋值不相容。
- [ ] 写 PredictionIntegrationTests：人工确认一个商店后另一个候选去掉商店；完成变空仍计原始商店；原始类型未知的完成节点导致 skippedIncompleteCoverage；整体无解回退独立候选带 conflict。
- [ ] 用独立暴力枚举器验证 1–6 节点、2–3 类型的小实例：逐候选是否存在合法赋值应与 flow 一致。只作为测试 oracle，不在生产使用。
- [ ] 运行 swift test --package-path Packages/TreeSeaCore --filter QuotaFlowTests 和 PredictionIntegrationTests，预期先失败。
- [ ] 按固定提交移植 Dinic、下界平衡、循环边、离散配额枚举与逐候选固定；记录源码来源，控制检查覆盖整个 predict 调用和所有可行性子调用。不统计合法赋值的频率。
- [ ] 增加固定提交 propagate_global_capacities 对照 fixture，完整一致输入的候选集合及顺序与源实现相同；整体无解时返回独立列表，局部已为空的列表不被伪造填回。
- [ ] 使用注入时钟让预算在流检查中耗尽，确认返回 interrupted/完整独立候选及 incomplete；局部筛选也未完成时不输出残缺列表，取消不得提交部分强传播。未核对规则不得进入强配额。
- [ ] 重跑测试，提交本任务文件。

## Task 5 移动状态与初始评分

**Files:** PlanModels.swift、MovementModels.swift、MovementModel.swift、RouteScorer.swift、MovementTests.swift、RouteScorerTests.swift。

**Interfaces:** 消费地图、确认库存、MovementCatalog 与 PredictionResult；产出规格第 7 节全部规划值类型、动作、资源转移、balanced-items-v0.4 与整数 ScoreDelta。RouteSetResult 包含 recommendations、feasibility、completeness、revision、predictionID、ruleVersion、scoreProfileVersion、goalRevision、movementCatalogVersion、expandedStates。RouteRecommendation 包含 preferenceBadges、steps、必经覆盖、scoreBreakdown、riskPenalty、资源消耗/剩余/确定增益、assumptions。

- [ ] 写 MovementTests：AP=2、cost=2 可以执行并到达出口 AP=0；cost=3 不可执行；已确认一次性 gain=1 只发放一次；加工品 charge=1 使用后为 0，不能再用；未进入内容节点挡住穿行；inferred 徒步边不生成可执行动作，确认的飞行按落点独立判断。
- [ ] 写启动门槛与增益测试：M12 确认 AP=1/cost=0/gain=3 后 AP=4、次数归零；AP=0 默认拒绝启动。希望/源石锭分别增加已确认效果，没有已知初始总额时只记增量；同动作增益只计算一次。
- [ ] 写几何与资格测试：M01 正交 2 格可落地、斜向拒绝；M02 对角 1 格合法；全图物品可到无道路相连的合法落点；M10 不可落到未确认行商，即使只有行商候选；M07 随机物品不生成确定动作。
- [ ] 写逐实例次数测试：两件标准引擎剩余 1 和 3 总共只允许 4 次，不能填成 3 或 6；层末失效物品不按跨层保留罚分。
- [ ] 写 RouteScorerTests：shopWalkScoreUsesQuarterUnits 的已揭示商店 S-v-E 得 30 单位；unknownMysteryUsesFixedExplorationScore 的未揭示诡秘 S-v-E 得 6 单位；singletonDoesNotGrantTypeReward 的商店单候选仍只加探索 16 单位，不给类型收益、不确认身份或资源；persistentItemCostsSix 的跨层加工品通常扣 24 单位。
- [ ] 写 ordinaryUnknownFerocityUsesConservativeCost：battleScope=ordinaryConfirmed 时扣 32 单位，揭示普通作战后扣 16；未确认战斗范围时拒绝动作。revisitHasNoExplorationReward 验证重访收益 0；candidateCountAndOrderDoNotAffectScore 验证候选增减或排列不改变未揭示诡秘的固定分。

    核心断言：
        #expect(knownShopRouteUnits == 30)
        #expect(unknownMysteryRouteUnits == 6)
        #expect(singletonExplorationUnits == 16)
        #expect(ordinaryUnknownRiskUnits == 32)
        #expect(revisitedRewardUnits == 0)
        #expect(persistentItemPenaltyUnits == 24)

- [ ] 运行 MovementTests、RouteScorerTests，预期先失败。
- [ ] 对照 MAA Model/CompactStateSpace 移植 walk、确定性加工品目标、AP 启动门槛、逐实例扣次数及确认增益；默认成本和用户确认 override 分开。保留 completed/opened/rewardClaimed mask，不能用同一个集合替代。
- [ ] 对相同合法坐标、节点状态、加工品和资源输入，用 Fixtures/maa-movements.json 对照目标集合及每步资源输出；必经 BFS、人工确认门槛和不启用随机动作的差异记录为 App 适配，不声称整个自动化行为完全一致。
- [ ] 实现规格全部基础权重，乘 4 存 Int；只使用已确认类型收益、未知诡秘固定探索分和保守战斗代价。羽瞰额外信息收益必须有可靠范围与未揭示计数，否则按 0，最多加 6 分；不随候选数变化。
- [ ] 实现加工品确定希望增益每点 +1、源石锭每枚 +0.5；AP 增益通过可行性和结束余额参与，不额外加奖。上界只包括已揭示收益、固定探索分及剩余加工品确定资源收益，不发放未来可能获得的新物品。
- [ ] 写 candidateCannotGrantResourceGain：未知节点只剩安全角落等候选仍不给未确认 AP；只有已确认加工品/节点增益可支付后续动作；模拟访问不改真实 rewardClaimed。
- [ ] 写未建模随机加工品、战斗范围未确认的未知凶戾和未知传送拒绝测试；资源说明明确模型假设。
- [ ] 重跑测试，提交本任务文件。

## Task 6 必经约束与多条推荐路线

**Files:** SafetySolver.swift、RoutePlanner.swift、RouteSelector.swift、SafetySolverTests.swift、RoutePlannerTests.swift、RouteSelectorTests.swift、Fixtures/planning-small-maps.json、Fixtures/maa-safety-planning.json。

**Interfaces:** 消费冻结的 PlanningSnapshot（含候选结果、库存、mustPassNodeIDs）、MovementModel、RouteScorer；产出 SafetyResult、SafetySolver、RouteSetResult 和 RouteSelector。安全阶段与三种偏好共享 SearchControl，不在搜索模拟分支中假装揭示未知类型。

- [ ] 写 RoutePlannerTests：S-E 的 cost=2/AP=2 可行，终点 E/AP=0；必须经过 A 时每条候选均包含 A；AP=1 可用确认的 0 消耗物品移动，但 AP=0 不可忽略启动门槛；M12 增益可使原本 AP 不足的后续路线变可行，次数仍消耗。
- [ ] 写综合偏好用例：AP=3，S-E 与 S-v-E 均可行，v 为未揭示诡秘，比较 1.5 分与 -1.25 分，综合偏好选择 S-v-E；AP=1 且直接 cost=1 时只找直接出口。改变候选数量或顺序不改变固定探索分；揭示诡意行商后绕路分改为 7.5。
- [ ] 写必经位置用例：未知节点与已完成空地可被选择；当前点满足自身必经条件；过去完成但不在当前路线的点不自动满足；S-A-E 的徒步真实经过 A 满足，S-E 的飞行箭头跨过 A 不满足。相同终点的路径若必经集合不同不得合并。
- [ ] 写三偏好用例：同一必经 A 下，存在一条徒步绕路、一条使用确认飞行捷径、一条包含高收益但战斗风险更高的路线；综合、节省加工品、较低风险可选择不同方案，逐步回放全部候选的次数/AP/必经/出口条件。
- [ ] 写 RouteSelectorTests：相同路线被三个偏好选中只显示一次并合并 badges；同名等价实例或徒步切分不增加推荐数；不同内容节点或加工品安排可作为备选；只有一条可行时返回一条；禁止无收益绕圈凑数。
- [ ] 写终局测试：出口不得被当中间节点绕过；重复领奖循环不能刷分；缺出口返回 invalidInput；推断道路唯一连通不返回 confirmed 可执行路径。
- [ ] 写预算测试：maxExpansions=0 且未找到完整路线返回 unresolved/budgetLimited；首阶段 60 ms 未找到仍由后续队列继续；前缀/标签非证明裁剪标 heuristicLimited，不能声称无解；无截断且搜索穷尽才允许 noFeasibleRoute；取消返回 cancelled。
- [ ] 写 singletonDoesNotConfirmShopEligibility、staleCandidatesAreRejected 与 unconfirmedAPIsNotSpendable：未知节点可按位置作为必经，但商店单候选不能变成确认行商资格；旧 predictionID/规则版本拒绝；未确认 AP 增益不能使原本不可支付动作变可行。
- [ ] 写 SafetySolverTests：简单出口 minimumRequiredAP=2，AP=1 不可达；确认 gain/飞行改变可达性；必经位不同的状态不能共享错误 memo；循环不能被临时递归状态误判无解；注入时钟在安全检查中截止返回 unresolved 并消耗同一总预算。
- [ ] 以 MAA 确定性子集生成安全和状态转移 fixture，与 Swift 对照；适配必经、多路线和权重后的最终推荐单独验收，不要求它们与 MAA 单次自动决策相同。
- [ ] 分别运行 swift test --package-path Packages/TreeSeaCore --filter SafetySolverTests 与 --filter RoutePlannerTests，预期先失败。
- [ ] 移植 MAA 确定性安全求解的记忆化、资源支配和循环处理，再接贪心完整路径种子、best-first 标签与收益上界剪枝。安全与首条可行阶段共至多 60 ms，后续搜索仍可继续求可行性；剩余预算按三偏好轮转。池最多 32 条、最终最多三条，总计 300 ms/20,000 展开/40,000 标签，含安全、内部 BFS、去重和选择，不能在安全结束后重启计时。
- [ ] 上界包含已揭示类型收益、未知诡秘固定探索分、羽瞰和剩余加工品确定资源收益，不加入未知候选类型收益；单一 incumbent 不能提前剪掉所有备选。按偏好与多样性类别保留标签，不跨类别错误支配。统一使用整数评分单位比较。
- [ ] 对 <=6 节点、AP<=8、加工品次数<=1 的固定合成图，以独立暴力枚举测试最佳分数和所有资源约束；另验证有 gain 或飞行时不能用纯徒步 AP 硬剪枝。
- [ ] 重跑测试，保存用例期望路线和评分明细，提交本任务文件。不对大型限时结果宣称全局最优。

## Task 7 图片预处理与识别提案

**Files:** ImagePreprocessor.swift、NodeCenterDetector.swift、GridFitter.swift、TemplateMatcher.swift、CorridorClassifier.swift、Models/BlackFlowCorridor.mlpackage、Models/corridor-runtime.json、ScreenshotRecognizer.swift、ImagePreprocessorTests.swift、GridFitterTests.swift、CorridorClassifierTests.swift、RecognitionImportTests.swift、Fixtures/maa-perception-reference.json 与图片 Fixtures。

**Interfaces:** 消费 TemplateCatalog；产出 PreparedScreenshot、CoordinateTransform、RecognitionProposal、RecognitionStatus。Proposal 含预期修订号、模板候选、每格证据与冲突，不直接提交 FloorMap。

- [ ] 写预处理测试：EXIF 旋转后坐标可逆；裁剪与缩放往返误差 <=1 个工作图像素；最长边 <=1280；超过 20 MiB 或 1600 万像素拒绝完整解码；无法解码、空裁剪、取消均不产生可提交地图。
- [ ] 写网格测试：自建网格的缩放和平移正确吸附；重复圆/文字中心去重；同分模板拒识；唯一模板仍检查覆盖；缺一列的图不得误判全图覆盖。
- [ ] 写节点标签测试：Vision 返回候选与图标证据有冲突时标 ambiguous；不得把文字未命中当空地；截取半张地图不能丢失未覆盖的旧节点。
- [ ] 写 MAA 模板兼容测试：非 absent 观测边为模板边子集且唯一时允许提案补出口；多个兼容时不补；没有识别坐标的节点不凭模板新增；连通性修补的弱边仍为 inferred。
- [ ] 在开发宿主评估 MAA ONNX 的等价 Core ML 导出，记录源/导出模型和 runtime 配置哈希、工具版本；不训练新模型。写 CorridorClassifierTests：RGB Float32 3×40×160 与配套归一化，相同合成走廊的 logit 绝对误差 <=1e-4；阈值上下至少 0.01 的源结果边判断相同。转换或对照失败依用户规则报告暂停，不能写模型通过。
- [ ] 先运行新增 iOS 单元测试，确认预期失败；按 MAA 归一化、地图 ROI、网格、行 OCR/图标、道路模型和模板兼容链移植。Core Image/Accelerate/Vision/Core ML 替换宿主依赖，hlsh 占用格评分作为模板候选补充；只有用户确认后才写入地图。
- [ ] 验证完整游戏画布映射到 1280×720、地图裁剪保持比例重拟合、不直接套原始 ROI；人工模板和道路编辑保留，模型未启用时如实说明自动支持范围。将 MAA 源对照和 Apple 适配差异写入 maa-porting-notes。
- [ ] 对每层合法取得实战截图回放；保存图片哈希、授权/来源记录、期待模板与节点标注，错误保留作回归证据，不删除或把阈值调到全部通过。
- [ ] 核心测试与 iOS 测试通过后提交文件；没有实战图时本任务只能完成合成验证部分，按用户要求报告暂停实际识别验收。

## Task 7A 加工品背包与移动预览识别

**Files:** InventoryRecognizer.swift、InventoryRecognitionTests.swift、Fixtures 加工品文字/截图；复用 ImagePreprocessor，不新增模型训练或联网依赖。

**Interfaces:** 消费 PreparedScreenshot、MovementCatalog，产出 InventoryProposal、MovementPreviewProposal、InventoryObservationCoverage；所有提案未确认前不能改变真实库存。

- [ ] 写文字解析测试：名称标准引擎配剩余 1/3 得 currentCharges=1，不用目录 3；只见持有 2 件但没见剩余次数，remainingCharges=nil；两件同名保持两个候选实例；仅图标无文字返回待确认。
- [ ] 写 OCR 歧义测试：1/7、不同物品相邻、次数不显示、未知加工品、M04/M12 无模板，均不得静默填初始次数；目录已知名称能给人工选择列表。
- [ ] 写覆盖与去重测试：同截图摘要不累加库存；部分背包不删除未显示实例；重叠图无法唯一匹配时保留冲突；完整替换需显式确认；不能把当前装载方式当成全部持有库存。
- [ ] 写移动预览测试：用户指定目标与物品实例，识别显示 -2 AP 后提案 cost=2；目标/方式不明不提交；希望 +2 文本不得误读成 AP 消耗 2。
- [ ] 先运行 InventoryRecognitionTests 确认失败，再对照 MAA MovementRecognition/InventoryModel 移植名称/别名、slot 定位和预览成本语义，用 Vision OCR 替换宿主识别；保持逐字段证据、截图覆盖与缺失状态。
- [ ] 以合法取得的实际背包、详情和预览图回放，记录字段正确性和人工修改。识别缺口按实际记录，不把 MAA 默认值当 OCR 正确结果。
- [ ] 测试通过后提交；自动识别失败时人工录入可继续完成加工品规划，但该失败样例保留并按用户规则报告。

## Task 8 导入预览与人工纠错闭环

**Files:** ScreenshotImportView.swift、RecognitionReviewView.swift、MapEditorView.swift、MapCanvasView.swift、InventoryImportView.swift、InventoryReviewView.swift、SessionHomeView.swift、AppShellView.swift、SessionStore.swift、SessionStoreTests.swift、ScreenshotWorkflowTests.swift、AdaptiveShellTests.swift。

**Interfaces:** 消费 RecognitionProposal、InventoryProposal、MovementPreviewProposal 和任务 1A 的主题/导航；产出 MapSession、SessionEdit、SessionStore.apply/commit/commitInventory、MapViewport 与 MapCanvasView，地图、库存确认及必经入口。MapViewport 保存 scale/translation，UI 重排不修改核心会话修订号。

- [ ] 写 SessionStoreTests：取消提案保留旧地图；过期 expected stamp 被拒；确认楼层、出生点、位置、出口、AP 后才提交；修改当前节点不改出生点；修正 originalKind 触发新 mapRevision。
- [ ] 写 UI 测试：通过测试启动参数注入独立合成图片，完成裁剪→预览→点节点纠错→确认地图；低置信度走人工模板/手动图，不出现伪成功提示。
- [ ] 增加 iPhone/iPad 前端流程测试：单栏逐步导入与双栏原图/提案对照使用同一确认逻辑；AP 输入到一半时旋转/重排仍保留草稿；键盘出现后确认和取消可达；缩放地图后点击节点对应同一逻辑 NodeID，拖动不误改必经条件。
- [ ] 先运行失败测试，再实现 PhotosPicker、fileImporter 与错误展示，不申请整库照片访问或录屏权限。
- [ ] 实现节点类型、完成状态、当前位置、出生点、出口、道路、AP 与确定性加工品编辑；未知凶戾只有人工明确确认普通战斗范围后设 battleScope=ordinaryConfirmed，否则路线要求揭示。允许一层最多 64 节点，基础场景为规格的固定网格。
- [ ] 加入背包/详情/移动预览导入与人工确认：件数、逐实例剩余次数、成本、射程、增益和层末失效分栏；OCR 不确定字段必须确认后使用。重复图不增加次数，查看方案不扣真实资源。
- [ ] 地图节点详情提供必须经过切换，默认无序，最多 8 个；未知和已完成节点可选。变更递增 goalRevision、失效全部旧路线，不改变候选集合。
- [ ] 按 V2 实现会话首页、导入裁剪、地图确认/编辑和加工品确认：iPhone 单栏＋详情，iPad 满足宽度时原图/提案或地图/检查区并排。加工品采用选中物件＋逐实例列表，未确认项用文字/图标和就近修正入口。
- [ ] 实现共享 MapCanvasView 的缩放、平移、重置与节点列表替代操作；按当前视口换算点击坐标。内容节点、出口、当前位置、必经和推断边使用不同图标/线型及图例，装饰赭金线不得连接为真实道路；视口和选择由外层持有，旋转不重置。
- [ ] 运行 xcodebuild -project TreeSeaAssistant.xcodeproj -scheme TreeSeaAssistant -destination "platform=iOS Simulator,id=$TREESEA_SIMULATOR_ID" test，预期 TEST SUCCEEDED；人工检查 iPhone 与 iPad 的地图缩放、中文内容和底部详情。
- [ ] 提交文件。界面不出现未实现实时或小窗的占位入口。

## Task 9 候选说明、路线解释与版本安全

**Files:** ComputationWorker.swift、SessionStore.swift、CandidateDetailView.swift、PlanRequestView.swift、RouteDetailView.swift、SessionHomeView.swift、SessionListView.swift、AppShellView.swift、SessionRepository.swift、SessionStoreTests.swift、ScreenshotWorkflowTests.swift、AdaptiveShellTests.swift、AccessibilityWorkflowTests.swift。

**Interfaces:** 消费 predict、plan 和会话编辑；产出后台计算入口、acceptPrediction/acceptPlan、SessionRepository、可持久化多路线摘要。流水线为候选筛选与配额传播→必经与加工品多路线规划。

- [ ] 写 SessionStoreTests：启动计算后修改 AP，旧 plan 结果不能被接受；新原始类型确认后旧 prediction 不能接受；取消不覆盖最后有效结果；等价编辑不反复增加修订；保存恢复保留原始身份。
- [ ] 写旧 PredictionResult 不能接到新 mapRevision/ruleVersion 的测试；规则变更重算后旧路线失效，收益配置变更只重算路线而不改变候选。全部候选计算共享 100 ms 总截止，取消后的结果不得提交。
- [ ] 写修改必经、库存剩余次数、加工品效果或成本后旧 RouteSetResult 拒绝测试；切换查看三条推荐不会扣次数。用户确认实际执行或重新导入库存才对账。
- [ ] 写本地存储测试：原子保存成功可往返；损坏 JSON 显示恢复失败并保留坏文件作为证据，不覆盖成空会话；只保存模型、必要图片路径与结果，不写凭证。
- [ ] 运行失败测试，实现单次任务、取消、依赖 stamp 比较及 MainActor 同步提交。使用明确后台入口，不认为 Task 或 async 本身意味着重计算离开主线程。
- [ ] 候选页面只显示可能类型、距离、排除原因和配额状态，单候选标按当前规则唯一，不显示百分比或高低可能排名；路线页展示最多三条有差异的方案、偏好 badges、必经覆盖、每步起止/移动方式/加工品实例/次数/AP与增益，以及固定偏好分与保守战斗代价。地图区分徒步线和飞行箭头。
- [ ] 列表显示仅找到 N 条而非重复凑三条；无解或预算未求得时标出必经节点及已知限制。不能把失败节点悄悄取消。
- [ ] UI 测试贯通：导入地图→确认→导入加工品/确认次数→查看候选→选必经节点→比较几条加工品路线→修改 AP/次数/必经→重新规划；确认商店后候选更新、使用已知商店分重规划，修改收益偏好不改候选。重启后恢复库存、必经和配置版本。
- [ ] 按 V2 和旧规范有效交互完成候选详情、规划条件、宽胶囊路线比较、步骤台账和会话恢复入口。iPad 地图工作台的所选路线与检查区绑定同一 selectedRouteSignature；折叠为单栏后可通过返回回到地图。首版按实际已保存的最近有效会话显示，不伪造固定六个存档槽。
- [ ] 增加重排与状态测试：查看方案 A→缩窄 iPad 窗口→旋转→返回，仍显示 A 和原必经/AP；计算中旋转不重启计算或接受过期结果；节点列表和地图上的身份、必经、完成状态一致。
- [ ] 增加 AccessibilityWorkflowTests：辅助功能字号下不截断候选/加工品关键数值，主要操作可滚动到达；VoiceOver 标签表达节点类型、未揭示/必经、移动方式与 AP；Tab/指针焦点和原生确认/取消可用；Reduce Motion/Transparency 下业务状态与操作不变。灰度显示时仍可通过图标、线型和文字区分路线与状态。
- [ ] 运行核心与 iOS 测试，提交本任务文件。

## Task 10 首版整体验收与文档交接

**Files:** docs/acceptance/ios-v0.1.md、README.md；仅在发现属于本任务范围的产品问题时按用户暂停规则处理，不顺带重构。

**Interfaces:** 消费全部产品与测试；产出按证据填写的验收报告。

- [ ] 全部核心测试：swift test --package-path Packages/TreeSeaCore，预期所有测试通过。
- [ ] iOS 模拟器测试：xcodebuild -project TreeSeaAssistant.xcodeproj -scheme TreeSeaAssistant -destination "platform=iOS Simulator,id=$TREESEA_SIMULATOR_ID" test；再选择 iPad 模拟器验证两种设备族。
- [ ] 前端适配矩阵：iPhone 窄屏/较大屏的横竖屏；iPad 横竖屏、单/双/三栏、分屏及窄窗口；默认/辅助功能字号，键盘、指针与焦点，Reduce Motion/Transparency、灰度与增强对比度。逐项记录实际设备/容器尺寸，确认导入、编辑、候选、库存、必经、多路线和步骤均可操作且草稿/选择保留。
- [ ] 人工检查 V2 色板、标题/正文、黑墨承托、光域胶囊、边缘装饰、44 pt 命中区和 52 pt 主要操作；测运行组件对比度。已有/待生成/待审阅预览只记参考状态，不替代产品视觉验收。
- [ ] 真机测试：至少一台较旧 iPhone、一台近期 iPhone；记录型号、系统、截图大小、识别 P50/P95、预测和规划耗时、取消延迟、峰值内存。预算指标以规格第 8 节为准，不从源码阈值推算实测成绩。
- [ ] 连续 20 次导入与纠错，检查没有持续内存增长；用 Instruments 确认主线程不被识别或搜索长时间占用。
- [ ] 每层至少一张实际截图完成闭环；记录未支持模板、数据核对覆盖和异常图拒识行为。人工验收与自动测试分栏。
- [ ] 整理权重回放：至少直接出口、绕路商店、行动力不足、加工品捷径、重复节点、未知战斗六类；对照未知诡秘揭示前后评分、固定探索分和保守战斗代价，验证候选数量/顺序不改变固定分，不称统计校准或大型图最优性验证。
- [ ] 增加实际库存导入与多路线验收：M12 充能、M08/M11 跨断路、M10 行商限制、部分/重复库存截图、多个必经、飞行掠过不算必经；每条推荐逐步回放资源，记录实际剩余次数，而非目录初始次数。
- [ ] 更新 README 的真实能力、截图与已知限制，保留来源记录和回归图片；只清理由本次实现导致不再使用的文件。
- [ ] 汇总 MAA 目录/加工品/动作/安全/识别对照结果，以及 hlsh 候选结果；按实际验证记录资源转换、策略条件和 App 适配差异。路标、羽瞰点仅记录已核对的交互，不编造未公开算法。
- [ ] 提交验收与文档。此任务不包含签名发布、TestFlight、App Store、实时识别或 PiP。

## 3 覆盖映射

| 规格要求 | 负责任务 |
|---|---|
| 仅 iPhone/iPad、版本下限、离线与共享纯核心 | 1、2、10 |
| V2 风格、语义色、字体、共享组件与原生反馈 | 1A、8、9、10 |
| iPhone 单栏、iPad 分栏/窄窗口、旋转与键盘状态保留 | 1A、8、9、10 |
| 地图视口、节点列表、触摸/指针/键盘与无障碍 | 8、9、10 |
| Dynamic Type、VoiceOver、减少动态/透明度、对比度 | 1A、9、10 |
| 原始身份、完成状态、修订号、保存恢复 | 1、8、9 |
| 来源与许可、模板/规则独立核对 | 2、7、10 |
| MAA 主要功能移植清单、资源哈希、策略条件与 App 差异 | 1、2、5、6、7、7A、10 |
| 出生点 BFS、局部候选与缺失资料行为 | 3 |
| 数量上下界、Dinic、离散总数、完整性与冲突 | 4 |
| hlsh-helper 完整输入的候选集合与顺序对齐、仅显示列表及排除依据 | 3、4、9 |
| 行动力、一次增益、阻挡、确定性加工品 | 5 |
| 加工品目录、启动门槛、逐实例次数、确认资源增益 | 2、5、7A |
| 库存/详情/移动预览截图、人工确认、覆盖与去重 | 7A、8、9 |
| 无序必经位置、飞行落点、多路线偏好与去重 | 5、6、8、9 |
| 初始权重、固定探索分、保守战斗代价与逐项解释 | 5、9、10 |
| 可行性、收益搜索、硬目标、总预算和取消 | 6、9 |
| 图片导入、拒识、预览、人工纠错 | 7、8 |
| 实战图、性能与人工验收 | 7、10 |
| 实时识别与小窗后续评估 | 首版排除，规格第 9 节 |

## 4 本计划的自检与后续入口

- 类型、接口、预算与权重已对照规格；所有首版要求有负责任务。
- 初始规则值为源码参照，强规则的游戏核对状态与复制许可单独处理。
- 核心测试中的地图是独立合成数据；实战截图仍是视觉验收必需输入。
- 全局时限覆盖可行性和收益阶段，未找到与无解有不同结果。
- 本次修订以 MAA 为主要移植来源，补入源资源/状态/动作/安全/识别的对照要求；候选只采用 hlsh-helper，不恢复概率。必经、多路线和 balanced-items-v0.4 保留为 App 适配，其他项目补充交互。
- 前端以 V2 视觉规范为主，旧 UI 文档补充交互和无障碍；已接入任务 1A、8、9、10，包含具体布局阈值、页面覆盖、状态保留与双设备验收，不新增或重生成静态图片。
- 没有创建 App、写入产品代码、运行测试或完成设备验收；上述复选框全部待执行。

后续实现从任务 1 开始。用户选择执行方式并授权实现前，只调整文档，不自动开始工程开发。
