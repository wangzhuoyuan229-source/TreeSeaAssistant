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
@MainActor struct ReviewRegressionTests {
    @Test func partialCropPreservesUnseenNodesAndCompletedOriginalIdentity() throws {
        var session=try sampleSession();session.map.nodes[1].originalKind = .secretShop;session.map.nodes[1].observedKind = .empty;session.map.nodes[1].progress = .completed;session.map.nodes[1].rewardClaimed=true;session.map.nodes[1].confirmedAPGain=1
        let store=SessionStore(session:session)
        var crop=session.map;crop.originalCoverage = .partial;crop.nodes.removeAll{$0.id==1};crop.edges=[]
        var proposal=RecognitionProposal(map:crop);proposal.confirmed=true
        try store.commit(proposal,expected:store.session.stamp)
        #expect(store.session.map.nodes.count==3);#expect(store.session.map.edges.count==2);#expect(store.session.map.nodes.first{$0.id==1}?.originalKind == .secretShop)
        var empty=session.map;empty.originalCoverage = .partial;empty.nodes[1]=MapNode(id:1,row:0,column:1,kind:.empty)
        proposal=RecognitionProposal(map:empty);proposal.confirmed=true
        try store.commit(proposal,expected:store.session.stamp)
        let node=try #require(store.session.map.node(1));#expect(node.originalKind == .secretShop);#expect(node.progress == .completed);#expect(node.rewardClaimed);#expect(node.confirmedAPGain==1)
    }
    @Test func partialInventoryDoesNotEraseConfirmedEffects() throws {
        var session=try sampleSession();let item=ItemInstance(typeID:"M12",remainingCharges:1,confirmedEffects:ItemEffects(ap:3));session.resources.items=[item]
        let store=SessionStore(session:session);var entry=InventoryEntry(typeID:"M12",remainingCharges:0);entry.existingID=item.id;entry.confirmed=true
        try store.commitInventory(InventoryProposal(digest:"partial",entries:[entry]),expected:store.session.stamp)
        #expect(store.session.resources.items[0].confirmedEffects?.ap==3)
        entry.clearEffectsConfirmed=true
        try store.commitInventory(InventoryProposal(digest:"explicit-clear",entries:[entry]),expected:store.session.stamp)
        #expect(store.session.resources.items[0].confirmedEffects==nil)
    }
    @Test func sameImageCanConfirmDifferentItemsButCannotDuplicateSameObservation() throws {
        let store=SessionStore(session:try sampleSession());var a=InventoryEntry(typeID:"M12",remainingCharges:1),b=InventoryEntry(typeID:"M03",remainingCharges:2)
        a.confirmed=true;a.newInstanceConfirmed=true;b.confirmed=true;b.newInstanceConfirmed=true
        let first=InventoryProposal(digest:"same-image",entries:[a]),second=InventoryProposal(digest:"same-image",entries:[b])
        try store.commitInventory(first,expected:store.session.stamp);try store.commitInventory(second,expected:store.session.stamp)
        #expect(store.session.resources.items.count==2)
        try store.commitInventory(first,expected:store.session.stamp);#expect(store.session.resources.items.count==2)
    }
    @Test func incompleteFullReplacementRejectedAtomically() throws {
        var session=try sampleSession();session.resources.items=[ItemInstance(typeID:"M12",remainingCharges:1),ItemInstance(typeID:"M03",remainingCharges:3)]
        let store=SessionStore(session:session);var a=InventoryEntry(typeID:"M12",remainingCharges:0);a.confirmed=true;a.existingID=session.resources.items[0].id
        var filtered=InventoryProposal(digest:"complete-filtered",coverage:.complete,entries:[a]);filtered.observedEntryCount=2
        #expect(throws:SessionError.self){try store.commitInventory(filtered,expected:store.session.stamp,replaceAll:true)}
        let b=InventoryEntry(typeID:"M03",remainingCharges:nil)
        #expect(throws:SessionError.self){try store.commitInventory(InventoryProposal(digest:"complete",coverage:.complete,entries:[a,b]),expected:store.session.stamp,replaceAll:true)}
        #expect(store.session.resources.items==session.resources.items)
    }
}
@MainActor struct LastValidRouteTests {
    @Test func unresolvedAttemptPreservesLastValidRoute() throws {
        let store=SessionStore(session:try sampleSession()),movements=try CatalogLoader.bundledMovements(),rules=try CatalogLoader.bundled().rules
        var p=PredictionEngine.localCandidates(map:store.session.map,rules:rules);#expect(store.acceptPrediction(p))
        var snap=PlanningSnapshot(map:store.session.map,resources:store.session.resources,prediction:p,movements:movements)
        let valid=RoutePlanner.plan(PlanRequest(snapshot:snap));#expect(valid.status == .feasible);#expect(store.acceptPlan(valid))
        p.predictionID=UUID();#expect(store.acceptPrediction(p));snap.prediction=p
        var limited=RouteSetResult(snapshot:snap,profile:ScoreProfile(),status:.unresolved);limited.budgetLimited=true
        #expect(store.acceptPlan(limited));#expect(store.session.routes?.recommendations==valid.recommendations);#expect(store.session.routes?.status == .feasible);#expect(store.session.latestPlanningFailure?.status == .unresolved)
    }
}
