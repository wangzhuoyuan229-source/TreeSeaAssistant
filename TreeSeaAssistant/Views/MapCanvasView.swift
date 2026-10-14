import SwiftUI
import TreeSeaCore
struct MapCanvasView:View {
    var map:FloorMap;var mustPass:Set<NodeID>;var route:RouteRecommendation?;var selected:NodeID?
    @Binding var viewport:MapViewport
    var select:(NodeID)->Void
    @GestureState private var drag=CGSize.zero
    @GestureState private var magnification:CGFloat=1
    private func metrics(_ size:CGSize) -> MapBoardMetrics {MapBoardMetrics(rows:map.rows,columns:map.columns,width:size.width)}
    private func point(row:Int,column:Int,size:CGSize) -> CGPoint {metrics(size).point(row:row,column:column)}
    private func point(_ id:NodeID,size:CGSize) -> CGPoint {
        guard let node=map.node(id) else{return .zero}
        return point(row:node.row,column:node.column,size:size)
    }
    private func road(_ a:CGPoint,_ b:CGPoint,bend:CGFloat) -> Path {
        let dx=b.x-a.x,dy=b.y-a.y,length=max(1,hypot(dx,dy)),nx = -dy/length*bend,ny=dx/length*bend
        var path=Path();path.move(to:a)
        path.addCurve(to:b,control1:CGPoint(x:a.x+dx*0.35+nx,y:a.y+dy*0.35+ny),control2:CGPoint(x:a.x+dx*0.65-nx,y:a.y+dy*0.65-ny))
        return path
    }
    private func label(_ kind:NodeKind) -> String {
        switch kind {case .unknownMystery:"未知的诡秘";case .unknownFerocity:"未知的凶戾";case .exit:"险路尽头";case .battle:"作战";case .start:"起点";case .empty:"";default:kind.name}
    }
    var body:some View {GeometryReader{geo in
        let board=metrics(geo.size),unit=board.spacing,icon=board.iconSize,font=board.labelSize
        ZStack {
            ThemeTokens.background.color
            Image("map-area-\(min(5,max(1,map.floor)))").resizable().scaledToFill().frame(width:geo.size.width,height:geo.size.height).clipped().opacity(0.88).accessibilityHidden(true)
            ZStack {
                Canvas{context,size in
                    let occupied=Set(map.nodes.map{"\($0.row):\($0.column)"})
                    for row in 0..<map.rows {for column in 0..<map.columns where !occupied.contains("\(row):\(column)") {
                        let p=point(row:row,column:column,size:size),r=unit*0.135
                        var mark=Path(ellipseIn:CGRect(x:p.x-r,y:p.y-r,width:r*2,height:r*2))
                        for offset:CGFloat in [-0.55,0,0.55] {
                            let delta=r*offset/sqrt(2),half=r*sqrt(1-offset*offset)/sqrt(2)*0.94
                            mark.move(to:CGPoint(x:p.x+delta-half,y:p.y-delta-half));mark.addLine(to:CGPoint(x:p.x+delta+half,y:p.y-delta+half))
                        }
                        context.stroke(mark,with:.color(ThemeTokens.burgundy.color.opacity(0.45)),lineWidth:unit*1.5/220)
                    }}
                    for edge in map.edges where edge.state != .absent {
                        let a=point(edge.a,size:size),b=point(edge.b,size:size),bend=unit*0.1
                        let path=road(a,b,bend:bend)
                        let dash: [CGFloat]=edge.state == .inferred ? [unit*0.035,unit*0.025] : []
                        context.stroke(path,with:.color(.black.opacity(0.35)),style:StrokeStyle(lineWidth:unit*8/220,lineCap:.round,dash:dash))
                        context.stroke(path,with:.color(Color(red:0.64,green:0.70,blue:0.68).opacity(0.48)),style:StrokeStyle(lineWidth:board.roadWidth,lineCap:.round,dash:dash))
                        context.stroke(road(a,b,bend:-bend),with:.color(.white.opacity(0.2)),style:StrokeStyle(lineWidth:unit/220,lineCap:.round,dash:dash))
                    }
                    if let route {for step in route.steps {
                        let a=point(step.action.from,size:size),b=point(step.action.to,size:size)
                        let ids=step.action.isFlight ? [step.action.from,step.action.to] : step.action.walkPath
                        var path=Path();for (i,id) in ids.enumerated(){if i==0{path.move(to:point(id,size:size))}else{path.addLine(to:point(id,size:size))}}
                        context.stroke(path,with:.color(ThemeTokens.warning.color),style:StrokeStyle(lineWidth:unit*4/220,lineCap:.round,dash:step.action.isFlight ? [unit*0.05,unit*0.025] : []))
                        if step.action.isFlight {let angle=atan2(b.y-a.y,b.x-a.x),head=unit*14/220;var arrow=Path();arrow.move(to:CGPoint(x:b.x-head*cos(angle-0.45),y:b.y-head*sin(angle-0.45)));arrow.addLine(to:b);arrow.addLine(to:CGPoint(x:b.x-head*cos(angle+0.45),y:b.y-head*sin(angle+0.45)));context.stroke(arrow,with:.color(ThemeTokens.warning.color),lineWidth:unit*2/220)}
                    }}
                }.accessibilityHidden(true)
                ForEach(map.nodes){node in
                    Button{select(node.id)}label:{
                        ZStack {
                            if selected==node.id {Circle().stroke(ThemeTokens.capsuleRim.color,lineWidth:unit*2/220).frame(width:icon*0.85,height:icon*0.85)}
                            if node.observedKind == .empty {
                                Circle().fill(ThemeTokens.inkSurface.color).overlay(Circle().stroke(ThemeTokens.textSecondary.color.opacity(0.7),lineWidth:unit*2/220)).frame(width:unit*28/220,height:unit*28/220)
                                Circle().fill(ThemeTokens.textSecondary.color).frame(width:unit*8/220,height:unit*8/220)
                            } else if node.observedKind == .start {
                                Image("game-themes-blackstream-start-cursor_anchor").resizable().scaledToFit().frame(width:unit*0.56,height:unit*0.56)
                                Circle().fill(ThemeTokens.background.color).overlay(Circle().stroke(ThemeTokens.textSecondary.color,lineWidth:unit/220)).frame(width:unit*0.1,height:unit*0.1)
                                GameIcon(kind:.start).frame(width:unit*0.42,height:unit*0.64).offset(x:-unit*0.23)
                                Text("YOU ARE HERE").font(.system(size:unit*0.04)).foregroundStyle(.white).offset(y:-unit*0.4)
                            } else {
                                GameIcon(kind:node.observedKind).frame(width:node.observedKind == .exit ? icon*1.28:icon,height:node.observedKind == .exit ? icon*1.28:icon)
                            }
                            if mustPass.contains(node.id) {Image(systemName:"checkmark.circle.fill").font(.system(size:unit*0.1)).foregroundStyle(ThemeTokens.warning.color).offset(x:icon/2,y:-icon/2)}
                            if map.currentNodeID==node.id {Image(systemName:"arrowtriangle.down.fill").font(.system(size:unit*0.05)).foregroundStyle(.white).offset(y:-unit*0.32)}
                            if node.observedKind != .start {
                                Text(label(node.observedKind)).font(.system(size:font,weight:.regular)).foregroundStyle(.white).shadow(color:.black,radius:unit*2/220).fixedSize().offset(y:board.labelOffset)
                            }
                            if selected==node.id {Text("N\(node.id)").font(.system(size:unit*0.075,design:.monospaced)).foregroundStyle(ThemeTokens.capsuleRim.color).offset(y:unit*0.46)}
                        }.frame(width:unit*0.85,height:unit*0.85).contentShape(Rectangle())
                    }.buttonStyle(.plain).position(point(node.id,size:geo.size)).accessibilityLabel("节点 N\(node.id)，\(node.observedKind.name)，\(mustPass.contains(node.id) ? "必须经过" : "非必经")，\(map.currentNodeID==node.id ? "当前位置" : "")").accessibilityIdentifier("node-\(node.id)")
                }
            }.scaleEffect(viewport.scale*magnification).offset(x:viewport.translation.width+drag.width,y:viewport.translation.height+drag.height)
        }.clipped().contentShape(Rectangle()).gesture(DragGesture(minimumDistance:12).updating($drag){value,state,_ in state=value.translation}.onEnded{viewport.translation.width += $0.translation.width;viewport.translation.height += $0.translation.height}).simultaneousGesture(MagnificationGesture().updating($magnification){value,state,_ in state=value}.onEnded{viewport.scale=min(3,max(0.7,viewport.scale*$0))})
    }.aspectRatio(MapBoardMetrics.aspectRatio(rows:map.rows,columns:map.columns),contentMode:.fit).clipShape(RoundedRectangle(cornerRadius:12))}
}
struct MapWorkspaceView:View {
    @Bindable var model:AppModel;var wide:Bool
    var body:some View {ScrollView{VStack(alignment:.leading,spacing:20){
        HStack{VStack(alignment:.leading,spacing:4){Text("BLACKSTREAM / 0\(model.store.session.map.floor)").font(.caption2.monospaced()).tracking(2).foregroundStyle(ThemeTokens.capsuleRim.color);Text("第 \(model.store.session.map.floor) 层").font(.title2).fontDesign(.serif)};Spacer();Text("AP \(model.store.session.resources.actionPoints)").monospacedDigit();Button("撤销"){model.undo()}.disabled(!model.store.canUndo)}
        if model.store.session.title.contains("合成") {StatusLabel(text:"合成示例 · 不是已识别的游戏地图",warning:true)}
        if model.store.isComputing {HStack{ProgressView();Text("计算中");Spacer();Button("取消计算"){model.cancel()}}}
        else if !model.store.session.routesAreCurrent && model.store.session.routes != nil {StatusLabel(text:"已过期：修改后的地图/资源需要重新规划",warning:true)}
        MapCanvasView(map:model.store.session.map,mustPass:model.store.session.mustPass,route:model.store.session.routesAreCurrent ? model.selectedRoute : nil,selected:model.navigation.selectedNodeID,viewport:$model.viewport){model.select($0,open:!wide)}
        HStack{Button("缩小"){model.viewport.scale=max(0.7,model.viewport.scale/1.2)};Button("放大"){model.viewport.scale=min(3,model.viewport.scale*1.2)};Button("重置视口"){model.viewport=MapViewport()}}.buttonStyle(.bordered).frame(minHeight:44)
        Text("流线：徒步道路 · 虚线：待确认 · 金线：推荐路线").font(.footnote).foregroundStyle(ThemeTokens.textSecondary.color)
        ActionCapsule(title:"导入地图截图",symbol:"photo"){model.importPurpose = .map}
        HStack{NavigationLink("加工品与资源",value:AppPage.inventory);NavigationLink("规划条件与推荐路线",value:AppPage.planning)}.buttonStyle(.bordered).frame(minHeight:44)
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
