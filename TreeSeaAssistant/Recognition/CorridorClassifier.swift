import Foundation
import CoreGraphics
import CoreML
nonisolated struct EdgeScore: Sendable {var rawLogit:Double;var hasEdge:Bool}
nonisolated final class CorridorClassifier {
    private let model:MLModel
    init() throws {
        #if SWIFT_PACKAGE
        guard let source=Bundle.module.url(forResource:"BlackFlowCorridor",withExtension:"mlpackage") else {throw ScreenshotError.modelUnavailable}
        let url=try MLModel.compileModel(at:source)
        #else
        guard let url=Bundle.main.url(forResource:"BlackFlowCorridor",withExtension:"mlmodelc") else {throw ScreenshotError.modelUnavailable}
        #endif
        let config=MLModelConfiguration();config.computeUnits = .cpuOnly
        model=try MLModel(contentsOf:url,configuration:config)
    }
    func classify(_ crops:[[Float]]) throws -> [EdgeScore] {
        try crops.map {crop in
            guard crop.count==3*40*160 else {throw ScreenshotError.invalidCrop}
            let array=try MLMultiArray(shape:[1,3,40,160],dataType:.float32)
            for i in crop.indices {array[i]=NSNumber(value:crop[i])}
            let input=try MLDictionaryFeatureProvider(dictionary:["input":MLFeatureValue(multiArray:array)]),output=try model.prediction(from:input)
            guard let logit=output.featureValue(for:"logit")?.multiArrayValue,logit.count>0 else {throw ScreenshotError.modelUnavailable}
            let value=logit[0].doubleValue
            return EdgeScore(rawLogit:value,hasEdge:value>=2.2421875)
        }
    }
    func classify(image:CGImage,from:CGPoint,to:CGPoint) throws -> EdgeScore {
        let distance=hypot(to.x-from.x,to.y-from.y),width=min(64,max(16,distance*0.3)),length=distance*(1-2*0.16)
        guard length>0 else {throw ScreenshotError.invalidCrop}
        var rgba=[UInt8](repeating:0,count:160*40*4)
        let created=rgba.withUnsafeMutableBytes {buffer -> Bool in
            guard let context=CGContext(data:buffer.baseAddress,width:160,height:40,bitsPerComponent:8,bytesPerRow:160*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else {return false}
            context.interpolationQuality = .high
            context.translateBy(x:80,y:20);context.scaleBy(x:160/length,y:40/width)
            context.rotate(by:-atan2(to.y-from.y,to.x-from.x));context.translateBy(x:-(from.x+to.x)/2,y:-(from.y+to.y)/2)
            context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height));return true
        }
        guard created else {throw ScreenshotError.invalidImage}
        var tensor=[Float](repeating:0,count:3*40*160)
        for channel in 0..<3 {for pixel in 0..<40*160 {tensor[channel*40*160+pixel]=(Float(rgba[pixel*4+channel])/255-0.5)/0.25}}
        return try classify([tensor])[0]
    }
}
