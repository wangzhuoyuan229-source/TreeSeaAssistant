import Foundation
import Testing
@testable import TreeSeaCore
func snapshot(_ map: FloorMap, ap: Int, items: [ItemInstance] = [], must: Set<Int> = []) throws -> PlanningSnapshot {
    var r=RunResources(actionPoints:ap); r.items=items
    return PlanningSnapshot(map:map,resources:r,prediction:PredictionEngine.localCandidates(map:map,rules:RuleCatalog(version:"test",rules:[])),movements:try CatalogLoader.bundledMovements(),mustPassNodeIDs:must)
}
struct MovementTests {
    @Test func affordabilityAndExitZero() throws {
        var s=try snapshot(lineMap([.start,.exit]),ap:2); s.resources.costOverrides=[CostOverride(from:0,to:1,cost:2)]
        let a=try #require(MovementModel.actions(from:PlannerState(snapshot:s),in:s,control:SearchControl()).first)
        let after=try MovementModel.apply(a,to:PlannerState(snapshot:s),in:s)
        #expect(after.ap==0); #expect(after.terminal(in:s))
        s.resources.costOverrides=[CostOverride(from:0,to:1,cost:3)]
        #expect(MovementModel.actions(from:PlannerState(snapshot:s),in:s,control:SearchControl()).isEmpty)
        s.map.edges[0].state = .inferred
        #expect(MovementModel.actions(from:PlannerState(snapshot:s),in:s,control:SearchControl()).isEmpty)
    }
    @Test func remoteChargeOnceAndStartup() throws {
        let item=ItemInstance(typeID:"M12",remainingCharges:1,confirmedEffects:ItemEffects(ap:3))
        var s=try snapshot(lineMap([.start,.empty,.exit]),ap:1,items:[item])
        let initial=PlannerState(snapshot:s)
        let a=try #require(MovementModel.actions(from:initial,in:s,control:SearchControl()).first { $0.itemType=="M12" })
        let after=try MovementModel.apply(a,to:initial,in:s)
        #expect(after.ap==4); #expect(after.charges==[0])
        #expect(MovementModel.actions(from:after,in:s,control:SearchControl()).allSatisfy{$0.itemType != "M12"})
        s.resources.actionPoints=0
        #expect(MovementModel.actions(from:PlannerState(snapshot:s),in:s,control:SearchControl()).isEmpty)
    }
    @Test func geometryEligibilityRandomAndSeparateInstances() throws {
        var m=lineMap([.start,.unknownMystery,.exit]); m.edges=[]
        let items=[ItemInstance(typeID:"M01",remainingCharges:1),ItemInstance(typeID:"M10",remainingCharges:2,confirmedEffects:ItemEffects(ingots:4)),ItemInstance(typeID:"M07",remainingCharges:1),ItemInstance(typeID:"M03",remainingCharges:1),ItemInstance(typeID:"M03",remainingCharges:3)]
        let s=try snapshot(m,ap:2,items:items), actions=MovementModel.actions(from:PlannerState(snapshot:s),in:s,control:SearchControl())
        #expect(actions.contains{$0.to==2 && $0.itemType=="M01"})
        #expect(actions.allSatisfy{$0.itemType != "M10" && $0.itemType != "M07"})
        #expect(PlannerState(snapshot:s).charges==[1,2,1,1,3])
    }
    @Test func battleScopeAndUnconfirmedGain() throws {
        var m=lineMap([.start,.unknownFerocity,.exit])
        var s=try snapshot(m,ap:2)
        #expect(MovementModel.actions(from:PlannerState(snapshot:s),in:s,control:SearchControl()).isEmpty)
        m.nodes[1].battleScope = .ordinaryConfirmed; m.nodes[1].confirmedAPGain=5; m.nodes[1].identityEvidence = .ruleInferred
        s=try snapshot(m,ap:2)
        let a=try #require(MovementModel.actions(from:PlannerState(snapshot:s),in:s,control:SearchControl()).first)
        #expect(try MovementModel.apply(a,to:PlannerState(snapshot:s),in:s).ap==1)
    }
}
struct RouteScorerTests {
    @Test func exactQuarterUnitsAndNoRepeat() throws {
        for (kind,expected) in [(NodeKind.strangeShop,30),(.unknownMystery,6)] {
            let s=try snapshot(lineMap([.start,kind,.exit]),ap:3)
            var state=PlannerState(snapshot:s),total=0
            for target in [1,2] {
                let a=try #require(MovementModel.actions(from:state,in:s,control:SearchControl()).first{$0.to==target && !$0.isFlight})
                let after=try MovementModel.apply(a,to:state,in:s); total += RouteScorer.delta(for:a,before:state,after:after,in:s).total; state=after
            }
            #expect(total==expected)
        }
    }
    @Test func fixedUnknownBattleAndPersistentPenalty() throws {
        var s=try snapshot(lineMap([.start,.unknownMystery,.exit]),ap:3,items:[ItemInstance(typeID:"M03",remainingCharges:1)])
        s.prediction.candidates[1]=[.strangeShop]
        let state=PlannerState(snapshot:s),a=try #require(MovementModel.actions(from:state,in:s,control:SearchControl()).first{$0.itemType=="M03"})
        let after=try MovementModel.apply(a,to:state,in:s),score=RouteScorer.delta(for:a,before:state,after:after,in:s)
        #expect(score.reward==16); #expect(score.itemPenalty==24)
        var revisit=state; revisit.claimed |= s.bit(1)
        #expect(RouteScorer.delta(for:a,before:revisit,after:after,in:s).reward==0)
        s.map.nodes[1].observedKind = .unknownFerocity; s.map.nodes[1].originalKind = .unknownFerocity; s.map.nodes[1].battleScope = .ordinaryConfirmed
        #expect(RouteScorer.delta(for:a,before:state,after:after,in:s).battlePenalty==32)
    }
}
