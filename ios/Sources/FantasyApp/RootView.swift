import SwiftUI

public struct RootView: View {
    @Environment(AppState.self) private var appState

    public init() {}

    public var body: some View {
        Group {
            if appState.isAuthenticated {
                LeaguesListView()
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
