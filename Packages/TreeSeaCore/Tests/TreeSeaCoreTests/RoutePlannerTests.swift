import Testing
@testable import TreeSeaCore
struct SafetySolverTests {
    @Test func exactAPAndBudget() throws {
        let s=try snapshot(lineMap([.start,.empty,.exit]),ap:2)
        let result=SafetySolver.check(state:PlannerState(snapshot:s),snapshot:s,control:SearchControl())
        #expect(result.status == .reachable); #expect(result.minimumRequiredAP==2)
        #expect(SafetySolver.check(state:PlannerState(snapshot:s),snapshot:s,control:SearchControl(maxExpansions:0)).status == .unresolved)
        let low=try snapshot(s.map,ap:1)
        #expect(SafetySolver.check(state:PlannerState(snapshot:low),snapshot:low,control:SearchControl()).status == .unreachable)
    }
}
struct RoutePlannerTests {
    @Test func feasibleAndMustPass() throws {
        let s=try snapshot(lineMap([.start,.unknownMystery,.exit]),ap:2,must:[1])
        let result=RoutePlanner.plan(PlanRequest(snapshot:s))
        #expect(result.status == .feasible); #expect(!result.recommendations.isEmpty)
        for route in result.recommendations { #expect(route.finalState.ap==0); #expect(route.covered==[1]); #expect(route.scoreUnits==6) }
    }
    @Test func fixedExplorationPrefersDetour() throws {
        var m=lineMap([.start,.unknownMystery,.exit]); m.edges.append(MapEdge(0,2))
        let s=try snapshot(m,ap:3)
        let routes=RoutePlanner.plan(PlanRequest(snapshot:s)).recommendations
        #expect(routes.first?.steps.map{$0.action.to}==[1,2])
        #expect(routes.first?.scoreUnits==6)
        #expect(routes.count==2)
    }
    @Test func remoteCanFundLaterAndFlightDoesNotPass() throws {
        let s=try snapshot(lineMap([.start,.empty,.empty,.exit]),ap:1,items:[ItemInstance(typeID:"M12",remainingCharges:1,confirmedEffects:ItemEffects(ap:3))],must:[1,2])
        let result=RoutePlanner.plan(PlanRequest(snapshot:s))
        #expect(result.status == .feasible)
        for route in result.recommendations { #expect(route.covered==[1,2]); #expect(route.finalState.charges==[0]) }
        var flight=try snapshot(lineMap([.start,.empty,.exit]),ap:1,items:[ItemInstance(typeID:"M08",remainingCharges:1)],must:[1]); flight.map.edges=[]
        #expect(RoutePlanner.plan(PlanRequest(snapshot:flight)).recommendations.isEmpty)
    }
    @Test func unresolvedCancelledStaleAndNoExit() throws {
        var s=try snapshot(lineMap([.start,.exit]),ap:1)
        #expect(RoutePlanner.plan(PlanRequest(snapshot:s,budget:PlanningBudget(maxExpansions:0))).status == .unresolved)
        #expect(RoutePlanner.plan(PlanRequest(snapshot:s),shouldCancel:{true}).status == .cancelled)
        s.prediction.mapRevision += 1
        #expect(RoutePlanner.plan(PlanRequest(snapshot:s)).status == .invalidInput)
        s.prediction.mapRevision -= 1; s.map.exitIDs=[]
        #expect(RoutePlanner.plan(PlanRequest(snapshot:s)).status == .invalidInput)
    }
    @Test func returnedRoutesReplayAndViewsDontConsume() throws {
        var m=lineMap([.start,.strangeShop,.exit]); m.edges.append(MapEdge(0,2))
        let s=try snapshot(m,ap:3,items:[ItemInstance(typeID:"M08",remainingCharges:1)])
        let result=RoutePlanner.plan(PlanRequest(snapshot:s))
        #expect(result.recommendations.count>0)
        for r in result.recommendations {
            var state=PlannerState(snapshot:s),score=0
            for step in r.steps { let after=try MovementModel.apply(step.action,to:state,in:s); #expect(after.ap==step.afterAP); #expect(after.ap>=0); score += RouteScorer.delta(for:step.action,before:state,after:after,in:s).total; state=after }
            #expect(state.terminal(in:s)); #expect(state==r.finalState); #expect(score==r.scoreUnits)
        }
        #expect(s.resources.items[0].remainingCharges==1)
    }
}
