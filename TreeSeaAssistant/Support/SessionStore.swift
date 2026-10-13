import Foundation
import Observation
import TreeSeaCore
@MainActor @Observable public final class SessionStore {
    public private(set) var session: MapSession
    public private(set) var computationID: UUID?
    public private(set) var isComputing = false
    private var undoHistory: [MapSession] = []
    public var canUndo: Bool { !undoHistory.isEmpty }
    public init(session: MapSession) { self.session=session }
    private func publish(_ next: MapSession) {
        guard next != session else {return}
        undoHistory.append(session); if undoHistory.count>20 {undoHistory.removeFirst()}
        var updated=next;updated.updatedAt=Date();session=updated;cancelComputation()
    }
    public func apply(_ edit: SessionEdit) throws {
        var next=session
        switch edit {
        case var .map(map):
            try MapValidator.validate(map);map.mapRevision=next.map.mapRevision
            guard next.mustPass.allSatisfy({map.node($0) != nil}), map.floor==next.map.floor || next.mustPass.isEmpty else {throw SessionError.invalidInput}
            if map != next.map { map.mapRevision += 1;next.map=map }
        case let .node(node):
            guard let index=next.map.nodes.firstIndex(where:{$0.id==node.id}) else {throw SessionError.invalidInput}
            if next.map.nodes[index] != node { next.map.nodes[index]=node;try MapValidator.validate(next.map);next.map.mapRevision += 1 }
        case let .actionPoints(ap):
            guard (0...1000).contains(ap) else {throw SessionError.invalidInput}
            if next.resources.actionPoints != ap {next.resources.actionPoints=ap;next.resources.resourceRevision += 1}
        case let .items(items):
            guard items.count<=64, Set(items.map(\.instanceID)).count==items.count, items.allSatisfy({(0...100).contains($0.remainingCharges)}) else {throw SessionError.invalidInput}
            if next.resources.items != items {next.resources.items=items;next.resources.resourceRevision += 1}
        case let .cost(cost):
            guard next.map.node(cost.from) != nil,next.map.node(cost.to) != nil,(0...1000).contains(cost.cost), cost.itemInstanceID == nil || next.resources.items.contains(where:{$0.id==cost.itemInstanceID}) else {throw SessionError.invalidInput}
            let index=next.resources.costOverrides.firstIndex{$0.from==cost.from && $0.to==cost.to && $0.itemInstanceID==cost.itemInstanceID}
            if let index { if next.resources.costOverrides[index] != cost {next.resources.costOverrides[index]=cost;next.resources.costRevision += 1} }
            else {next.resources.costOverrides.append(cost);next.resources.costRevision += 1}
        case let .goals(goals):
            guard goals.count<=8,goals.allSatisfy({next.map.node($0) != nil}) else {throw SessionError.invalidInput}
            if next.mustPass != goals {next.mustPass=goals;next.goalRevision += 1}
        case let .reviewedRules(value):
            if next.reviewedRules != value {next.reviewedRules=value;next.ruleVersion=(next.ruleVersion.components(separatedBy:"-reviewed").first ?? next.ruleVersion)+(value ? "-reviewed" : "")}
        }
        publish(next)
    }
    public func commit(_ proposal: RecognitionProposal, expected: RevisionStamp, actionPoints: Int? = nil) throws {
        guard expected==session.stamp else {throw SessionError.stale}
        guard proposal.confirmed,let map=proposal.map,map.initialStartID != nil,map.currentNodeID != nil,!map.exitIDs.isEmpty,map.startEvidence == .userConfirmed else {throw SessionError.unconfirmed}
        try MapValidator.validate(map)
        guard session.mustPass.allSatisfy({map.node($0) != nil}),map.floor==session.map.floor || session.mustPass.isEmpty else {throw SessionError.invalidInput}
        if let actionPoints, !(0...1000).contains(actionPoints) {throw SessionError.invalidInput}
        var next=session,updated=map;updated.mapRevision=session.map.mapRevision
        if updated != session.map {updated.mapRevision += 1;next.map=updated}
        if let actionPoints, actionPoints != next.resources.actionPoints {next.resources.actionPoints=actionPoints;next.resources.resourceRevision += 1}
        next.title="第 \(map.floor) 层 · 截图会话"
        publish(next)
    }
    public func commitInventory(_ proposal: InventoryProposal, expected: RevisionStamp, replaceAll: Bool = false) throws {
        guard expected==session.stamp else {throw SessionError.stale}
        guard !proposal.digest.isEmpty else {throw SessionError.invalidInput}
        if session.importedDigests.contains(proposal.digest) {return}
        guard !replaceAll || proposal.coverage == .complete else {throw SessionError.unconfirmed}
        var items=replaceAll ? [] : session.resources.items
        for entry in proposal.entries {
            guard entry.confirmed,let charges=entry.remainingCharges,(0...100).contains(charges) else {throw SessionError.unconfirmed}
            if let id=entry.existingID {
                guard let existing=session.resources.items.first(where:{$0.id==id}),existing.typeID==entry.typeID else {throw SessionError.ambiguousInventory}
                var item=existing;item.remainingCharges=charges;item.confirmedEffects=entry.effects;item.evidence = .userConfirmed
                if let index=items.firstIndex(where:{$0.id==id}) {items[index]=item} else {items.append(item)}
            } else {
                guard entry.newInstanceConfirmed else {throw SessionError.ambiguousInventory}
                items.append(ItemInstance(id:entry.id,typeID:entry.typeID,remainingCharges:charges,confirmedEffects:entry.effects))
            }
        }
        guard items.count<=64 else {throw SessionError.invalidInput}
        var next=session;next.resources.items=items
        if next.resources.items != session.resources.items {next.resources.resourceRevision += 1}
        next.importedDigests.insert(proposal.digest);publish(next)
    }
    public func commitMovePreview(_ proposal: MovementPreviewProposal, expected: RevisionStamp) throws {
        guard expected==session.stamp else {throw SessionError.stale}
        guard proposal.confirmed,let target=proposal.target,let from=proposal.from,let cost=proposal.cost else {throw SessionError.unconfirmed}
        try apply(.cost(CostOverride(from:from,to:target,itemInstanceID:proposal.itemInstanceID,cost:cost)))
    }
    public func acceptPrediction(_ result: PredictionResult, computationID token: UUID? = nil) -> Bool {
        guard token == nil || token==computationID, result.mapRevision==session.map.mapRevision,result.ruleVersion==session.ruleVersion,
              ![.cancelled,.invalidInput,.incomplete].contains(result.propagationStatus) else {return false}
        session.prediction=result;return true
    }
    public func acceptPlan(_ result: RouteSetResult, computationID token: UUID? = nil) -> Bool {
        guard token == nil || token==computationID, result.stamp==session.stamp,session.predictionIsCurrent,
              result.predictionID==session.prediction?.predictionID,result.ruleVersion==session.ruleVersion,
              result.movementCatalogVersion==session.movementVersion,result.scoreProfileVersion==session.scoreVersion,
              result.status != .cancelled,result.status != .invalidInput,
              result.recommendations.allSatisfy({$0.covered==session.mustPass && session.map.exitIDs.contains($0.finalState.current) && $0.finalState.ap>=0 && $0.finalState.charges.allSatisfy{$0>=0}}) else {return false}
        session.routes=result;isComputing=false;return true
    }
    public func beginComputation() -> UUID {let id=UUID();computationID=id;isComputing=true;return id}
    public func cancelComputation() {computationID=nil;isComputing=false}
    public func undo() {
        guard var old=undoHistory.popLast() else {return}
        old.map.mapRevision=session.map.mapRevision+1;old.resources.resourceRevision=session.resources.resourceRevision+1
        old.resources.costRevision=session.resources.costRevision+1;old.goalRevision=session.goalRevision+1
        old.updatedAt=Date();session=old;cancelComputation()
    }
    public func replaceSession(_ value: MapSession) throws {try MapValidator.validate(value.map);session=value;undoHistory=[];cancelComputation()}
}
