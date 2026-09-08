import SwiftUI

@main
public struct FantasyAppApp: App {
    @State private var appState = AppState()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
