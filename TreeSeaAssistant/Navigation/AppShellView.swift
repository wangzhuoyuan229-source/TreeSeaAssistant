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
            }.background(ThemeTokens.background.color).foregroundStyle(ThemeTokens.textPrimary.color)
        }.navigationDestination(for:AppPage.self){destination in
            switch destination {
            case .inventory:InventoryView(model:model)
            case .planning:PlanRequestView(model:model)
            case .roads:RoadEditorView(model:model)
            case .manualMap:ManualMapView(model:model)
            case let .route(signature):if let snapshot=model.navigation.routePages[signature] {RouteDetailView(model:model,route:snapshot.route,sourceStamp:snapshot.stamp,sourcePredictionID:snapshot.predictionID)} else {StatusLabel(text:"这份路线已不可用，请返回重新选择",warning:true)}
            }
        }}
        .sheet(item:$model.importPurpose){purpose in ScreenshotImportView(model:model,purpose:purpose)}
        .sheet(item:$model.nodeDraft){draft in NodeEditorView(model:model,node:draft.node)}
        .alert("操作未完成",isPresented:Binding(get:{model.error != nil},set:{if !$0 {model.error=nil}})){Button("知道了"){model.error=nil}}message:{Text(model.error ?? "")}
        .task{model.recompute()}
    }
    private var sidebar:some View {VStack(alignment:.leading,spacing:20){Image("emblem").resizable().scaledToFit().frame(height:90).accessibilityHidden(true);Text("黑流树海").font(.title2.weight(.light)).fontDesign(.serif);ForEach(AppSection.allCases){section in Button{model.navigation.selectedSection=section}label:{Label(section.title,systemImage:section.symbol).frame(maxWidth:.infinity,minHeight:52,alignment:.leading)}.buttonStyle(.bordered).tint(model.navigation.selectedSection==section ? ThemeTokens.capsuleRim.color : ThemeTokens.textSecondary.color)};Spacer()}}
    @ViewBuilder private func page(_ section:AppSection,mode:LayoutMode) -> some View {switch section {case .map:MapWorkspaceView(model:model,wide:mode != .singleColumn);case .sessions:SessionHomeView(model:model);case .settings:SettingsView(model:model)}}
}
struct SessionHomeView:View {
    @Bindable var model:AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    var body:some View {ScrollView{VStack(alignment:.leading,spacing:24){
        ZStack(alignment:.bottomLeading){Image(sizeClass == .regular ? "cover-pad":"cover-phone").resizable().scaledToFill().frame(height:220).clipped().accessibilityHidden(true);Text("黑流树海").font(.largeTitle.weight(.light)).fontDesign(.serif).padding(20).background(ThemeTokens.background.color.opacity(0.85),in:RoundedRectangle(cornerRadius:16))}.clipShape(RoundedRectangle(cornerRadius:20))
        InkPanel{VStack(alignment:.leading,spacing:16){Text(model.store.session.title).font(.title3);Text("第 \(model.store.session.map.floor) 层 · AP \(model.store.session.resources.actionPoints) · 必经 \(model.store.session.mustPass.count)/8").monospacedDigit();ActionCapsule(title:"继续探索",symbol:"arrow.right"){model.navigation.selectedSection = .map}}}
        ActionCapsule(title:"导入地图截图",symbol:"photo"){model.importPurpose = .map}
        ActionCapsule(title:"导入背包 / 加工品",symbol:"shippingbox"){model.importPurpose = .inventory}
        NavigationLink("手动新建地图",value:AppPage.manualMap).buttonStyle(.bordered).frame(minHeight:44)
        Text("本地会话").font(.title2).fontDesign(.serif)
        if model.savedSessions.isEmpty {StatusLabel(text:"暂无已保存的会话。合成示例供操作演示。")}
        ForEach(model.savedSessions){session in Button{model.restore(session);model.navigation.selectedSection = .map}label:{InkPanel{VStack(alignment:.leading){Text(session.title);Text("第 \(session.map.floor) 层 · AP \(session.resources.actionPoints)").font(.subheadline).foregroundStyle(ThemeTokens.textSecondary.color)}}}.buttonStyle(.plain)}
    }.padding(20).frame(maxWidth:720)}.navigationTitle("会话")}
}
struct SettingsView:View {
    @Bindable var model:AppModel
    var body:some View {Form{
        Section("离线规则资料"){Text("参考资料版本：\(model.catalog.rules.version)");Text("源码参照未视为当前游戏实测。只有你已核对规则并接受其限制时，才启用距离及数量强约束。").foregroundStyle(ThemeTokens.textSecondary.color)
            Toggle("我已核对当前规则，启用强约束",isOn:Binding(get:{model.store.session.reviewedRules},set:{model.apply(.reviewedRules($0))}))}
        Section("识别与模型"){Text("地图文字使用 Apple Vision；道路模型已通过合成输出对照。实际截图支持范围仍待逐层回放验收，导入后必须核对节点和道路。");Text("仅第一至第五层；不含概率、实时录屏、小窗或联网识别。")}
        Section("本地记录"){Text("截图处理与规划在设备上完成。会话为本地 JSON；查看路线不会扣除真实库存。");Button("新建合成示例"){model.newDemo()}}
        Section("来源与许可"){Text("MAA 59bd4ce · AGPL-3.0\nhlsh-helper b81965b · 复用许可待确认\n原版图标：路标；美术：本地自建素材").font(.footnote)}
    }.scrollContentBackground(.hidden).navigationTitle("设置")}
}
