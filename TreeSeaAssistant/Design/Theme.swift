import SwiftUI
import TreeSeaCore
extension RGB {var color:Color {Color(red:red,green:green,blue:blue)}}
struct AppBackdrop:View {
    var body:some View {GeometryReader {geo in
        ZStack(alignment:.topTrailing){
            ThemeTokens.background.color
            Image("botanical").resizable().scaledToFill().frame(width:geo.size.width,height:max(420,geo.size.height*0.65)).clipped().opacity(0.22)
            LinearGradient(colors:[ThemeTokens.background.color.opacity(0.2),ThemeTokens.background.color.opacity(0.85),ThemeTokens.background.color],startPoint:.top,endPoint:.bottom)
        }.ignoresSafeArea().accessibilityHidden(true)
    }}
}
struct InkPanel<Content:View>:View {
    @ViewBuilder var content:Content
    var body:some View {content.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(ThemeTokens.inkSurface.color.opacity(0.94),in:RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(ThemeTokens.textSecondary.color.opacity(0.12),lineWidth:1))}
}
struct ActionCapsule:View {
    var title:String;var symbol:String;var disabled=false;var action:()->Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body:some View {Button(action:action){HStack(spacing:12){Image(systemName:symbol).font(.body);Text(title).font(.body.weight(.semibold));Spacer(minLength:4);Image(systemName:"arrow.up.right").font(.caption)}.frame(maxWidth:.infinity,minHeight:52).padding(.horizontal,18)}.buttonStyle(CapsuleStyle(reduceMotion:reduceMotion)).disabled(disabled)}
}
struct CapsuleStyle:ButtonStyle {
    var reduceMotion:Bool
    func makeBody(configuration:Configuration) -> some View {configuration.label.foregroundStyle(ThemeTokens.textPrimary.color).background(ThemeTokens.forest.color,in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(ThemeTokens.capsuleRim.color.opacity(0.45),lineWidth:1)).scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1).opacity(configuration.isPressed ? 0.75 : 1).animation(reduceMotion ? nil : .easeOut(duration:0.16),value:configuration.isPressed)}
}
struct StatusLabel:View {
    var text:String;var warning=false
    var body:some View {Label(text,systemImage:warning ? "exclamationmark.triangle" : "info.circle").font(.subheadline).foregroundStyle(warning ? ThemeTokens.warning.color : ThemeTokens.textSecondary.color).fixedSize(horizontal:false,vertical:true)}
}
struct GameIcon:View {
    var kind:NodeKind?;var itemID:String?;var illustration=false
    private static let index:[String:String]={guard let url=Bundle.main.url(forResource:"asset-index",withExtension:"json"),let data=try? Data(contentsOf:url),let index=try? JSONDecoder().decode([String:String].self,from:data) else {return [:]};return index}()
    private var asset:String? {
        if let itemID {return Self.index[illustration ? "items/rogue_6_scrap_\(itemID.prefix(1))_\(itemID.suffix(2)).png" : "themes/blackstream/products/"+(Self.itemNames[itemID] ?? "")+".png"]}
        return kind.flatMap{Self.nodeNames[$0]}.flatMap{Self.index["themes/blackstream/nodes/\($0).png"]}
    }
    private static let itemNames=["M01":"scrap-wheel","M02":"scrap-prosthesis","M03":"standard-engine","M04":"heavy-spring","M05":"hover-base","M06":"prototype-exoskeleton","M07":"little-bajie","M08":"jetpack","M09":"mama-snowmelt","M10":"cannot-tentacle","M11":"structural-principle","M12":"simple-remote"]
    private static let nodeNames:[NodeKind:String]=[.battle:"combat",.emergencyBattle:"emergency-combat",.dangerousEnemy:"danger-enemy",.resident:"settlement",.strangeShop:"rogue-trader",.secretShop:"secret-trader",.safeCorner:"safe-corner",.encounter:"encounter",.wish:"wish",.lossGain:"gain-loss",.advance:"first-step",.wonderland:"wrong-turn",.narrowEncounter:"narrow-meet",.emergencyAid:"emergency-aid",.dangerousPath:"danger-path",.lookout:"overlook",.start:"start",.exit:"danger-end",.unknownMystery:"unknown-mystery",.unknownFerocity:"unknown-ferocity"]
    var body:some View {Group{if kind == .start {Image("start-traveler").resizable().scaledToFit()} else if let asset {Image(asset).resizable().scaledToFit()} else {Text(kind?.name ?? itemID ?? "素材缺失").font(.caption).multilineTextAlignment(.center)}}.accessibilityHidden(true)}
}
