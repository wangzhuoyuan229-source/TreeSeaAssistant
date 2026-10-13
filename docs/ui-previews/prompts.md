# 界面预览最终提示词

此文件保留旧版实际提示词与尚未调用的草案。后续调用以 [V2](../ui-design-reference-v2.md) 为准：游戏对象图标直接取路标原版，自创仅用于背景、动物装饰和非游戏通用 UI。SF 风格图标仅用于通用操作。实际新素材提示词见 [自建素材](../../自建素材/prompts.md)，不直接执行已过期草案。

生成方式：内置 imagegen；类型 ui-mockup；不使用 CLI 或自定义 API 调用。目前实际生成 01–03；04–11 的提示词尚待调用。

第一张图建立视觉基准。后续业务页面将第一张图作为风格参考，保留配色与视觉语言，生成不同页面；状态对照图独立生成。

## 通用约束

```text
Use case: ui-mockup. Create a polished, high fidelity Chinese iOS/iPadOS application interface concept for an offline Arknights Black Flow Tree Sea screenshot prediction and route planning assistant. This is a DESIGN PREVIEW, not an implemented app screenshot.
Shared visual language: exclusively dark. Background #0A1115, content surfaces #142126 and #213238, primary text #E9EEE8, secondary #A5B8B8, muted #8A9E9F, interactive aqua #90E4D7 with dark #0A2220 text, illustration violet #AEA4FA, warning #E6C77D, error #F29494. Sophisticated bioluminescent forest/organic cartographic language: tiny engraved branch silhouettes, fibrous ink textures at the outer edges, soft irregular aqua light domains, restrained purple-blue gradient-mapped illustrative forms, fine diagram lines. Keep text, map and input areas extremely readable and clean. Use spacious disciplined alignment, native iOS navigation and SF-style icons, elegant Chinese system sans-serif typography. No generic cyberpunk neon, no repeated nested dashboard cards, no horror characters. Botanical ornament is subtle and supports hierarchy.
Deliver ONE large straight-on full interface, no perspective device photography, no surrounding marketing copy or multi-phone collage. Render key Chinese labels verbatim, large and sharp, with correct spelling. Use minimal small copy. Include a quiet footer '界面概念预览 · 示例数据'. All numbers are synthetic examples. Never include live recording, floating PiP, cloud/account/social functionality or a false verified/implemented badge.
```

## 01 iPhone 会话首页

目标文件：`01-iphone-session-home.png`。全新生成，无图片输入。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Portrait iPhone single-screen composition, approximately 9:19.5. Header '黑流树海', small subtitle '离线辅助'. A tasteful, original organic aqua light orb enclosed in fine branching engraving appears in the upper quarter, with quiet violet-blue depth; controls remain clean. The main continuation area: '继续探索', '第一层', '行动力 6', '必经 1/8', primary button '恢复会话'. Below show '新建会话', '导入地图', '导入资源' as distinct clear actions, a small recent session row '第一层 · 待规划'. Native bottom tabs '地图' selected, '会话', '设置'. No user profile or generic statistics cards.
```

## 02 iPhone 导入与裁剪

目标文件：`02-iphone-import-crop.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Portrait iPhone single screen. Native header '导入截图', navigation action '取消'. A horizontal import-purpose selection with '地图' selected, '背包', '详情', '移动预览'. Main area displays an ORIGINAL synthetic game-like map screenshot fragment framed by a crop rectangle with four corner handles, dim outside crop. Beneath: floor selector '第一层', small helper '裁剪地图区域'. Bottom primary action '继续识别' and secondary '重新选图'. Show only importing and cropping, no recognition-success claim. Shared synthetic map, floor I, a 5-column x 3-row grid. Node coordinates (column,row): N05=(0,1), N06=(1,1), N07=(2,1), N08=(3,1), N09=(4,1), N12=(2,2), N13=(3,2), N14=(4,2), N02=(2,0). Exact confirmed roads: N05-N06-N07-N08-N09, N07-N12-N13-N14-N09, N07-N02. Do not invent roads. N05 is initial and current position, N07 is completed empty space and mandatory, N09 exit, N08 ordinary combat, N13 confirmed shop, N02 unrevealed mystery question mark. Remaining listed nodes empty. AP=6, mandatory=1/8.
```

## 03 iPhone 地图确认

目标文件：`03-iphone-map-review.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Portrait iPhone single screen, header '确认地图', '取消'. Show a large clean 5x3 map editor with tiny coordinate/grid guides, exact shared topology and clearly readable node markers. N05 dual label '出生点 / 当前位置', N07 '必经', N09 '出口', N02 '?' with amber '待确认'. Below map compact form rows '楼层 第一层', '行动力 6', '当前位置 N05', '出口 N09'. Amber inline note '请确认节点与道路', modest correction action '编辑节点'. Bottom primary button '确认并提交'. This is an uncommitted preview; no currently valid route displayed. Shared synthetic map, floor I, a 5-column x 3-row grid. Node coordinates (column,row): N05=(0,1), N06=(1,1), N07=(2,1), N08=(3,1), N09=(4,1), N12=(2,2), N13=(3,2), N14=(4,2), N02=(2,0). Exact confirmed roads: N05-N06-N07-N08-N09, N07-N12-N13-N14-N09, N07-N02. Do not invent roads. N05 is initial and current position, N07 is completed empty space and mandatory, N09 exit, N08 ordinary combat, N13 confirmed shop, N02 unrevealed mystery question mark. Remaining listed nodes empty. AP=6, mandatory=1/8.
```

## 04 iPhone 加工品确认

目标文件：`04-iphone-inventory-review.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Portrait iPhone single screen. Header '确认加工品', back action. Small screenshot strip at top suggests OCR evidence. Three clean separated rows: '标准引擎 · 实例 A' with '剩余 1 次'; '标准引擎 · 实例 B' with '剩余 3 次'; '简易遥控器' with amber '次数待确认' and '1 / 7' plus edit symbol. Show per-instance stepper controls on the two confirmed rows. Section note '本图仅更新已显示物品', warning '未确认物品不参与规划'. Secondary '手动添加', primary '保存已确认项'. No combining the two engines, no default inventory counts, no real resource spending.
```

## 05 iPhone 节点候选详情

目标文件：`05-iphone-node-candidates.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Portrait iPhone single screen. Header '节点 N02'. Top displays one enlarged mystery node in a soft aqua halo, central '?' retained, label '未揭示'. Title '可能类型'. Two equally styled readable list rows in this order: '诡意行商' and '不期而遇'. No percentages, probability bars or likelihood ranking. Adjacent note '按当前规则保留的候选'. Lower section '筛选依据', '出生点距离', '数量资料待核对'. Disclosure row '查看排除依据'. Bottom actions '人工揭示' and a native toggle row '必须经过' off. Do not show this node as confirmed or verified. Keep the data high contrast and limit decoration to the node halo and edge branches.
```

## 06 iPhone 规划条件

目标文件：`06-iphone-plan-request.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Portrait iPhone single screen. Header '规划路线'. Small map with N07 highlighted as mandatory, exit N09. Clean grouped settings: '行动力 6'; '目标出口 N09'; section '必经节点 1/8' containing selected chip 'N07' and '+ 添加'; helper '按实际到达位置计入'. Section '确认库存': '标准引擎 A · 1 次', '标准引擎 B · 3 次'. A concise soft objective selection '综合收益' selected with '寻找商店', '探索未知' optional. Primary bottom button '生成推荐路线'. No ordered waypoint UI, no probability settings that redefine route preference, no unconfirmed remote charges. Shared synthetic map, floor I, a 5-column x 3-row grid. Node coordinates (column,row): N05=(0,1), N06=(1,1), N07=(2,1), N08=(3,1), N09=(4,1), N12=(2,2), N13=(3,2), N14=(4,2), N02=(2,0). Exact confirmed roads: N05-N06-N07-N08-N09, N07-N12-N13-N14-N09, N07-N02. Do not invent roads. N05 is initial and current position, N07 is completed empty space and mandatory, N09 exit, N08 ordinary combat, N13 confirmed shop, N02 unrevealed mystery question mark. Remaining listed nodes empty. AP=6, mandatory=1/8.
```

## 07 iPhone 路线比较

目标文件：`07-iphone-route-comparison.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Portrait iPhone single screen. Header '推荐路线', subheading '找到 2 条不同路线'. Upper map highlights ONLY route A in aqua, from N05 through N06,N07,N12,N13,N14 to N09. Two large comparison rows, not three duplicates. Route A title '方案 A' with TWO badges '综合收益', '较低战斗风险'; numbers '预计收益分 6.5', '消耗 6 AP', '剩余 0 AP', '加工品 0 次', '战斗 0 次', '必经 1/1'. Route B title '方案 B', one badge '节省加工品'; numbers '预计收益分 -9.0', '消耗 4 AP', '剩余 2 AP', '加工品 0 次', '战斗 1 次', '必经 1/1'. Active A outlined subtly aqua, B neutral dark. Bottom note '按当前估计可执行', primary '查看步骤'. Do not include a success probability or a globally optimal label. Shared synthetic map, floor I, a 5-column x 3-row grid. Node coordinates (column,row): N05=(0,1), N06=(1,1), N07=(2,1), N08=(3,1), N09=(4,1), N12=(2,2), N13=(3,2), N14=(4,2), N02=(2,0). Exact confirmed roads: N05-N06-N07-N08-N09, N07-N12-N13-N14-N09, N07-N02. Do not invent roads. N05 is initial and current position, N07 is completed empty space and mandatory, N09 exit, N08 ordinary combat, N13 confirmed shop, N02 unrevealed mystery question mark. Remaining listed nodes empty. AP=6, mandatory=1/8.
```

## 08 iPhone 路线步骤

目标文件：`08-iphone-route-steps.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Portrait iPhone single screen. Header '方案 A · 路线步骤'. Compact top summary '行动力 6 → 0', '加工品 0 次', '必经 1/1'. Readable vertical six-step timeline, each row labelled '徒步': 'N05 → N06' with '6 → 5 AP'; 'N06 → N07' with '5 → 4 AP' and mandatory check; 'N07 → N12' with '4 → 3 AP'; 'N12 → N13' with '3 → 2 AP' and '秘境行商'; 'N13 → N14' with '2 → 1 AP'; 'N14 → N09' with '1 → 0 AP' and '到达出口'. Bottom small notice '示例成本：每条边 1 AP', '查看步骤不扣实际资源'. The six entries must be correct, sequential and present exactly once. No automatic game operation button.
```

## 09 iPad 地图工作台

目标文件：`09-ipad-map-workspace.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Landscape iPad full interface, approximately 4:3. Three generous columns: narrow native dark sidebar '黑流树海', '地图' selected, '会话', '设置'; central large map workspace with top '第一层' and '行动力 6', exact map with ONLY route A aqua highlight and subtle reset/zoom controls; right inspector '推荐路线', '找到 2 条不同路线', compact A/B comparison and selected A detail. A badges '综合收益', '较低战斗风险', cost6/remain0/score6.5; B '节省加工品', cost4/remain2/score-9.0. Right lower summary '必经 N07', '加工品 0 次', '按当前估计可执行'. Plenty of map negative space and faint organic aqua branches at perimeter, not behind labels. Tool actions '导入地图', '导入资源', '撤销'. Shared synthetic map, floor I, a 5-column x 3-row grid. Node coordinates (column,row): N05=(0,1), N06=(1,1), N07=(2,1), N08=(3,1), N09=(4,1), N12=(2,2), N13=(3,2), N14=(4,2), N02=(2,0). Exact confirmed roads: N05-N06-N07-N08-N09, N07-N12-N13-N14-N09, N07-N02. Do not invent roads. N05 is initial and current position, N07 is completed empty space and mandatory, N09 exit, N08 ordinary combat, N13 confirmed shop, N02 unrevealed mystery question mark. Remaining listed nodes empty. AP=6, mandatory=1/8.
```

## 10 iPad 导入确认工作台

目标文件：`10-ipad-import-workspace.png`。输入图作用：01 的视觉风格参考，不是需要保持原布局的编辑目标。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Landscape iPad full interface approximately 4:3. Header '地图导入确认', '取消' at leading edge, primary '确认并提交' at trailing edge. Left half shows a large ORIGINAL synthetic game-like source image under heading '截图', with crop boundary and node-center overlays. Right half shows clean reconstructed 5x3 map under '识别提案', exact same node coordinates and roads; amber '?' for unresolved N02. Side/bottom confirmation area displays '第一层', '出生点 N05', '当前位置 N05', '出口 N09', '行动力 6', note '有 1 项待确认' and '编辑节点'. Small notice '提交前不会覆盖当前会话'. Contrast source screenshot versus proposed model, not two different topologies. Shared synthetic map, floor I, a 5-column x 3-row grid. Node coordinates (column,row): N05=(0,1), N06=(1,1), N07=(2,1), N08=(3,1), N09=(4,1), N12=(2,2), N13=(3,2), N14=(4,2), N02=(2,0). Exact confirmed roads: N05-N06-N07-N08-N09, N07-N12-N13-N14-N09, N07-N02. Do not invent roads. N05 is initial and current position, N07 is completed empty space and mandatory, N09 exit, N08 ordinary combat, N13 confirmed shop, N02 unrevealed mystery question mark. Remaining listed nodes empty. AP=6, mandatory=1/8.
```

## 11 业务状态对照

目标文件：`11-state-comparison.png`。全新生成，无图片输入。

实际发送的完整 prompt 为上方通用约束与以下页面要求连接。

```text
Landscape large readable design reference board, approximately 4:3. NOT a phone montage. Heading '结果与状态', subtitle '界面概念预览 · 示例数据'. Five generous dark UI feedback panels arranged in a 3+2 grid. Panel1 amber '待确认', '请确认剩余次数', action '修改'. Panel2 aqua activity indicator '计算中', '保留当前会话', action '取消'. Panel3 muted/amber '已过期', '输入已修改', action '重新规划'. Panel4 restrained red '无可行路线', '当前约束已证明不可行', action '检查条件'. Panel5 amber '暂未求得', '计算预算内未找到路线', action '重新规划'. An airy bottom legend '未揭示 ≠ 已确认' and '暂未求得 ≠ 无解'. Make all five states distinct through icons and text, not color alone. Use coherent shared organic aqua/violet art at quiet outer margins.
```

