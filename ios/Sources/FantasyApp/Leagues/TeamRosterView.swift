import SwiftUI
import FantasyKit

public struct TeamRosterView: View {
    let team: Team
    @Environment(AppState.self) private var appState

    @State private var slots: [RosterSlot] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var pendingDropId: String?

    // Locker-room order: starters first, then bench, then injured reserve.
    private let slotOrder: [(key: String, label: String, tint: Color)] = [
        ("starter", "Starters", Theme.Palette.turf),
        ("bench", "Bench", Theme.Palette.slate),
        ("ir", "Injured Reserve", Theme.Palette.jerseyRed)
    ]

    public init(team: Team) {
        self.team = team
    }

    public var body: some View {
        ZStack {
            FieldBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if isLoading && slots.isEmpty {
                        ProgressView()
                            .tint(Theme.Palette.chalk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if let errorMessage, slots.isEmpty {
                        ErrorBanner(message: errorMessage)
                    } else if slots.isEmpty {
                        emptyState
                    } else {
                        if let errorMessage {
                            ErrorBanner(message: errorMessage)
                        }
                        ForEach(slotOrder, id: \.key) { group in
                            let groupSlots = slots.filter { $0.slotType == group.key }
                            if !groupSlots.isEmpty {
                                section(title: group.label, tint: group.tint, slots: groupSlots)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Palette.fieldNight, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.Palette.endZoneGold)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AddPlayerView(teamId: team.id, onSuccess: loadRoster)
            }
            .preferredColorScheme(.dark)
        }
        .task { await loadRosterAsync() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow("Roster")
            Text(team.teamName)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(Theme.Palette.chalk)
            HStack(spacing: 16) {
                stat(count: countFor("starter"), label: "Starters")
                stat(count: countFor("bench"), label: "Bench")
                stat(count: countFor("ir"), label: "IR")
            }
            YardLine().padding(.top, 2)
        }
    }

    private func stat(count: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(count)")
                .font(Theme.Fonts.score(20))
                .foregroundColor(Theme.Palette.endZoneGold)
            Eyebrow(label)
        }
    }

    private func section(title: String, tint: Color, slots: [RosterSlot]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Rectangle().fill(tint).frame(width: 3, height: 14)
                Eyebrow(title)
                Spacer()
                Text("\(slots.count)")
                    .font(Theme.Fonts.score(13))
                    .foregroundColor(Theme.Palette.slate)
            }
            ForEach(slots) { slot in
                playerRow(slot)
            }
        }
    }

    private func playerRow(_ slot: RosterSlot) -> some View {
        HStack(spacing: 12) {
            Text(slot.position ?? "—")
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(Theme.Palette.fieldNight)
                .frame(width: 40, height: 26)
                .background(positionTint(slot.position))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.fullName ?? "Unknown player")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Palette.chalk)
                HStack(spacing: 6) {
                    if let nfl = slot.nflTeam {
                        Text(nfl)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Palette.slate)
                    }
                    if let status = slot.status, status != "active" {
                        Text(status.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.Palette.jerseyRed)
                    }
                }
            }
            Spacer()
            if pendingDropId == slot.playerId {
                ProgressView().tint(Theme.Palette.slate)
            } else {
                Button {
                    Task { await drop(slot) }
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundColor(Theme.Palette.jerseyRed)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.Palette.fieldNight2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Theme.Palette.turf)
            Text("No players on the roster yet.")
                .font(.system(size: 15))
                .foregroundColor(Theme.Palette.slate)
            Button("Add a player") { showAddSheet = true }
                .buttonStyle(KickoffButtonStyle())
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }

    private func countFor(_ type: String) -> Int {
        slots.filter { $0.slotType == type }.count
    }

    private func loadRosterAsync() async {
        isLoading = true
        errorMessage = nil
        do {
            slots = try await appState.api.roster(teamId: team.id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func loadRoster() {
        Task { await loadRosterAsync() }
    }

    private func drop(_ slot: RosterSlot) async {
        pendingDropId = slot.playerId
        defer { pendingDropId = nil }
        do {
            try await appState.api.dropPlayer(teamId: team.id, playerId: slot.playerId)
            slots.removeAll { $0.id == slot.id }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// Position color coding — a quick visual read of the roster, like a depth chart.
func positionTint(_ position: String?) -> Color {
    switch position {
    case "QB": return Theme.Palette.endZoneGold
    case "RB": return Theme.Palette.turfBright
    case "WR": return Color(hex: 0x4FA3E3)
    case "TE": return Color(hex: 0xB98CE0)
    case "K": return Theme.Palette.slate
    case "DEF": return Color(hex: 0xE07B4F)
    default: return Theme.Palette.slate
    }
}

#Preview {
    NavigationStack {
        TeamRosterView(
            team: Team(
                id: "1",
                leagueId: "l1",
                ownerUserId: "u1",
                teamName: "Gridiron Gurus",
                createdAt: "2026-01-01"
            )
        )
        .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
