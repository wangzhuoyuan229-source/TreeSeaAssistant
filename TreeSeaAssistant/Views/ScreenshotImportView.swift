import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import TreeSeaCore
struct ScreenshotImportView:View {
    @Bindable var model:AppModel;var purpose:ImportPurpose
    @Environment(\.dismiss) private var dismiss
    @State private var photo:PhotosPickerItem?
    @State private var showFiles=false
    @State private var data:Data?
    @State private var prepared:PreparedScreenshot?
    @State private var expected:RevisionStamp
    @State private var floor:Int
    @State private var left=0.0,right=1.0,top=0.0,bottom=1.0
    @State private var busy=false
    @State private var issue:String?
    @State private var task:Task<Void,Never>?
    @State private var loadID=UUID()
    @State private var mapProposal:RecognitionProposal?
    @State private var inventoryProposal:InventoryProposal?
    @State private var previewProposal:MovementPreviewProposal?
    @State private var manualTemplate=""
    @State private var apText:String
    @State private var reviewed=false
    @State private var from:Int?
    @State private var target:Int?
    @State private var itemID:UUID?
    init(model:AppModel,purpose:ImportPurpose){self.model=model;self.purpose=purpose;_expected=State(initialValue:model.store.session.stamp);_floor=State(initialValue:model.store.session.map.floor);_apText=State(initialValue:String(model.store.session.resources.actionPoints));_from=State(initialValue:model.store.session.map.currentNodeID);_target=State(initialValue:model.navigation.selectedNodeID)}
    var body:some View {NavigationStack{ScrollView{VStack(alignment:.leading,spacing:20){
        StatusLabel(text:"选择、识别和纠错只修改提案；确认前保留当前会话。")
        PhotosPicker(selection:$photo,matching:.images){Label("从照片选择",systemImage:"photo").frame(maxWidth:.infinity,minHeight:52)}.buttonStyle(.bordered)
        ActionCapsule(title:"从文件导入 PNG / JPEG / WebP",symbol:"folder"){showFiles=true}
        if let prepared,let image=UIImage(data:prepared.png){Image(uiImage:image).resizable().scaledToFit().frame(maxHeight:420).accessibilityLabel("待导入的原图预览");Text("工作图 \(prepared.width) × \(prepared.height) · 本地处理").font(.footnote)}
        if data != nil {
            InkPanel{VStack(alignment:.leading){Text("裁剪区域").font(.headline);cropSlider("左",value:$left);cropSlider("右",value:$right);cropSlider("上",value:$top);cropSlider("下",value:$bottom);ActionCapsule(title:"应用裁剪",symbol:"crop",disabled:busy){crop()}}}
            if purpose == .map {Picker("确认楼层",selection:$floor){ForEach(1...5,id:\.self){Text("第 \($0) 层").tag($0)}}}
            if purpose == .movePreview {previewSelectors}
            ActionCapsule(title:busy ? "正在识别":"生成识别提案",symbol:"viewfinder",disabled:busy || prepared==nil){recognize()}
        }
        if busy {HStack{ProgressView();Text("本地处理，请稍候");Button("取消本次处理"){loadID=UUID();task?.cancel();busy=false}}}
        if let issue {StatusLabel(text:issue,warning:true)}
        if purpose == .map {
            ForEach(mapProposal?.warnings ?? [],id:\.self){StatusLabel(text:$0,warning:true)}
            if let map=mapProposal?.map {DraftMapReview(map:Binding(get:{mapProposal?.map ?? map},set:{mapProposal?.map=$0}))}
            Picker("人工模板保底",selection:$manualTemplate){Text("选择模板").tag("");ForEach(model.catalog.templates.templates.filter{$0.map.floor==floor}){Text($0.id).tag($0.id)}}
            Button("采用模板作为人工提案"){if let template=model.catalog.templates.templates.first(where:{$0.id==manualTemplate}){mapProposal=RecognitionProposal(map:template.map,warnings:["人工选择的完整模板，必须核对实际截图；不会自动确认节点身份或道路"]);reviewed=false}}.buttonStyle(.bordered).disabled(manualTemplate.isEmpty)
            if mapProposal?.map != nil {TextField("截图中的当前 AP",text:$apText).keyboardType(.numberPad).textFieldStyle(.roundedBorder);Toggle("已核对 AP、节点、出生点、出口及每条道路",isOn:$reviewed);ActionCapsule(title:"确认并提交地图",symbol:"checkmark",disabled:!reviewed || Int(apText)==nil){commitMap()}}
        }
        if let proposal=inventoryProposal {InventoryProposalReview(model:model,proposal:proposal,expected:expected){dismiss()}}
        if previewProposal != nil {TextField("实际 AP 消耗",text:Binding(get:{previewProposal?.cost.map(String.init) ?? ""},set:{previewProposal?.cost=Int($0)})).keyboardType(.numberPad).textFieldStyle(.roundedBorder);Toggle("目标、移动方式及 AP 消耗均已人工核对",isOn:$reviewed);ActionCapsule(title:"保存该动作成本",symbol:"checkmark",disabled:!reviewed || from==nil || target==nil || previewProposal?.cost==nil){commitPreview()}}
    }.padding(20).frame(maxWidth:1000)}.navigationTitle(purpose.title).toolbar{ToolbarItem(placement:.cancellationAction){Button("取消"){task?.cancel();dismiss()}}}.fileImporter(isPresented:$showFiles,allowedContentTypes:[.png,.jpeg,.webP]){result in
        do {let url=try result.get();let access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}};let attributes=try FileManager.default.attributesOfItem(atPath:url.path);guard ((attributes[.size] as? NSNumber)?.intValue ?? Int.max) <= 20*1024*1024 else {issue="图片超过 20 MiB，请先裁剪。";return};load(try Data(contentsOf:url,options:.mappedIfSafe))}catch{issue="未能读取这张图片，当前会话已保留。"}
    }.onChange(of:photo){_,selection in guard let selection else{return};task?.cancel();let id=UUID();loadID=id;busy=true;task=Task{do{guard let bytes=try await selection.loadTransferable(type:Data.self),!Task.isCancelled,loadID==id else{return};load(bytes)}catch{issue="照片加载失败，当前会话已保留。";busy=false}}}
    }.onDisappear{loadID=UUID();task?.cancel()}}
    private func cropSlider(_ name:String,value:Binding<Double>) -> some View {HStack{Text(name).frame(width:28);Slider(value:value,in:0...1).accessibilityLabel("裁剪\(name)边界")}}
    private var previewSelectors:some View {VStack{Picker("移动起点",selection:$from){Text("请选择").tag(Int?.none);ForEach(model.store.session.map.nodes){Text("N\($0.id)").tag(Optional($0.id))}};Picker("实际目标",selection:$target){Text("请选择").tag(Int?.none);ForEach(model.store.session.map.nodes){Text("N\($0.id)").tag(Optional($0.id))}};Picker("移动方式",selection:$itemID){Text("徒步").tag(UUID?.none);ForEach(model.store.session.resources.items){Text("\(model.movements.spec($0.typeID)?.name ?? $0.typeID) · \($0.id.uuidString.prefix(4))").tag(Optional($0.id))}}}}
    private func load(_ bytes:Data){task?.cancel();let id=UUID();loadID=id;data=bytes;mapProposal=nil;inventoryProposal=nil;previewProposal=nil;reviewed=false;left=0;right=1;top=0;bottom=1;busy=true;task=Task{do{let screenshot=try await ImagePreprocessor.process(bytes,crop:nil);guard !Task.isCancelled,loadID==id else{return};prepared=screenshot;issue=nil;busy=false}catch{guard loadID==id else{return};prepared=nil;issue="图片无法解码、格式不支持或超过大小限制；当前会话已保留。";busy=false}}}
    private func crop(){guard let data,let prepared else{return};let rect=CGRect(x:left*Double(prepared.originalWidth),y:top*Double(prepared.originalHeight),width:(right-left)*Double(prepared.originalWidth),height:(bottom-top)*Double(prepared.originalHeight));task?.cancel();let id=UUID();loadID=id;busy=true;task=Task{do{let result=try await ImagePreprocessor.process(data,crop:rect);guard !Task.isCancelled,loadID==id else{return};self.prepared=result;mapProposal=nil;inventoryProposal=nil;previewProposal=nil;reviewed=false;issue=nil;busy=false}catch{guard loadID==id else{return};issue="裁剪区域无效，请检查四个边界。";busy=false}}}
    private func recognize(){guard let prepared else{return};task?.cancel();let id=UUID();loadID=id;busy=true;task=Task{do{switch purpose{case .map:let proposal=try await ScreenshotRecognizer.recognize(prepared,floor:floor,catalog:model.catalog.templates);guard !Task.isCancelled,loadID==id else{return};mapProposal=proposal
        case .inventory,.detail:let proposal=try await InventoryRecognizer.recognize(prepared,catalog:model.movements,coverage:purpose == .detail ? .detail:.partial);guard !Task.isCancelled,loadID==id else{return};inventoryProposal=proposal
        case .movePreview:let proposal=try await InventoryRecognizer.recognizeMovePreview(prepared,from:from,target:target,itemInstanceID:itemID);guard !Task.isCancelled,loadID==id else{return};previewProposal=proposal};busy=false;reviewed=false;issue=nil
    }catch{guard loadID==id else{return};busy=false;issue="本次识别未完成，可用人工模板或手动录入继续核对。"}}}
    private func commitMap(){guard var proposal=mapProposal,var map=proposal.map,let ap=Int(apText),(0...1000).contains(ap),reviewed else{return};for i in map.nodes.indices{map.nodes[i].traversalEvidence = .userConfirmed;if map.nodes[i].originalKind != .unknown{map.nodes[i].identityEvidence = .userConfirmed}};for i in map.edges.indices where map.edges[i].state != .absent{map.edges[i].state = .confirmed};map.startEvidence = .userConfirmed;map.topologyVerified=true;proposal.map=map;proposal.confirmed=true
        do{try model.store.commit(proposal,expected:expected,actionPoints:ap);model.apDraft=String(ap);model.persist();model.recompute();model.navigation.selectedSection = .map;dismiss()}catch{issue="提案未提交：请确认出生点、当前位置、出口；若旧会话已修改，请重新导入。"}}
    private func commitPreview(){guard var proposal=previewProposal else{return};proposal.confirmed=reviewed;proposal.from=from;proposal.target=target;proposal.itemInstanceID=itemID
        do{try model.store.commitMovePreview(proposal,expected:expected);model.persist();model.recompute();dismiss()}catch{issue="成本未保存：目标、实例或会话版本已变化，请重新核对。"}}
}
struct DraftMapReview:View {
    @Binding var map:FloorMap
    var body:some View {VStack(alignment:.leading,spacing:12){Text("地图确认提案").font(.title2);Picker("初始出生点",selection:$map.initialStartID){Text("未确认").tag(Int?.none);ForEach(map.nodes){Text("N\($0.id)").tag(Optional($0.id))}};Picker("当前位置",selection:$map.currentNodeID){Text("未确认").tag(Int?.none);ForEach(map.nodes){Text("N\($0.id)").tag(Optional($0.id))}};Toggle("原始生成节点信息覆盖完整",isOn:Binding(get:{map.originalCoverage == .complete},set:{map.originalCoverage=$0 ? .complete:.partial}))
        ForEach(map.nodes.indices,id:\.self){i in InkPanel{VStack(alignment:.leading){Text("N\(map.nodes[i].id) · \(map.nodes[i].row+1) 行 \(map.nodes[i].column+1) 列");Picker("原始类型",selection:$map.nodes[i].originalKind){ForEach(NodeKind.allCases,id:\.self){Text($0.name).tag($0)}}.onChange(of:map.nodes[i].originalKind){_,kind in map.nodes[i].observedKind=kind};Toggle("出口",isOn:Binding(get:{map.exitIDs.contains(map.nodes[i].id)},set:{value in if value{map.exitIDs.insert(map.nodes[i].id)}else{map.exitIDs.remove(map.nodes[i].id)}}))}}}
        DisclosureGroup("逐条核对道路"){ForEach(map.edges.indices,id:\.self){i in Picker("N\(map.edges[i].a) ↔ N\(map.edges[i].b)",selection:$map.edges[i].state){Text("存在").tag(EdgeState.confirmed);Text("待确认").tag(EdgeState.inferred);Text("不存在").tag(EdgeState.absent)}}}
    }}
}
struct InventoryProposalReview:View {
    @Bindable var model:AppModel
    @State var proposal:InventoryProposal
    var expected:RevisionStamp
    var complete:()->Void
    @State private var replaceAll=false
    @State private var issue:String?
    var body:some View {VStack(alignment:.leading,spacing:16){Text("逐实例确认加工品").font(.title2);ForEach(proposal.warnings,id:\.self){StatusLabel(text:$0,warning:true)};Picker("截图覆盖",selection:$proposal.coverage){Text("部分背包").tag(InventoryObservationCoverage.partial);Text("完整背包（已核对）").tag(InventoryObservationCoverage.complete);Text("单件详情").tag(InventoryObservationCoverage.detail);Text("当前装载方式").tag(InventoryObservationCoverage.loadedOnly)}
        ForEach(proposal.entries.indices,id:\.self){i in InkPanel{VStack(alignment:.leading,spacing:12){GameIcon(itemID:proposal.entries[i].typeID).frame(height:70);Picker("名称",selection:$proposal.entries[i].typeID){ForEach(model.movements.movements){Text($0.name).tag($0.id)}};TextField("实际剩余次数",text:Binding(get:{proposal.entries[i].remainingCharges.map(String.init) ?? ""},set:{proposal.entries[i].remainingCharges=Int($0)})).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
            Picker("对应库存实例",selection:$proposal.entries[i].existingID){Text("新的独立实例").tag(UUID?.none);ForEach(model.store.session.resources.items.filter{$0.typeID==proposal.entries[i].typeID}){Text("\($0.id.uuidString.prefix(4)) · 剩余 \($0.remainingCharges)").tag(Optional($0.id))}}
            if proposal.entries[i].existingID==nil {Toggle("确认是新的独立实例（不是重叠截图）",isOn:$proposal.entries[i].newInstanceConfirmed)}
            if let spec=model.movements.spec(proposal.entries[i].typeID) {Toggle("已核对资源增益（AP +\(spec.effects.ap)，希望 +\(spec.effects.hope)，源石锭 +\(spec.effects.ingots)）",isOn:Binding(get:{proposal.entries[i].effects != nil},set:{proposal.entries[i].effects=$0 ? spec.effects:nil}))}
            if let warning=proposal.entries[i].warning {StatusLabel(text:warning,warning:true)};Toggle("名称、射程、消耗与次数均已核对",isOn:$proposal.entries[i].confirmed)}}}
        Button("手动添加提案"){proposal.entries.append(InventoryEntry(typeID:"M03",remainingCharges:nil))}.buttonStyle(.bordered)
        if proposal.coverage == .complete {Toggle("明确替换整份库存",isOn:$replaceAll)}
        if let issue {StatusLabel(text:issue,warning:true)}
        ActionCapsule(title:"保存已确认项",symbol:"checkmark"){var selected=proposal;selected.entries=proposal.entries.filter(\.confirmed);guard !selected.entries.isEmpty else {issue="请至少确认一个实例，未确认项不会加入库存。";return};do{try model.store.commitInventory(selected,expected:expected,replaceAll:replaceAll && proposal.coverage == .complete);model.persist();model.recompute();complete()}catch{issue="库存未提交：请填剩余次数，并区分新实例 / 已有实例；会话版本需保持一致。"}}
    }}
}
