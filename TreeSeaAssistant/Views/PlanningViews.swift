import SwiftUI
import TreeSeaCore
struct CandidateDetailView:View {
    @Bindable var model:AppModel;var nodeID:NodeID
    var body:some View {InkPanel{VStack(alignment:.leading,spacing:12){Text("可能类型").font(.title3)
        if let node=model.store.session.map.node(nodeID),node.originalKind == .unknownFerocity {StatusLabel(text:"待揭示：未知凶戾不生成类型候选",warning:true)}
        else if let result=model.store.session.prediction,model.store.session.predictionIsCurrent,let candidates=result.candidates[nodeID]{
            Text(candidates.count==1 ? "按当前规则唯一 · 身份仍未揭示":"候选顺序不代表出现倾向").font(.subheadline)
            if candidates.isEmpty {StatusLabel(text:"当前规则无可用候选，请复核节点与规则",warning:true)}
            ForEach(candidates,id:\.self){kind in HStack{GameIcon(kind:kind).frame(width:36,height:36);Text(kind.name)}}
            if let distance=result.distances[nodeID]{Text("出生点图距离：\(distance)").monospacedDigit()}
            Text("全图约束：\(status(result.propagationStatus))").font(.footnote)
            ForEach(result.exclusions[nodeID] ?? [],id:\.kind){reason in Text("排除 \(reason.kind.name)：\(reason.explanation)").font(.footnote)}
            ForEach(result.warnings,id:\.self){StatusLabel(text:$0,warning:true)}
        } else {StatusLabel(text:"该节点没有当前有效候选；请确认原始身份并重新计算。")}
    }}}
    private func status(_ value:PropagationStatus) -> String {switch value{case .complete:"已完成";case .conflict:"资料冲突，保留局部筛选";case .skippedIncompleteCoverage:"原始覆盖 / 拓扑未完整确认，已跳过";case .skippedUnverifiedRules:"规则未核对，已跳过";case .incomplete:"预算内未完成";case .cancelled:"已取消";case .invalidInput:"地图无效";case .localOnly:"仅局部筛选"}}
}
struct PlanRequestView:View {
    @Bindable var model:AppModel
    @FocusState private var editingAP:Bool
    var body:some View {ScrollView{VStack(alignment:.leading,spacing:20){
        InkPanel{VStack(alignment:.leading,spacing:16){Text("规划条件").font(.title2).fontDesign(.serif);TextField("当前行动力",text:$model.apDraft).keyboardType(.numberPad).focused($editingAP).textFieldStyle(.roundedBorder);ActionCapsule(title:"确认 AP 并重新规划",symbol:"checkmark",disabled:Int(model.apDraft)==nil){if let ap=Int(model.apDraft){editingAP=false;model.apply(.actionPoints(ap))}};Text("必经 \(model.store.session.mustPass.count)/8 · 按实际经过 / 飞行落点判断");ForEach(model.store.session.mustPass.sorted(),id:\.self){Text("N\($0) 必须经过")};Text("请在地图或节点列表中选择必经节点。未知及已完成节点均可选。").font(.footnote)}}
        NavigationLink("编辑道路 / 出生点覆盖",value:AppPage.roads).buttonStyle(.bordered).frame(minHeight:44)
        NavigationLink("加工品与次数",value:AppPage.inventory).buttonStyle(.bordered).frame(minHeight:44)
        ActionCapsule(title:model.store.isComputing ? "取消计算":"重新计算",symbol:model.store.isComputing ? "xmark":"arrow.clockwise"){if model.store.isComputing{model.cancel()}else{model.recompute()}}
        RouteComparisonView(model:model)
    }.padding(20)}.navigationTitle("规划与路线").toolbar{ToolbarItemGroup(placement:.keyboard){Spacer();Button("完成"){editingAP=false}}}}
}
struct RouteComparisonView:View {
    @Bindable var model:AppModel
    var body:some View {VStack(alignment:.leading,spacing:16){Text(model.store.session.routesAreCurrent ? "推荐路线":"上次路线 · 待更新").font(.title2).fontDesign(.serif)
        if let failure=model.store.session.latestPlanningFailure,failure.stamp==model.store.session.stamp {
            StatusLabel(text:failure.status == .noFeasibleRoute ? "本次：在当前模型内无可行路线；保留上次路线供回看" : failure.status == .invalidInput ? "本次：请确认出生点、位置、出口与资源" : "本次：预算内暂未求得；保留上次有效路线",warning:true)
            ForEach(failure.warnings,id:\.self){StatusLabel(text:$0,warning:true)}
        }
        if let result=model.store.session.routes {
            if !model.store.session.routesAreCurrent {StatusLabel(text:"已过期，仅供回看；请重新规划",warning:true)}
            switch result.status {case .feasible:Text("找到 \(result.recommendations.count) 条不同路线");case .noFeasibleRoute:StatusLabel(text:"在当前已确认模型内无可行路线；未放宽必经条件",warning:true);case .unresolved:StatusLabel(text:"预算或保留限制内暂未求得，不等于无解",warning:true);case .cancelled:StatusLabel(text:"已取消，保留上次有效结果");case .invalidInput:StatusLabel(text:"请确认出口、AP 与地图身份",warning:true)}
            ForEach(result.warnings,id:\.self){StatusLabel(text:$0,warning:true)}
            ForEach(result.recommendations){route in Button{model.navigation.routePages[route.signature]=RoutePageSnapshot(route:route,stamp:result.stamp,predictionID:result.predictionID);model.navigation.path.append(AppPage.route(route.signature))}label:{InkPanel{VStack(alignment:.leading,spacing:12){Text(route.badges.isEmpty ? "备选路线" : route.badges.map(\.name).joined(separator:" / ")).font(.headline);Text("App 偏好分 \(Double(route.scoreUnits)/4, specifier:"%.2f") · 毛消耗 \(route.grossAP) AP · 余额 \(route.finalState.ap)").monospacedDigit();Text("加工品 \(route.itemUses) 次 · 必经覆盖 \(route.covered.count)/\(model.store.session.mustPass.count)");Text("按当前估计可执行；战斗与事件副作用不在资源保证内").font(.footnote).foregroundStyle(ThemeTokens.textSecondary.color)}}}.buttonStyle(.plain)}
        } else {StatusLabel(text:"确认地图、出口与资源后计算路线")}
    }}
}
struct RouteDetailView:View {
    @Bindable var model:AppModel;var route:RouteRecommendation
    var sourceStamp:RevisionStamp;var sourcePredictionID:UUID
    private var isCurrent:Bool {model.store.session.routesAreCurrent && sourceStamp==model.store.session.stamp && sourcePredictionID==model.store.session.prediction?.predictionID}
    @Environment(\.dismiss) private var dismiss
    var body:some View {ScrollView{VStack(alignment:.leading,spacing:20){
        StatusLabel(text:"查看方案不会消耗真实库存")
        if !isCurrent {StatusLabel(text:"已过期：以下为历史步骤，需重新规划",warning:true)}
        Text("必经覆盖：\(route.covered.sorted().map{"N\($0) ✓"}.joined(separator:"、"))")
        Text("AP 毛消耗 \(route.grossAP)，结束余额 \(route.finalState.ap)；保守战斗代价 \(Double(route.battleRisk)/4,specifier:"%.1f") 分")
        ActionCapsule(title:"在地图上查看此路线",symbol:"map",disabled:!isCurrent){model.navigation.selectedRouteSignature=route.signature;model.navigation.selectedSection = .map;dismiss()}
        ForEach(Array(route.steps.enumerated()),id:\.offset){index,step in InkPanel{VStack(alignment:.leading,spacing:12){Text("步骤 \(index+1)：N\(step.action.from) → N\(step.action.to)").font(.headline);if !step.action.isFlight {Text("实际经过："+step.action.walkPath.map{"N\($0)"}.joined(separator:" → "))};Text(step.action.itemType.flatMap{model.movements.spec($0)?.name} ?? "徒步");Text("AP \(step.beforeAP) − \(step.action.cost) → \(step.afterAP)").monospacedDigit();if let remaining=step.remainingCharges {Text("实例 \(step.action.itemInstanceID?.uuidString.prefix(4) ?? "")，剩余 \(remaining) 次")};Text("确认加工品增益：AP +\(step.action.gain.ap)、希望 +\(step.action.gain.hope)、源石锭 +\(step.action.gain.ingots)");Text("评分：收益 \(step.score.reward)/4 − AP \(step.score.apPenalty)/4 − 道路 \(step.score.edgePenalty)/4 − 加工品 \(step.score.itemPenalty)/4 − 战斗 \(step.score.battlePenalty)/4 + 资源 \(step.score.resourceReward)/4").font(.footnote);ForEach(step.assumptions,id:\.self){StatusLabel(text:$0,warning:true)}}}}
        Text("确认希望增量 +\(route.finalState.hopeDelta)、源石锭增量 +\(route.finalState.ingotDelta)；未记录的初始总额不会补成 0。")
    }.padding(20)}.navigationTitle("步骤台账").onAppear{model.navigation.selectedRouteSignature=route.signature}}
}
