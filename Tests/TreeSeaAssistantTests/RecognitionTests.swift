import Foundation
import Testing
import TreeSeaCore
#if SWIFT_PACKAGE
@testable import TreeSeaAppSupport
#else
@testable import TreeSeaAssistant
#endif
struct GridFitterTests {
    @Test func translatedGridAndMissingColumn() throws {
        let centers=(0..<3).flatMap{row in (0..<3).map{DetectedCenter(x:50+Double($0)*80,y:20+Double(row)*60)}}
        let grid=try #require(GridFitter.fit(centers:centers,rows:3,columns:3))
        #expect(grid.occupied==Set(0..<9));#expect(grid.residual<0.01);#expect(grid.coversAxes)
        #expect(GridFitter.fit(centers:centers.filter{$0.center.x<210},rows:3,columns:4)==nil)
    }
    @Test func compatibleCannotInventCoordinates() throws {
        let bundle=try CatalogLoader.bundled(),template=try #require(bundle.templates.templates.first)
        let single=TemplateCatalog(version:"test",templates:[template])
        let ids=Set(template.map.nodes.map(\.id)),oneExit=try #require(template.map.exitIDs.first)
        let withoutExit=TemplateMatcher.compatible(observedEdges:template.map.edges,recognizedNodeIDs:ids.subtracting([oneExit]),catalog:single,floor:template.map.floor)
        #expect(withoutExit.proposedExitIDs.isEmpty)
        #expect(TemplateMatcher.compatible(observedEdges:template.map.edges,recognizedNodeIDs:ids,catalog:single,floor:template.map.floor).proposedExitIDs==template.map.exitIDs)
        var duplicate=template;duplicate.id="duplicate"
        #expect(TemplateMatcher.compatible(observedEdges:[],recognizedNodeIDs:ids,catalog:TemplateCatalog(version:"test",templates:[template,duplicate]),floor:template.map.floor).selectedID==nil)
    }
}
struct InventoryRecognitionTests {
    @Test func remainingNotInitialOrHeldCount() throws {
        let catalog=try CatalogLoader.bundledMovements()
        let p=InventoryTextParser.parse([TextObservation(text:"标准引擎 剩余 1/3"),TextObservation(text:"标准引擎 持有 2 件"),TextObservation(text:"简易遥控器 剩余 1/7",confidence:0.5)],catalog:catalog,digest:"test")
        #expect(p.entries.count==3);#expect(p.entries.first?.remainingCharges==1)
        #expect(p.entries[1].remainingCharges==nil);#expect(p.entries[2].remainingCharges==nil)
        #expect(p.entries[0].id != p.entries[1].id)
    }
    @Test func movePreviewDoesNotConfuseHopeWithAP() {
        #expect(InventoryTextParser.movePreview([TextObservation(text:"希望 +2")],from:0,target:2).cost==nil)
        #expect(InventoryTextParser.movePreview([TextObservation(text:"-2 AP")],from:0,target:2).cost==2)
        #expect(!InventoryTextParser.movePreview([TextObservation(text:"-2 AP")],from:nil,target:nil).confirmed)
    }
}
