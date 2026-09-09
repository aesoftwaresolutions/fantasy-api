import SwiftUI

// Bottom-tab shell, the way Sleeper organizes its app: the main sections
// are always one tap away rather than buried in a menu.
public struct MainTabView: View {
    @State private var selection = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selection) {
            LeaguesListView()
                .tabItem {
                    Label("Leagues", systemImage: "trophy.fill")
                }
                .tag(0)

            ScoresView()
                .tabItem {
                    Label("Scores", systemImage: "sportscourt.fill")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        .tint(Theme.Palette.endZoneGold)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
