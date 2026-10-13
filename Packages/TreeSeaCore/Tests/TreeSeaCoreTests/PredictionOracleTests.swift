import Foundation
import Testing
@testable import TreeSeaCore
struct PredictionOracleTests {
    struct LocalCase: Decodable { var floor: Int; var distance: Int; var secretShopCount: Int; var expected: [NodeKind] }
    struct GlobalCase: Decodable { var floor: Int; var domains: [String:[NodeKind]]; var expected: [String:[NodeKind]] }
    @Test func upstreamLocalFixture() throws {
        var rules=try CatalogLoader.bundled().rules
        for i in rules.rules.indices { rules.rules[i].provenance.status = .authorizedReviewed }
        let cases=try JSONDecoder().decode([LocalCase].self,from:Data(contentsOf:Bundle.module.url(forResource:"hlsh-local-candidates",withExtension:"json")!))
        for c in cases {
            var kinds=Array(repeating:NodeKind.empty,count:max(2,c.distance+1))
            kinds[c.distance] = .unknownMystery
            var m=lineMap(kinds); m.floor=c.floor
            // Visible shops are independent leaves; they do not change target BFS distance.
            m.columns += c.secretShopCount
            for i in m.nodes.indices { m.nodes[i].id=m.nodes[i].column }
            for i in 0..<c.secretShopCount { m.nodes.append(MapNode(id:kinds.count+i,row:0,column:kinds.count+i,kind:.secretShop)) }
            #expect(PredictionEngine.localCandidates(map:m,rules:rules).candidates[c.distance]==c.expected)
        }
    }
    @Test func upstreamGlobalFixture() throws {
        let rules=try CatalogLoader.bundled().rules
        let cases=try JSONDecoder().decode([GlobalCase].self,from:Data(contentsOf:Bundle.module.url(forResource:"hlsh-global-candidates",withExtension:"json")!))
        for c in cases {
            let quotas=Dictionary(uniqueKeysWithValues:rules.rules.filter{$0.floor==c.floor}.map{($0.kind,$0.count!)})
            let independent=Dictionary(uniqueKeysWithValues:c.domains.map{(Int($0.key)!,$0.value)})
            var actual=independent
            let control=SearchControl(milliseconds:1000,maxChecks:10000)
            let feasible=QuotaFlow.isFeasible(domains:independent.mapValues{Set($0)},quotas:quotas,knownCounts:[:],control:control)
            if feasible == .possible {
                for id in independent.keys.sorted() {
                    actual[id]=independent[id]!.filter { kind in
                        var fixed=independent.mapValues{Set($0)}; fixed[id]=[kind]
                        return QuotaFlow.isFeasible(domains:fixed,quotas:quotas,knownCounts:[:],control:control) == .possible
                    }
                }
            }
            #expect(actual==Dictionary(uniqueKeysWithValues:c.expected.map{(Int($0.key)!,$0.value)}))
        }
    }
    @Test func flowAgainstIndependentAssignmentOracle() {
        for n in 1...6 {
            for encoding in 0..<(1<<n) {
                let domains=Dictionary(uniqueKeysWithValues:(0..<n).map { ($0,encoding & (1<<$0)==0 ? Set([NodeKind.secretShop,.encounter]) : Set([.secretShop])) })
                for required in 0...n {
                    let q: [NodeKind:CountRule]=[.secretShop:.range(min:required,max:required),.encounter:.range(min:n-required,max:n-required)]
                    var possible=false
                    for assignment in 0..<(1<<n) {
                        var shops=0,valid=true
                        for id in 0..<n { let kind: NodeKind=assignment & (1<<id)==0 ? .secretShop : .encounter; if !domains[id]!.contains(kind) { valid=false }; if kind == .secretShop { shops += 1 } }
                        if valid && shops==required { possible=true; break }
                    }
                    #expect(QuotaFlow.isFeasible(domains:domains,quotas:q,knownCounts:[:],control:SearchControl(milliseconds:1000)) == (possible ? .possible : .impossible))
                }
            }
        }
    }
}
