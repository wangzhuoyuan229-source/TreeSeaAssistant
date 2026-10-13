# 路标原版游戏素材

日期：2026-10-13。已下载 11 张原始 PNG：6 张图集、5 张区域背景；保存 76 个素材映射与 12 种移动加工品的图标/插图配对。原文件未重绘、换色或重新压缩。

文件完整性、SHA-256、实际尺寸、71 个图集矩形边界及加工品/别名映射核验通过，见 [核验报告](../docs/asset-verification.json)。仅代表素材与元数据检查，不表示识别或 App 已运行验收。

来源：[路标黑流树海路线工具](https://www.lubiao.wiki/tools/blackstream-route)。公开资源版本为 `20260921021806`。逐文件原始 URL、SHA-256、字节数、尺寸、图集坐标与别名见 [manifest.json](manifest.json)，逐对象见 [asset-index.md](asset-index.md)。

## 内容与目录

| 原始文件 | 覆盖 |
|---|---|
| [nodes.png](raw/themes/blackstream/atlases/nodes.png) | 29 个节点图标，包括未知节点、险路小径/尽头等原版符号 |
| [products.png](raw/themes/blackstream/atlases/products.png) | 12 个移动加工品小图 |
| [archive-012.png](raw/themes/blackstream/atlases/archive-012.png) | 对应 12 个加工品详情插图 |
| [ui-core.png](raw/themes/blackstream/atlases/ui-core.png) | 行动力与出生点资源 |
| [ui-marks.png](raw/themes/blackstream/atlases/ui-marks.png) | 7 个特殊标记 |
| [ui-effects.png](raw/themes/blackstream/atlases/ui-effects.png) | 2 个效果资源 |
| [区域背景目录](raw/themes/blackstream/backgrounds/) | 第一至第五张原版区域背景，**不是独立区域图标** |

映射分类：节点 29、加工品小图 12、加工品插图 12、特殊标记 7、行动力 1、出生点 8、效果 2、区域背景 5。别名另外记录，不重复算成新图案。

## 在 iOS 中取用

网站使用图集。通过 `assetKey` 查 `assets`：读取 `file`，按 `sprite.x/y/width/height` 的原始像素矩形取用，保留 `sourceWidth/sourceHeight/offsetX/offsetY` 对齐信息；矩形原点为图集左上角。不得把整个图集显示为一个节点，也不得把逻辑点数当作原始像素坐标。

`movementProducts` 已关联规格 M01–M12 与 `iconKey` / `illustrationKey`。界面小图和详情插图分别使用，不能从 AI 概念图提取想象出的加工品。MAA 识别模板另属识别输入，不自动代替展示资源。

节点、加工品、区域、路径和游戏标记使用对应原版图形，保留原色与比例。未知状态用网站对应未知节点图标，通用问号不能替代。未覆盖对象先记录素材缺失并使用文字说明，不能创造图案冒充原版。真实道路根据确认图绘制，路径专用符号取原版；装饰线不能成为道路。

应用图标、背景和通用操作图标见 [自建素材](../自建素材/README.md)。清单如实记录资源清单未声明许可证，不将游戏图片一概标成 MAA 的 AGPL 许可。
