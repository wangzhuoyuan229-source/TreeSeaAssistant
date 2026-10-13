import Foundation
extension MapGraph {
    static func bfs(from: NodeID, in map: FloorMap, control: SearchControl?) -> [NodeID:Int] {
        guard map.node(from) != nil else { return [:] }
        var adjacency: [NodeID:[NodeID]] = [:]
        for edge in map.edges where edge.state != .absent { adjacency[edge.a,default:[]].append(edge.b); adjacency[edge.b,default:[]].append(edge.a) }
        var distances=[from:0], queue=[from], head=0
        while head < queue.count {
            if control?.stopped == true { return [:] }
            let id=queue[head]; head += 1
            for next in (adjacency[id] ?? []).sorted() where distances[next] == nil {
                distances[next] = distances[id]! + 1; queue.append(next)
            }
        }
        return distances
    }
}
public enum Monotonic {
    public static func nowNanoseconds() -> UInt64 { UInt64(ProcessInfo.processInfo.systemUptime * 1_000_000_000) }
}
public struct PredictionBudget: Sendable {
    public var milliseconds: Int; public var maxChecks: Int
    public init(milliseconds: Int = 100, maxChecks: Int = 1000) { self.milliseconds=milliseconds; self.maxChecks=maxChecks }
}
public final class SearchControl {
    let start: UInt64; let duration: UInt64
    let now: () -> UInt64; let shouldCancel: () -> Bool
    let maxChecks: Int; let maxExpansions: Int; let maxLabels: Int
    public private(set) var checks = 0; public private(set) var expansions = 0; public private(set) var labels = 0
    public private(set) var budgetLimited = false
    var phaseDeadline: UInt64?
    var phaseLimited = false
    public var cancelled: Bool { shouldCancel() }
    public var stopped: Bool {
        if cancelled { return true }
        let t=now(); if t >= start && t-start >= duration { budgetLimited=true; return true }
        if let phaseDeadline, t >= phaseDeadline { phaseLimited=true; return true }
        return budgetLimited
    }
    public init(milliseconds: Int = 100, maxChecks: Int = 1000, maxExpansions: Int = 20000, maxLabels: Int = 40000, shouldCancel: @escaping () -> Bool = {false}, nowNanoseconds: @escaping () -> UInt64 = Monotonic.nowNanoseconds) {
        self.now=nowNanoseconds; self.shouldCancel=shouldCancel; self.start=nowNanoseconds(); self.duration=UInt64(max(0,min(milliseconds,60_000))) * 1_000_000
        self.maxChecks=max(0,maxChecks); self.maxExpansions=max(0,maxExpansions); self.maxLabels=max(0,maxLabels)
    }
    func check() -> Bool { guard !stopped, checks < maxChecks else { budgetLimited=true; return false }; checks += 1; return true }
    func expand() -> Bool { guard !stopped, expansions < maxExpansions else { budgetLimited=true; return false }; expansions += 1; return true }
    func retain() -> Bool { guard !stopped, labels < maxLabels else { budgetLimited=true; return false }; labels += 1; return true }
    func beginPhase(milliseconds: Int) { phaseDeadline=now()+UInt64(max(0,milliseconds))*1_000_000; phaseLimited=false }
    func endPhase() { phaseDeadline=nil }
}
