import SwiftUI
import FantasyKit

// Season standings: rank, record, and points — computed from final matchups.
struct StandingsView: View {
    let league: League
    @Environment(AppState.self) private var appState

    @State private var standings: [Standing] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && standings.isEmpty {
                ScrollView { SkeletonRows(count: 6).padding(16) }
            } else if let errorMessage, standings.isEmpty {
                ErrorBanner(message: errorMessage).padding(16)
            } else if standings.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        headerRow
                        ForEach(Array(standings.enumerated()), id: \.element.id) { index, s in
                            standingRow(rank: index + 1, s)
                        }
                    }
                    .padding(16)
                }
                .refreshable { await load() }
            }
        }
        .task(id: league.id) { await load() }
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            Text("#").frame(width: 24, alignment: .leading)
            Text("Team")
            Spacer()
            Text("W-L-T").frame(width: 70, alignment: .trailing)
            Text("PF").frame(width: 56, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .bold))
        .tracking(1)
        .foregroundColor(Theme.Palette.slate)
        .textCase(.uppercase)
        .padding(.horizontal, 14)
    }

    private func standingRow(rank: Int, _ s: Standing) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(Theme.Fonts.score(16))
                .foregroundColor(rank <= 4 ? Theme.Palette.endZoneGold : Theme.Palette.slate)
                .frame(width: 24, alignment: .leading)
            Text(s.teamName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.Palette.chalk)
                .lineLimit(1)
            Spacer()
            Text("\(s.wins)-\(s.losses)-\(s.ties)")
                .font(Theme.Fonts.score(14))
                .foregroundColor(Theme.Palette.chalkDim)
                .frame(width: 70, alignment: .trailing)
            Text(String(format: "%.0f", s.pointsFor))
                .font(Theme.Fonts.score(14))
                .foregroundColor(Theme.Palette.chalkDim)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.Palette.fieldNight2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.number")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Theme.Palette.turf)
            Text("Standings appear once matchups are final.")
                .font(.system(size: 14))
                .foregroundColor(Theme.Palette.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            standings = try await appState.api.standings(leagueId: league.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
