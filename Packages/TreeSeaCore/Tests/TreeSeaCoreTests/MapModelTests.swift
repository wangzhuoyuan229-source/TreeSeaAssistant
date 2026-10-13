import Foundation
import Testing
@testable import TreeSeaCore
func lineMap(_ kinds: [NodeKind]) -> FloorMap {
    var m = FloorMap(rows: 1, columns: kinds.count, nodes: kinds.enumerated().map { MapNode(id:$0.offset,row:0,column:$0.offset,kind:$0.element) }, edges: (0..<max(0,kinds.count-1)).map { MapEdge($0,$0+1) }, start: 0)
    m.exitIDs = [kinds.count-1]; m.topologyVerified = true; m.originalCoverage = .complete
    return m
}
struct MapModelTests {
    @Test func roundTripAndOriginalIdentity() throws {
        var m=lineMap([.start,.secretShop,.exit]); m.nodes[1].progress = .completed; m.nodes[1].observedKind = .empty; m.currentNodeID=1
        #expect(m.initialStartID==0); #expect(m.nodes[1].originalKind == .secretShop)
        #expect(try JSONDecoder().decode(FloorMap.self,from:JSONEncoder().encode(m))==m)
        #expect(MapNode(id:0,row:0,column:0,kind:.unknownFerocity).battleScope == .unconfirmed)
    }
    @Test func rejectsInvalidMaps() {
        var duplicate=lineMap([.start,.exit]); duplicate.nodes[1].id=0
        #expect(throws: CoreError.self) { try MapValidator.validate(duplicate) }
        var edge=lineMap([.start,.exit]); edge.edges.append(MapEdge(0,7))
        #expect(throws: CoreError.self) { try MapValidator.validate(edge) }
        #expect(throws: CoreError.self) { try MapValidator.validate(lineMap(Array(repeating:.empty,count:65))) }
    }
}
