import Foundation
public typealias NodeID = Int
public enum NodeKind: String, Codable, Sendable, CaseIterable {
    case empty, start, exit, unknownMystery, unknownFerocity, unknown
    case strangeShop, secretShop, safeCorner, encounter, wish, lossGain, advance, wonderland, narrowEncounter, emergencyAid, dangerousPath
    case lookout, battle, emergencyBattle, dangerousEnemy, resident, teleport
    public var name: String {
        switch self {
        case .empty: "空地"; case .start: "出生点"; case .exit: "出口"; case .unknownMystery: "未知诡秘"; case .unknownFerocity: "未知凶戾"; case .unknown: "未分类"
        case .strangeShop: "诡意行商"; case .secretShop: "秘境行商"; case .safeCorner: "安全的角落"; case .encounter: "不期而遇"; case .wish: "得偿所愿"; case .lossGain: "失与得"; case .advance: "先行一步"; case .wonderland: "误入奇境"; case .narrowEncounter: "狭路相逢"; case .emergencyAid: "应急助力"; case .dangerousPath: "险路小径"; case .lookout: "羽瞰点"; case .battle: "普通作战"; case .emergencyBattle: "紧急作战"; case .dangerousEnemy: "险路恶敌"; case .resident: "居民据点"; case .teleport: "未知传送"
        }
    }
    public static let mysteryOrder: [Self] = [.strangeShop, .secretShop, .safeCorner, .encounter, .wish, .lossGain, .advance, .wonderland, .narrowEncounter, .emergencyAid, .dangerousPath]
    public var isHidden: Bool { [.unknownMystery, .unknownFerocity, .unknown].contains(self) }
    public var isBattle: Bool { [.battle, .emergencyBattle, .dangerousEnemy, .resident, .unknownFerocity].contains(self) }
}
public enum Evidence: String, Codable, Sendable { case userConfirmed, directObservation, templateInferred, ruleInferred, unresolved
    public var confirmed: Bool { self == .userConfirmed || self == .directObservation }
}
public enum Progress: String, Codable, Sendable { case unopened, opened, completed }
public enum Traversability: String, Codable, Sendable { case available, blocked, unresolved }
public enum BattleScope: String, Codable, Sendable { case unconfirmed, ordinaryConfirmed }
public enum EdgeState: String, Codable, Sendable { case confirmed, inferred, absent }
public enum Coverage: String, Codable, Sendable { case complete, partial }
public struct MapNode: Codable, Sendable, Equatable, Identifiable {
    public var id: NodeID
    public var row: Int
    public var column: Int
    public var observedKind: NodeKind
    public var originalKind: NodeKind
    public var progress: Progress = .unopened
    public var traversability: Traversability = .available
    public var identityEvidence: Evidence = .userConfirmed
    public var traversalEvidence: Evidence = .userConfirmed
    public var battleScope: BattleScope = .unconfirmed
    public var rewardClaimed = false
    public var confirmedAPGain = 0
    public var lookoutRevealCount = 0
    public init(id: NodeID, row: Int, column: Int, kind: NodeKind) {
        self.id = id; self.row = row; self.column = column; self.observedKind = kind; self.originalKind = kind
    }
}
public struct MapEdge: Codable, Sendable, Equatable, Hashable {
    public var a: NodeID; public var b: NodeID; public var state: EdgeState
    public init(_ a: NodeID, _ b: NodeID, state: EdgeState = .confirmed) { self.a = min(a,b); self.b = max(a,b); self.state = state }
}
public struct FloorMap: Codable, Sendable, Equatable {
    public var floor: Int; public var rows: Int; public var columns: Int
    public var nodes: [MapNode]; public var edges: [MapEdge]
    public var initialStartID: NodeID?; public var currentNodeID: NodeID?
    public var exitIDs: Set<NodeID> = []
    public var startEvidence: Evidence = .userConfirmed
    public var originalCoverage: Coverage = .partial
    public var topologyVerified = false
    public var templateID: String?
    public var mapRevision = 0
    public init(floor: Int = 1, rows: Int, columns: Int, nodes: [MapNode], edges: [MapEdge], start: NodeID?) {
        self.floor = floor; self.rows = rows; self.columns = columns; self.nodes = nodes; self.edges = edges; self.initialStartID = start; self.currentNodeID = start
    }
    public func node(_ id: NodeID) -> MapNode? { nodes.first { $0.id == id } }
}
public struct ItemEffects: Codable, Sendable, Equatable {
    public var ap: Int; public var hope: Int; public var ingots: Int
    public init(ap: Int = 0, hope: Int = 0, ingots: Int = 0) { self.ap = ap; self.hope = hope; self.ingots = ingots }
}
public struct ItemInstance: Codable, Sendable, Equatable, Identifiable {
    public var instanceID: UUID; public var typeID: String; public var remainingCharges: Int
    public var evidence: Evidence
    public var confirmedEffects: ItemEffects?
    public var id: UUID { instanceID }
    public init(id: UUID = UUID(), typeID: String, remainingCharges: Int, evidence: Evidence = .userConfirmed, confirmedEffects: ItemEffects? = nil) {
        self.instanceID = id; self.typeID = typeID; self.remainingCharges = remainingCharges; self.evidence = evidence; self.confirmedEffects = confirmedEffects
    }
}
public struct CostOverride: Codable, Sendable, Equatable {
    public var from: NodeID; public var to: NodeID; public var itemInstanceID: UUID?; public var cost: Int
    public init(from: NodeID, to: NodeID, itemInstanceID: UUID? = nil, cost: Int) { self.from=from; self.to=to; self.itemInstanceID=itemInstanceID; self.cost=cost }
}
public struct RunResources: Codable, Sendable, Equatable {
    public var actionPoints: Int
    public var hope: Int?; public var ingots: Int?
    public var items: [ItemInstance] = []
    public var costOverrides: [CostOverride] = []
    public var resourceRevision = 0; public var costRevision = 0
    public init(actionPoints: Int) { self.actionPoints = actionPoints }
}
public struct RevisionStamp: Codable, Sendable, Equatable {
    public var map: Int; public var resource: Int; public var cost: Int; public var goal: Int
    public init(map: Int, resource: Int = 0, cost: Int = 0, goal: Int = 0) { self.map=map; self.resource=resource; self.cost=cost; self.goal=goal }
}
public enum CoreError: Error, Equatable { case invalidMap(String), invalidCatalog(String), invalidAction, invalidInput(String), staleResult }
public enum MapValidator {
    public static func validate(_ map: FloorMap) throws {
        guard (1...5).contains(map.floor), map.rows > 0, map.columns > 0,
              map.rows <= 64, map.columns <= 64, !map.nodes.isEmpty, map.nodes.count <= 64 else { throw CoreError.invalidMap("楼层、网格或节点数超限") }
        let ids = Set(map.nodes.map(\.id))
        guard ids.count == map.nodes.count else { throw CoreError.invalidMap("节点 ID 重复") }
        for node in map.nodes {
            guard (0..<map.rows).contains(node.row), (0..<map.columns).contains(node.column), node.id == node.row * map.columns + node.column,
                  node.confirmedAPGain >= 0, (0...6).contains(node.lookoutRevealCount) else { throw CoreError.invalidMap("节点坐标或增益无效") }
        }
        guard Set(map.edges.map { "\($0.a):\($0.b)" }).count == map.edges.count else { throw CoreError.invalidMap("道路重复") }
        for edge in map.edges {
            guard edge.a != edge.b, ids.contains(edge.a), ids.contains(edge.b) else { throw CoreError.invalidMap("道路端点无效") }
        }
        for id in [map.initialStartID, map.currentNodeID].compactMap({ $0 }) + Array(map.exitIDs) {
            guard ids.contains(id) else { throw CoreError.invalidMap("出生点、当前位置或出口不存在") }
        }
    }
}
