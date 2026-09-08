import SwiftUI

public struct RootView: View {
    @EnvironmentObject private var appState: AppState

    public var body: some View {
        if appState.isAuthenticated {
            LeaguesListView()
        } else {
            LoginView()
        }
    }
}
