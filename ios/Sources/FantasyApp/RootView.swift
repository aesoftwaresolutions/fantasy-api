import SwiftUI

public struct RootView: View {
    @EnvironmentObject private var appState: AppState

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
