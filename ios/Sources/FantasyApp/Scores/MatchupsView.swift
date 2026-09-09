import SwiftUI
import FantasyKit

// Head-to-head matchup cards, grouped by week — the Sleeper "Scores" view:
// two teams face off with their scores, the leader highlighted.
struct MatchupsView: View {
    let league: League
    @Environment(AppState.self) private var appState

    @State private var matchups: [Matchup] = []
    @State private var teamNames: [String: String] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && matchups.isEmpty {
                ScrollView { SkeletonRows(count: 5).padding(16) }
            } else if let errorMessage, matchups.isEmpty {
                ErrorBanner(message: errorMessage).padding(16)
            } else if matchups.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(weeks, id: \.self) { week in
                            weekSection(week)
                        }
                    }
                    .padding(16)
                }
                .refreshable { await load() }
            }
        }
        .task(id: league.id) { await load() }
    }

    private var weeks: [Int] {
        Array(Set(matchups.map { $0.weekNumber })).sorted()
    }

    private func weekSection(_ week: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Rectangle().fill(Theme.Palette.turf).frame(width: 3, height: 14)
                Eyebrow("Week \(week)")
            }
            ForEach(matchups.filter { $0.weekNumber == week }) { m in
                matchupCard(m)
            }
        }
    }

    private func matchupCard(_ m: Matchup) -> some View {
        let aWins = m.status == "final" && m.teamAScore > m.teamBScore
        let bWins = m.status == "final" && m.teamBScore > m.teamAScore
        return VStack(spacing: 0) {
            teamRow(name: teamNames[m.teamAId] ?? "Team", score: m.teamAScore, winner: aWins)
            Divider().overlay(Theme.Palette.hashLine)
            teamRow(name: teamNames[m.teamBId] ?? "Team", score: m.teamBScore, winner: bWins)
        }
        .padding(14)
        .background(Theme.Palette.fieldNight2)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metric.corner, style: .continuous))
        .overlay(alignment: .topTrailing) {
            statusBadge(m.status)
                .padding(10)
        }
    }

    private func teamRow(name: String, score: Double, winner: Bool) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 16, weight: winner ? .bold : .medium))
                .foregroundColor(winner ? Theme.Palette.chalk : Theme.Palette.chalkDim)
                .lineLimit(1)
            Spacer()
            Text(String(format: "%.1f", score))
                .font(Theme.Fonts.score(20))
                .foregroundColor(winner ? Theme.Palette.endZoneGold : Theme.Palette.chalkDim)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        switch status {
        case "final":
            Chip(text: "Final", tint: Theme.Palette.slate)
        case "in_progress":
            Chip(text: "Live", tint: Theme.Palette.jerseyRed)
        default:
            EmptyView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Theme.Palette.turf)
            Text("No matchups scheduled yet.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Palette.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let m = appState.api.matchups(leagueId: league.id)
            async let t = appState.api.leagueTeams(leagueId: league.id)
            let (fetchedMatchups, teams) = try await (m, t)
            matchups = fetchedMatchups
            teamNames = Dictionary(uniqueKeysWithValues: teams.map { ($0.id, $0.teamName) })
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
