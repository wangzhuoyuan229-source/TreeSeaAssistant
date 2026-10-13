import Foundation
public enum RouteSelector {
    static func better(_ a: RouteRecommendation, _ b: RouteRecommendation, preference: RoutePreference) -> Bool {
        let lhs: [Int],rhs: [Int]
        switch preference {
        case .balanced: lhs=[-a.scoreUnits,a.persistentUses,-a.finalState.ap,a.steps.count]; rhs=[-b.scoreUnits,b.persistentUses,-b.finalState.ap,b.steps.count]
        case .conserveItems: lhs=[a.persistentUses,a.itemUses,a.grossAP,-a.scoreUnits]; rhs=[b.persistentUses,b.itemUses,b.grossAP,-b.scoreUnits]
        case .lowerBattleRisk: lhs=[a.battleRisk,a.grossAP,a.persistentUses,-a.scoreUnits]; rhs=[b.battleRisk,b.grossAP,b.persistentUses,-b.scoreUnits]
        }
        if lhs != rhs { return lhs.lexicographicallyPrecedes(rhs) }
        let idsA=a.steps.map(\.action.to),idsB=b.steps.map(\.action.to)
        if idsA != idsB { return idsA.lexicographicallyPrecedes(idsB) }
        return a.signature < b.signature
    }
    public static func select(_ candidates: [RouteRecommendation], maximum: Int = 3) -> [RouteRecommendation] {
        let limit=max(0,min(3,maximum)); if limit==0 { return [] }
        var unique: [String:RouteRecommendation]=[:]
        for candidate in candidates {
            if let old=unique[candidate.signature], !better(candidate,old,preference:.balanced) { continue }
            unique[candidate.signature]=candidate
        }
        let pool=Array(unique.values)
        var selected: [RouteRecommendation]=[]
        for preference in RoutePreference.allCases {
            guard let best=pool.sorted(by:{better($0,$1,preference:preference)}).first else { continue }
            if let index=selected.firstIndex(where:{$0.signature==best.signature}) { selected[index].badges.append(preference) }
            else if selected.count<limit { var route=best; route.badges=[preference]; selected.append(route) }
        }
        for candidate in pool.sorted(by:{better($0,$1,preference:.balanced)}) where selected.count<limit && !selected.contains(where:{$0.signature==candidate.signature}) { selected.append(candidate) }
        return selected
    }
    static func signature(steps: [PlanStep], snapshot: PlanningSnapshot) -> String {
        var parts: [String]=[],seen=Set([snapshot.map.currentNodeID].compactMap{$0})
        for step in steps {
            let target=step.action.to
            if let item=step.action.itemType { parts.append("\(item):\(step.action.from)>\(target)") }
            if let node=snapshot.map.node(target), (node.observedKind != .empty && node.observedKind != .start) || snapshot.mustPassNodeIDs.contains(target) || snapshot.map.exitIDs.contains(target) {
                if seen.insert(target).inserted { parts.append("N\(target)") }
            }
        }
        return parts.joined(separator:"|")
    }
}
