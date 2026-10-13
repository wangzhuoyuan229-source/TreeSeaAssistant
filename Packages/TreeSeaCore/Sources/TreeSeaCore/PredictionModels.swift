import Foundation
public enum PropagationStatus: String, Codable, Sendable { case localOnly, complete, skippedIncompleteCoverage, skippedUnverifiedRules, conflict, incomplete, cancelled, invalidInput }
public struct CandidateReason: Codable, Sendable, Equatable {
    public var kind: NodeKind; public var explanation: String
    public init(kind: NodeKind, explanation: String) { self.kind=kind; self.explanation=explanation }
}
public struct PredictionResult: Codable, Sendable, Equatable {
    public var predictionID = UUID(); public var mapRevision: Int; public var ruleVersion: String
    public var candidates: [NodeID:[NodeKind]] = [:]
    public var distances: [NodeID:Int] = [:]
    public var exclusions: [NodeID:[CandidateReason]] = [:]
    public var warnings: [String] = []
    public var propagationStatus: PropagationStatus = .localOnly
    public init(mapRevision: Int, ruleVersion: String) { self.mapRevision=mapRevision; self.ruleVersion=ruleVersion }
}
public enum MapGraph {
    public static func distances(from: NodeID, in map: FloorMap) -> [NodeID:Int] { [:] }
}
public enum PredictionEngine {
    public static func localCandidates(map: FloorMap, rules: RuleCatalog) -> PredictionResult { PredictionResult(mapRevision:map.mapRevision,ruleVersion:rules.version) }
}
