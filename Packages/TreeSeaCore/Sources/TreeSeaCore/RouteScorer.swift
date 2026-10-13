import Foundation
extension RouteScorer {
    public static func rewardUnits(_ node: MapNode) -> Int {
        if node.observedKind == .unknownMystery { return 16 }
        guard node.identityEvidence.confirmed else { return 0 }
        return switch node.observedKind {
        case .secretShop: 56; case .strangeShop: 40; case .wish: 32
        case .lookout: 24 + min(6,node.lookoutRevealCount)*4
        case .emergencyAid: 20; case .safeCorner: 16
        case .encounter,.lossGain,.wonderland: 12
        case .advance,.narrowEncounter: 8
        default: 0
        }
    }
    public static func battleUnits(_ node: MapNode) -> Int {
        switch node.observedKind {
        case .unknownFerocity: node.battleScope == .ordinaryConfirmed ? 32 : 0
        case .battle: 16; case .emergencyBattle: 32; case .dangerousEnemy: 48; case .resident: 40
        default: 0
        }
    }
    public static func delta(for action: MoveAction, before: PlannerState, after: PlannerState, in snapshot: PlanningSnapshot, profile: ScoreProfile = ScoreProfile()) -> ScoreDelta {
        let node=snapshot.map.node(action.to)!,first=before.claimed & snapshot.bit(action.to)==0
        let itemPenalty: Int
        if let type=action.itemType,let spec=snapshot.movements.spec(type) { itemPenalty=spec.expiresOnFloorEnd ? 12 : 24 } else { itemPenalty=0 }
        return ScoreDelta(reward:first ? rewardUnits(node) : 0,apPenalty:4*action.cost,edgePenalty:action.isFlight ? 0 : 1,itemPenalty:itemPenalty,battlePenalty:first ? battleUnits(node) : 0,resourceReward:4*action.gain.hope+2*action.gain.ingots)
    }
}
