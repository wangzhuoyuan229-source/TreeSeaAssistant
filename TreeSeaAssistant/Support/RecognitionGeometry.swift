import Foundation
import TreeSeaCore
nonisolated public struct Point2D: Codable, Sendable, Equatable { public var x: Double;public var y: Double;public init(x: Double,y: Double) {self.x=x;self.y=y} }
nonisolated public struct TextObservation: Sendable {
    public var text: String; public var center: Point2D; public var confidence: Float
    public init(text: String, center: Point2D = Point2D(x:0,y:0), confidence: Float = 1) {self.text=text;self.center=center;self.confidence=confidence}
}
nonisolated public struct DetectedCenter: Sendable {public var center: Point2D;public var kind: NodeKind?;public var ambiguous: Bool
    public init(x:Double,y:Double,kind:NodeKind? = nil,ambiguous:Bool = false) {center=Point2D(x:x,y:y);self.kind=kind;self.ambiguous=ambiguous}
}
nonisolated public struct GridFit: Sendable {
    public var origin: Point2D;public var step: Point2D;public var residual: Double;public var occupied: Set<NodeID>;public var centers: [NodeID:DetectedCenter];public var coversAxes: Bool
}
nonisolated public enum GridFitter {
    public static func fit(centers: [DetectedCenter], rows: Int, columns: Int) -> GridFit? {
        guard (1...64).contains(rows),(1...64).contains(columns),centers.count>=3,centers.allSatisfy({$0.center.x.isFinite && $0.center.y.isFinite}) else {return nil}
        func axis(_ values:[Double],count:Int) -> (Double,Double)? {
            let sorted=values.sorted();var clusters:[Double]=[]
            for value in sorted {if let last=clusters.last,abs(value-last)<12 {continue};clusters.append(value)}
            if count==1 {return (clusters.first ?? 0,1)}
            guard clusters.count>=min(3,count),let low=clusters.first,let high=clusters.last,high-low>10 else {return nil}
            let step=(high-low)/Double(count-1)
            guard clusters.allSatisfy({abs(($0-low)/step-(($0-low)/step).rounded())<=0.12}) else {return nil}
            return (low,step)
        }
        guard let x=axis(centers.map(\.center.x),count:columns),let y=axis(centers.map(\.center.y),count:rows) else {return nil}
        var assigned:[NodeID:DetectedCenter]=[:],sum=0.0
        for center in centers {
            let fx=(center.center.x-x.0)/x.1,fy=(center.center.y-y.0)/y.1,col=Int(fx.rounded()),row=Int(fy.rounded())
            guard (0..<columns).contains(col),(0..<rows).contains(row) else {return nil}
            sum += pow(fx-Double(col),2)+pow(fy-Double(row),2)
            let id=row*columns+col
            if let old=assigned[id] {
                var merged=old
                if let kind=center.kind { if let known=old.kind,known != kind {merged.ambiguous=true} else {merged.kind=kind} }
                assigned[id]=merged
            } else {assigned[id]=center}
        }
        let residual=sqrt(sum/Double(centers.count))
        guard residual<=0.12 else {return nil}
        return GridFit(origin:Point2D(x:x.0,y:y.0),step:Point2D(x:x.1,y:y.1),residual:residual,occupied:Set(assigned.keys),centers:assigned,coversAxes:Set(assigned.keys.map{$0%columns}).count==columns && Set(assigned.keys.map{$0/columns}).count==rows)
    }
}
nonisolated public struct TemplateMatchResult: Sendable {public var candidates:[String];public var selectedID:String?;public var proposedExitIDs:Set<NodeID>;public var warnings:[String]}
nonisolated public enum TemplateMatcher {
    public static func compatible(observedEdges:[MapEdge],recognizedNodeIDs:Set<NodeID>,catalog:TemplateCatalog,floor:Int) -> TemplateMatchResult {
        let actual=Set(observedEdges.filter{$0.state != .absent}.map {"\($0.a):\($0.b)"})
        let candidates=catalog.templates.filter{$0.map.floor==floor && actual.isSubset(of:Set($0.map.edges.map{"\($0.a):\($0.b)"}))}
        let selected=candidates.count==1 ? candidates[0] : nil
        return TemplateMatchResult(candidates:candidates.map(\.id).sorted(),selectedID:selected?.id,proposedExitIDs:selected?.map.exitIDs.intersection(recognizedNodeIDs) ?? [],warnings:selected==nil ? ["模板不唯一，不补充出口"] : ["模板仅提供推断身份与道路，提交前需人工确认"])
    }
    public static func match(occupied:Set<NodeID>,grid:GridFit,catalog:TemplateCatalog,floor:Int) -> TemplateMatchResult {
        var scores:[(MapTemplate,Double)]=[]
        for template in catalog.templates where template.map.floor==floor {
            let expected=Set(template.map.nodes.map(\.id)),matched=occupied.intersection(expected).count
            let recall=Double(matched)/Double(max(1,expected.count)),precision=Double(matched)/Double(max(1,occupied.count))
            let countScore=exp(-Double(abs(occupied.count-expected.count))/max(2,0.3*Double(expected.count)))
            scores.append((template,0.38*recall+0.54*precision+0.08*countScore))
        }
        scores.sort{ $0.1==$1.1 ? $0.0.id<$1.0.id : $0.1>$1.1 }
        guard let best=scores.first else {return TemplateMatchResult(candidates:[],proposedExitIDs:[],warnings:["没有该层模板"])}
        let margin=scores.count==1 ? 0.12 : best.1-scores[1].1,confidence=best.1*(0.82+0.18*min(1,max(0,margin/0.12)))
        let selected=confidence>=0.75 && margin>=0.025 && grid.coversAxes && grid.residual<=0.12 && occupied==Set(best.0.map.nodes.map(\.id))
        return TemplateMatchResult(candidates:Array(scores.prefix(5)).map{$0.0.id},selectedID:selected ? best.0.id : nil,proposedExitIDs:selected ? best.0.map.exitIDs.intersection(occupied) : [],warnings:selected ? ["模板结构匹配，节点与道路仍待人工确认"] : ["覆盖或模板分差不足，请手动选择并修正"])
    }
}
nonisolated public enum InventoryTextParser {
    static func matches(_ pattern:String,_ text:String) -> [String]? {
        guard let regex=try? NSRegularExpression(pattern:pattern),let match=regex.firstMatch(in:text,range:NSRange(text.startIndex...,in:text)) else {return nil}
        return (1..<match.numberOfRanges).map {index in guard let range=Range(match.range(at:index),in:text) else {return ""};return String(text[range])}
    }
    public static func parse(_ texts:[TextObservation],catalog:MovementCatalog,digest:String,coverage:InventoryObservationCoverage = .partial) -> InventoryProposal {
        var entries:[InventoryEntry]=[]
        for (index,text) in texts.enumerated() {
            guard let spec=catalog.movements.first(where:{([ $0.name ]+$0.aliases).contains(where:{text.text.contains($0)})}) else {continue}
            var content=text.text
            if index+1<texts.count, !catalog.movements.contains(where:{texts[index+1].text.contains($0.name)}), abs(texts[index+1].center.y-text.center.y)<100 {content += " "+texts[index+1].text}
            let digits=matches("(?:剩余|次数|可用)[^0-9]*([0-9]+)(?:\\s*/\\s*([0-9]+))?",content) ?? matches("([0-9]+)\\s*/\\s*([0-9]+)",content)
            var charges=digits.flatMap{Int($0[0])}
            var warning:String?
            if text.confidence<0.8 || charges == nil || charges!>100 || (digits?.count ?? 0)>1 && !(digits?[1].isEmpty ?? true) && Int(digits![1]) != spec.initialCharges {charges=nil;warning="剩余次数缺失或有歧义，请人工确认"}
            var entry=InventoryEntry(typeID:spec.id,remainingCharges:charges,effects:nil);entry.warning=warning
            entry.observationKey="slot-\(spec.id)-\(Int((text.center.x/32).rounded()))-\(Int((text.center.y/32).rounded()))"+(text.center.x==0 && text.center.y==0 ? "-line-\(index)" : "")
            entries.append(entry)
        }
        return InventoryProposal(digest:digest,coverage:coverage,entries:entries,warnings:entries.isEmpty ? ["未识别到名称，请手动添加；图标不替代次数确认"] : ["目录次数不会填入库存；增益需核对详情"])
    }
    public static func movePreview(_ texts:[TextObservation],from:NodeID?,target:NodeID?,itemInstanceID:UUID? = nil) -> MovementPreviewProposal {
        let text=texts.map(\.text).joined(separator:" ")
        let number=matches("[-−]\\s*([0-9]+)\\s*(?:AP|行动力)",text) ?? matches("(?:消耗|需要)\\s*(?:行动力|AP)[^0-9]*([0-9]+)",text)
        return MovementPreviewProposal(from:from,target:target,itemInstanceID:itemInstanceID,cost:number.flatMap{Int($0[0])})
    }
}
