// Deterministic movement subset adapted from MAA BlackFlowModel/CompactStateSpace,
// fixed commit 59bd4ce. User confirmation replaces automatic game execution.
import Foundation
extension MovementModel {
    static func legalTarget(_ node: MapNode, in snapshot: PlanningSnapshot) -> Bool {
        if node.observedKind == .unknownMystery && (snapshot.prediction.propagationStatus == .conflict || snapshot.prediction.candidates[node.id]?.isEmpty == true) {return false}
        guard node.traversability == .available, node.traversalEvidence.confirmed else { return false }
        if node.observedKind == .unknownFerocity && node.battleScope != .ordinaryConfirmed { return false }
        return node.observedKind != .unknown && node.observedKind != .teleport
    }
    static func makeAction(from state: PlannerState, to target: MapNode, itemIndex: Int?, path: [NodeID]? = nil, in snapshot: PlanningSnapshot) -> MoveAction? {
        guard state.current != target.id, legalTarget(target,in:snapshot), let source=snapshot.map.node(state.current), state.charges.count == snapshot.resources.items.count else { return nil }
        var cost=1,minimum=1,effects=ItemEffects(),typeID: String?,instanceID: UUID?
        if let i=itemIndex {
            guard snapshot.resources.items.indices.contains(i), state.charges[i]>0 else { return nil }
            let item=snapshot.resources.items[i]
            guard item.evidence == .userConfirmed, let spec=snapshot.movements.spec(item.typeID), !spec.randomTarget else { return nil }
            let dr=abs(source.row-target.row),dc=abs(source.column-target.column)
            let validRange: Bool = switch spec.range {
            case .orthogonalTwo: (dr==0 || dc==0) && dr+dc<=2
            case .surroundingEight: max(dr,dc)==1
            case .manhattanTwo: dr+dc<=2
            case .orthogonalThree: (dr==0 || dc==0) && dr+dc<=3
            case .fullMap: true
            }
            guard validRange else { return nil }
            if spec.targetFilter == .shop { guard target.identityEvidence.confirmed, [.strangeShop,.secretShop].contains(target.observedKind) else { return nil } }
            if spec.targetFilter == .nonCombat { guard target.identityEvidence.confirmed, !target.observedKind.isHidden, !target.observedKind.isBattle else { return nil } }
            cost=spec.apCost; minimum=spec.minimumAPToStart
            effects=item.confirmedEffects ?? ItemEffects(); typeID=item.typeID; instanceID=item.instanceID
        } else {
            guard let path,path.count>=2,path.first==state.current,path.last==target.id,Set(path).count==path.count else {return nil}
            for i in 1..<path.count {
                guard snapshot.map.edges.contains(MapEdge(path[i-1],path[i],state:.confirmed)),let node=snapshot.map.node(path[i]),legalTarget(node,in:snapshot) else {return nil}
                if i<path.count-1 && !canPass(node,state:state,snapshot:snapshot) {return nil}
            }
            cost=path.count-1
        }
        let override=snapshot.resources.costOverrides.first { $0.from==state.current && $0.to==target.id && $0.itemInstanceID==instanceID }
        if let override { cost=override.cost }
        guard (0...1000).contains(cost), (0...1000).contains(minimum), state.ap>=max(minimum,cost), [effects.ap,effects.hope,effects.ingots].allSatisfy({(0...1000).contains($0)}) else { return nil }
        return MoveAction(from:state.current,to:target.id,itemIndex:itemIndex,itemInstanceID:instanceID,itemType:typeID,cost:cost,minimumAPToStart:minimum,gain:effects,costConfirmed:override != nil,walkPath:itemIndex == nil ? (path ?? []) : [state.current,target.id])
    }
    private static func canPass(_ node:MapNode,state:PlannerState,snapshot:PlanningSnapshot) -> Bool {
        !snapshot.map.exitIDs.contains(node.id) && (node.observedKind == .empty || node.observedKind == .start || state.completed & snapshot.bit(node.id) != 0)
    }
    private static func walkPaths(from state:PlannerState,in snapshot:PlanningSnapshot,control:SearchControl) -> [NodeID:[NodeID]] {
        var paths=[state.current:[state.current]],queue=[state.current],head=0
        while head<queue.count {
            if control.stopped {return [:]}
            let id=queue[head];head += 1
            let neighbors=snapshot.map.edges.filter{$0.state == .confirmed && ($0.a==id || $0.b==id)}.map{$0.a==id ? $0.b : $0.a}.sorted()
            for next in neighbors where paths[next]==nil {
                guard let node=snapshot.map.node(next),legalTarget(node,in:snapshot) else {continue}
                paths[next]=paths[id]!+[next]
                if canPass(node,state:state,snapshot:snapshot) {queue.append(next)}
            }
        }
        paths[state.current]=nil
        return paths
    }
    public static func actions(from state: PlannerState, in snapshot: PlanningSnapshot, control: SearchControl) -> [MoveAction] {
        guard !snapshot.map.exitIDs.contains(state.current), !control.stopped else { return [] }
        var actions: [MoveAction]=[]
        let paths=walkPaths(from:state,in:snapshot,control:control)
        for node in snapshot.map.nodes.sorted(by:{$0.id<$1.id}) {
            if control.stopped { return [] }
            if let a=makeAction(from:state,to:node,itemIndex:nil,path:paths[node.id],in:snapshot) { actions.append(a) }
            for i in snapshot.resources.items.indices { if control.stopped { return [] }; if let a=makeAction(from:state,to:node,itemIndex:i,in:snapshot) { actions.append(a) } }
        }
        return actions
    }
    public static func apply(_ action: MoveAction, to state: PlannerState, in snapshot: PlanningSnapshot) throws -> PlannerState {
        guard !snapshot.map.exitIDs.contains(state.current), let node=snapshot.map.node(action.to),
              makeAction(from:state,to:node,itemIndex:action.itemIndex,path:action.walkPath,in:snapshot)==action else { throw CoreError.invalidAction }
        var next=state; let bit=snapshot.bit(action.to)
        let nodeGain=(state.claimed & bit)==0 && node.identityEvidence.confirmed && !node.observedKind.isHidden ? node.confirmedAPGain : 0
        next.ap=state.ap-action.cost+action.gain.ap+nodeGain
        next.hopeDelta += action.gain.hope; next.ingotDelta += action.gain.ingots
        if let i=action.itemIndex { next.charges[i]-=1 }
        next.current=action.to
        let traversed=action.isFlight ? [action.to] : Array(action.walkPath.dropFirst())
        for id in traversed {let passed=snapshot.bit(id);next.visited |= passed;next.mandatory |= passed & snapshot.mandatoryMask;next.opened |= passed;next.completed |= passed;next.claimed |= passed}
        return next
    }
}
