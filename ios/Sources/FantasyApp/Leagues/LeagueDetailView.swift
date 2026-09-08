import SwiftUI
import FantasyKit

public struct LeagueDetailView: View {
    let league: League
    @EnvironmentObject private var appState: AppState
    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedTeams = false

    public var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(league.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            VStack(alignment: .leading, spacing: 4) {
                                DetailRow(label: "Season", value: String(league.seasonYear))
                                DetailRow(label: "Format", value: league.format)
                                DetailRow(label: "Privacy", value: league.privacy)
                                DetailRow(label: "Max Teams", value: String(league.maxTeams))
                                if let inviteCode = league.inviteCode {
                                    HStack {
                                        Text("Invite Code")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Text(inviteCode)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .textSelection(.enabled)
                                            Button(action: { UIPasteboard.general.string = inviteCode }) {
                                                Image(systemName: "doc.on.doc")
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                            .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Teams (\(teams.count))")
                                .font(.headline)

                            if teams.isEmpty {
                                Text("No teams yet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(teams) { team in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(team.teamName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        if let capSpace = team.capSpaceRemaining {
                                            Text("Cap Space: \(capSpace)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }

            if let errorMessage = errorMessage {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding()

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .navigationTitle("League Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !hasLoadedTeams {
                await loadTeams()
                hasLoadedTeams = true
            }
        }
    }

    private func loadTeams() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let fetchedTeams = try await appState.api.leagueTeams(leagueId: league.id)
            await MainActor.run {
                self.teams = fetchedTeams
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        LeagueDetailView(
            league: League(
                id: "1",
                name: "Example League",
                commissionerId: "user1",
                format: "redraft",
                privacy: "private",
                inviteCode: "ABC123",
                maxTeams: 12,
                seasonYear: 2024,
                createdAt: "2024-01-01"
            )
        )
        .environmentObject(AppState())
    }
}
