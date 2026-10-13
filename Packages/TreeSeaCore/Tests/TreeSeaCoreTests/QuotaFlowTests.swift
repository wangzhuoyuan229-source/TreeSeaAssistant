import Testing
@testable import TreeSeaCore
struct QuotaFlowTests {
    @Test func lowerUpperAndDiscrete() {
        let quotas: [NodeKind:CountRule]=[.secretShop:.range(min:1,max:1),.encounter:.range(min:1,max:1)]
        #expect(QuotaFlow.isFeasible(domains:[0:[.secretShop],1:[.encounter]],quotas:quotas,knownCounts:[:],control:SearchControl()) == .possible)
        #expect(QuotaFlow.isFeasible(domains:[0:[.secretShop],1:[.secretShop]],quotas:quotas,knownCounts:[:],control:SearchControl()) == .impossible)
        #expect(QuotaFlow.isFeasible(domains:[0:[.secretShop]],quotas:[.secretShop:.discrete([0,2])],knownCounts:[:],control:SearchControl()) == .impossible)
        #expect(QuotaFlow.isFeasible(domains:[0:[.secretShop]],quotas:[.secretShop:.range(min:0,max:1)],knownCounts:[.secretShop:2],control:SearchControl()) == .impossible)
    }
    @Test func interruptedNotImpossible() {
        #expect(QuotaFlow.isFeasible(domains:[0:[.encounter]],quotas:[:],knownCounts:[:],control:SearchControl(maxChecks:0)) == .interrupted)
    }
}
struct PredictionIntegrationTests {
    @Test func globalAndIncomplete() {
        var m=lineMap([.start,.unknownMystery,.unknownMystery,.exit]); m.floor=2
        let rules=RuleCatalog(version:"test",order:[.secretShop,.encounter],rules:[TypeRule(kind:.secretShop,floor:2,count:.range(min:1,max:1),provenance:reviewed),TypeRule(kind:.encounter,floor:2,count:.range(min:1,max:1),provenance:reviewed)])
        #expect(PredictionEngine.predict(map:m,rules:rules).propagationStatus == .complete)
        m.nodes[1].originalKind = .secretShop; m.nodes[1].observedKind = .empty; m.nodes[1].progress = .completed
        #expect(PredictionEngine.predict(map:m,rules:rules).candidates[2]==[.encounter])
        m.nodes[1].originalKind = .unknown
        #expect(PredictionEngine.predict(map:m,rules:rules).propagationStatus == .skippedIncompleteCoverage)
    }
    @Test func budgetFallbackAndCancel() {
        var m=lineMap([.start,.unknownMystery,.exit]); m.floor=2
        let result=PredictionEngine.predict(map:m,rules:shopRules(),budget:PredictionBudget(maxChecks:0))
        #expect(result.propagationStatus == .incomplete)
        #expect(result.candidates==PredictionEngine.localCandidates(map:m,rules:shopRules()).candidates)
        #expect(PredictionEngine.predict(map:m,rules:shopRules(),shouldCancel:{true}).propagationStatus == .cancelled)
    }
}
