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
    static func kind(for text:String) -> NodeKind? {
        let lexicon:[(String,NodeKind)]=[("未知的诡秘",.unknownMystery),("未知诡秘",.unknownMystery),("未知的凶戾",.unknownFerocity),("未知凶戾",.unknownFerocity),("紧急作战",.emergencyBattle),("作战",.battle),("林间空地",.empty),("起点",.start),("险路尽头",.exit)]+NodeKind.allCases.filter{!$0.isHidden}.map{($0.name,$0)}
        return lexicon.first(where:{text.contains($0.0)})?.1
    }

    static func isMapLabel(_ text:String) -> Bool {kind(for:text) != nil || text.contains("曲折密道")}

    private static func median(_ values:[Double]) -> Double {let v=values.sorted();return v[v.count/2]}
    private static func clusters(_ values:[Double],tolerance:Double) -> [Double] {
        var groups:[[Double]]=[]
        for value in values.sorted() {
            if let last=groups.last,abs(value-median(last))<=tolerance {groups[groups.count-1].append(value)}
            else {groups.append([value])}
        }
        return groups.map(median)
    }
    private static func line(_ values:[Double],pitch:Double) -> (origin:Double,step:Double) {
        let indices=values.map{(($0-values[0])/pitch).rounded()},n=Double(values.count)
        let meanI=indices.reduce(0,+)/n,meanV=values.reduce(0,+)/n
        let denominator=indices.reduce(0){$0+pow($1-meanI,2)}
        let step=zip(indices,values).reduce(0){$0+($1.0-meanI)*($1.1-meanV)}/denominator
        return (meanV-step*meanI,step)
    }

    // Small completed/current nodes are dark discs with a pale circular rim. They are
    // nested in roads and glows, so Vision's top-level contours cannot isolate them.
    private struct Pixels {
        var values:[UInt8];var width:Int;var height:Int
        init(_ image:CGImage) throws {
            width=image.width;height=image.height
            var data=[UInt8](repeating:0,count:width*height*4)
            let rendered=data.withUnsafeMutableBytes {buffer -> Bool in
                guard let context=CGContext(data:buffer.baseAddress,width:image.width,height:image.height,bitsPerComponent:8,bytesPerRow:image.width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else {return false}
                context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height));return true
            }
            guard rendered else {throw ScreenshotError.invalidImage};values=data
        }
        func luminance(x:Double,y:Double) -> Double {
            let col=min(width-1,max(0,Int(x.rounded()))),row=min(height-1,max(0,Int(y.rounded()))),i=(row*width+col)*4
            return (0.2126*Double(values[i])+0.7152*Double(values[i+1])+0.0722*Double(values[i+2]))/255
        }
        func ring(x:Double,y:Double,pitch:Double) -> Double {
            guard x>pitch*0.12,y>pitch*0.12,x<Double(width)-pitch*0.12,y<Double(height)-pitch*0.12 else {return 0}
            var best=0.0
            for fraction in [0.04,0.0475,0.055,0.0625,0.07,0.0775,0.085] {
                let radius=pitch*fraction
                var sum=0.0,positive=0
                for index in 0..<24 {
                    let angle=Double(index)*Double.pi/12,dx=cos(angle)*radius,dy=sin(angle)*radius
                    let difference=luminance(x:x+dx,y:y+dy)-(luminance(x:x+dx*0.5,y:y+dy*0.5)+luminance(x:x+dx*1.65,y:y+dy*1.65))/2
                    sum+=difference;if difference>0.015 {positive+=1}
                }
                if positive>=15 {best=max(best,sum/24)}
            }
            return best
        }
        func disc(near point:Point2D,pitch:Double) -> (point:Point2D,score:Double) {
            var best=(point,0.0)
            let shift=max(1,pitch*0.025)
            for dx in -2...2 {for dy in -2...2 {
                let p=Point2D(x:point.x+Double(dx)*shift,y:point.y+Double(dy)*shift),score=ring(x:p.x,y:p.y,pitch:pitch)
                if score>best.1 {best=(p,score)}
            }}
            return best
        }
    }

    static func detect(in screenshot:PreparedScreenshot,texts:[RecognizedText],image:CGImage) throws -> [DetectedCenter] {
        let labels=texts.filter{isMapLabel($0.text)}
        let fallback=labels.count<3 ? labels.map{DetectedCenter(x:$0.center.x,y:$0.center.y-30,kind:kind(for:$0.text),ambiguous:$0.confidence<0.8)} : []
        let xs=clusters(labels.map(\.center.x),tolerance:12)
        guard labels.count>=3,xs.count>=3 else {return fallback}
        let pitch=median(zip(xs.dropFirst(),xs).map{$0-$1})
        guard pitch>=32 else {return fallback}
        let ys=clusters(labels.map(\.center.y),tolerance:pitch*0.18)
        guard ys.count>=2 else {return fallback}
        let xAxis=line(xs,pitch:pitch),yAxis=line(ys,pitch:pitch)
        guard xAxis.origin.isFinite,yAxis.origin.isFinite,xAxis.step.isFinite,yAxis.step.isFinite,xAxis.step>=32,yAxis.step>=32,abs(xAxis.step-yAxis.step)<=pitch*0.12,
              xs.allSatisfy({abs(($0-xAxis.origin)/xAxis.step-(($0-xAxis.origin)/xAxis.step).rounded())<0.08}),
              ys.allSatisfy({abs(($0-yAxis.origin)/yAxis.step-(($0-yAxis.origin)/yAxis.step).rounded())<0.08}) else {return fallback}
        let columns=Int(((xs.last!-xAxis.origin)/xAxis.step).rounded())+1,rows=Int(((ys.last!-yAxis.origin)/yAxis.step).rounded())+1
        guard columns<=12,rows<=8 else {return fallback}
        var labelled:[Int:RecognizedText]=[:]
        // OCR variants with an uncertain name still locate a node; they do not establish its identity.
        for text in texts where text.text.unicodeScalars.contains(where:{(0x3400...0x9fff).contains($0.value)}) {
            let fx=(text.center.x-xAxis.origin)/xAxis.step,fy=(text.center.y-yAxis.origin)/yAxis.step,c=Int(fx.rounded()),r=Int(fy.rounded())
            guard (0..<columns).contains(c),(0..<rows).contains(r),abs(fx-Double(c))<0.12,abs(fy-Double(r))<0.2 else {continue}
            let id=r*columns+c
            if labelled[id]==nil || kind(for:text.text) != nil {labelled[id]=text}
        }
        let pixels=try Pixels(image)
        var bestOffset=0.25,bestScore=0.0,bestCount=0
        // Calibrate label-to-icon offset from the unlabelled discs, not a fixed pixel value.
        for tick in 12...40 {
            let offset=Double(tick)/100
            var score=0.0,count=0
            for row in 0..<rows {for col in -1...columns where labelled[row*columns+col]==nil || col<0 || col>=columns {
                let p=Point2D(x:xAxis.origin+Double(col)*xAxis.step,y:yAxis.origin+(Double(row)-offset)*yAxis.step)
                let value=pixels.disc(near:p,pitch:pitch).score
                if value>=0.045 {count+=1};score+=pow(max(0,value-0.035),2)
            }}
            if count>bestCount || count==bestCount && score>bestScore {bestScore=score;bestOffset=offset;bestCount=count}
        }
        guard bestCount>=2 else {return fallback}
        var discs:[(row:Int,col:Int,point:Point2D)]=[]
        for row in 0..<rows {for col in -1...columns where col<0 || col>=columns || labelled[row*columns+col]==nil {
            let point=Point2D(x:xAxis.origin+Double(col)*xAxis.step,y:yAxis.origin+(Double(row)-bestOffset)*yAxis.step)
            let disc=pixels.disc(near:point,pitch:pitch)
            if disc.score>=0.045 {discs.append((row,col,disc.point))}
        }}
        // Recenter the entire lattice on the actual rim locations. The broad offset
        // search must not leave every labelled icon several pixels above its centre.
        let originX=median(discs.map{$0.point.x-Double($0.col)*xAxis.step})
        let originY=median(discs.map{$0.point.y-Double($0.row)*yAxis.step})
        var result:[DetectedCenter]=[]
        for row in 0..<rows {for col in 0..<columns {
            if let text=labelled[row*columns+col] {
                result.append(DetectedCenter(x:originX+Double(col)*xAxis.step,y:originY+Double(row)*yAxis.step,kind:kind(for:text.text),ambiguous:text.confidence<0.8))
            }
        }}
        result+=discs.map{DetectedCenter(x:$0.point.x,y:$0.point.y)}
        return result
    }
}
// Future imported image-reference databases can supply a match without coupling
// recognition to a storage format. Return nil when no reliable match is available.
nonisolated protocol MapImageRecognitionDatabase: Sendable {
    var version:String {get}
    func proposal(for screenshot:PreparedScreenshot,floor:Int) async throws -> RecognitionProposal?
}

nonisolated enum ScreenshotRecognizer {
    static func texts(_ image:CGImage,width:Int,height:Int) throws -> [RecognizedText] {
        let request=VNRecognizeTextRequest();request.recognitionLevel = .accurate;request.recognitionLanguages=["zh-Hans","en-US"];request.usesLanguageCorrection=true
        try VNImageRequestHandler(cgImage:image).perform([request])
        return (request.results ?? []).sorted{ $0.boundingBox.midY > $1.boundingBox.midY }.compactMap {result in guard let candidate=result.topCandidates(1).first else {return nil};return RecognizedText(text:candidate.string,center:Point2D(x:result.boundingBox.midX*Double(width),y:(1-result.boundingBox.midY)*Double(height)),confidence:candidate.confidence)}
    }
    static func mapTexts(_ image:CGImage,width:Int,height:Int) throws -> [RecognizedText] {
        let full=try texts(image,width:width,height:height)
        guard full.filter({NodeCenterDetector.isMapLabel($0.text)}).count<3 else {return full}
        // A very wide HUD can make Vision choose the wrong text orientation. A second
        // pass on the central scene restores readable labels without guessing their names.
        let rect=CGRect(x:Double(width)*0.1,y:0,width:Double(width)*0.8,height:Double(height)).integral
        guard let crop=image.cropping(to:rect) else {return full}
        let local=try texts(crop,width:crop.width,height:crop.height)
        return local.map{RecognizedText(text:$0.text,center:Point2D(x:$0.center.x+rect.minX,y:$0.center.y+rect.minY),confidence:$0.confidence)}
    }
    @concurrent static func recognize(_ screenshot:PreparedScreenshot,floor:Int,catalog:TemplateCatalog,database:(any MapImageRecognitionDatabase)? = nil) async throws -> RecognitionProposal {
        if Task.isCancelled {throw ScreenshotError.cancelled}
        if let database {
            let candidate=try await database.proposal(for:screenshot,floor:floor)
            if Task.isCancelled {throw ScreenshotError.cancelled}
            if var proposal=candidate,let map=proposal.map,map.floor==floor {
                proposal.confirmed=false
                return proposal
            }
        }
        let image=try ImagePreprocessor.image(screenshot),texts=try mapTexts(image,width:screenshot.width,height:screenshot.height),centers=try NodeCenterDetector.detect(in:screenshot,texts:texts,image:image)
        let dimensions=[1:(3,5),2:(4,5),3:(5,7),4:(5,8),5:(5,10)]
        guard let (rows,columns)=dimensions[floor],let fit=GridFitter.fit(centers:centers,rows:rows,columns:columns),fit.coversAxes else {return RecognitionProposal(map:nil,warnings:["未形成可靠网格，请选择模板或手动建立地图"])}
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
            map.exitIDs=Set(nodes.filter{$0.observedKind == .exit && $0.identityEvidence == .directObservation}.map(\.id))
            let classifier=try? CorridorClassifier()
            for edge in template.map.edges where fit.occupied.contains(edge.a) && fit.occupied.contains(edge.b) {
                let a=fit.centers[edge.a]!.center,b=fit.centers[edge.b]!.center
                // Vision coordinates start at the top; the Core Graphics crop transform starts at the bottom.
                let score=try? classifier?.classify(image:image,from:CGPoint(x:a.x,y:Double(image.height)-a.y),to:CGPoint(x:b.x,y:Double(image.height)-b.y))
                if score?.hasEdge != false {map.edges.append(MapEdge(edge.a,edge.b,state:.inferred))}
            }
            return RecognitionProposal(map:map,warnings:match.warnings+["裁剪覆盖和出生点尚未确认；道路为待核对提案"])
        }
        var map=FloorMap(floor:floor,rows:rows,columns:columns,nodes:nodes,edges:[],start:nil);map.startEvidence = .unresolved
        map.exitIDs=Set(nodes.filter{$0.observedKind == .exit && $0.identityEvidence == .directObservation}.map(\.id))
        return RecognitionProposal(map:map,warnings:match.warnings)
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
