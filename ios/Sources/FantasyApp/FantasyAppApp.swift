import SwiftUI

@main
public struct FantasyAppApp: App {
    @StateObject private var appState = AppState()

    public var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
