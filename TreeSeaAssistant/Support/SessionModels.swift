import Foundation
import TreeSeaCore
nonisolated public struct MapSession: Codable, Sendable, Equatable, Identifiable {
    public var id = UUID(); public var title: String; public var updatedAt = Date()
    public var map: FloorMap; public var resources: RunResources
    public var mustPass: Set<NodeID> = []; public var goalRevision = 0
    public var prediction: PredictionResult?; public var routes: RouteSetResult?
    public var latestPlanningFailure: RouteSetResult?
    public var ruleVersion: String; public var movementVersion: String; public var scoreVersion = "balanced-items-v0.4"
    public var reviewedRules = false; public var importedDigests: Set<String> = []
    public var processedInventoryObservations: [String:UUID] = [:]
    public init(title: String, map: FloorMap, resources: RunResources, ruleVersion: String, movementVersion: String) { self.title=title;self.map=map;self.resources=resources;self.ruleVersion=ruleVersion;self.movementVersion=movementVersion }
    public var stamp: RevisionStamp { RevisionStamp(map:map.mapRevision,resource:resources.resourceRevision,cost:resources.costRevision,goal:goalRevision) }
    public var predictionIsCurrent: Bool { prediction?.mapRevision==map.mapRevision && prediction?.ruleVersion==ruleVersion }
    public var routesAreCurrent: Bool { routes?.stamp==stamp && routes?.predictionID==prediction?.predictionID && predictionIsCurrent && routes?.ruleVersion==ruleVersion && routes?.movementCatalogVersion==movementVersion && routes?.scoreProfileVersion==scoreVersion }
}
nonisolated public enum SessionEdit {
    case node(MapNode), map(FloorMap), actionPoints(Int), items([ItemInstance]), cost(CostOverride), goals(Set<NodeID>), reviewedRules(Bool)
}
nonisolated public struct RecognitionProposal: Sendable {
    public var map: FloorMap?; public var warnings: [String]; public var confirmed = false
    public var originalIdentityCorrections: Set<NodeID> = []
    public init(map: FloorMap?, warnings: [String] = []) { self.map=map;self.warnings=warnings }
}
nonisolated public enum InventoryObservationCoverage: String, Codable, Sendable { case partial, complete, detail, loadedOnly }
nonisolated public struct InventoryEntry: Codable, Sendable, Equatable, Identifiable {
    public var id = UUID(); public var typeID: String; public var remainingCharges: Int?
    public var existingID: UUID?; public var newInstanceConfirmed = false
    public var effects: ItemEffects?; public var confirmed = false; public var warning: String?
    public var observationKey: String?
    public var clearEffectsConfirmed = false
    public init(typeID: String, remainingCharges: Int?, effects: ItemEffects? = nil) { self.typeID=typeID;self.remainingCharges=remainingCharges;self.effects=effects }
}
nonisolated public struct InventoryProposal: Codable, Sendable, Equatable {
    public var digest: String; public var coverage: InventoryObservationCoverage; public var entries: [InventoryEntry]; public var warnings: [String]
    public var observedEntryCount: Int
    public init(digest: String, coverage: InventoryObservationCoverage = .partial, entries: [InventoryEntry], warnings: [String] = []) { self.digest=digest;self.coverage=coverage;self.entries=entries;self.warnings=warnings;self.observedEntryCount=entries.count }
}
nonisolated public struct MovementPreviewProposal: Sendable {
    public var target: NodeID?; public var from: NodeID?; public var itemInstanceID: UUID?; public var cost: Int?; public var confirmed = false
    public init(from: NodeID?, target: NodeID?, itemInstanceID: UUID? = nil, cost: Int?) { self.from=from;self.target=target;self.itemInstanceID=itemInstanceID;self.cost=cost }
}
nonisolated public enum SessionError: Error, Equatable { case stale, unconfirmed, ambiguousInventory, invalidInput, corruptSession }
