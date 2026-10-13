import Foundation
import Vision
import CoreGraphics
import TreeSeaCore
#if SWIFT_PACKAGE
import TreeSeaAppSupport
typealias RecognizedText = TreeSeaAppSupport.TextObservation
#else
typealias RecognizedText = TextObservation
#endif
nonisolated enum NodeCenterDetector {
    static func detect(in screenshot:PreparedScreenshot,texts:[RecognizedText],image:CGImage) throws -> [DetectedCenter] {
        var centers:[DetectedCenter]=[]
        let lexicon:[(String,NodeKind)]=[("未知的诡秘",.unknownMystery),("未知的凶戾",.unknownFerocity),("紧急作战",.emergencyBattle),("林间空地",.empty),("起点",.start),("险路尽头",.exit)]+NodeKind.allCases.filter{!$0.isHidden}.map{($0.name,$0)}
        for text in texts {if let kind=lexicon.first(where:{text.text.contains($0.0)})?.1 {centers.append(DetectedCenter(x:text.center.x,y:text.center.y-30,kind:kind,ambiguous:text.confidence<0.8))}}
        let request=VNDetectContoursRequest();request.maximumImageDimension=1280;request.detectsDarkOnLight=false
        try VNImageRequestHandler(cgImage:image).perform([request])
        if let observation=request.results?.first {
            for contour in observation.topLevelContours {
                let bounds=contour.normalizedPath.boundingBox,width=bounds.width*Double(screenshot.width),height=bounds.height*Double(screenshot.height)
                guard (18...110).contains(width),(18...110).contains(height),(0.65...1.5).contains(width/height),contour.pointCount>=12 else {continue}
                let x=bounds.midX*Double(screenshot.width),y=(1-bounds.midY)*Double(screenshot.height)
                if let index=centers.firstIndex(where:{hypot($0.center.x-x,$0.center.y-y)<32}) {centers[index].center=Point2D(x:x,y:y)}
                else {centers.append(DetectedCenter(x:x,y:y))}
            }
        }
        return centers
    }
}
nonisolated enum ScreenshotRecognizer {
    static func texts(_ image:CGImage,width:Int,height:Int) throws -> [RecognizedText] {
        let request=VNRecognizeTextRequest();request.recognitionLevel = .accurate;request.recognitionLanguages=["zh-Hans","en-US"];request.usesLanguageCorrection=true
        try VNImageRequestHandler(cgImage:image).perform([request])
        return (request.results ?? []).sorted{ $0.boundingBox.midY > $1.boundingBox.midY }.compactMap {result in guard let candidate=result.topCandidates(1).first else {return nil};return RecognizedText(text:candidate.string,center:Point2D(x:result.boundingBox.midX*Double(width),y:(1-result.boundingBox.midY)*Double(height)),confidence:candidate.confidence)}
    }
    @concurrent static func recognize(_ screenshot:PreparedScreenshot,floor:Int,catalog:TemplateCatalog) async throws -> RecognitionProposal {
        if Task.isCancelled {throw ScreenshotError.cancelled}
        let image=try ImagePreprocessor.image(screenshot),texts=try texts(image,width:screenshot.width,height:screenshot.height),centers=try NodeCenterDetector.detect(in:screenshot,texts:texts,image:image)
        let dimensions=[1:(3,5),2:(4,5),3:(5,7),4:(5,8),5:(5,10)]
        guard let (rows,columns)=dimensions[floor],let fit=GridFitter.fit(centers:centers,rows:rows,columns:columns) else {return RecognitionProposal(map:nil,warnings:["未形成可靠网格，请选择模板或手动建立地图"])}
        let match=TemplateMatcher.match(occupied:fit.occupied,grid:fit,catalog:catalog,floor:floor)
        var nodes=fit.centers.keys.sorted().map {id -> MapNode in
            let detection=fit.centers[id]!
            var node=MapNode(id:id,row:id/columns,column:id%columns,kind:detection.kind ?? .unknown)
            node.identityEvidence=detection.kind==nil || detection.ambiguous ? .unresolved : .directObservation
            node.traversalEvidence = .unresolved
            return node
        }
        if let id=match.selectedID,let template=catalog.templates.first(where:{$0.id==id}) {
            for i in nodes.indices where match.proposedExitIDs.contains(nodes[i].id) && nodes[i].observedKind == .unknown {nodes[i].observedKind = .exit;nodes[i].originalKind = .exit;nodes[i].identityEvidence = .templateInferred}
            var map=FloorMap(floor:floor,rows:rows,columns:columns,nodes:nodes,edges:[],start:nil)
            map.templateID=id;map.startEvidence = .unresolved
            let classifier=try? CorridorClassifier()
            for edge in template.map.edges where fit.occupied.contains(edge.a) && fit.occupied.contains(edge.b) {
                let a=fit.centers[edge.a]!.center,b=fit.centers[edge.b]!.center
                let score=try? classifier?.classify(image:image,from:CGPoint(x:a.x,y:a.y),to:CGPoint(x:b.x,y:b.y))
                if score?.hasEdge != false {map.edges.append(MapEdge(edge.a,edge.b,state:.inferred))}
            }
            return RecognitionProposal(map:map,warnings:match.warnings+["裁剪覆盖和出生点尚未确认；道路为待核对提案"])
        }
        return RecognitionProposal(map:FloorMap(floor:floor,rows:rows,columns:columns,nodes:nodes,edges:[],start:nil),warnings:match.warnings)
    }
}
nonisolated enum InventoryRecognizer {
    @concurrent static func recognize(_ screenshot:PreparedScreenshot,catalog:MovementCatalog,coverage:InventoryObservationCoverage) async throws -> InventoryProposal {
        let image=try ImagePreprocessor.image(screenshot),texts=try ScreenshotRecognizer.texts(image,width:screenshot.width,height:screenshot.height)
        if Task.isCancelled {throw ScreenshotError.cancelled}
        let absolute=texts.map {text -> RecognizedText in
            let point=screenshot.transform.toOriginal(CGPoint(x:text.center.x,y:text.center.y))
            return RecognizedText(text:text.text,center:Point2D(x:point.x,y:point.y),confidence:text.confidence)
        }
        return InventoryTextParser.parse(absolute,catalog:catalog,digest:screenshot.digest,coverage:coverage)
    }
    @concurrent static func recognizeMovePreview(_ screenshot:PreparedScreenshot,from:NodeID?,target:NodeID?,itemInstanceID:UUID?) async throws -> MovementPreviewProposal {
        let image=try ImagePreprocessor.image(screenshot),texts=try ScreenshotRecognizer.texts(image,width:screenshot.width,height:screenshot.height)
        return InventoryTextParser.movePreview(texts,from:from,target:target,itemInstanceID:itemInstanceID)
    }
}
