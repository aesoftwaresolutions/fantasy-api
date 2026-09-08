import SwiftUI
import FantasyKit

public struct LeaguesListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var leagues: [League] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                FieldBackground()
                content
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Eyebrow("My Leagues")
                        DisplayText("Locker Room", size: 22)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("Create a league", systemImage: "flag.checkered")
                        }
                        Button {
                            showJoinSheet = true
                        } label: {
                            Label("Join with a code", systemImage: "person.badge.plus")
                        }
                        Divider()
                        Button(role: .destructive, action: appState.logout) {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundColor(Theme.Palette.endZoneGold)
                    }
                }
            }
            .toolbarBackground(Theme.Palette.fieldNight, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCreateSheet) {
                NavigationStack { CreateLeagueView(onSuccess: loadLeagues) }
                    .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showJoinSheet) {
                NavigationStack { JoinLeagueView(onSuccess: loadLeagues) }
                    .preferredColorScheme(.dark)
            }
            .task {
                if leagues.isEmpty { await loadLeaguesAsync() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && leagues.isEmpty {
            ProgressView().tint(Theme.Palette.chalk)
        } else if leagues.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                    ForEach(leagues) { league in
                        NavigationLink {
                            LeagueDetailView(league: league)
                        } label: {
                            LeagueCard(league: league)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .refreshable { await loadLeaguesAsync() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "sportscourt")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(Theme.Palette.turf)
            DisplayText("No leagues yet", size: 22)
            Text("Start a league as commissioner, or join a friend's with an invite code.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Palette.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            HStack(spacing: 12) {
                Button("Create a league") { showCreateSheet = true }
                    .buttonStyle(KickoffButtonStyle())
                Button("Join") { showJoinSheet = true }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.Palette.endZoneGold)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.Palette.hashLine, lineWidth: 1)
                    )
            }
            .padding(.top, 4)
            .padding(.horizontal, 24)
        }
    }

    private func loadLeaguesAsync() async {
        isLoading = true
        errorMessage = nil
        do {
            leagues = try await appState.api.listLeagues()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func loadLeagues() {
        Task { await loadLeaguesAsync() }
    }
}

// MARK: - League card: jersey-stripe spine tinted by format
struct LeagueCard: View {
    let league: League

    var body: some View {
        FieldCard(spineColor: formatTint(league.format)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(league.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Palette.chalk)
                        .lineLimit(2)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.Palette.slate)
                }
                HStack(spacing: 8) {
                    Chip(text: formatLabel(league.format), tint: formatTint(league.format))
                    Chip(text: league.privacy, tint: Theme.Palette.slate)
                    Spacer()
                    Text(String(league.seasonYear))
                        .font(Theme.Fonts.score(15))
                        .foregroundColor(Theme.Palette.endZoneGold)
                }
            }
        }
    }
}

// Format drives both the spine color and the chip — the color carries meaning.
func formatTint(_ format: String) -> Color {
    switch format {
    case "dynasty": return Theme.Palette.endZoneGold
    case "contract_dynasty": return Theme.Palette.jerseyRed
    default: return Theme.Palette.turf   // redraft
    }
}

func formatLabel(_ format: String) -> String {
    switch format {
    case "contract_dynasty": return "Contract"
    case "dynasty": return "Dynasty"
    default: return "Redraft"
    }
}

#Preview {
    LeaguesListView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
