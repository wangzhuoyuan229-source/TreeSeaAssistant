# 自建素材与当前选用版本

日期：2026-10-13。已保存 8 张 PNG 和 6 个 SVG。位图使用内置 image_gen 生成/编辑，通用控件直接制作成可编辑 SVG。风格依据 [V2 文档](../docs/ui-design-reference-v2.md) 与 [ui参考图](../ui参考图/)，实际提示词见 [prompts.md](prompts.md)，尺寸、SHA-256、来源路径及透明通道核验见 [manifest.json](manifest.json)。

## 当前选用

- **iPhone 封面**：[动物骨骼版画 v2](backgrounds/iphone-animal-cover-v2.png)，上部鹿与狼版画，下方留出操作区。
- **iPad 封面**：[动物与植物合并 v3](backgrounds/ipad-animal-botanical-cover-v3.png)，上部保留第二版动物骨骼拼贴，下部结合第一版植物边框、紫蓝墨迹与赭金细线，中央深色留白。
- **App 图标**：[第一次生成的三瓣徽记母版 v1](branding/app-icon-master-v1.png)，用户已指定选用；不改用动物图案或透明徽记。
- **普通工作页**：[iPhone 植物背景](backgrounds/iphone-ink-botanical-v1.png) / [iPad 植物背景](backgrounds/ipad-ink-botanical-v1.png)，用于低干扰承托。
- **独立叠加装饰**：[透明动物版画](decoration/deer-wolf-engraving-overlay-v1.png)、[透明应用徽记](branding/app-emblem-overlay-v1.png)。

## 文件表

| 文件 | 实际像素 | 用途与状态 |
|---|---|---|
| [iphone-ink-botanical-v1.png](backgrounds/iphone-ink-botanical-v1.png) | 757×2076 | 安静植物背景，按容器裁切 |
| [ipad-ink-botanical-v1.png](backgrounds/ipad-ink-botanical-v1.png) | 1448×1086 | 初版植物背景，合并版下部参考 |
| [iphone-animal-cover-v2.png](backgrounds/iphone-animal-cover-v2.png) | 851×1847 | iPhone 封面首选 |
| [ipad-animal-cover-v2.png](backgrounds/ipad-animal-cover-v2.png) | 1448×1086 | 第二版保留作修订来源，当前使用 v3 |
| [ipad-animal-botanical-cover-v3.png](backgrounds/ipad-animal-botanical-cover-v3.png) | 1448×1086 | iPad 合并封面首选 |
| [app-icon-master-v1.png](branding/app-icon-master-v1.png) | 1254×1254，RGB | 首次生成的应用图标母版；集成时导出 1024×1024 AppIcon |
| [app-emblem-overlay-v1.png](branding/app-emblem-overlay-v1.png) | 1254×1254，RGBA | 透明徽记，不替代不透明 AppIcon |
| [deer-wolf-engraving-overlay-v1.png](decoration/deer-wolf-engraving-overlay-v1.png) | 1536×1024，RGBA | 透明动物装饰 |

[ui-icons/](ui-icons/) 包含 `add.svg`、`back.svg`、`close.svg`、`confirm.svg`、`settings.svg`、`file-import.svg`，对应添加、返回、关闭、确认、设置、文件导入。统一 24×24 viewBox、1.5 描边、圆形端点、默认骨白色 #E8E5D9、透明背景；实际命中区至少 44×44 pt。集成时也可使用对应通用 SF Symbols。

## 使用规则

动物是原创页面装饰：借鉴自然史骨骼版画、奔跑剪影、紫蓝墨迹和赭金细线，不赋予节点、道具、区域或路线含义。专有游戏对象从 [图标](../图标/README.md) 使用原版资源，不从背景或动物图案中拆出替代图标。

原始尺寸以清单为准，不把提示词建议尺寸当作输出事实。封面保持动物完整；宽高比变化时调整画面位置，必要时使用安静植物底图叠加透明动物版画。iPad 窄窗口使用 iPhone 构图或拆层，不强制横屏。地图、表单和正文另用近实色 `inkSurface` 承托，不能用留白代替可读性验证；系统安全区、动态字号和主要操作必须保留。

动物与植物图层不可点击，不进入 VoiceOver 节点列表；装饰弧线不能连入真实道路。采用静态素材，不持续全屏动效。当前为素材交付，尚未创建 Asset Catalog、App 工程或完成真机性能/界面验收。

## 核验记录

最终文件完整性、SHA-256、尺寸、原件字节一致性、透明 alpha、SVG 结构及选定版本核验通过，见 [核验报告](../docs/asset-verification.json)。

原始生成文件按字节复制到项目，默认生成目录中的原件保留；旧版本与参考图未覆盖。两个透明 PNG 已检查实际 alpha。首次默认预览一度只呈现 App 图标背景；原尺寸读取和像素复核确认图案完整，未重新生成或替换已选图标。动物元素、iPad 下部装饰已目视检查；最终裁切、可读性和设备资源占用仍须 App 集成后核验。

## 2026-10-14 新版集成

当前封面改用 [黑流图谱 v4](backgrounds/blackstream-atlas-cover-v4.png)，AppIcon 改用 [寻路徽记 v2](branding/wayfinder-icon-v2.png)，均由内置 image_gen 生成并保存原件。地图起点使用 [透明旅人 SVG](branding/start-traveler-v2.svg)，根据路标 StartMarker 的人体矢量转录，替代旧方形节点截图。原版地图背景与节点仍使用来源图集。旧图仅作历史资料保留；本节覆盖上文旧版“尚未集成”的历史状态，当前设备验证见 docs/acceptance/report.md。
