import SwiftUI
import FantasyKit

public struct LeagueDetailView: View {
    let league: League
    @Environment(AppState.self) private var appState
    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var copied = false

    public init(league: League) {
        self.league = league
    }

    public var body: some View {
        ZStack {
            FieldBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let code = league.inviteCode {
                        inviteCard(code)
                    }
                    teamsSection
                }
                .padding(16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Palette.fieldNight, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await loadTeams() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Season \(String(league.seasonYear))")
            Text(league.name)
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(Theme.Palette.chalk)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Chip(text: formatLabel(league.format), tint: formatTint(league.format))
                Chip(text: league.privacy, tint: Theme.Palette.slate)
                Chip(text: "\(league.maxTeams) teams", tint: Theme.Palette.turf)
            }
            YardLine().padding(.top, 2)
        }
    }

    private func inviteCard(_ code: String) -> some View {
        FieldCard(spineColor: Theme.Palette.endZoneGold) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow("Invite Code")
                    Text(code)
                        .font(Theme.Fonts.score(24))
                        .foregroundColor(Theme.Palette.endZoneGold)
                        .tracking(2)
                        .textSelection(.enabled)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    Haptics.success()
                    withAnimation(Theme.Motion.snappy) { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(Theme.Motion.snappy) { copied = false }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied" : "Copy")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.Palette.fieldNight)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Theme.Palette.endZoneGold)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var teamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow("Teams")
                Spacer()
                Text("\(teams.count)/\(league.maxTeams)")
                    .font(Theme.Fonts.score(14))
                    .foregroundColor(Theme.Palette.slate)
            }

            if isLoading {
                ProgressView()
                    .tint(Theme.Palette.chalk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if let errorMessage {
                ErrorBanner(message: errorMessage)
            } else if teams.isEmpty {
                Text("No teams have joined yet. Share the invite code to fill the league.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Palette.slate)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(teams.enumerated()), id: \.element.id) { index, team in
                    teamRow(team, seed: index + 1)
                }
            }
        }
    }

    private func teamRow(_ team: Team, seed: Int) -> some View {
        NavigationLink {
            TeamRosterView(team: team)
        } label: {
            HStack(spacing: 14) {
                Text(String(format: "%02d", seed))
                    .font(Theme.Fonts.score(16))
                    .foregroundColor(Theme.Palette.turf)
                    .frame(width: 30, alignment: .leading)
                Text(team.teamName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Palette.chalk)
                Spacer()
                if let cap = team.capSpaceRemaining {
                    Text("$\(cap)")
                        .font(Theme.Fonts.score(13))
                        .foregroundColor(Theme.Palette.chalkDim)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.Palette.slate)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Theme.Palette.fieldNight2)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func loadTeams() async {
        isLoading = true
        errorMessage = nil
        do {
            teams = try await appState.api.leagueTeams(leagueId: league.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        LeagueDetailView(
            league: League(
                id: "1",
                name: "Sunday Night Rivals",
                commissionerId: "user1",
                format: "dynasty",
                privacy: "private",
                inviteCode: "GRIDIRON",
                maxTeams: 12,
                seasonYear: 2026,
                createdAt: "2026-01-01"
            )
        )
        .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
