# 独立审查与修复

审查范围 cadbec0 → 752f95f；只读独立 reviewer。随后的一次修复回合用失败回归 → 修复 → 全套测试验证，不以审查口头结论替代执行证据。

| 审查发现 | 修复 | 验证 |
|---|---|---|
| P1 部分截图删除旧节点、完成空地覆盖商店原始身份 | 同格局部分覆盖事务合并；未覆盖节点/道路保留；完成节点默认保留原始身份、领奖与增益，显式原始身份更正另记 | partialCropPreservesUnseenNodesAndCompletedOriginalIdentity，失败后通过 |
| P2 非相邻徒步实际成本未参与 | confirmed 道路 BFS 产生 walkPath；不能穿越未进入内容；按整个动作起止应用预览覆盖；必经更新所有实际经过格 | actualNonAdjacentWalkCostCoversIntermediateMustPass，失败后通过 |
| P2 空候选/冲突未知被当可执行 | 排除受影响未知；已确认绕行可保留并解释限制 | inconsistentUnknownCannotBeMadeExecutable，失败后通过 |
| P2 部分库存清空已确认效果 | 缺失效果保持原值；显式取消确认才清除 | partialInventoryDoesNotEraseConfirmedEffects，失败后通过 |
| P2 一张图保存部分项后其余项被去重跳过 | digest + 原图槽位 observation key 去重；记录对应实例；允许同图未处理项继续核对 | sameImageCanConfirmDifferentItemsButCannotDuplicateSameObservation，失败后通过 |
| P2 完整替换时过滤未确认条目 | 完整替换保留整个提案并验证所有条目及观测数量；部分确认只合并 | incompleteFullReplacementRejectedAtomically，补充过滤子集失败后通过 |

按实际使用后果将以下页面风险提升为本回合修复：切换楼层取消并清理提案；路线详情携带原结果 stamp/predictionID、过期标记并禁用作为当前路线；NavigationStack 使用外层持久 NavigationPath，布局变化不销毁路径。这些 UI 行为仍待真实 iPhone/iPad 自动化和人工验收。

宿主 SwiftUI 类型诊断另外发现并修复 catch 中的 error 遮蔽（改为 self.error）和裁剪四个属性共用一个 State wrapper（改为四个 State）。诊断使用已有 State wrapper 别名绕开 CLT 缺 SwiftUIMacros，并替换 UIKit/键盘/Size Class 平台 API，因此不能当 iOS 构建通过。实际诊断通过，来源与转换见 scripts/typecheck-ui-diagnostic.py。

未执行二次审查；后续以回归测试与整套运行记录验证。本轮没有以注释、禁用测试或降低断言掩盖失败。

补充回归：预算未求得保留最近有效路线，并单独记录当前失败状态（unresolvedAttemptPreservesLastValidRoute，失败后通过）；全局剔除附排除原因、未确认类别不强排除；60ms 安全阶段到期仍继续搜索、结果收尾检查总截止时间。

会话恢复补充：损坏文件与有效文件并存时，保留原坏文件、返回有效会话并单独报告损坏数量，避免损坏记录使列表与后续保存反复失败（corruptSessionDoesNotHideOtherValidSessions，失败后通过）。
