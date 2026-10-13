// MAA deterministic safety concepts: minimum startup/cost requirement,
// resource dominance, memoized semantics and bounded cycle handling.
import Foundation
struct SafetyKey: Hashable {
    var current: NodeID; var charges: [Int]; var opened: UInt64; var completed: UInt64; var claimed: UInt64; var mandatory: UInt64
    init(_ s: PlannerState) { current=s.current; charges=s.charges; opened=s.opened; completed=s.completed; claimed=s.claimed; mandatory=s.mandatory }
}
public enum SafetySolver {
    public static func check(state: PlannerState, snapshot: PlanningSnapshot, control: SearchControl) -> SafetyResult {
        if control.stopped { return SafetyResult(status:.unresolved) }
        if state.terminal(in:snapshot) { return SafetyResult(status:.reachable,minimumRequiredAP:0) }
        // With positive walk costs and no gains, a Dijkstra label proves the exact AP requirement.
        let simple=snapshot.resources.items.isEmpty && snapshot.map.nodes.allSatisfy{$0.confirmedAPGain==0} && snapshot.resources.costOverrides.allSatisfy{$0.cost>0}
        if simple {
            struct WalkKey: Hashable { var node: NodeID; var mandatory: UInt64 }
            var queue: [(PlannerState,Int,[MoveAction])]=[(state,0,[])], best=[WalkKey(node:state.current,mandatory:state.mandatory):0]
            while !queue.isEmpty {
                guard control.expand() else { return SafetyResult(status:.unresolved) }
                queue.sort { $0.1 < $1.1 }
                let (current,cost,path)=queue.removeFirst()
                if current.terminal(in:snapshot) { return SafetyResult(status:state.ap>=cost ? .reachable : .unreachable,minimumRequiredAP:cost,witness:state.ap>=cost ? path : []) }
                var virtual=current; virtual.ap=1_000_000
                for action in MovementModel.actions(from:virtual,in:snapshot,control:control) {
                    guard let next=try? MovementModel.apply(action,to:virtual,in:snapshot) else { continue }
                    let key=WalkKey(node:next.current,mandatory:next.mandatory), total=cost+action.cost
                    if total < best[key,default:Int.max] { guard control.retain() else { return SafetyResult(status:.unresolved) }; best[key]=total; queue.append((next,total,path+[action])) }
                }
            }
            return SafetyResult(status:control.stopped ? .unresolved : .unreachable)
        }
        var queue: [(PlannerState,[MoveAction])]=[(state,[])],head=0,frontier=[SafetyKey(state):state.ap]
        while head<queue.count {
            guard control.expand() else { return SafetyResult(status:.unresolved) }
            let (current,path)=queue[head]; head += 1
            if current.terminal(in:snapshot) { return SafetyResult(status:.reachable,witness:path) }
            for action in MovementModel.actions(from:current,in:snapshot,control:control) {
                guard let next=try? MovementModel.apply(action,to:current,in:snapshot) else { continue }
                let key=SafetyKey(next)
                if next.ap>frontier[key,default:-1] { guard control.retain() else { return SafetyResult(status:.unresolved) }; frontier[key]=next.ap; queue.append((next,path+[action])) }
            }
        }
        return SafetyResult(status:control.stopped ? .unresolved : .unreachable)
    }
}
