import Foundation
public enum SafetyStatus: String, Sendable { case reachable, unreachable, unresolved }
public struct SafetyResult: Sendable { public var status: SafetyStatus; public var minimumRequiredAP: Int?; public var witness: [MoveAction] = [] }
private struct PlanLabel {
    var state: PlannerState; var steps: [PlanStep]; var score: Int; var upper: Int
    var gross: Int; var items: Int; var persistent: Int; var risk: Int; var signature: String
}
private struct LabelHeap {
    var values: [PlanLabel]=[]; var mode: RoutePreference
    func better(_ a: PlanLabel, _ b: PlanLabel) -> Bool {
        let lhs: [Int],rhs: [Int]
        switch mode {
        case .balanced: lhs=[-a.upper,-a.score,a.persistent,a.gross]; rhs=[-b.upper,-b.score,b.persistent,b.gross]
        case .conserveItems: lhs=[a.persistent,a.items,a.gross,-a.upper]; rhs=[b.persistent,b.items,b.gross,-b.upper]
        case .lowerBattleRisk: lhs=[a.risk,a.gross,a.persistent,-a.upper]; rhs=[b.risk,b.gross,b.persistent,-b.upper]
        }
        if lhs != rhs { return lhs.lexicographicallyPrecedes(rhs) }
        return a.signature < b.signature
    }
    mutating func push(_ value: PlanLabel) { values.append(value); var i=values.count-1; while i>0 { let p=(i-1)/2; if !better(values[i],values[p]) {break}; values.swapAt(i,p); i=p } }
    mutating func pop() -> PlanLabel? {
        guard !values.isEmpty else {return nil}; if values.count==1 {return values.removeLast()}
        let best=values[0]; values[0]=values.removeLast(); var i=0
        while i*2+1<values.count { var child=i*2+1; if child+1<values.count && better(values[child+1],values[child]) {child += 1}; if !better(values[child],values[i]) {break}; values.swapAt(i,child); i=child }
        return best
    }
}
private struct DiversityKey: Hashable { var state: SafetyKey; var signature: String }
public enum RoutePlanner {
    private static func validate(_ s: PlanningSnapshot) throws {
        try MapValidator.validate(s.map)
        guard !s.map.exitIDs.isEmpty, let current=s.map.currentNodeID, s.map.node(current) != nil,
              s.map.node(current)?.traversalEvidence.confirmed == true, s.map.exitIDs.allSatisfy({s.map.node($0)?.identityEvidence.confirmed == true}),
              s.mustPassNodeIDs.count<=8, s.mustPassNodeIDs.allSatisfy({s.map.node($0) != nil}),
              (0...1000).contains(s.resources.actionPoints), s.resources.items.count<=64,
              Set(s.resources.items.map(\.instanceID)).count==s.resources.items.count,
              s.resources.items.allSatisfy({(0...100).contains($0.remainingCharges) && s.movements.spec($0.typeID) != nil}),
              s.resources.costOverrides.allSatisfy({ (0...1000).contains($0.cost) && s.map.node($0.from) != nil && s.map.node($0.to) != nil }),
              s.prediction.mapRevision==s.map.mapRevision, s.prediction.ruleVersion==s.ruleVersion,
              ![.cancelled,.invalidInput,.incomplete].contains(s.prediction.propagationStatus) else { throw CoreError.invalidInput("地图、资源、必经条件或候选版本无效") }
    }
    private static func upper(state: PlannerState, score: Int, snapshot: PlanningSnapshot) -> Int {
        var result=score
        for node in snapshot.map.nodes where state.claimed & snapshot.bit(node.id)==0 { result += RouteScorer.rewardUnits(node) }
        for (i,item) in snapshot.resources.items.enumerated() {
            if let effects=item.confirmedEffects { result += state.charges[i] * (effects.hope*4+effects.ingots*2) }
        }
        return result
    }
    private static func append(_ action: MoveAction, to label: PlanLabel, snapshot: PlanningSnapshot, profile: ScoreProfile) -> PlanLabel? {
        guard let after=try? MovementModel.apply(action,to:label.state,in:snapshot) else {return nil}
        let delta=RouteScorer.delta(for:action,before:label.state,after:after,in:snapshot,profile:profile)
        var assumptions: [String]=[]
        if !action.costConfirmed { assumptions.append("AP 消耗采用目录/徒步默认估计") }
        if snapshot.map.node(action.to)?.observedKind.isHidden == true { assumptions.append("未知内容完成后可继续移动，事件副作用未建模") }
        let step=PlanStep(action:action,beforeAP:label.state.ap,afterAP:after.ap,remainingCharges:action.itemIndex.map{after.charges[$0]},score:delta,assumptions:assumptions)
        let steps=label.steps+[step],score=label.score+delta.total
        return PlanLabel(state:after,steps:steps,score:score,upper:upper(state:after,score:score,snapshot:snapshot),gross:label.gross+action.cost,items:label.items+(action.isFlight ? 1 : 0),persistent:label.persistent+(delta.itemPenalty==24 ? 1 : 0),risk:label.risk+delta.battlePenalty,signature:RouteSelector.signature(steps:steps,snapshot:snapshot))
    }
    private static func route(_ label: PlanLabel, snapshot: PlanningSnapshot) -> RouteRecommendation {
        RouteRecommendation(signature:label.signature,steps:label.steps,finalState:label.state,covered:snapshot.mustPassNodeIDs.filter{label.state.mandatory & snapshot.bit($0) != 0},scoreUnits:label.score)
    }
    public static func plan(_ request: PlanRequest, shouldCancel: @escaping () -> Bool = {false}, nowNanoseconds: @escaping () -> UInt64 = Monotonic.nowNanoseconds) -> RouteSetResult {
        let s=request.snapshot,control=SearchControl(milliseconds:request.budget.milliseconds,maxChecks:Int.max,maxExpansions:request.budget.maxExpansions,maxLabels:request.budget.maxLabels,shouldCancel:shouldCancel,nowNanoseconds:nowNanoseconds)
        var result=RouteSetResult(snapshot:s,profile:request.profile,status:.unresolved)
        if control.cancelled { result.status = .cancelled; return result }
        do {try validate(s)} catch {result.status = .invalidInput;result.warnings=["请确认出口、节点、AP、库存和当前候选版本"];return result}
        let initialState=PlannerState(snapshot:s)
        let seed=PlanLabel(state:initialState,steps:[],score:0,upper:upper(state:initialState,score:0,snapshot:s),gross:0,items:0,persistent:0,risk:0,signature:"")
        var pool: [RouteRecommendation]=[]
        control.beginPhase(milliseconds:60)
        let safety=SafetySolver.check(state:initialState,snapshot:s,control:control)
        control.endPhase()
        if safety.status == .unreachable { result.status = .noFeasibleRoute; result.expansions=control.expansions; result.labels=control.labels; return result }
        if safety.status == .reachable {
            var label=seed
            for a in safety.witness { if let next=append(a,to:label,snapshot:s,profile:request.profile) {label=next} }
            if label.state.terminal(in:s) {pool.append(route(label,snapshot:s))}
        }
        var queues=RoutePreference.allCases.map{LabelHeap(mode:$0)},frontiers=Array(repeating:[DiversityKey:[PlanLabel]](),count:3)
        for i in queues.indices { if control.retain() { queues[i].push(seed) } }
        var mode=0
        while queues.contains(where:{!$0.values.isEmpty}) && !control.stopped {
            let i=mode%3; mode += 1
            guard let label=queues[i].pop() else {continue}
            guard control.expand() else {break}
            if label.state.terminal(in:s) {
                let candidate=route(label,snapshot:s)
                if let old=pool.firstIndex(where:{$0.signature==candidate.signature}) { if RouteSelector.better(candidate,pool[old],preference:.balanced) {pool[old]=candidate} }
                else { pool.append(candidate) }
                if pool.count>32 {
                    // Keep all preference winners, then the strongest balanced alternatives.
                    let winners=RouteSelector.select(pool,maximum:3),keys=Set(winners.map(\.signature))
                    pool=winners+pool.filter{!keys.contains($0.signature)}.sorted{RouteSelector.better($0,$1,preference:.balanced)}.prefix(32-winners.count)
                    result.heuristicLimited=true
                }
                continue
            }
            // A proof upper bound may prune only when the bounded pool is full.
            if pool.count==32, queues[i].mode == .balanced, let worst=pool.map(\.scoreUnits).min(), label.upper<worst { continue }
            for action in MovementModel.actions(from:label.state,in:s,control:control) {
                if control.stopped {break}
                guard let next=append(action,to:label,snapshot:s,profile:request.profile) else {continue}
                let key=DiversityKey(state:SafetyKey(next.state),signature:next.signature)
                var frontier=frontiers[i][key,default:[]]
                if frontier.contains(where:{$0.state.ap>=next.state.ap && $0.score>=next.score && $0.gross<=next.gross && $0.risk<=next.risk && $0.persistent<=next.persistent && $0.items<=next.items}) {continue}
                frontier.removeAll { next.state.ap >= $0.state.ap && next.score >= $0.score && next.gross <= $0.gross && next.risk <= $0.risk && next.persistent <= $0.persistent && next.items <= $0.items }
                if frontier.count>=3 {result.heuristicLimited=true;continue}
                guard control.retain() else {break}
                frontier.append(next); frontiers[i][key]=frontier; queues[i].push(next)
            }
        }
        result.expansions=control.expansions; result.labels=control.labels; result.budgetLimited=control.budgetLimited
        if control.cancelled {result.status = .cancelled;return result}
        result.recommendations=RouteSelector.select(pool,maximum:request.maximumRecommendations)
        result.status = !result.recommendations.isEmpty ? .feasible : (result.budgetLimited || result.heuristicLimited ? .unresolved : .noFeasibleRoute)
        if result.budgetLimited {result.warnings.append("共享预算已用尽；未声称全局最优")}
        if result.heuristicLimited {result.warnings.append("候选池或前缀保留已截断")}
        if s.map.edges.contains(where:{$0.state == .inferred}) {result.warnings.append("推断道路未用于可执行徒步步骤")}
        return result
    }
}
