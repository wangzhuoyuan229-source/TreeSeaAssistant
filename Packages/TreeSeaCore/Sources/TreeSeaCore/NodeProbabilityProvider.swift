/// Context for a future statistics provider. A missing distance means the
/// birth-point distance has not been confirmed. Revisions identify stale results.
public struct NodeProbabilityContext: Sendable, Equatable {
    public let nodeID: NodeID
    public let floor: Int
    public let distanceFromStart: Int?
    public let candidates: [NodeKind]
    public let mapRevision: Int
    public let ruleVersion: String
    public init(nodeID: NodeID, floor: Int, distanceFromStart: Int?, candidates: [NodeKind], mapRevision: Int, ruleVersion: String) {
        self.nodeID=nodeID; self.floor=floor; self.distanceFromStart=distanceFromStart
        self.candidates=candidates; self.mapRevision=mapRevision; self.ruleVersion=ruleVersion
    }
}
/// A provider must return only probabilities supported by imported statistics,
/// with their source and dataset version, for the unchanged request context.
public struct NodeProbabilityResult: Sendable, Equatable {
    public let context: NodeProbabilityContext
    public let sourceURL: String
    public let dataVersion: String
    public let probabilities: [NodeKind:Double]
    public init(context: NodeProbabilityContext, sourceURL: String, dataVersion: String, probabilities: [NodeKind:Double]) {
        self.context=context; self.sourceURL=sourceURL; self.dataVersion=dataVersion; self.probabilities=probabilities
    }
}
/// Reserved integration point; no provider or dataset is currently installed.
/// Return nil when imported data does not support the context; never invent a
/// uniform prior or substitute another statistic for node identity probability.
public protocol NodeProbabilityProvider: Sendable {
    func probabilities(for context: NodeProbabilityContext) throws -> NodeProbabilityResult?
}
