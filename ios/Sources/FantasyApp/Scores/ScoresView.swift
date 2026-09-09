import SwiftUI
import FantasyKit

// The Scores tab: pick a league, then flip between its weekly matchups and
// the season standings — the head-to-head core of a fantasy app.
public struct ScoresView: View {
    @Environment(AppState.self) private var appState

    @State private var leagues: [League] = []
    @State private var selectedLeague: League?
    @State private var tab: ScoreTab = .matchups
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum ScoreTab: String, CaseIterable {
        case matchups = "Matchups"
        case standings = "Standings"
    }

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
                        Eyebrow("Scores")
                        DisplayText(selectedLeague?.name ?? "Select a League", size: 20)
                    }
                }
                if leagues.count > 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        leaguePicker
                    }
                }
            }
            .toolbarBackground(Theme.Palette.fieldNight, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await loadLeagues() }
        }
    }

    private var leaguePicker: some View {
        Menu {
            ForEach(leagues) { league in
                Button(league.name) { selectedLeague = league }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .foregroundColor(Theme.Palette.endZoneGold)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && leagues.isEmpty {
            ProgressView().tint(Theme.Palette.chalk)
        } else if let errorMessage, leagues.isEmpty {
            ErrorBanner(message: errorMessage).padding(16)
        } else if leagues.isEmpty {
            emptyState
        } else if let league = selectedLeague {
            VStack(spacing: 0) {
                Picker("", selection: $tab) {
                    ForEach(ScoreTab.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .padding(16)

                switch tab {
                case .matchups:
                    MatchupsView(league: league)
                case .standings:
                    StandingsView(league: league)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "sportscourt")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.Palette.turf)
            Text("Join or create a league to see scores.")
                .font(.system(size: 15))
                .foregroundColor(Theme.Palette.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func loadLeagues() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await appState.api.listLeagues()
            leagues = fetched
            if selectedLeague == nil {
                selectedLeague = fetched.first
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    ScoresView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
