import Foundation
nonisolated public enum LayoutMode: String, Sendable { case singleColumn, twoColumns, threeColumns }
nonisolated public enum AdaptiveLayout {
    public static func resolve(availableContentWidth: CGFloat, isCompact: Bool, isAccessibilityTextSize: Bool) -> LayoutMode {
        if isCompact || isAccessibilityTextSize || availableContentWidth < 680 { return .singleColumn }
        return availableContentWidth >= 960 ? .threeColumns : .twoColumns
    }
}
nonisolated public struct RGB: Sendable {
    public var red: Double; public var green: Double; public var blue: Double
    public init(_ hex: UInt32) { red=Double((hex>>16)&255)/255; green=Double((hex>>8)&255)/255; blue=Double(hex&255)/255 }
    public var luminance: Double { func linear(_ n: Double) -> Double { n<=0.04045 ? n/12.92 : pow((n+0.055)/1.055,2.4) }; return 0.2126*linear(red)+0.7152*linear(green)+0.0722*linear(blue) }
    public func contrast(_ other: RGB) -> Double { (max(luminance,other.luminance)+0.05)/(min(luminance,other.luminance)+0.05) }
}
nonisolated public enum ThemeTokens {
    public static let background=RGB(0x091414),inkSurface=RGB(0x101F1E),forest=RGB(0x1D4540),capsuleRim=RGB(0x9DD2C6),ultramarine=RGB(0x3348D6),violet=RGB(0x7146B5),ochre=RGB(0xB99551),burgundy=RGB(0x6B2938),textPrimary=RGB(0xEEEBDD),textSecondary=RGB(0xBECAC2),warning=RGB(0xE5C177),error=RGB(0xEF9D9D)
}

/// One scene scale, measured from the supplied 1490 × 894 reference (220px grid).
nonisolated public struct MapBoardMetrics: Sendable {
    public let spacing: CGFloat
    public let size: CGSize
    public init(rows:Int,columns:Int,width:CGFloat) {
        spacing=width/(CGFloat(columns)+1.7727272727)
        size=CGSize(width:width,height:spacing*(CGFloat(rows)+1.0636363636))
    }
    public func point(row:Int,column:Int) -> CGPoint {
        CGPoint(x:spacing*(CGFloat(column)+1.0727272727),y:spacing*(CGFloat(row)+0.8454545455))
    }
    public var iconSize:CGFloat {spacing*128/220}
    public var labelSize:CGFloat {spacing*26/220}
    public var labelOffset:CGFloat {spacing*64/220}
    public var roadWidth:CGFloat {spacing*5/220}
    public static func aspectRatio(rows:Int,columns:Int) -> CGFloat {
        (CGFloat(columns)+1.7727272727)/(CGFloat(rows)+1.0636363636)
    }
}
