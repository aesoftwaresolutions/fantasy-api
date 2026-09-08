import SwiftUI
import FantasyKit

public struct JoinLeagueView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var teamName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onSuccess: () -> Void = {}

    public var body: some View {
        Form {
            Section(header: Text("Join a League")) {
                TextField("Invite Code", text: $inviteCode)
                    .autocapitalization(.allCharacters)
                    .textContentType(.none)

                TextField("Your Team Name (optional)", text: $teamName)
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            Section {
                Button(action: join) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Joining...")
                        }
                    } else {
                        Text("Join League")
                    }
                }
                .disabled(isLoading || inviteCode.isEmpty)
            }
        }
        .navigationTitle("Join League")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func join() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await appState.api.joinLeague(
                    inviteCode: inviteCode,
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
    NavigationStack {
        JoinLeagueView()
            .environmentObject(AppState())
    }
}
