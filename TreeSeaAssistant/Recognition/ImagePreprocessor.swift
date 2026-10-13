import Foundation
import ImageIO
import CoreGraphics
import CryptoKit
import UniformTypeIdentifiers
nonisolated enum ScreenshotError: Error {case tooLarge,invalidImage,invalidCrop,cancelled,modelUnavailable}
nonisolated struct CoordinateTransform: Sendable {
    var cropOrigin: CGPoint;var scaleX: CGFloat;var scaleY: CGFloat
    func toWorking(_ point: CGPoint) -> CGPoint {CGPoint(x:(point.x-cropOrigin.x)*scaleX,y:(point.y-cropOrigin.y)*scaleY)}
    func toOriginal(_ point: CGPoint) -> CGPoint {CGPoint(x:point.x/scaleX+cropOrigin.x,y:point.y/scaleY+cropOrigin.y)}
}
nonisolated struct PreparedScreenshot: Sendable {
    var png: Data;var width:Int;var height:Int;var originalWidth:Int;var originalHeight:Int;var digest:String;var transform:CoordinateTransform
}
nonisolated enum ImagePreprocessor {
    static func prepare(_ data: Data,crop: CGRect?) throws -> PreparedScreenshot {
        guard data.count<=20*1024*1024 else {throw ScreenshotError.tooLarge}
        guard let source=CGImageSourceCreateWithData(data as CFData,[kCGImageSourceShouldCache:false] as CFDictionary),let properties=CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any],
              let rawWidth=properties[kCGImagePropertyPixelWidth] as? Int,let rawHeight=properties[kCGImagePropertyPixelHeight] as? Int,rawWidth>0,rawHeight>0 else {throw ScreenshotError.invalidImage}
        guard rawWidth<=16_000_000/rawHeight else {throw ScreenshotError.tooLarge}
        guard let identifier=CGImageSourceGetType(source),let type=UTType(identifier as String),[UTType.png,.jpeg,.webP].contains(where:{type.conforms(to:$0)}) else {throw ScreenshotError.invalidImage}
        let orientation=properties[kCGImagePropertyOrientation] as? Int ?? 1,swapped=(5...8).contains(orientation),width=swapped ? rawHeight : rawWidth,height=swapped ? rawWidth : rawHeight
        if Task.isCancelled {throw ScreenshotError.cancelled}
        guard let image=CGImageSourceCreateThumbnailAtIndex(source,0,[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceCreateThumbnailWithTransform:true,kCGImageSourceThumbnailMaxPixelSize:1280,kCGImageSourceShouldCacheImmediately:true] as CFDictionary) else {throw ScreenshotError.invalidImage}
        let originalBounds=CGRect(x:0,y:0,width:width,height:height),requested=crop ?? originalBounds
        guard requested.origin.x.isFinite,requested.origin.y.isFinite,requested.width.isFinite,requested.height.isFinite,requested.width>0,requested.height>0,originalBounds.contains(requested) else {throw ScreenshotError.invalidCrop}
        let sx=CGFloat(image.width)/CGFloat(width),sy=CGFloat(image.height)/CGFloat(height)
        let rect=CGRect(x:requested.minX*sx,y:requested.minY*sy,width:requested.width*sx,height:requested.height*sy).integral.intersection(CGRect(x:0,y:0,width:image.width,height:image.height))
        guard let cropped=image.cropping(to:rect),cropped.width>0,cropped.height>0 else {throw ScreenshotError.invalidCrop}
        let encoded=NSMutableData()
        guard let destination=CGImageDestinationCreateWithData(encoded,UTType.png.identifier as CFString,1,nil) else {throw ScreenshotError.invalidImage}
        CGImageDestinationAddImage(destination,cropped,nil);guard CGImageDestinationFinalize(destination) else {throw ScreenshotError.invalidImage}
        let transform=CoordinateTransform(cropOrigin:CGPoint(x:rect.minX/sx,y:rect.minY/sy),scaleX:sx,scaleY:sy)
        return PreparedScreenshot(png:encoded as Data,width:cropped.width,height:cropped.height,originalWidth:width,originalHeight:height,digest:SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined(),transform:transform)
    }
    @concurrent static func process(_ data: Data,crop: CGRect?) async throws -> PreparedScreenshot {try prepare(data,crop:crop)}
    static func image(_ screenshot: PreparedScreenshot) throws -> CGImage {
        guard let source=CGImageSourceCreateWithData(screenshot.png as CFData,nil),let image=CGImageSourceCreateImageAtIndex(source,0,nil) else {throw ScreenshotError.invalidImage};return image
    }
}
