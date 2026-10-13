import Foundation
import Testing
@testable import TreeSeaCore
struct MaaMovementOracleTests {
    struct Fixture:Decodable {var geometry:[Geometry];var resources:[Resources]}
    struct Geometry:Decodable {var range:Int;var row:Int;var column:Int;var appAllows:Bool}
    struct Resources:Decodable {var ap:Int;var cost:Int;var gain:Int;var result:Int}
    @Test func sourceGeometryAndResources() throws {
        let fixture=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:Bundle.module.url(forResource:"maa-movements",withExtension:"json")!))
        let ids=["M01","M02","M04","M06","M11"]
        var map=FloorMap(rows:5,columns:5,nodes:(0..<25).map{MapNode(id:$0,row:$0/5,column:$0%5,kind:.empty)},edges:[],start:12)
        map.exitIDs=[24]
        for c in fixture.geometry {
            let s=try snapshot(map,ap:1,items:[ItemInstance(typeID:ids[c.range],remainingCharges:1)])
            let actions=MovementModel.actions(from:PlannerState(snapshot:s),in:s,control:SearchControl())
            #expect(actions.contains{$0.to==c.row*5+c.column && $0.itemType==ids[c.range]} == c.appAllows)
        }
        map=FloorMap(rows:1,columns:2,nodes:[MapNode(id:0,row:0,column:0,kind:.start),MapNode(id:1,row:0,column:1,kind:.exit)],edges:[],start:0);map.exitIDs=[1]
        for c in fixture.resources {
            var s=try snapshot(map,ap:c.ap,items:[ItemInstance(typeID:"M12",remainingCharges:1,confirmedEffects:ItemEffects(ap:c.gain))])
            s.resources.costOverrides=[CostOverride(from:0,to:1,itemInstanceID:s.resources.items[0].id,cost:c.cost)]
            let state=PlannerState(snapshot:s),actions=MovementModel.actions(from:state,in:s,control:SearchControl())
            if c.ap>=max(1,c.cost) {let a=try #require(actions.first);#expect(try MovementModel.apply(a,to:state,in:s).ap==c.result)}else{#expect(actions.isEmpty)}
        }
    }
}
struct MaaSafetyOracleTests {
    struct Fixture:Decodable {var cases:[Case]}
    struct Case:Decodable {var scenario:Int;var ap:Int;var minimumRequiredAP:Int;var reachable:Bool}
    @Test func fixedPointSourceAndDeterministicSwiftAgreeOnReachability() throws {
        let fixture=try JSONDecoder().decode(Fixture.self,from:Data(contentsOf:Bundle.module.url(forResource:"maa-safety-planning",withExtension:"json")!))
        for c in fixture.cases {
            var map=lineMap([.start,.empty,.exit]),items:[ItemInstance]=[]
            if c.scenario==1 {items=[ItemInstance(typeID:"M12",remainingCharges:1,confirmedEffects:ItemEffects(ap:3))]}
            if c.scenario==2 {map.edges=[];items=[ItemInstance(typeID:"M08",remainingCharges:1)]}
            var s=try snapshot(map,ap:c.ap,items:items)
            if c.scenario==1 {s.resources.costOverrides=[CostOverride(from:1,to:2,cost:4)]}
            let result=SafetySolver.check(state:PlannerState(snapshot:s),snapshot:s,control:SearchControl(milliseconds:1000))
            #expect(result.status == (c.reachable ? .reachable:.unreachable))
            if let minimum=result.minimumRequiredAP {#expect(minimum==c.minimumRequiredAP)}
        }
    }
}
