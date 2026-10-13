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
    public static let background=RGB(0x060A08),inkSurface=RGB(0x0B1210),forest=RGB(0x173B31),capsuleRim=RGB(0x79BCAF),ultramarine=RGB(0x3348D6),violet=RGB(0x7146B5),ochre=RGB(0xB99551),burgundy=RGB(0x6B2938),textPrimary=RGB(0xE8E5D9),textSecondary=RGB(0xB7BBAF),warning=RGB(0xE5C177),error=RGB(0xEF9D9D)
}
