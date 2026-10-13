import Foundation
import TreeSeaCore
nonisolated public enum ComputationWorker {
    @concurrent public static func compute(session: MapSession, rules: RuleCatalog, movements: MovementCatalog) async -> (PredictionResult,RouteSetResult) {
        var active=rules;active.version=session.ruleVersion
        if session.reviewedRules {for i in active.rules.indices {active.rules[i].provenance.status = .authorizedReviewed}}
        let prediction=PredictionEngine.predict(map:session.map,rules:active,shouldCancel:{Task.isCancelled})
        let snapshot=PlanningSnapshot(map:session.map,resources:session.resources,prediction:prediction,movements:movements,mustPassNodeIDs:session.mustPass,goalRevision:session.goalRevision,ruleVersion:session.ruleVersion)
        return (prediction,RoutePlanner.plan(PlanRequest(snapshot:snapshot),shouldCancel:{Task.isCancelled}))
    }
}
