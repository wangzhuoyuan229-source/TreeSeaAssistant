# 已实际调用的生成提示词

## 03-v2 单点修正

用户授权：仅修正 03 后暂停。输入：03-iphone-map-review.png。输出：03-iphone-map-review-v2.png。工具：内置 imagegen。

```text
Edit the supplied UI screenshot with ONE precise correction only. Add the missing confirmed road between node N09 and node N14 in the far-right map column. N09 is the glowing aqua exit circle in middle row (center approximately x736,y638 in the 852x1846 image). N14 is the empty circle immediately below it (center approximately x735,y847). Draw a straight vertical aqua line of the same thickness, luminosity and color as existing map roads, from the bottom edge of N09 circle toward the top edge of N14 circle. Maintain a clean line without crossing or erasing the labels '出口' and 'N14': interrupt the line behind these text label areas to preserve text readability, resuming between them, just as nearby N07-N12 road yields to labels. The resulting map must visibly connect N09 and N14. Preserve original image dimensions, entire UI layout, every node center, all other roads, colors, decorations, every Chinese character, every number and every control exactly. Do not regenerate or redesign the page, do not move any nodes, do not add any other roads, do not change fonts, crop or add wording. Nontransparent background.
```


01–03 均使用内置 imagegen。01 无图片输入；02/03 使用 01 原始生成图作为视觉风格参考。其余 8 张未调用。

## 01 iPhone 会话首页

项目文件：`01-iphone-session-home.png`。

```text
Use case: ui-mockup. Create a polished, high fidelity Chinese iOS/iPadOS application interface concept for an offline Arknights Black Flow Tree Sea screenshot prediction and route planning assistant. This is a DESIGN PREVIEW, not an implemented app screenshot.
Shared visual language: exclusively dark. Background #0A1115, content surfaces #142126 and #213238, primary text #E9EEE8, secondary #A5B8B8, muted #8A9E9F, interactive aqua #90E4D7 with dark #0A2220 text, illustration violet #AEA4FA, warning #E6C77D, error #F29494. Sophisticated bioluminescent forest/organic cartographic language: tiny engraved branch silhouettes, fibrous ink textures at the outer edges, soft irregular aqua light domains, restrained purple-blue gradient-mapped illustrative forms, fine diagram lines. Keep text, map and input areas extremely readable and clean. Use spacious disciplined alignment, native iOS navigation and SF-style icons, elegant Chinese system sans-serif typography. No generic cyberpunk neon, no repeated nested dashboard cards, no horror characters. Botanical ornament is subtle and supports hierarchy.
Deliver ONE large straight-on full interface, no perspective device photography, no surrounding marketing copy or multi-phone collage. Render key Chinese labels verbatim, large and sharp, with correct spelling. Use minimal small copy. Include a quiet footer '界面概念预览 · 示例数据'. All numbers are synthetic examples. Never include live recording, floating PiP, cloud/account/social functionality or a false verified/implemented badge.

Portrait iPhone single-screen composition, approximately 9:19.5. Header '黑流树海', small subtitle '离线辅助'. A tasteful, original organic aqua light orb enclosed in fine branching engraving appears in the upper quarter, with quiet violet-blue depth; controls remain clean. The main continuation area: '继续探索', '第一层', '行动力 6', '必经 1/8', primary button '恢复会话'. Below show '新建会话', '导入地图', '导入资源' as distinct clear actions, a small recent session row '第一层 · 待规划'. Native bottom tabs '地图' selected, '会话', '设置'. No user profile or generic statistics cards.
```

## 02 iPhone 导入与裁剪

项目文件：`02-iphone-import-crop.png`。

```text
Use case: ui-mockup. Create a polished, high fidelity Chinese iOS/iPadOS application interface concept for an offline Arknights Black Flow Tree Sea screenshot prediction and route planning assistant. This is a DESIGN PREVIEW, not an implemented app screenshot.
Shared visual language: exclusively dark. Background #0A1115, content surfaces #142126 and #213238, primary text #E9EEE8, secondary #A5B8B8, muted #8A9E9F, interactive aqua #90E4D7 with dark #0A2220 text, illustration violet #AEA4FA, warning #E6C77D, error #F29494. Sophisticated bioluminescent forest/organic cartographic language: tiny engraved branch silhouettes, fibrous ink textures at the outer edges, soft irregular aqua light domains, restrained purple-blue gradient-mapped illustrative forms, fine diagram lines. Keep text, map and input areas extremely readable and clean. Use spacious disciplined alignment, native iOS navigation and SF-style icons, elegant Chinese system sans-serif typography. No generic cyberpunk neon, no repeated nested dashboard cards, no horror characters. Botanical ornament is subtle and supports hierarchy.
Deliver ONE large straight-on full interface, no perspective device photography, no surrounding marketing copy or multi-phone collage. Render key Chinese labels verbatim, large and sharp, with correct spelling. Use minimal small copy. Include a quiet footer '界面概念预览 · 示例数据'. All numbers are synthetic examples. Never include live recording, floating PiP, cloud/account/social functionality or a false verified/implemented badge.

Portrait iPhone single screen. Native header '导入截图', navigation action '取消'. A horizontal import-purpose selection with '地图' selected, '背包', '详情', '移动预览'. Main area displays an ORIGINAL synthetic game-like map screenshot fragment framed by a crop rectangle with four corner handles, dim outside crop. Beneath: floor selector '第一层', small helper '裁剪地图区域'. Bottom primary action '继续识别' and secondary '重新选图'. Show only importing and cropping, no recognition-success claim. Shared synthetic map, floor I, a 5-column x 3-row grid. Node coordinates (column,row): N05=(0,1), N06=(1,1), N07=(2,1), N08=(3,1), N09=(4,1), N12=(2,2), N13=(3,2), N14=(4,2), N02=(2,0). Exact confirmed roads: N05-N06-N07-N08-N09, N07-N12-N13-N14-N09, N07-N02. Do not invent roads. N05 is initial and current position, N07 is completed empty space and mandatory, N09 exit, N08 ordinary combat, N13 confirmed shop, N02 unrevealed mystery question mark. Remaining listed nodes empty. AP=6, mandatory=1/8.

Input image 1: visual style reference only. Generate a NEW page; do not preserve the home layout or its prose. Only render the specified UI text and necessary map identifiers, no invented poems or dates. Use Chinese system sans-serif for interface labels.
```

## 03 iPhone 地图确认

项目文件：`03-iphone-map-review.png`。

```text
Use case: ui-mockup. Create a polished, high fidelity Chinese iOS/iPadOS application interface concept for an offline Arknights Black Flow Tree Sea screenshot prediction and route planning assistant. This is a DESIGN PREVIEW, not an implemented app screenshot.
Shared visual language: exclusively dark. Background #0A1115, content surfaces #142126 and #213238, primary text #E9EEE8, secondary #A5B8B8, muted #8A9E9F, interactive aqua #90E4D7 with dark #0A2220 text, illustration violet #AEA4FA, warning #E6C77D, error #F29494. Sophisticated bioluminescent forest/organic cartographic language: tiny engraved branch silhouettes, fibrous ink textures at the outer edges, soft irregular aqua light domains, restrained purple-blue gradient-mapped illustrative forms, fine diagram lines. Keep text, map and input areas extremely readable and clean. Use spacious disciplined alignment, native iOS navigation and SF-style icons, elegant Chinese system sans-serif typography. No generic cyberpunk neon, no repeated nested dashboard cards, no horror characters. Botanical ornament is subtle and supports hierarchy.
Deliver ONE large straight-on full interface, no perspective device photography, no surrounding marketing copy or multi-phone collage. Render key Chinese labels verbatim, large and sharp, with correct spelling. Use minimal small copy. Include a quiet footer '界面概念预览 · 示例数据'. All numbers are synthetic examples. Never include live recording, floating PiP, cloud/account/social functionality or a false verified/implemented badge.

Portrait iPhone single screen, header '确认地图', '取消'. Show a large clean 5x3 map editor with tiny coordinate/grid guides, exact shared topology and clearly readable node markers. N05 dual label '出生点 / 当前位置', N07 '必经', N09 '出口', N02 '?' with amber '待确认'. Below map compact form rows '楼层 第一层', '行动力 6', '当前位置 N05', '出口 N09'. Amber inline note '请确认节点与道路', modest correction action '编辑节点'. Bottom primary button '确认并提交'. This is an uncommitted preview; no currently valid route displayed. Shared synthetic map, floor I, a 5-column x 3-row grid. Node coordinates (column,row): N05=(0,1), N06=(1,1), N07=(2,1), N08=(3,1), N09=(4,1), N12=(2,2), N13=(3,2), N14=(4,2), N02=(2,0). Exact confirmed roads: N05-N06-N07-N08-N09, N07-N12-N13-N14-N09, N07-N02. Do not invent roads. N05 is initial and current position, N07 is completed empty space and mandatory, N09 exit, N08 ordinary combat, N13 confirmed shop, N02 unrevealed mystery question mark. Remaining listed nodes empty. AP=6, mandatory=1/8.

Input image 1 is a style reference only. Generate a NEW confirmation page, not the home. Interface text must be system sans-serif, no invented poetry or dates. Map background is near-solid #142126, faint grid only; no forest painting under the nodes. Only labels listed, correct grid positions, all connecting roads straight and unambiguous.
```

