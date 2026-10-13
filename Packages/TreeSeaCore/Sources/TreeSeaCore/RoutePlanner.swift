import Foundation
public enum SafetyStatus: String, Sendable { case reachable, unreachable, unresolved }
public struct SafetyResult: Sendable { public var status: SafetyStatus; public var minimumRequiredAP: Int?; public var witness: [MoveAction] = [] }
public enum SafetySolver {
    public static func check(state: PlannerState, snapshot: PlanningSnapshot, control: SearchControl) -> SafetyResult { SafetyResult(status:.unreachable) }
}
public enum RoutePlanner {
    public static func plan(_ request: PlanRequest, shouldCancel: @escaping () -> Bool = {false}, nowNanoseconds: @escaping () -> UInt64 = Monotonic.nowNanoseconds) -> RouteSetResult { RouteSetResult(snapshot:request.snapshot,profile:request.profile,status:.noFeasibleRoute) }
}
public enum RouteSelector {
    public static func select(_ candidates: [RouteRecommendation], maximum: Int = 3) -> [RouteRecommendation] { Array(candidates.prefix(maximum)) }
}
