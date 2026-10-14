import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TreeSeaAppSupport
#else
@testable import TreeSeaAssistant
#endif
struct MapBoardLayoutTests {
    @Test func referenceUsesOneScaleForNodesLabelsAndRoads() {
        let full=MapBoardMetrics(rows:3,columns:5,width:1490)
        #expect(abs(full.size.height-894)<0.01)
        #expect(abs(full.spacing-220)<0.01)
        #expect(abs(full.point(row:1,column:0).x-236)<0.01)
        #expect(abs(full.point(row:1,column:0).y-406)<0.01)
        let phone=MapBoardMetrics(rows:3,columns:5,width:373)
        for (a,b) in [(full.iconSize,phone.iconSize),(full.labelSize,phone.labelSize),(full.labelOffset,phone.labelOffset),(full.roadWidth,phone.roadWidth)] {
            #expect(abs(b/a-373/1490.0)<0.00001)
        }
        #expect(abs(phone.point(row:2,column:4).x/full.point(row:2,column:4).x-373/1490.0)<0.00001)
    }
    @Test func largeFloorsKeepSquareNodePitchAndFit() {
        let board=MapBoardMetrics(rows:5,columns:10,width:960)
        #expect(abs(board.point(row:1,column:1).x-board.point(row:1,column:0).x-board.spacing)<0.001)
        #expect(abs(board.point(row:1,column:0).y-board.point(row:0,column:0).y-board.spacing)<0.001)
        #expect(board.point(row:4,column:9).x+board.iconSize/2<board.size.width)
        #expect(board.point(row:4,column:9).y+board.labelOffset+board.labelSize<board.size.height)
    }
}
