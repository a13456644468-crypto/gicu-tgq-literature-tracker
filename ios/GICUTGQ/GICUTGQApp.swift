import SwiftUI

@main
struct GICUTGQApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var router = AppIntentRouter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(router)
                .task {
                    await appState.bootstrap()
                }
        }
    }
}
