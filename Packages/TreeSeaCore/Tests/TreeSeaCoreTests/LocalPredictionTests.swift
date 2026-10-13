import Testing
@testable import TreeSeaCore
func shopRules() -> RuleCatalog { RuleCatalog(version:"test",order:[.secretShop,.encounter],rules:[TypeRule(kind:.secretShop,floor:2,distance:.closedRange(min:2,max:6),count:.range(min:0,max:1),provenance:reviewed),TypeRule(kind:.encounter,floor:2,distance:.unrestricted,count:.range(min:0,max:8),provenance:reviewed)]) }
struct MapGraphTests {
    @Test func ordinaryBFSFromBirth() {
        var m=lineMap([.start,.empty,.exit]); m.currentNodeID=2
        #expect(MapGraph.distances(from:m.initialStartID!,in:m)==[0:0,1:1,2:2])
        m.edges=[MapEdge(0,1)]
        #expect(MapGraph.distances(from:0,in:m)[2]==nil)
    }
}
struct LocalPredictionTests {
    @Test func reliableDistanceAndMaximum() {
        var m=lineMap([.start,.empty,.empty,.unknownMystery,.unknownFerocity,.empty,.empty,.unknownMystery]); m.floor=2
        let a=PredictionEngine.localCandidates(map:m,rules:shopRules())
        #expect(a.candidates[3]==[.secretShop,.encounter]); #expect(a.candidates[7]==[.encounter]); #expect(a.candidates[4]==nil)
        m.nodes[1].originalKind = .secretShop; m.nodes[1].observedKind = .empty; m.nodes[1].progress = .completed
        #expect(PredictionEngine.localCandidates(map:m,rules:shopRules()).candidates[3]==[.encounter])
    }
    @Test func incompleteAndResearchDoNotOverExclude() {
        var m=lineMap([.start,.unknownMystery]); m.floor=2; m.topologyVerified=false
        #expect(PredictionEngine.localCandidates(map:m,rules:shopRules()).candidates[1]==[.secretShop,.encounter])
        var rules=shopRules(); rules.rules[0].provenance.status = .researchReference; m.topologyVerified=true
        #expect(PredictionEngine.localCandidates(map:m,rules:rules).candidates[1]==[.secretShop,.encounter])
    }
}
