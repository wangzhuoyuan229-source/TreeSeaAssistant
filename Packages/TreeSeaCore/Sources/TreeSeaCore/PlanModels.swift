import Foundation
public struct PlanningSnapshot: Sendable {
    public var map: FloorMap; public var resources: RunResources; public var prediction: PredictionResult
    public var movements: MovementCatalog; public var mustPassNodeIDs: Set<NodeID>; public var goalRevision: Int
    public var ruleVersion: String
    public init(map: FloorMap, resources: RunResources, prediction: PredictionResult, movements: MovementCatalog, mustPassNodeIDs: Set<NodeID> = [], goalRevision: Int = 0, ruleVersion: String? = nil) {
        self.map=map; self.resources=resources; self.prediction=prediction; self.movements=movements; self.mustPassNodeIDs=mustPassNodeIDs; self.goalRevision=goalRevision; self.ruleVersion=ruleVersion ?? prediction.ruleVersion
    }
    public var stamp: RevisionStamp { RevisionStamp(map:map.mapRevision,resource:resources.resourceRevision,cost:resources.costRevision,goal:goalRevision) }
    public func bit(_ id: NodeID) -> UInt64 { guard let index=map.nodes.firstIndex(where:{$0.id==id}),index<64 else { return 0 }; return UInt64(1)<<index }
    public var mandatoryMask: UInt64 { mustPassNodeIDs.reduce(0) { $0 | bit($1) } }
}
public struct PlannerState: Codable, Sendable, Equatable, Hashable {
    public var current: NodeID; public var ap: Int; public var charges: [Int]
    public var opened: UInt64; public var completed: UInt64; public var claimed: UInt64; public var visited: UInt64; public var mandatory: UInt64
    public var hopeDelta: Int = 0; public var ingotDelta: Int = 0
    public init(snapshot: PlanningSnapshot) {
        current=snapshot.map.currentNodeID ?? -1; ap=snapshot.resources.actionPoints; charges=snapshot.resources.items.map(\.remainingCharges)
        opened=0; completed=0; claimed=0; visited=snapshot.bit(current); mandatory=visited & snapshot.mandatoryMask
        for node in snapshot.map.nodes {
            let bit=snapshot.bit(node.id)
            if node.progress != .unopened { opened |= bit }
            if node.progress == .completed { completed |= bit }
            if node.rewardClaimed || node.id == current { claimed |= bit }
        }
    }
    public func terminal(in snapshot: PlanningSnapshot) -> Bool { snapshot.map.exitIDs.contains(current) && mandatory == snapshot.mandatoryMask }
}
public struct MoveAction: Codable, Sendable, Equatable, Hashable {
    public var from: NodeID; public var to: NodeID; public var itemIndex: Int?; public var itemInstanceID: UUID?; public var itemType: String?
    public var cost: Int; public var minimumAPToStart: Int; public var gain: ItemEffects; public var costConfirmed: Bool
    public var walkPath: [NodeID]
    public var isFlight: Bool { itemIndex != nil }
}
public struct ScoreProfile: Codable, Sendable, Equatable {
    public var version = "balanced-items-v0.4"
    public init() { }
}
public struct ScoreDelta: Codable, Sendable, Equatable {
    public var reward: Int; public var apPenalty: Int; public var edgePenalty: Int; public var itemPenalty: Int; public var battlePenalty: Int; public var resourceReward: Int
    public var total: Int { reward - apPenalty - edgePenalty - itemPenalty - battlePenalty + resourceReward }
}
public struct PlanStep: Codable, Sendable, Equatable {
    public var action: MoveAction; public var beforeAP: Int; public var afterAP: Int; public var remainingCharges: Int?; public var score: ScoreDelta; public var assumptions: [String]
}
public enum RoutePreference: String, Codable, Sendable, CaseIterable { case balanced, conserveItems, lowerBattleRisk
    public var name: String { switch self { case .balanced: "综合收益"; case .conserveItems: "节省加工品"; case .lowerBattleRisk: "较低战斗风险" } }
}
public struct RouteRecommendation: Codable, Sendable, Equatable, Identifiable {
    public var signature: String; public var badges: [RoutePreference] = []; public var steps: [PlanStep]
    public var finalState: PlannerState; public var covered: Set<NodeID>; public var scoreUnits: Int
    public var id: String { signature }
    public var grossAP: Int { steps.reduce(0){$0+$1.action.cost} }
    public var itemUses: Int { steps.filter{$0.action.isFlight}.count }
    public var persistentUses: Int { steps.filter{$0.score.itemPenalty==24}.count }
    public var battleRisk: Int { steps.reduce(0){$0+$1.score.battlePenalty} }
}
public enum PlanStatus: String, Codable, Sendable { case feasible, noFeasibleRoute, unresolved, cancelled, invalidInput }
public struct RouteSetResult: Codable, Sendable, Equatable {
    public var stamp: RevisionStamp; public var predictionID: UUID; public var ruleVersion: String; public var movementCatalogVersion: String; public var scoreProfileVersion: String
    public var recommendations: [RouteRecommendation] = []; public var status: PlanStatus
    public var budgetLimited = false; public var heuristicLimited = false; public var expansions = 0; public var labels = 0; public var warnings: [String] = []
    public init(snapshot: PlanningSnapshot, profile: ScoreProfile, status: PlanStatus) { stamp=snapshot.stamp; predictionID=snapshot.prediction.predictionID; ruleVersion=snapshot.ruleVersion; movementCatalogVersion=snapshot.movements.version; scoreProfileVersion=profile.version; self.status=status }
}
public struct PlanningBudget: Sendable {
    public var milliseconds: Int; public var maxExpansions: Int; public var maxLabels: Int
    public init(milliseconds: Int = 300, maxExpansions: Int = 20000, maxLabels: Int = 40000) { self.milliseconds=milliseconds; self.maxExpansions=maxExpansions; self.maxLabels=maxLabels }
}
public struct PlanRequest: Sendable {
    public var snapshot: PlanningSnapshot; public var budget: PlanningBudget; public var maximumRecommendations: Int; public var profile: ScoreProfile
    public init(snapshot: PlanningSnapshot, budget: PlanningBudget = PlanningBudget(), maximumRecommendations: Int = 3, profile: ScoreProfile = ScoreProfile()) { self.snapshot=snapshot; self.budget=budget; self.maximumRecommendations=maximumRecommendations; self.profile=profile }
}
public enum MovementModel { }
public enum RouteScorer { }
