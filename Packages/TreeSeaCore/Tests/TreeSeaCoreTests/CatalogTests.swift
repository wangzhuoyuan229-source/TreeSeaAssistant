import Foundation
import Testing
@testable import TreeSeaCore
let reviewed = Provenance(sourceURL:"https://example.org/synthetic",commit:"test",status:.independentlyVerified)
struct CatalogTests {
    @Test func distanceSemantics() {
        #expect(!DistanceRule.forbidden.allows(0))
        #expect(DistanceRule.unrestricted.allows(100))
        #expect(DistanceRule.closedRange(min:2,max:6).allows(2))
        #expect(DistanceRule.closedRange(min:2,max:6).allows(6))
        #expect(!DistanceRule.closedRange(min:2,max:6).allows(7))
        #expect(CountRule.discrete([0,2]).allowed == [0,2])
    }
    @Test func malformedRuleRejected() throws {
        let bad=CatalogBundle(rules:RuleCatalog(version:"test",rules:[TypeRule(kind:.secretShop,floor:2,count:.range(min:3,max:1),provenance:reviewed)]),templates:TemplateCatalog(version:"test",templates:[]))
        let data=try JSONEncoder().encode(bad)
        #expect(throws:CoreError.self) { try CatalogLoader.decode(data) }
    }
}
struct BundledCatalogTests {
    @Test func loadPinnedResources() throws {
        let bundle=try CatalogLoader.bundled()
        #expect(bundle.rules.rules.count==55)
        #expect(Set(bundle.templates.templates.map { $0.map.floor })==Set(1...5))
        #expect(bundle.rules.rules.allSatisfy { !$0.provenance.status.strong })
        let m=try CatalogLoader.bundledMovements()
        #expect(m.movements.count==12)
        #expect(m.spec("M12")?.effects.ap==3); #expect(m.spec("M12")?.apCost==0)
        #expect(m.spec("M11")?.initialCharges==3); #expect(m.spec("M11")?.minimumAPToStart==1)
        #expect(m.spec("M10")?.effects.ingots==4); #expect(m.spec("M09")?.effects.hope==2)
    }
}
