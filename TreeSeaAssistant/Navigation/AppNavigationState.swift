import SwiftUI
import Observation
import TreeSeaCore
nonisolated enum AppSection: String, CaseIterable, Identifiable {case map,sessions,settings
    var id:String {rawValue}
    var title:String {switch self {case .map:"地图";case .sessions:"会话";case .settings:"设置"}}
    var symbol:String {switch self {case .map:"map";case .sessions:"tray.full";case .settings:"gearshape"}}
}
@MainActor @Observable final class AppNavigationState {
    var selectedSection:AppSection = .sessions
    var selectedNodeID:NodeID?
    var selectedRouteSignature:String?
    var path=NavigationPath()
    var routePages:[String:RoutePageSnapshot]=[:]
}
nonisolated enum AppPage:Hashable {case inventory,planning,roads,manualMap,route(String)}
nonisolated struct RoutePageSnapshot {var route:RouteRecommendation;var stamp:RevisionStamp;var predictionID:UUID}
nonisolated struct MapViewport {var scale:CGFloat=1;var translation:CGSize = .zero}
nonisolated enum ImportPurpose: String, Identifiable, CaseIterable {
    case map,inventory,detail,movePreview
    var id:String {rawValue}
    var title:String {switch self {case .map:"导入地图";case .inventory:"导入背包";case .detail:"导入加工品详情";case .movePreview:"导入移动预览"}}
}
nonisolated struct NodeDraft:Identifiable {var node:MapNode;var id:NodeID {node.id}}
@MainActor @Observable final class AppModel {
    var store:SessionStore
    let catalog:CatalogBundle
    let movements:MovementCatalog
    let repository:SessionRepository
    var navigation=AppNavigationState()
    var viewport=MapViewport()
    var importPurpose:ImportPurpose?
    var nodeDraft:NodeDraft?
    var error:String?
    var savedSessions:[MapSession]=[]
    var apDraft="6"
    private var computationTask:Task<Void,Never>?
    private var corruptWarningCount=0
    var selectedRoute:RouteRecommendation? {store.session.routes?.recommendations.first{$0.signature==navigation.selectedRouteSignature}}
    init() {
        let bundle=(try? CatalogLoader.bundled()) ?? CatalogBundle(rules:RuleCatalog(version:"unavailable",rules:[]),templates:TemplateCatalog(version:"unavailable",templates:[]))
        let items=(try? CatalogLoader.bundledMovements()) ?? MovementCatalog(version:"unavailable",movements:[])
        catalog=bundle;movements=items
        var dir=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("TreeSeaAssistant/Sessions",isDirectory:true)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {dir=FileManager.default.temporaryDirectory.appendingPathComponent("TreeSeaUITests-"+UUID().uuidString)}
        #endif
        repository=SessionRepository(directory:dir)
        let initial=Self.demo(rule:bundle.rules.version,movement:items.version)
        store=SessionStore(session:initial)
        do {let listing=try repository.listRecoverable();savedSessions=listing.sessions;corruptWarningCount=listing.corruptCount;if listing.corruptCount>0 {self.error="有 \(listing.corruptCount) 份会话损坏，原文件已保留；其他有效会话仍可使用。"};if let recent=savedSessions.first {try store.replaceSession(recent)}} catch {self.error="本地会话恢复失败，损坏文件已保留。当前显示独立合成示例。"}
        apDraft=String(store.session.resources.actionPoints)
        if items.movements.isEmpty {error="本地加工品目录载入失败，暂不能规划。"}
    }
    static func demo(rule:String,movement:String) -> MapSession {
        let kinds:[Int:NodeKind]=[1:.unknownFerocity,2:.unknownFerocity,3:.unknownMystery,4:.exit,5:.start,6:.battle,7:.unknownMystery,8:.strangeShop,11:.empty,12:.unknownFerocity,13:.unknownMystery,14:.exit]
        var nodes=kinds.keys.sorted().map{MapNode(id:$0,row:$0/5,column:$0%5,kind:kinds[$0]!)}
        if let i=nodes.firstIndex(where:{$0.id==6}) {nodes[i].battleScope = .ordinaryConfirmed}
        var map=FloorMap(rows:3,columns:5,nodes:nodes,edges:[MapEdge(1,2),MapEdge(2,3),MapEdge(3,4),MapEdge(2,7),MapEdge(3,8),MapEdge(5,6),MapEdge(6,7),MapEdge(7,8),MapEdge(7,12),MapEdge(8,13),MapEdge(11,12),MapEdge(12,13),MapEdge(13,14)],start:5)
        map.exitIDs=[4,14];map.topologyVerified=true;map.originalCoverage = .complete
        return MapSession(title:"合成示例 · 非实战存档",map:map,resources:RunResources(actionPoints:6),ruleVersion:rule,movementVersion:movement)
    }
    func apply(_ edit:SessionEdit) {do {try store.apply(edit);persist();recompute()} catch {self.error="修改未提交，请检查节点、次数或最多 8 个必经条件。"}}
    func persist() {do {try repository.save(store.session);let listing=try repository.listRecoverable();savedSessions=listing.sessions;if listing.corruptCount>corruptWarningCount {self.error="有 \(listing.corruptCount) 份会话损坏，原文件已保留；其他有效会话仍可使用。"};corruptWarningCount=listing.corruptCount} catch {self.error="会话保存或读取失败；现有文件已保留。"}}
    func recompute() {
        computationTask?.cancel()
        let id=store.beginComputation(),session=store.session,rules=catalog.rules,movements=movements
        computationTask=Task {let (prediction,plan)=await ComputationWorker.compute(session:session,rules:rules,movements:movements)
            guard !Task.isCancelled else {return}
            if store.acceptPrediction(prediction,computationID:id),store.acceptPlan(plan,computationID:id) {persist()} else {store.cancelComputation()}
        }
    }
    func cancel() {computationTask?.cancel();store.cancelComputation()}
    func undo() {cancel();store.undo();apDraft=String(store.session.resources.actionPoints);persist();recompute()}
    func restore(_ session:MapSession) {do {cancel();try store.replaceSession(session);navigation.path=NavigationPath();navigation.routePages=[:];navigation.selectedNodeID=nil;navigation.selectedRouteSignature=nil;viewport=MapViewport();apDraft=String(session.resources.actionPoints);recompute()} catch {self.error="无法恢复这份会话，原文件已保留。"}}
    func newDemo() {restore(Self.demo(rule:catalog.rules.version,movement:movements.version));navigation.selectedSection = .map}
    func select(_ id:NodeID,open:Bool=false) {navigation.selectedNodeID=id;if open,let node=store.session.map.node(id) {nodeDraft=NodeDraft(node:node)}}
}
