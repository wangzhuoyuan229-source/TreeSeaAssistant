# 四图参考版生成提示词

历史实际提示词保留，不改写已发生的调用。以下概率显示和自创物件插图要求已被当前规格覆盖：不计算节点概率，专有游戏图标使用原版；后续采用 [V2 最新要求](../../ui-design-reference-v2.md) 与 [自建素材提示词](../../../自建素材/prompts.md)。

## 03 单点修正的实际提示词

工具：内置 imagegen。输入为 03-iphone-inventory-review.png，作为编辑目标；输出为 03-iphone-inventory-review-v2.png。原图保留。

```text
Edit the supplied UI image with exactly ONE local correction. In the SECOND confirmed '标准引擎 · 实例 B' row, the left description correctly says '剩余 3 次' but the numeric stepper field on the RIGHT incorrectly shows '1'. Change ONLY that right stepper digit from '1' to '3', with exactly the same ivory font, size, alignment and dark field. This field is between the minus and plus buttons in the second jade-rimmed capsule, around x646,y1122 of the 851x1849 source. Leave the FIRST instance A stepper at '1'. Preserve the left instance-B '剩余 3 次' text, the pending remote's '1 / 7', every other number, character, icon, artwork, layout, colors and original full canvas dimensions. Do not redraw the interface, do not change the upper item description or the item specimen. Opaque background retained.
```


工具：内置 imagegen。输入图 1–4 为用户的 IMG_1671–IMG_1674 原图，均为风格参考；工作台另外输入旧版 03 修正版，只用作拓扑参考，不沿用旧版界面皮肤。每页为全新构图，不编辑用户原图。

调用状态：01–04 已生成；03 原图数字冲突已保留证据，并另存修正版。用户授权修正后完成 04，当前本轮四页已交付。

## 通用提示词

```text
Use case: ui-mockup. Create one high-fidelity static UI design preview for a Chinese offline iOS/iPadOS Black Flow Tree Sea map-prediction assistant. Inputs 1–4 are the USER'S direct visual style references, not screenshots to preserve or collage as-is. Faithfully adapt and partially reuse their design motifs: irregular black ink silhouette masks, surreal natural-history assemblage, white engraved skeletal-animal cutouts, violet and ultramarine brush-painted areas, sparse aged-gold geometric/radiating lines, dark green staged woodland, soft jade rims and purple/teal/ochre optical glow cores inside wide pill-shaped buttons and content units. It should unmistakably resemble these four reference images. Use flat print/engraving and painted collage visual craft rather than generic fantasy moonlit scenery or conventional glossy dashboard rectangles.
Only dark appearance. Palette near-black #060A08, text-bearing ink #0B1210, forest #173B31, jade rim #79BCAF, ultramarine #3348D6, violet #7146B5, ochre #B99551, restrained burgundy #6B2938, ivory text #E8E5D9 and secondary #B7BBAF. Title may be Chinese Song-style serif as in the references. All functional body labels and numbers must be sharply legible Chinese system sans-serif; separate illustration/detail from readable controls with near-opaque ink backing. Preserve native iOS navigation placement and touch-friendly control scale. No platform watermarks or account numbers, no copied narrative dialogue, no extra NPC/chatbot functionality, no cloud/login/PiP/recording controls. ONE large straight-on app screen, not a multi-device mood board or device photograph. Quiet footer '界面概念预览 · 示例数据'. Strictly use the specified UI text and data; no invented slogans, dates or metrics.
```

## 1 iPhone 会话首页

输出：`01-iphone-session-home.png`。实际 prompt 为通用提示词加以下页面要求。

```text
Portrait single iPhone screen approximately 9:19.5. Top small native status bar. Large ivory Song-style title '黑流树海', subtitle '地图预判'. The upper third is a restrained but distinctive surreal collage: an ivory etched skeletal deer/canine fragment set among ultramarine brush streaks, a dark teal red-purple deer collage and fine ochre chart lines inside a black irregular leafy vignette, borrowed visibly from reference images 1 and 2. It must feel like an art-directed game menu, but not occupy the whole usable screen.
Main continuation area is a wide pill with a jade rounded glowing perimeter and subtle purple/teal/ochre circular light core behind a small icon, inspired by the save slots in image4. Clear text '继续探索', '第一层', '行动力 6', '必经 1/8'. Inside/just beneath an unmistakable primary capsule '恢复会话'. Below, two distinct capsule actions '导入地图' and '导入资源', then a modest '+ 新建会话' text action and '最近会话' with ONE example '第一层 · 待规划'. Native bottom tabs '地图', '会话', '设置'. Text set on dark stable ink; ornaments in margins. No invented poetry.
```

## 2 iPad 地图工作台

输出：`02-ipad-map-workspace.png`。实际 prompt 为通用提示词加以下页面要求。额外结构参考：../03-iphone-map-review-v2.png。

```text
Landscape single iPad app screen approximately 4:3. Three purposeful areas: a thin dark native leading sidebar '黑流树海', '地图' selected, '会话', '设置'; wide center map; medium right context inspector. Top toolbar has '第一层', '行动力 6', '必经 1/8', '导入截图', undo icon. Use reference image2's subdued dark teal staged forest only as a peripheral backdrop; center map rests on readable black ink shape with rugged silhouette edges, aged gold faint grid annotation, not a noisy forest painting.
Draw the exact 5x3 topology from the provided structural reference, all nine roads, ivory circles, distinguished N05 current marker, N07 mandatory flag, N09 exit icon, N02 question mark. Connect N14-N09 clearly. Topology reference image5 is ONLY for node positions and connections; do NOT copy its old application skin, typography or layout.
Right inspector has tabs '节点' selected and '路线'. Show selected '节点 N02', central '?' halo, '未揭示', heading '估计概率', two clean bars: '诡意行商 50.0%' and '不期而遇 50.0%'. Caption '依据规则估算，非实测概率'. Footer options '必须经过' toggle OFF, '人工揭示'. Employ reference image3's irregular black explanation field with an aged gold section title, and reference image4's subdued jade/purple/ochre light around the selected unknown icon. No route strokes selected in this view; no probability masquerading as confirmation. Exact synthetic map used for UI demonstration, not an actual game rule prediction: floor I, 5 columns by 3 rows. Positions (column,row): N05(0,1), N06(1,1), N07(2,1), N08(3,1), N09(4,1), N12(2,2), N13(3,2), N14(4,2), N02(2,0). Roads only: N05-N06, N06-N07, N07-N08, N08-N09, N07-N12, N12-N13, N13-N14, N14-N09, N07-N02. N14-N09 MUST be visible as a vertical connection in the far-right column. N05 initial/current, N07 mandatory completed empty node, N09 exit, N08 ordinary battle, N13 confirmed shop, N02 unrevealed mystery. No extra edges or omitted edges.
```

## 3 iPhone 加工品确认

输出：`03-iphone-inventory-review.png`。实际 prompt 为通用提示词加以下页面要求。

```text
Portrait single iPhone app screen approximately 9:19.5. Native back chevron, title '确认加工品', subtle top '示例'. Strongly adapt image4's selected-object display and image3's ragged dark explanation panel. In the upper third a silver mechanical engine specimen floats in a small purple-teal-ochre glowing domain against an inky forest assemblage with ochre engraving annotations. It represents '标准引擎'; no character portrait. This is an illustrative selected item, not a gameplay character scene.
Below the dark ink panel, an easily readable two-row confirmed-instance list: '标准引擎 · 实例 A' — '剩余 1 次'; '标准引擎 · 实例 B' — '剩余 3 次'. Each instance has separate minus/plus controls or stepper. Use jade-rimmed pill units from reference image4, with dark centers, not repeated bright filled aqua rectangles. A separate amber row '简易遥控器', '次数待确认', '1 / 7' and edit icon. Clear note '未确认物品不参与规划', secondary note '仅更新本图显示的物品'. Bottom '+ 手动添加' and primary soft iridescent jade capsule '保存已确认项'. Keep the two confirmed engines separate and never auto-fill the pending remote.
```

## 4 iPhone 路线比较

输出：`04-iphone-route-comparison.png`。实际 prompt 为通用提示词加以下页面要求。

```text
Portrait single iPhone app screen approximately 9:19.5. Title '推荐路线', subheading '找到 2 条不同路线'. Small upper decorative natural-history route vignette with ivory skeletal animal cutouts, ochre path-like engraving, blue/purple ink collage and rough black edges, derived from image1; explicitly decorative, not another labelled map. Below two large broad pill-shaped comparison units closely inspired by the save slots in image4, jade feathered perimeter, subtle iridescent light core, ivory serif card title and high contrast sans-serif metrics on dark ink. No conventional rounded-rectangle dashboard grid.
First unit active '方案 A'; badges '综合收益' and '较低战斗风险'; numbers exactly '预计收益分 6.5', '消耗 6 AP', '剩余 0 AP', '加工品 0 次', '战斗 0 次', '必经 1/1'. Second unit '方案 B', badge '节省加工品'; numbers '预计收益分 -9.0', '消耗 4 AP', '剩余 2 AP', '加工品 0 次', '战斗 1 次', '必经 1/1'. A selected with slightly brighter jade edge, B subdued, no third unit. Bottom note '按当前估计可执行' and primary '查看步骤'; modest '调整条件' secondary action. No success rate or claim of optimality. Make both unit contents spacious and fully visible.
```

