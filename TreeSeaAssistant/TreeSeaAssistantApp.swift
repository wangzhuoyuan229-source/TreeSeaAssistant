import SwiftUI
@main struct TreeSeaAssistantApp:App {
    @State private var model:AppModel=AppModel()
    var body:some Scene {WindowGroup{AppShellView(model:model).preferredColorScheme(.dark).tint(ThemeTokens.capsuleRim.color)}}
}
