import SwiftUI
import FantasyKit

public struct JoinLeagueView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var teamName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onSuccess: () -> Void = {}

    public init(onSuccess: @escaping () -> Void = {}) {
        self.onSuccess = onSuccess
    }

    public var body: some View {
        ZStack {
            FieldBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Have a code?")
                        Text("Enter your league's invite code to claim a team.")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Palette.chalkDim)
                    }
                    .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("Invite code")
                        TextField("", text: $inviteCode)
                            .font(Theme.Fonts.score(22))
                            .tracking(3)
                            .foregroundColor(Theme.Palette.endZoneGold)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .tint(Theme.Palette.endZoneGold)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 14)
                            .background(Theme.Palette.fieldNight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Theme.Palette.hashLine, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    FieldTextField(title: "Your team name (optional)", text: $teamName, autocap: .words)

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    Button(action: join) {
                        if isLoading {
                            ProgressView().tint(Theme.Palette.chalk)
                        } else {
                            Text("Claim your team")
                        }
                    }
                    .buttonStyle(KickoffButtonStyle())
                    .disabled(isLoading || inviteCode.isEmpty)
                    .opacity(inviteCode.isEmpty ? 0.5 : 1)
                }
                .padding(24)
            }
        }
        .navigationTitle("Join League")
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

    private func join() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                _ = try await appState.api.joinLeague(
                    inviteCode: inviteCode.trimmingCharacters(in: .whitespaces),
                    teamName: teamName.isEmpty ? nil : teamName
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
    NavigationStack { JoinLeagueView() }
        .environment(AppState())
        .preferredColorScheme(.dark)
}
