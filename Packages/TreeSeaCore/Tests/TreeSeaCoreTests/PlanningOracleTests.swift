import Testing
@testable import TreeSeaCore
struct PlanningOracleTests {
    // Independent exhaustive edge-by-edge oracle; no production movement/scoring calls.
    @Test func smallGraphsMatchExhaustiveBestScore() throws {
        for count in 3...6 {
            var kinds=Array(repeating:NodeKind.empty,count:count);kinds[0] = .start;kinds[1] = .unknownMystery;kinds[count-1] = .exit
            if count>=5 {kinds[2] = .battle;kinds[3] = .strangeShop}
            var map=lineMap(kinds);map.edges.append(MapEdge(0,count-1))
            for ap in [1,2,4,8] {
                for itemID in ["none","M08","M12"] {
                    let must:Set<Int>=ap%2==0 ? [1] : []
                    let items=itemID=="none" ? [] : [ItemInstance(typeID:itemID,remainingCharges:1,confirmedEffects:itemID=="M12" ? ItemEffects(ap:3):nil)]
                    let s=try snapshot(map,ap:ap,items:items,must:must)
                    let neighbors=Dictionary(grouping:map.edges.flatMap{[($0.a,$0.b),($0.b,$0.a)]},by:{$0.0}).mapValues{$0.map{$0.1}}
                    var best:Int?
                    func visit(_ current:Int,_ remaining:Int,_ seen:UInt64,_ used:Bool,_ score:Int) {
                        if current==count-1 {if must.allSatisfy({seen & (UInt64(1)<<$0) != 0}) {best=max(best ?? Int.min,score)};return}
                        guard remaining>=1 else {return}
                        func reward(_ target:Int)->Int {guard seen & (UInt64(1)<<target)==0 else {return 0};switch kinds[target]{case .unknownMystery:return 16;case .strangeShop:return 40;case .battle:return -16;default:return 0}}
                        for target in neighbors[current] ?? [] {visit(target,remaining-1,seen | (UInt64(1)<<target),used,score+reward(target)-5)}
                        if !used && itemID != "none" {
                            for target in 0..<count where target != current && (itemID=="M08" || abs(target-current)==1) {visit(target,remaining+(itemID=="M12" ? 3:0),seen | (UInt64(1)<<target),true,score+reward(target)-24)}
                        }
                    }
                    visit(0,ap,1,false,0)
                    let result=RoutePlanner.plan(PlanRequest(snapshot:s,budget:PlanningBudget(milliseconds:2000,maxExpansions:100000,maxLabels:200000)))
                    #expect(result.recommendations.first(where:{$0.badges.contains(.balanced)})?.scoreUnits==best)
                    for route in result.recommendations {#expect(route.covered==must);#expect(route.finalState.ap>=0);#expect(route.finalState.charges.allSatisfy{$0>=0})}
                }
            }
        }
    }
}
