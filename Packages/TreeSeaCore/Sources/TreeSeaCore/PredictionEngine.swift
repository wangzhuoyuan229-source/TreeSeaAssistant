import Foundation
extension PredictionEngine {
    static func knownCounts(_ map: FloorMap) -> [NodeKind:Int] {
        var counts: [NodeKind:Int]=[:]
        for node in map.nodes where node.identityEvidence.confirmed && !node.originalKind.isHidden { counts[node.originalKind,default:0] += 1 }
        return counts
    }
    static func local(map: FloorMap, rules: RuleCatalog, control: SearchControl?) -> PredictionResult {
        var result=PredictionResult(mapRevision:map.mapRevision,ruleVersion:rules.version)
        do { try MapValidator.validate(map) } catch { result.propagationStatus = .invalidInput; result.warnings=["地图结构无效，请修正"]; return result }
        guard control?.stopped != true else { result.propagationStatus = control?.cancelled == true ? .cancelled : .incomplete; return result }
        let reliable=map.topologyVerified && map.startEvidence == .userConfirmed && map.initialStartID != nil && map.edges.allSatisfy { $0.state != .inferred }
        if reliable, let start=map.initialStartID { result.distances=MapGraph.bfs(from:start,in:map,control:control) }
        if !reliable { result.warnings.append("出生点或拓扑未完整确认，跳过距离排除") }
        let counts=knownCounts(map)
        for kind in rules.order {
            if let rule=rules.rule(kind,floor:map.floor), rule.provenance.status.strong, let maximum=rule.count?.maximum, counts[kind,default:0] > maximum { result.warnings.append("\(kind.name)已出现数量超过参考上限"); result.propagationStatus = .conflict }
        }
        if rules.rules.contains(where: { $0.floor == map.floor && !$0.provenance.status.strong }) { result.warnings.append("参考规则未独立核对，保留候选并跳过对应约束") }
        for node in map.nodes.sorted(by:{$0.id<$1.id}) where node.originalKind == .unknownMystery {
            if control?.stopped == true { result.candidates=[:]; result.exclusions=[:]; result.propagationStatus=control?.cancelled == true ? .cancelled : .incomplete; return result }
            if !node.identityEvidence.confirmed {result.candidates[node.id]=rules.order;result.warnings.append("N\(node.id) 的未知类别尚未确认，跳过局部强排除");continue}
            var retained: [NodeKind]=[], reasons: [CandidateReason]=[]
            for kind in rules.order {
                guard let rule=rules.rule(kind,floor:map.floor), rule.provenance.status.strong else { retained.append(kind); continue }
                var reason: String?
                if let distanceRule=rule.distance {
                    if distanceRule == .forbidden { reason="该层参考规则禁止生成" }
                    else if let d=result.distances[node.id], !distanceRule.allows(d) { reason="出生点图距离 \(d) 不在允许范围" }
                }
                if let maxCount=rule.count?.maximum, counts[kind,default:0]>=maxCount { reason="已出现 \(counts[kind,default:0])，达到数量上限 \(maxCount)" }
                if let reason { reasons.append(CandidateReason(kind:kind,explanation:reason+"（\(rules.version)）")) } else { retained.append(kind) }
            }
            result.candidates[node.id]=retained; result.exclusions[node.id]=reasons
        }
        if map.nodes.contains(where:{$0.originalKind == .unknownFerocity}) { result.warnings.append("未知凶戾待揭示，不计算类型候选") }
        return result
    }
}
