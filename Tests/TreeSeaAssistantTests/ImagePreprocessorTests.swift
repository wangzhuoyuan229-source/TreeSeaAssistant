import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Testing
#if SWIFT_PACKAGE
@testable import TreeSeaRecognition
#else
@testable import TreeSeaAssistant
#endif
func syntheticPNG(width:Int,height:Int,orientation:Int = 1) throws -> Data {
    let context=try #require(CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(red:0.1,green:0.3,blue:0.2,alpha:1));context.fill(CGRect(x:0,y:0,width:width,height:height))
    let image=try #require(context.makeImage()),data=NSMutableData(),destination=try #require(CGImageDestinationCreateWithData(data,UTType.png.identifier as CFString,1,nil))
    CGImageDestinationAddImage(destination,image,[kCGImagePropertyOrientation:orientation] as CFDictionary);#expect(CGImageDestinationFinalize(destination));return data as Data
}
struct ImagePreprocessorTests {
    @Test func rejectsOversizeAndBadImage() {
        #expect(throws:ScreenshotError.self) {try ImagePreprocessor.prepare(Data(repeating:0,count:20*1024*1024+1),crop:nil)}
        #expect(throws:ScreenshotError.self) {try ImagePreprocessor.prepare(Data("invalid".utf8),crop:nil)}
    }
    @Test func thumbnailAndCropCoordinates() throws {
        let data=try syntheticPNG(width:2000,height:1000)
        let result=try ImagePreprocessor.prepare(data,crop:CGRect(x:200,y:100,width:1600,height:800))
        #expect(max(result.width,result.height)<=1280)
        let p=CGPoint(x:500,y:300),roundTrip=result.transform.toOriginal(result.transform.toWorking(p))
        #expect(abs(p.x-roundTrip.x)<1);#expect(abs(p.y-roundTrip.y)<1)
        #expect(throws:ScreenshotError.self) {try ImagePreprocessor.prepare(data,crop:.zero)}
    }
    @Test func exifRotationAndPixelLimit() throws {
        let rotated=try ImagePreprocessor.prepare(syntheticPNG(width:200,height:100,orientation:6),crop:nil)
        #expect(rotated.originalWidth==100);#expect(rotated.originalHeight==200);#expect(rotated.width==100);#expect(rotated.height==200)
        #expect(throws:ScreenshotError.self) {try ImagePreprocessor.prepare(syntheticPNG(width:4097,height:4097),crop:nil)}
    }
}
struct CorridorClassifierTests {
    @Test func convertedModelMatchesPinnedSyntheticLogits() throws {
        let classifier=try CorridorClassifier()
        let scores=try classifier.classify([Array(repeating:Float(-2),count:3*40*160),Array(repeating:Float(2),count:3*40*160)])
        #expect(abs(scores[0].rawLogit - (-12.03437328338623))<=1e-4)
        #expect(abs(scores[1].rawLogit - (-0.15620452165603638))<=1e-4)
        #expect(!scores[0].hasEdge);#expect(!scores[1].hasEdge)
        #expect(throws:ScreenshotError.self) {try classifier.classify([[0]])}
    }
}
