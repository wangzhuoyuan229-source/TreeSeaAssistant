import SwiftUI
import TreeSeaCore
struct NodeEditorView:View {
    @Bindable var model:AppModel
    @State private var node:MapNode
    @State private var isBirth:Bool
    @State private var isCurrent:Bool
    @State private var isExit:Bool
    @Environment(\.dismiss) private var dismiss
    init(model:AppModel,node:MapNode){self.model=model;_node=State(initialValue:node);_isBirth=State(initialValue:model.store.session.map.initialStartID==node.id);_isCurrent=State(initialValue:model.store.session.map.currentNodeID==node.id);_isExit=State(initialValue:model.store.session.map.exitIDs.contains(node.id))}
    var body:some View {NavigationStack{Form{
        Section("N\(node.id) · 第 \(node.row+1) 行，第 \(node.column+1) 列"){
            GameIcon(kind:node.originalKind).frame(height:96)
            Picker("原始节点类型",selection:$node.originalKind){ForEach(NodeKind.allCases,id:\.self){Text($0.name).tag($0)}}
            Picker("完成状态",selection:$node.progress){Text("未进入").tag(Progress.unopened);Text("已打开").tag(Progress.opened);Text("已完成（当前为空地）").tag(Progress.completed)}
            Toggle("可移动到此节点",isOn:Binding(get:{node.traversability == .available},set:{node.traversability=$0 ? .available:.blocked}))
            Toggle("已领取奖励",isOn:$node.rewardClaimed)
            if node.originalKind == .unknownFerocity {Toggle("已确认仅为普通 / 紧急战斗范围",isOn:Binding(get:{node.battleScope == .ordinaryConfirmed},set:{node.battleScope=$0 ? .ordinaryConfirmed:.unconfirmed}));Text("未确认范围时，规划不会进入这个未知凶戾节点。").font(.footnote)}
            if !node.originalKind.isHidden {Stepper("确认的一次性 AP 增益 \(node.confirmedAPGain)",value:$node.confirmedAPGain,in:0...1000);if node.originalKind == .lookout {Stepper("可靠范围内可额外揭示 \(node.lookoutRevealCount) 个",value:$node.lookoutRevealCount,in:0...6)}}
        }
        Section("地图身份"){Toggle("初始出生点",isOn:$isBirth);Toggle("当前位置",isOn:$isCurrent);Toggle("出口",isOn:$isExit);Text("更改当前位置不改变初始出生点；完成后仍保留原始身份。").font(.footnote)}
    }.navigationTitle("核对节点").toolbar{ToolbarItem(placement:.cancellationAction){Button("取消"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("保存"){save()}}}}}
    private func save(){var map=model.store.session.map;guard let i=map.nodes.firstIndex(where:{$0.id==node.id}) else {return};node.observedKind=node.progress == .completed ? .empty:node.originalKind;node.identityEvidence = .userConfirmed;node.traversalEvidence = .userConfirmed;map.nodes[i]=node
        if isBirth {map.initialStartID=node.id;map.startEvidence = .userConfirmed} else if map.initialStartID==node.id {map.initialStartID=nil;map.startEvidence = .unresolved}
        if isCurrent {map.currentNodeID=node.id} else if map.currentNodeID==node.id {map.currentNodeID=nil}
        if isExit {map.exitIDs.insert(node.id)} else {map.exitIDs.remove(node.id)}
        model.apply(.map(map));dismiss()
    }
}
struct RoadEditorView:View {
    @Bindable var model:AppModel
    @State private var from:Int=0
    @State private var to:Int=1
    var body:some View {Form{
        Section("现有道路"){ForEach(Array(model.store.session.map.edges.enumerated()),id:\.offset){index,edge in HStack{Text("N\(edge.a) ↔ N\(edge.b)");Spacer();Picker("道路状态",selection:Binding(get:{edge.state},set:{state in var map=model.store.session.map;map.edges[index].state=state;map.topologyVerified=false;model.apply(.map(map))})){Text("已确认").tag(EdgeState.confirmed);Text("推断").tag(EdgeState.inferred);Text("不存在").tag(EdgeState.absent)}}}}
        Section("添加道路"){nodePicker("起点",selection:$from);nodePicker("终点",selection:$to);Button("添加已确认道路"){var map=model.store.session.map;let edge=MapEdge(from,to);if from != to && !map.edges.contains(where:{$0.a==edge.a && $0.b==edge.b}) {map.edges.append(edge);map.topologyVerified=false;model.apply(.map(map))}}}
        Section("覆盖与核对"){Toggle("原始生成节点信息完整",isOn:Binding(get:{model.store.session.map.originalCoverage == .complete},set:{value in var map=model.store.session.map;map.originalCoverage=value ? .complete:.partial;model.apply(.map(map))}));Toggle("拓扑与出生点已完整核对",isOn:Binding(get:{model.store.session.map.topologyVerified},set:{value in var map=model.store.session.map;if value && (map.startEvidence != .userConfirmed || map.edges.contains(where:{$0.state == .inferred})) {model.error="请先确认出生点和每条推断道路。";return};map.topologyVerified=value;model.apply(.map(map))}))}
    }.navigationTitle("道路与原始覆盖")}
    private func nodePicker(_ title:String,selection:Binding<Int>) -> some View {Picker(title,selection:selection){ForEach(model.store.session.map.nodes){Text("N\($0.id)").tag($0.id)}}}
}
struct ManualMapView:View {
    @Bindable var model:AppModel
    @State private var floor:Int=1
    @State private var templateID:String=""
    @Environment(\.dismiss) private var dismiss
    var body:some View {Form{
        Section("手动建立"){Picker("楼层",selection:$floor){ForEach(1...5,id:\.self){Text("第 \($0) 层").tag($0)}};Picker("模板",selection:$templateID){Text("空白网格").tag("");ForEach(model.catalog.templates.templates.filter{$0.map.floor==floor}){Text($0.id).tag($0.id)}};Text("模板为固定源码参照，节点身份和道路不视为实战确认。新建会话后请逐项核对。").font(.footnote)}
        ActionCapsule(title:"新建独立会话",symbol:"plus"){create()}
    }.navigationTitle("手动新建地图").onChange(of:floor){_,_ in templateID=""}}
    private func create(){let map:FloorMap
        if let template=model.catalog.templates.templates.first(where:{$0.id==templateID}) {var draft=template.map;draft.initialStartID=nil;draft.currentNodeID=nil;draft.exitIDs=[];map=draft}
        else {let dimensions=[1:(3,5),2:(4,5),3:(5,7),4:(5,8),5:(5,10)],(rows,columns)=dimensions[floor]!;let nodes=(0..<rows*columns).map{MapNode(id:$0,row:$0/columns,column:$0%columns,kind:.unknown)};map=FloorMap(floor:floor,rows:rows,columns:columns,nodes:nodes,edges:[],start:nil)}
        let session=MapSession(title:"第 \(floor) 层 · 手动地图",map:map,resources:RunResources(actionPoints:0),ruleVersion:model.catalog.rules.version,movementVersion:model.movements.version)
        model.restore(session);model.persist();model.navigation.selectedSection = .map;dismiss()
    }
}
struct InventoryView:View {
    @Bindable var model:AppModel
    @State private var adding:Bool=false
    @State private var editing:ItemInstance?
    var body:some View {ScrollView{VStack(alignment:.leading,spacing:20){Text("加工品与资源").font(.largeTitle.weight(.light)).fontDesign(.serif)
        Text("希望：\(model.store.session.resources.hope.map(String.init) ?? "未记录") · 源石锭：\(model.store.session.resources.ingots.map(String.init) ?? "未记录")")
        ForEach(model.store.session.resources.items){item in Button{editing=item}label:{InkPanel{HStack{GameIcon(itemID:item.typeID).frame(width:64,height:64);VStack(alignment:.leading){Text(model.movements.spec(item.typeID)?.name ?? item.typeID);Text("实例 \(item.instanceID.uuidString.prefix(4)) · 剩余 \(item.remainingCharges) 次").monospacedDigit();Text(item.confirmedEffects==nil ? "增益未确认，不参与资源转移":"已确认资源增益").font(.footnote)}}}}.buttonStyle(.plain)}
        if model.store.session.resources.items.isEmpty {StatusLabel(text:"尚无已确认加工品，目录初始次数不会自动进入库存。")}
        ActionCapsule(title:"手动添加实例",symbol:"plus"){adding=true}
        ForEach([ImportPurpose.inventory,.detail,.movePreview]){purpose in ActionCapsule(title:purpose.title,symbol:"photo"){model.importPurpose=purpose}}
    }.padding(20)}.sheet(isPresented:$adding){ItemEditorView(model:model,item:nil)}.sheet(item:$editing){item in ItemEditorView(model:model,item:item)}}
}
struct ItemEditorView:View {
    @Bindable var model:AppModel
    var item:ItemInstance?
    @State private var typeID:String
    @State private var charges:String
    @State private var effectsConfirmed:Bool
    @State private var reviewed:Bool=false
    @FocusState private var editingCharges:Bool
    @Environment(\.dismiss) private var dismiss
    init(model:AppModel,item:ItemInstance?){self.model=model;self.item=item;_typeID=State(initialValue:item?.typeID ?? "M03");_charges=State(initialValue:item.map{String($0.remainingCharges)} ?? "");_effectsConfirmed=State(initialValue:item?.confirmedEffects != nil)}
    private var spec:MovementSpec? {model.movements.spec(typeID)}
    var body:some View {NavigationStack{Form{
        Section("逐实例确认"){GameIcon(itemID:typeID,illustration:true).frame(height:180);Picker("名称",selection:$typeID){ForEach(model.movements.movements){Text($0.name).tag($0.id)}};TextField("实际剩余次数（必填）",text:$charges).keyboardType(.numberPad).focused($editingCharges);if let spec {Text("参考：AP 消耗 \(spec.apCost)，新物品初始 \(spec.initialCharges) 次；当前剩余次数必须单独确认。\n射程 \(spec.range.rawValue) · 目标 \(spec.targetFilter.rawValue) · \(spec.expiresOnFloorEnd ? "层末失效":"可跨层保留")");if spec.randomTarget {StatusLabel(text:"随机落点：可保存，不进入确定性路线",warning:true)};Toggle("已核对资源增益：AP +\(spec.effects.ap)、希望 +\(spec.effects.hope)、源石锭 +\(spec.effects.ingots)",isOn:$effectsConfirmed)};Toggle("已核对名称、射程、消耗和剩余次数",isOn:$reviewed)}
        if let item {Section{Button("删除此实例",role:.destructive){model.apply(.items(model.store.session.resources.items.filter{$0.id != item.id}));dismiss()}}}
    }.navigationTitle("确认加工品").toolbar{ToolbarItem(placement:.cancellationAction){Button("取消"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("保存"){save()}.disabled(!reviewed || Int(charges)==nil)};ToolbarItemGroup(placement:.keyboard){if editingCharges {Spacer();Button("完成"){editingCharges=false}.accessibilityIdentifier("charges-keyboard-done")}}}}}
    private func save(){guard let count=Int(charges),(0...100).contains(count),let spec else {model.error="请填写有效剩余次数。";return};let instance=ItemInstance(id:item?.instanceID ?? UUID(),typeID:typeID,remainingCharges:count,confirmedEffects:effectsConfirmed ? spec.effects:nil);var items=model.store.session.resources.items;if let index=items.firstIndex(where:{$0.id==instance.id}){items[index]=instance}else{items.append(instance)};model.apply(.items(items));dismiss()}
}
