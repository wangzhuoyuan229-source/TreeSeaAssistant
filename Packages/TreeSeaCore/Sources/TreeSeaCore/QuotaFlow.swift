// Bounded circulation and discrete-total enumeration adapted from
// ega0123/hlsh-helper b81965b rules/candidate_filter.py. See Legal/NOTICE.md.
import Foundation
public enum FeasibilityResult: Sendable, Equatable { case possible, impossible, interrupted }
private struct FlowEdge { var to: Int; var capacity: Int }
private struct Dinic {
    var graph: [[Int]]; var edges: [FlowEdge] = []
    var levels: [Int]; var positions: [Int]
    let control: SearchControl
    init(size: Int, control: SearchControl) { graph=Array(repeating:[],count:size); levels=Array(repeating:-1,count:size); positions=Array(repeating:0,count:size); self.control=control }
    mutating func add(_ a: Int, _ b: Int, _ cap: Int) { let index=edges.count; graph[a].append(index); graph[b].append(index+1); edges.append(FlowEdge(to:b,capacity:cap)); edges.append(FlowEdge(to:a,capacity:0)) }
    mutating func send(_ v: Int, _ sink: Int, _ amount: Int) -> Int {
        if control.stopped { return 0 }; if v == sink { return amount }
        while positions[v] < graph[v].count {
            let e=graph[v][positions[v]], t=edges[e].to
            if edges[e].capacity>0 && levels[t] == levels[v]+1 {
                let pushed=send(t,sink,min(amount,edges[e].capacity))
                if pushed>0 { edges[e].capacity -= pushed; edges[e ^ 1].capacity += pushed; return pushed }
            }
            positions[v] += 1
        }
        return 0
    }
    mutating func maxFlow(_ source: Int, _ sink: Int) -> Int {
        var total=0
        while !control.stopped {
            levels=Array(repeating:-1,count:graph.count); levels[source]=0
            var queue=[source],head=0
            while head<queue.count {
                if control.stopped { return total }
                let v=queue[head]; head += 1
                for e in graph[v] where edges[e].capacity>0 && levels[edges[e].to]<0 { levels[edges[e].to]=levels[v]+1; queue.append(edges[e].to) }
            }
            if levels[sink]<0 { return total }
            positions=Array(repeating:0,count:graph.count)
            while !control.stopped { let pushed=send(source,sink,1<<20); if pushed==0 { break }; total += pushed }
        }
        return total
    }
}
public enum QuotaFlow {
    public static func isFeasible(domains: [NodeID:Set<NodeKind>], quotas: [NodeKind:CountRule], knownCounts: [NodeKind:Int], control: SearchControl) -> FeasibilityResult {
        if control.stopped { return .interrupted }
        let kinds=Set(quotas.keys).union(domains.values.flatMap { $0 }).sorted { $0.rawValue < $1.rawValue }
        var bounds: [NodeKind:(Int,Int)]=[:], discrete: [(NodeKind,[Int])]=[]
        for kind in kinds {
            let known=knownCounts[kind,default:0]
            guard known>=0 else { return .impossible }
            if let q=quotas[kind] {
                guard q.maximum>=known else { return .impossible }
                bounds[kind]=(max(0,q.minimum-known),q.maximum-known)
                if case let .discrete(values)=q { discrete.append((kind,values.filter { $0>=known && $0-known<=domains.count }.map { $0-known })) }
            } else { bounds[kind]=(0,domains.count) }
        }
        func enumerate(_ index: Int, _ selected: [NodeKind:(Int,Int)]) -> FeasibilityResult {
            if control.stopped { return .interrupted }
            if index==discrete.count { return bounded(domains:domains,kinds:kinds,bounds:selected,control:control) }
            for value in discrete[index].1 {
                var next=selected; next[discrete[index].0]=(value,value)
                let result=enumerate(index+1,next)
                if result != .impossible { return result }
            }
            return .impossible
        }
        return enumerate(0,bounds)
    }
    private static func bounded(domains: [NodeID:Set<NodeKind>], kinds: [NodeKind], bounds: [NodeKind:(Int,Int)], control: SearchControl) -> FeasibilityResult {
        guard control.check() else { return .interrupted }
        if domains.values.contains(where:{$0.isEmpty}) { return .impossible }
        let nodes=domains.keys.sorted(),source=0,typeOffset=1+domains.count,sink=1+domains.count+kinds.count,superSource=sink+1,superSink=sink+2
        var flow=Dinic(size:superSink+1,control:control), balances=Array(repeating:0,count:superSink+1)
        func addBound(_ a: Int, _ b: Int, _ low: Int, _ high: Int) { flow.add(a,b,high-low); balances[a]-=low; balances[b]+=low }
        let typeVertices=Dictionary(uniqueKeysWithValues:kinds.enumerated().map { ($0.element,typeOffset+$0.offset) })
        for (i,node) in nodes.enumerated() {
            if control.stopped { return .interrupted }
            addBound(source,1+i,1,1)
            for kind in kinds where domains[node]!.contains(kind) { addBound(1+i,typeVertices[kind]!,0,1) }
        }
        for kind in kinds {
            let (low,high)=bounds[kind]!
            if low>high || high<0 { return .impossible }
            addBound(typeVertices[kind]!,sink,low,high)
        }
        addBound(sink,source,0,nodes.count)
        var required=0
        for v in 0..<superSource { if balances[v]>0 { flow.add(superSource,v,balances[v]); required += balances[v] } else if balances[v]<0 { flow.add(v,superSink,-balances[v]) } }
        let obtained=flow.maxFlow(superSource,superSink)
        if control.stopped { return .interrupted }
        return obtained==required ? .possible : .impossible
    }
}
extension PredictionEngine {
    public static func predict(map: FloorMap, rules: RuleCatalog, budget: PredictionBudget = PredictionBudget(), shouldCancel: @escaping () -> Bool = {false}, nowNanoseconds: @escaping () -> UInt64 = Monotonic.nowNanoseconds) -> PredictionResult {
        let control=SearchControl(milliseconds:budget.milliseconds,maxChecks:budget.maxChecks,shouldCancel:shouldCancel,nowNanoseconds:nowNanoseconds)
        var result=local(map:map,rules:rules,control:control)
        guard ![.incomplete,.cancelled,.invalidInput,.conflict].contains(result.propagationStatus) else { return result }
        guard map.originalCoverage == .complete, map.topologyVerified, map.startEvidence == .userConfirmed,
              !map.nodes.contains(where: { $0.originalKind == .unknown || (!$0.originalKind.isHidden && !$0.identityEvidence.confirmed) || $0.originalKind == .unknownMystery && $0.progress == .completed }),
              map.edges.allSatisfy({$0.state != .inferred}) else { result.propagationStatus = .skippedIncompleteCoverage; return result }
        guard rules.order.allSatisfy({ rules.rule($0,floor:map.floor)?.provenance.status.strong == true && rules.rule($0,floor:map.floor)?.count != nil }) else { result.propagationStatus = .skippedUnverifiedRules; return result }
        let independent=result.candidates, counts=knownCounts(map)
        let quotas=Dictionary(uniqueKeysWithValues:rules.order.compactMap { kind -> (NodeKind,CountRule)? in guard let count=rules.rule(kind,floor:map.floor)?.count else {return nil}; return (kind,count) })
        let domains=independent.mapValues { Set($0) }
        let feasible=QuotaFlow.isFeasible(domains:domains,quotas:quotas,knownCounts:counts,control:control)
        if feasible == .impossible { result.propagationStatus = .conflict; result.warnings.append("全图配额冲突，保留独立筛选结果"); return result }
        if feasible == .interrupted { result.propagationStatus=control.cancelled ? .cancelled : .incomplete; return result }
        var reduced=independent
        for node in independent.keys.sorted() {
            var kept: [NodeKind]=[]
            for kind in independent[node]! {
                var fixed=domains; fixed[node]=[kind]
                let value=QuotaFlow.isFeasible(domains:fixed,quotas:quotas,knownCounts:counts,control:control)
                if value == .interrupted { result.propagationStatus=control.cancelled ? .cancelled : .incomplete; return result }
                if value == .possible { kept.append(kind) }
            }
            reduced[node]=kept
        }
        result.candidates=reduced; result.propagationStatus = .complete
        return result
    }
}
