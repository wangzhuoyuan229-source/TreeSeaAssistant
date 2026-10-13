import SwiftUI
import TreeSeaCore
struct MapCanvasView:View {
    var map:FloorMap;var mustPass:Set<NodeID>;var route:RouteRecommendation?;var selected:NodeID?
    @Binding var viewport:MapViewport
    var select:(NodeID)->Void
    @GestureState private var drag=CGSize.zero
    @GestureState private var magnification:CGFloat=1
    private func point(_ id:NodeID,size:CGSize) -> CGPoint {
        guard let node=map.node(id) else {return .zero}
        let base=CGPoint(x:40+CGFloat(node.column)*max(1,size.width-80)/CGFloat(max(1,map.columns-1)),y:45+CGFloat(node.row)*max(1,size.height-90)/CGFloat(max(1,map.rows-1)))
        let scale=viewport.scale*magnification
        return CGPoint(x:(base.x-size.width/2)*scale+size.width/2+viewport.translation.width+drag.width,y:(base.y-size.height/2)*scale+size.height/2+viewport.translation.height+drag.height)
    }
    var body:some View {GeometryReader{geo in
        ZStack{
            ThemeTokens.inkSurface.color
            Canvas{context,size in
                for edge in map.edges where edge.state != .absent {var path=Path();path.move(to:point(edge.a,size:size));path.addLine(to:point(edge.b,size:size));context.stroke(path,with:.color(ThemeTokens.textSecondary.color.opacity(0.65)),style:StrokeStyle(lineWidth:2,dash:edge.state == .inferred ? [5,5] : []))}
                if let route {for step in route.steps {
                    let a=point(step.action.from,size:size),b=point(step.action.to,size:size);var path=Path();path.move(to:a);path.addLine(to:b)
                    context.stroke(path,with:.color(ThemeTokens.capsuleRim.color),style:StrokeStyle(lineWidth:4,dash:step.action.isFlight ? [12,4] : []))
                    if step.action.isFlight {let angle=atan2(b.y-a.y,b.x-a.x);var arrow=Path();arrow.move(to:CGPoint(x:b.x-16*cos(angle-0.45),y:b.y-16*sin(angle-0.45)));arrow.addLine(to:b);arrow.addLine(to:CGPoint(x:b.x-16*cos(angle+0.45),y:b.y-16*sin(angle+0.45)));context.stroke(arrow,with:.color(ThemeTokens.capsuleRim.color),lineWidth:3)}
                }}
            }.accessibilityHidden(true)
            ForEach(map.nodes){node in Button{select(node.id)}label:{VStack(spacing:2){GameIcon(kind:node.observedKind).frame(width:44,height:44);Text("N\(node.id)").font(.caption).monospacedDigit();if mustPass.contains(node.id){Text("必经").font(.caption2).foregroundStyle(ThemeTokens.warning.color)};if map.currentNodeID==node.id {Text("当前位置").font(.caption2)}}.padding(4).background(selected==node.id ? ThemeTokens.forest.color : ThemeTokens.inkSurface.color,in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(selected==node.id ? ThemeTokens.capsuleRim.color : .clear,lineWidth:2))}.buttonStyle(.plain).position(point(node.id,size:geo.size)).accessibilityLabel("节点 N\(node.id)，\(node.observedKind.name)，\(mustPass.contains(node.id) ? "必须经过" : "非必经")，\(map.currentNodeID==node.id ? "当前位置" : "")").accessibilityIdentifier("node-\(node.id)")}
        }.clipped().gesture(DragGesture(minimumDistance:12).updating($drag){value,state,_ in state=value.translation}.onEnded{viewport.translation.width += $0.translation.width;viewport.translation.height += $0.translation.height}).simultaneousGesture(MagnificationGesture().updating($magnification){value,state,_ in state=value}.onEnded{viewport.scale=min(3,max(0.7,viewport.scale*$0))})
    }.frame(minHeight:340).clipShape(RoundedRectangle(cornerRadius:20))}
}
struct MapWorkspaceView:View {
    @Bindable var model:AppModel;var wide:Bool
    var body:some View {ScrollView{VStack(alignment:.leading,spacing:20){
        HStack{Text("第 \(model.store.session.map.floor) 层").font(.title2).fontDesign(.serif);Spacer();Text("AP \(model.store.session.resources.actionPoints)").monospacedDigit();Button("撤销"){model.undo()}.disabled(!model.store.canUndo)}
        if model.store.session.title.contains("合成") {StatusLabel(text:"合成示例 · 不是已识别的游戏地图",warning:true)}
        if model.store.isComputing {HStack{ProgressView();Text("计算中");Spacer();Button("取消计算"){model.cancel()}}}
        else if !model.store.session.routesAreCurrent && model.store.session.routes != nil {StatusLabel(text:"已过期：修改后的地图/资源需要重新规划",warning:true)}
        MapCanvasView(map:model.store.session.map,mustPass:model.store.session.mustPass,route:model.store.session.routesAreCurrent ? model.selectedRoute : nil,selected:model.navigation.selectedNodeID,viewport:$model.viewport){model.select($0,open:!wide)}
        HStack{Button("缩小"){model.viewport.scale=max(0.7,model.viewport.scale/1.2)};Button("放大"){model.viewport.scale=min(3,model.viewport.scale*1.2)};Button("重置视口"){model.viewport=MapViewport()}}.buttonStyle(.bordered).frame(minHeight:44)
        Text("实线：徒步道路 · 虚线：待确认道路 · 箭头：加工品飞行").font(.footnote).foregroundStyle(ThemeTokens.textSecondary.color)
        ActionCapsule(title:"导入地图截图",symbol:"photo"){model.importPurpose = .map}
        HStack{NavigationLink("加工品与资源"){InventoryView(model:model)};NavigationLink("规划条件与推荐路线"){PlanRequestView(model:model)}}.buttonStyle(.bordered).frame(minHeight:44)
        DisclosureGroup("节点列表（可替代触摸地图）"){ForEach(model.store.session.map.nodes){node in Button{model.select(node.id,open:true)}label:{HStack{GameIcon(kind:node.observedKind).frame(width:32,height:32);Text("N\(node.id) · \(node.observedKind.name)");Spacer();if model.store.session.mustPass.contains(node.id){Label("必经",systemImage:"checkmark")}}.frame(minHeight:52)}.buttonStyle(.plain)}}
        if !wide {NodeInspectorView(model:model)}
    }.padding(20)}.navigationTitle("地图工作台")}
}
struct NodeInspectorView:View {
    @Bindable var model:AppModel
    var body:some View {VStack(alignment:.leading,spacing:20){if let id=model.navigation.selectedNodeID,let node=model.store.session.map.node(id){InkPanel{VStack(alignment:.leading,spacing:12){Text("N\(id) · \(node.observedKind.name)").font(.title3);Text("原始身份：\(node.originalKind.name)");Button("编辑节点"){model.select(id,open:true)}.buttonStyle(.bordered);Toggle("必须经过",isOn:Binding(get:{model.store.session.mustPass.contains(id)},set:{value in var must=model.store.session.mustPass;if value {must.insert(id)} else {must.remove(id)};model.apply(.goals(must))}))}}
            CandidateDetailView(model:model,nodeID:id)
        } else {StatusLabel(text:"选择地图或节点列表中的节点，查看身份与候选")}
        RouteComparisonView(model:model)
    }}
}
