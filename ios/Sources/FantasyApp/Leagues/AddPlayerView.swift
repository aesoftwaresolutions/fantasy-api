import SwiftUI
import FantasyKit

// Adds a player to a team's roster by ID. A searchable player browser
// will replace the ID field once the players endpoint ships (it's a stub
// on the backend today), so this is deliberately minimal for now.
public struct AddPlayerView: View {
    let teamId: String
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var playerId = ""
    @State private var slotType = "bench"
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                        Text("Enter a player ID to add them to your roster.")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Palette.chalkDim)
                    }
                    .padding(.top, 4)

                    FieldTextField(title: "Player ID", text: $playerId)

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
                    .disabled(isLoading || playerId.isEmpty)
                    .opacity(playerId.isEmpty ? 0.5 : 1)
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
    }

    private func add() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await appState.api.addPlayer(
                    teamId: teamId,
                    playerId: playerId.trimmingCharacters(in: .whitespaces),
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
