import Foundation
import Testing
import TreeSeaCore
#if SWIFT_PACKAGE
@testable import TreeSeaAppSupport
#else
@testable import TreeSeaAssistant
#endif
func sampleSession() throws -> MapSession {
    var map=FloorMap(rows:1,columns:3,nodes:[MapNode(id:0,row:0,column:0,kind:.start),MapNode(id:1,row:0,column:1,kind:.unknownMystery),MapNode(id:2,row:0,column:2,kind:.exit)],edges:[MapEdge(0,1),MapEdge(1,2)],start:0)
    map.exitIDs=[2]; map.topologyVerified=true;map.originalCoverage = .complete
    let bundle=try CatalogLoader.bundled(),movements=try CatalogLoader.bundledMovements()
    return MapSession(title:"合成测试",map:map,resources:RunResources(actionPoints:3),ruleVersion:bundle.rules.version,movementVersion:movements.version)
}
@MainActor struct SessionStoreTests {
    @Test func semanticEditsStaleAndNoop() throws {
        let store=SessionStore(session:try sampleSession()), old=store.session.stamp
        try store.apply(.actionPoints(4)); #expect(store.session.resources.actionPoints==4); #expect(store.session.stamp.resource==old.resource+1)
        try store.apply(.actionPoints(4)); #expect(store.session.stamp.resource==old.resource+1)
        var proposal=RecognitionProposal(map:store.session.map); proposal.confirmed=true
        #expect(throws:SessionError.self) {try store.commit(proposal,expected:old)}
        var prediction=PredictionResult(mapRevision:old.map,ruleVersion:store.session.ruleVersion); prediction.mapRevision += 1
        #expect(!store.acceptPrediction(prediction))
    }
    @Test func staleGenerationAndCancelKeepLastValid() throws {
        let store=SessionStore(session:try sampleSession())
        let a=store.beginComputation(),b=store.beginComputation()
        let p=PredictionResult(mapRevision:store.session.map.mapRevision,ruleVersion:store.session.ruleVersion)
        #expect(!store.acceptPrediction(p,computationID:a)); #expect(store.acceptPrediction(p,computationID:b))
        store.cancelComputation()
        #expect(!store.acceptPrediction(p,computationID:b)); #expect(store.session.prediction==p)
    }
    @Test func unknownCountsDuplicateDigestAndPartialInventory() throws {
        let store=SessionStore(session:try sampleSession())
        var entry=InventoryEntry(typeID:"M03",remainingCharges:nil);entry.confirmed=true
        #expect(throws:SessionError.self) {try store.commitInventory(InventoryProposal(digest:"image-a",entries:[entry]),expected:store.session.stamp)}
        entry.remainingCharges=1;entry.newInstanceConfirmed=true
        let proposal=InventoryProposal(digest:"image-a",entries:[entry])
        try store.commitInventory(proposal,expected:store.session.stamp); #expect(store.session.resources.items.count==1)
        try store.commitInventory(proposal,expected:store.session.stamp); #expect(store.session.resources.items.count==1)
        #expect(store.session.resources.items.first?.remainingCharges==1)
    }
    @Test func goalsCannotExceedEightAndResourceInvalidation() throws {
        let store=SessionStore(session:try sampleSession())
        #expect(throws:SessionError.self) { try store.apply(.goals(Set(0...8))) }
        try store.apply(.goals([1])); #expect(store.session.mustPass==[1]); #expect(store.session.goalRevision==1)
    }
}
@MainActor struct ImportTransactionTests {
    @Test func mapReplacementMustNotSilentlyDropHardGoals() throws {
        let store=SessionStore(session:try sampleSession());try store.apply(.goals([1]))
        var map=store.session.map;map.nodes.removeAll{$0.id==1};map.edges=[]
        #expect(throws:SessionError.self) {try store.apply(.map(map))}
        #expect(store.session.mustPass==[1]);#expect(store.session.map.nodes.count==3)
    }
    @Test func currentPlanRejectedAfterAPChangeAndUndoRestoresIdentity() throws {
        let store=SessionStore(session:try sampleSession()),rules=try CatalogLoader.bundled().rules
        let p=PredictionEngine.localCandidates(map:store.session.map,rules:rules);#expect(store.acceptPrediction(p))
        let s=PlanningSnapshot(map:store.session.map,resources:store.session.resources,prediction:p,movements:try CatalogLoader.bundledMovements())
        let result=RoutePlanner.plan(PlanRequest(snapshot:s));try store.apply(.actionPoints(9))
        #expect(!store.acceptPlan(result));store.undo();#expect(store.session.resources.actionPoints==3);#expect(store.session.map.nodes[1].originalKind == .unknownMystery)
    }
}
