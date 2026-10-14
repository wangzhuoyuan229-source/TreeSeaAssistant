import SwiftUI
struct AppShellView:View {
    @Bindable var model:AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var textSize
    var body:some View {
        NavigationStack(path:$model.navigation.path){GeometryReader{geometry in
            let width=geometry.size.width-geometry.safeAreaInsets.leading-geometry.safeAreaInsets.trailing-48
            let mode=AdaptiveLayout.resolve(availableContentWidth:width,isCompact:sizeClass == .compact,isAccessibilityTextSize:textSize.isAccessibilitySize)
            Group{
                if mode == .singleColumn {
                    TabView(selection:$model.navigation.selectedSection){ForEach(AppSection.allCases){section in page(section,mode:mode).tabItem{Label(section.title,systemImage:section.symbol)}.tag(section)}}
                } else {
                    HStack(spacing:20){
                            if mode == .threeColumns {sidebar.frame(width:240)}
                            VStack{if mode == .twoColumns {Picker("主入口",selection:$model.navigation.selectedSection){ForEach(AppSection.allCases){Text($0.title).tag($0)}}.pickerStyle(.segmented)};page(model.navigation.selectedSection,mode:mode)}
                            if model.navigation.selectedSection == .map {ScrollView{NodeInspectorView(model:model)}.frame(width:300)}
                        }.padding(24)
                }
            }.background(AppBackdrop()).foregroundStyle(ThemeTokens.textPrimary.color)
        }.navigationDestination(for:AppPage.self){destination in
            Group{switch destination {
            case .inventory:InventoryView(model:model)
            case .planning:PlanRequestView(model:model)
            case .roads:RoadEditorView(model:model)
            case .manualMap:ManualMapView(model:model)
            case let .route(signature):if let snapshot=model.navigation.routePages[signature] {RouteDetailView(model:model,route:snapshot.route,sourceStamp:snapshot.stamp,sourcePredictionID:snapshot.predictionID)} else {StatusLabel(text:"这份路线已不可用，请返回重新选择",warning:true)}
            }}.background(AppBackdrop())
        }}
        .background(AppBackdrop()).scrollContentBackground(.hidden)
        .sheet(item:$model.importPurpose){purpose in ScreenshotImportView(model:model,purpose:purpose)}
        .sheet(item:$model.nodeDraft){draft in NodeEditorView(model:model,node:draft.node).scrollContentBackground(.hidden).background(AppBackdrop())}
        .alert("操作未完成",isPresented:Binding(get:{model.error != nil},set:{if !$0 {model.error=nil}})){Button("知道了"){model.error=nil}}message:{Text(model.error ?? "")}
        .task{model.recompute()}
    }
    private var sidebar:some View {VStack(alignment:.leading,spacing:20){Image("emblem").resizable().scaledToFit().frame(height:90).accessibilityHidden(true);Text("黑流树海").font(.title2.weight(.light)).fontDesign(.serif);ForEach(AppSection.allCases){section in Button{model.navigation.selectedSection=section}label:{Label(section.title,systemImage:section.symbol).frame(maxWidth:.infinity,minHeight:52,alignment:.leading)}.buttonStyle(.bordered).tint(model.navigation.selectedSection==section ? ThemeTokens.capsuleRim.color : ThemeTokens.textSecondary.color)};Spacer()}}
    @ViewBuilder private func page(_ section:AppSection,mode:LayoutMode) -> some View {Group{switch section {case .map:MapWorkspaceView(model:model,wide:mode != .singleColumn);case .sessions:SessionHomeView(model:model);case .settings:SettingsView(model:model)}}.background(AppBackdrop())}
}
struct SessionHomeView:View {
    @Bindable var model:AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    var body:some View {ScrollView{VStack(alignment:.leading,spacing:24){
        ZStack(alignment:.bottomLeading){
            GeometryReader{geo in Image(sizeClass == .regular ? "cover-pad":"cover-phone").resizable().scaledToFill().frame(width:geo.size.width,height:geo.size.height).clipped()}.accessibilityHidden(true)
            LinearGradient(colors:[.clear,ThemeTokens.background.color.opacity(0.8)],startPoint:.center,endPoint:.bottom)
            VStack(alignment:.leading,spacing:10){
                Text("FIELD ATLAS / 06").font(.caption2.monospaced()).tracking(2.5).foregroundStyle(ThemeTokens.capsuleRim.color)
                Text("黑流树海").font(.system(size:38,weight:.light,design:.serif)).tracking(3)
                Text("在未知之中，寻一条去路。 ").font(.subheadline).foregroundStyle(ThemeTokens.textPrimary.color.opacity(0.8))
            }.padding(24)
        }.frame(height:sizeClass == .regular ? 300:250).clipShape(RoundedRectangle(cornerRadius:14))
        Button{model.navigation.selectedSection = .map}label:{
            HStack(spacing:16){
                Image(systemName:"point.topleft.down.to.point.bottomright.curvepath").font(.title2).foregroundStyle(ThemeTokens.capsuleRim.color)
                VStack(alignment:.leading,spacing:7){Text(model.store.session.title).font(.headline);Text("第 \(model.store.session.map.floor) 层   /   AP \(model.store.session.resources.actionPoints)   /   必经 \(model.store.session.mustPass.count)").font(.caption.monospaced()).foregroundStyle(ThemeTokens.textSecondary.color)}
                Spacer();Image(systemName:"arrow.right").foregroundStyle(ThemeTokens.capsuleRim.color)
            }.padding(20).frame(maxWidth:.infinity,alignment:.leading).background(ThemeTokens.inkSurface.color.opacity(0.95),in:RoundedRectangle(cornerRadius:12))
        }.buttonStyle(.plain).accessibilityLabel("继续探索")
        VStack(spacing:12){
            ActionCapsule(title:"导入地图截图",symbol:"viewfinder"){model.importPurpose = .map}
            ActionCapsule(title:"导入背包 / 加工品",symbol:"shippingbox"){model.importPurpose = .inventory}
            NavigationLink(value:AppPage.manualMap){HStack{Text("手动新建地图");Spacer();Image(systemName:"plus")}.font(.subheadline).padding(.vertical,12)}.frame(minHeight:44)
        }
        HStack{Text("本地会话").font(.title3.weight(.medium));Spacer();Text("ON DEVICE").font(.caption2.monospaced()).tracking(2).foregroundStyle(ThemeTokens.textSecondary.color)}.padding(.top,8)
        if model.savedSessions.isEmpty {StatusLabel(text:"暂无保存记录。导入地图，或从示例开始。")}
        ForEach(model.savedSessions){session in Button{model.restore(session);model.navigation.selectedSection = .map}label:{HStack{VStack(alignment:.leading,spacing:6){Text(session.title);Text("第 \(session.map.floor) 层 · AP \(session.resources.actionPoints)").font(.caption.monospaced()).foregroundStyle(ThemeTokens.textSecondary.color)};Spacer();Image(systemName:"chevron.right").font(.caption)}.padding(.vertical,16).overlay(alignment:.bottom){Rectangle().fill(ThemeTokens.textSecondary.color.opacity(0.15)).frame(height:1)}}.buttonStyle(.plain)}
    }.padding(20).frame(maxWidth:900).frame(maxWidth:.infinity)}.navigationTitle("会话").background(AppBackdrop())}
}
struct SettingsView:View {
    @Bindable var model:AppModel
    var body:some View {Form{
        Section("离线规则资料"){Text("参考资料版本：\(model.catalog.rules.version)");Text("源码参照未视为当前游戏实测。只有你已核对规则并接受其限制时，才启用距离及数量强约束。").foregroundStyle(ThemeTokens.textSecondary.color)
            Toggle("我已核对当前规则，启用强约束",isOn:Binding(get:{model.store.session.reviewedRules},set:{model.apply(.reviewedRules($0))}))}
        Section("识别与模型"){Text("地图文字使用 Apple Vision；道路模型已通过合成输出对照。实际截图支持范围仍待逐层回放验收，导入后必须核对节点和道路。");Text("支持第一至第五层。统计权重来自已收录资料；截图和规划均在本地处理。")}
        Section("本地记录"){Text("截图处理与规划在设备上完成。会话为本地 JSON；查看路线不会扣除真实库存。");Button("新建合成示例"){model.newDemo()}}
        Section("来源与许可"){Text("MAA 59bd4ce · AGPL-3.0\nhlsh-helper b81965b · 复用许可待确认\n原版图标：路标；美术：本地自建素材").font(.footnote)}
    }.scrollContentBackground(.hidden).navigationTitle("设置")}
}
