import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TreeSeaAppSupport
#else
@testable import TreeSeaAssistant
#endif
struct AdaptiveLayoutTests {
    @Test func widthBoundaries() {
        for (width,mode) in [(679,LayoutMode.singleColumn),(680,.twoColumns),(959,.twoColumns),(960,.threeColumns)] { #expect(AdaptiveLayout.resolve(availableContentWidth:CGFloat(width),isCompact:false,isAccessibilityTextSize:false)==mode) }
        #expect(AdaptiveLayout.resolve(availableContentWidth:1100,isCompact:true,isAccessibilityTextSize:false) == .singleColumn)
        #expect(AdaptiveLayout.resolve(availableContentWidth:1100,isCompact:false,isAccessibilityTextSize:true) == .singleColumn)
    }
}
struct ThemeContrastTests {
    @Test func semanticContrast() {
        for background in [ThemeTokens.background,ThemeTokens.inkSurface] {
            for foreground in [ThemeTokens.textPrimary,ThemeTokens.textSecondary,ThemeTokens.warning,ThemeTokens.error] { #expect(foreground.contrast(background)>=4.5) }
            #expect(ThemeTokens.capsuleRim.contrast(background)>=3)
        }
    }
}
