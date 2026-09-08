import SwiftUI
import FantasyKit

// Adds a player to a team's roster: pick a player from the searchable
// browser, choose a slot, and sign them.
public struct AddPlayerView: View {
    let teamId: String
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlayer: Player?
    @State private var slotType = "bench"
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showBrowser = false

    var onSuccess: () -> Void = {}

    public init(teamId: String, onSuccess: @escaping () -> Void = {}) {
        self.teamId = teamId
        self.onSuccess = onSuccess
    }

    public var body: some View {
        ZStack {
            FieldBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Sign a player")
                        Text("Search the player pool and add them to your roster.")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Palette.chalkDim)
                    }
                    .padding(.top, 4)

                    playerSelector

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Slot")
                        Picker("", selection: $slotType) {
                            Text("Starter").tag("starter")
                            Text("Bench").tag("bench")
                            Text("IR").tag("ir")
                        }
                        .pickerStyle(.segmented)
                    }

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    Button(action: add) {
                        if isLoading {
                            ProgressView().tint(Theme.Palette.chalk)
                        } else {
                            Text("Add to roster")
                        }
                    }
                    .buttonStyle(KickoffButtonStyle())
                    .disabled(isLoading || selectedPlayer == nil)
                    .opacity(selectedPlayer == nil ? 0.5 : 1)
                }
                .padding(24)
            }
        }
        .navigationTitle("Add Player")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Palette.fieldNight, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(Theme.Palette.slate)
            }
        }
        .sheet(isPresented: $showBrowser) {
            NavigationStack {
                PlayerBrowserView { player in
                    selectedPlayer = player
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private var playerSelector: some View {
        if let player = selectedPlayer {
            Button {
                showBrowser = true
            } label: {
                HStack(spacing: 12) {
                    Text(player.position)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Theme.Palette.fieldNight)
                        .frame(width: 40, height: 26)
                        .background(positionTint(player.position))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.fullName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Palette.chalk)
                        if let nfl = player.nflTeam {
                            Text(nfl)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Palette.slate)
                        }
                    }
                    Spacer()
                    Text("Change")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.Palette.endZoneGold)
                }
                .padding(14)
                .background(Theme.Palette.fieldNight2)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        } else {
            Button {
                showBrowser = true
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Choose a player")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Palette.chalk)
                .padding(14)
                .background(Theme.Palette.fieldNight2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.Palette.hashLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func add() {
        guard let player = selectedPlayer else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await appState.api.addPlayer(
                    teamId: teamId,
                    playerId: player.id,
                    slotType: slotType
                )
                await MainActor.run {
                    onSuccess()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddPlayerView(teamId: "1")
            .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
