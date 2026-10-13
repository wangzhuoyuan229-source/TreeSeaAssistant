# 自建素材实际生成提示词

日期：2026-10-13。使用内置 image_gen；未使用 CLI/API 兜底。以下保留每次实际提示词，包含植物版、后续动物版及 iPad 合并修订；每个文件均单独生成。六个通用 UI 图标直接编写为可编辑 SVG，不经过图片生成。原始 UI 参考图片未修改。

## phone

输出：[backgrounds/iphone-ink-botanical-v1.png](backgrounds/iphone-ink-botanical-v1.png)

```text
Use case: stylized-concept.
Asset type: finished iPhone portrait app background, vertical 9:19.5, ideally 1296 x 2808 pixels; one single full-bleed background image, not a screenshot or device mockup.
Primary request: Create a new original decorative background following the project's dark natural-history ink-collage visual style.
Input images: Image 1 (IMG_1672) and Image 2 (IMG_1674) are STYLE REFERENCES ONLY. Borrow the dark teal, irregular black ink edges, restrained botanical etching and colored ink glow. Do not copy reference content, game entities, interface elements, lettering or watermarks.
Composition: almost black spacious middle covering 70 percent of the canvas, calm continuous #060A08 / #0B1210 field so real app text and controls can be placed later. Decorative layers confined to upper 15 percent and outer narrow margins/bottom corners. Asymmetric torn ink silhouette with sparse engraved fern fronds and abstract organic paper fragments. A restrained ultramarine/violet brushed patch at the top, small ochre hairline ornaments at the margin, faint forest teal around edges. No bright central focal object.
Palette: #060A08 black-green, #0B1210 ink, #173B31 forest, #3348D6 ultramarine, #7146B5 violet, #B99551 ochre; sparing muted #79BCAF. Matte ink texture, very subtle coarse print grain, dark readable work surface, layered editorial collage.
Constraints: original non-game decorative artwork only; no characters, animals, game items, tools, map nodes, routes, graph, paths, area symbols, compass or gameplay icons. No UI, buttons, cards, screens, phone frame, text, pseudo-writing, titles, logo, watermark or readable words. Do not bake controls into this asset. Opaque background.
```

## pad

输出：[backgrounds/ipad-ink-botanical-v1.png](backgrounds/ipad-ink-botanical-v1.png)

```text
Use case: stylized-concept.
Asset type: single finished iPad landscape background image, horizontal 4:3 composition, ideally 2048 x 1536 pixels. Full-bleed background artwork only, no device.
Input images: IMG_1672 and IMG_1674 are STYLE REFERENCES ONLY. Use their dark natural-history ink collage, torn black edges, restrained colored ink glows and botanical print textures. Do not reproduce their characters, animals, game items, lettering, watermarks or interface.
Primary request: An original understated dark botanical editorial collage background for an iPad planning workspace. A broad quiet nearly solid #060A08 / #0B1210 middle occupying 80 percent of the image, so dense real data and interface panels can sit on it. Sparse fine engraved fern and leaf fragments, torn matte ink silhouettes along the very outside margins. A small cobalt/violet ink accent in upper-left perimeter and a muted ochre fragment near lower-right perimeter; central field should remain very dark and unstructured. Fine ochre curved ornament only at outer edges, not a connected diagram. No forest perspective trail.
Palette: #060A08 black-green, #0B1210 ink, #173B31 forest teal, sparing #3348D6 ultramarine / #7146B5 violet / #B99551 ochre / #79BCAF muted jade. Matte printed texture, atmospheric but low contrast, asymmetric margins.
Constraints: background only, original decorative non-game art. No animals, people, NPCs, creatures, props, tools, map grid, roads, routes, nodes, area or item symbols, compass, gameplay icons. No UI, cards, buttons, devices, logo, title, text, pseudo-writing, watermark. Opaque background; flat spacious center, never a bright focal subject.
```

## icon

输出：[branding/app-icon-master-v1.png](branding/app-icon-master-v1.png)

```text
Use case: logo-brand.
Asset type: one original iOS application icon master, square 1024 x 1024 pixels, full bleed opaque square. No device mockup, no presentation board.
Input images: IMG_1674 is a STYLE REFERENCE ONLY for jade edging, violet and muted ochre ink-light accents against dark teal. Do not borrow any game symbol, creature, item, inventory icon, lettering or UI object.
Primary request: Create an original abstract app identity mark unrelated to gameplay: three broad asymmetrical torn paper/ink petals curling around a small calm luminous hollow core, readable as a simple editorial emblem, not a plant specimen, not a compass and not a game badge. One strong centered symbol occupying about 60 percent of the square. Petals are matte bone-white/forest teal with restrained violet and muted ochre accents; slightly rough engraved ink edges, minimal inner detail, crisp silhouette that remains legible at small icon sizes.
Background: rich nearly black #060A08 full bleed square, subtle #173B31 edge haze, restrained jade #79BCAF lighting around the mark. Palette accents #7146B5 violet and #B99551 ochre, bone white #E8E5D9. Sophisticated printed collage identity, quiet and graphic, restrained glow.
Constraints: Original APPLICATION identity only. No map, graph, routes, nodes, game item, region, road, arrows, compass, animal, NPC, horns, weapon, gear, machinery or known game logo. No text, monogram, lettering, title, watermark. No rounded-square outer mask, border frame, corner treatment or mockup; iOS applies its own icon mask. Opaque image. One isolated large emblem, no peripheral ornament.
```

## phone_animal

输出：[backgrounds/iphone-animal-cover-v2.png](backgrounds/iphone-animal-cover-v2.png)

```text
Use case: stylized-concept.
Asset type: finished iPhone portrait app COVER background, a single vertical image approximately 9:19.5. Full bleed original background artwork only, no phone/device/UI.
Input image: IMG_1671.JPG is STYLE AND ANIMAL-MOTIF REFERENCE ONLY. Borrow white skeletal animal engraving, layered purple/ultramarine ink strokes, torn black silhouettes, sparse gold natural-history hairlines. Do not reproduce the reference's exact animals, game logo, compositional symbols, text, buttons or watermarks.
Primary request: An original natural-history ink-collage cover background with clear animal elements. Upper quarter contains a compact expressive composition of a running deer with branching antlers and a running wolf in opposing overlapping poses; both are delicate bone-white anatomical/skeletal engravings with partial translucent silhouette tissue, elegant museum print treatment, no gore. Place them inside a torn violet/cobalt brush sweep, a little muted ochre arc and forest-teal collage. Give animals distinct natural believable anatomy, no magical game appendages or gear. Upper animal collage is decorative artwork only, not a node or gameplay symbol.
Composition: vertical. Animal collage confined to upper 25 percent of canvas with space above it for system safe area. Middle and lower-middle 65 percent nearly solid #060A08 / #0B1210 to support later real text and capsule controls. Narrow outside margins have subtle torn black ink, engraved fern fragments; lower corners can have sparse teal leaf fragments. No bright animals in the central data field.
Palette #060A08, #0B1210, #173B31, #3348D6, #7146B5, bone-white #E8E5D9, very sparing #B99551. Expressive editorial print collage, matte etched detail, restrained glow, strong animal motif at top and dark readable empty work surface below.
Constraints: no text, pseudo-writing, logo, watermarks, game items, characters, NPCs, node/map/route/area symbols, roads, graph or UI. Do not copy existing game creature designs. No device, cards, buttons or screen frame. Opaque background. One cohesive background asset, no contact sheet.
```

## pad_animal

输出：[backgrounds/ipad-animal-cover-v2.png](backgrounds/ipad-animal-cover-v2.png)

```text
Use case: stylized-concept.
Asset type: finished original iPad landscape COVER background, horizontal 4:3 composition, ideally 2048 x 1536 pixels. A single full-bleed background, no screen or device mockup.
Input image: IMG_1671.JPG is STYLE AND ANIMAL-MOTIF REFERENCE ONLY: bone-white animal anatomical etchings, ultramarine/purple rough ink collage, torn black silhouettes, sparse ochre natural-history ornament. Do not copy exact game creatures, symbols, text, logo, watermarks or interface.
Primary request: original dark natural-history ink collage with a running antlered deer and a running wolf represented as delicate bone-white skeletal/anatomical engravings, non-gory, believable natural mammals without gear or fantasy game appendages. Place the animal composition across the upper left quarter to upper middle margin, within a compact violet/cobalt brushed strip. Keep their complete silhouettes visible. A few thin muted ochre arcs and sparse engraved fern shapes at outside corners unify the composition.
Composition: broad horizontal canvas. Main middle and bottom 70 percent remain very dark, calm and visually unstructured #060A08 / #0B1210 for future real app controls; animal illustration lives in upper 25 percent only. Restrained collage at extreme outer edge, never bright central subject. Not a diagram or scene with a trail.
Palette: #060A08 near black, #0B1210 ink, #173B31 forest teal, #3348D6 ultramarine, #7146B5 violet, #E8E5D9 bone white, sparse #B99551 ochre; matte engraved print texture and irregular ink edges.
Constraints: animal decoration only, unrelated to gameplay. No text, lettering, pseudo-writing, watermark, logo, UI, buttons, cards, devices, grid, route, roads, nodes, area/item icons, NPCs, game objects or exact reference creature designs. Opaque background. One coherent landscape asset, no contact sheet.
```

## animal_overlay

输出：[decoration/deer-wolf-engraving-overlay-v1.png](decoration/deer-wolf-engraving-overlay-v1.png)

```text
Use case: stylized-concept.
Asset type: one genuinely TRANSPARENT PNG decorative animal collage overlay for an app header, horizontal 3:2 framing.
Input image: IMG_1671.JPG is STYLE AND ANIMAL-MOTIF REFERENCE ONLY, not an edit target. Borrow its white anatomical animal engravings, purple/cobalt ink sweep and sparse ochre hairlines. Do not copy exact creatures, game symbols, text or watermark.
Primary request: create an ORIGINAL isolated ornamental composition of one leaping natural antlered deer and one running natural wolf. Bone-white skeletal/anatomical etching with fine engraved hatching, partial pale translucent body silhouette, elegant natural-history print, no gore. Both animals complete, natural believable anatomy, no fantastical attachments, gear or NPC traits. Deer at upper left facing left, wolf at lower right facing right, partly overlapping with a restrained torn ultramarine/violet brush ribbon beneath them and two very thin muted ochre arcs. Compact coherent composition, generous transparent margin, not separate stickers on a contact sheet.
Colors: bone white #E8E5D9, muted forest #173B31, accents #3348D6 cobalt, #7146B5 violet, #B99551 ochre.
Transparency: actual transparent alpha outside the isolated illustration, including spaces around antlers/legs/tails. NO opaque background, black rectangle, dark green plate, forest scene, vignette, painted checkerboard or drop shadow. Keep the etching and small ink ribbon opaque/semitransparent, keep all outside empty. Do not flatten on any backdrop.
Constraints: decoration ONLY, not a node/game/item/map symbol or game logo. No UI, buttons, labels, words, writing, numerals, watermark, compass, graph, paths or roads. One transparent production asset, no mockup.
```

## brand_overlay

输出：[branding/app-emblem-overlay-v1.png](branding/app-emblem-overlay-v1.png)

```text
Use case: background-extraction.
Asset type: genuinely transparent PNG application brand emblem, square composition, no mockup.
Input image: app-icon-master is the EDIT TARGET. Preserve the exact three broad curled torn ink/paper petals, bone-white/forest-teal/violet/ochre palette, center light core, etched paper texture, orientation, shapes and proportions.
Primary request: remove ONLY the dark black-green background and broad background haze. Isolate the three-petal emblem with a very small soft alpha glow immediately around the luminous central core. Preserve the actual emblem design; do not invent, restyle or recompose it. Outside the petals and central core, the field must be genuinely transparent, including wide outside margins and empty gaps between petals.
Transparency: true alpha channel, not a black rectangle, painted checkerboard, green vignette, opaque shadow or backdrop. Keep edges clean while retaining the torn-paper texture. No cropping of petals.
Constraints: no new objects, text, logos, game symbol, animal, item, map or routes. Change background transparency only; keep emblem matching the opaque app icon.
```

## pad_combined

输出：[backgrounds/ipad-animal-botanical-cover-v3.png](backgrounds/ipad-animal-botanical-cover-v3.png)

```text
Use case: compositing.
Asset type: revised iPad landscape app cover background, single full-bleed 4:3 image.
Input images: Image 1 ipad-animal-cover-v2 is the PRIMARY EDIT TARGET. Image 2 ipad-ink-botanical-v1 is a SUPPORTING COMPOSITION REFERENCE to supply the lower-edge decoration.
Primary request: combine these two backgrounds. Preserve Image 1's upper animal composition: the complete bone-white anatomical deer and running wolf, their relative position, purple/cobalt rough ink sweep, dark natural-history style. Bring Image 2's rich etched fern fronds, layered forest-teal leaves, torn ink/paper edges, subtle violet patches and muted ochre arcs into the lower third and bottom corners of Image 1. The bottom currently feels empty: make the botanical pattern visibly present, with engraved fronds reaching upward from both bottom corners and a connected loose border of leaf and ink fragments along the lower edge. Especially retain the first image reference's gold/ochre botanical paper fragment at lower right (Image 2). Use the same matte collage texture and palette. Do not add more animals at bottom.
Layout: upper animals stay visually strong, bottom decorative frame also clearly visible. Keep a large quiet dark central region roughly middle 55 percent for future real controls, with botanical decoration remaining near the perimeter. Increase lower decoration enough to balance the top, never fill the entire workspace with detail. Keep all animals and bottom engraved motifs inside the image; no crop of antlers or paws.
Constraints: change ONLY background decoration according to this combination. No UI, buttons, labels, cards, device, title, words, watermark, graph, roads, map/gameplay symbols, items or new game creatures. Preserve 4:3 horizontal composition. Opaque background, no black outer frame or contact sheet.
```
