import SwiftUI
import FantasyKit

public struct CreateLeagueView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var seasonYear = Calendar.current.component(.year, from: Date())
    @State private var format = "redraft"
    @State private var privacy = "private"
    @State private var maxTeams = 12
    @State private var teamName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onSuccess: () -> Void = {}

    private let formats = ["redraft", "dynasty", "contract_dynasty"]
    private let privacyOptions = ["private", "public"]

    public var body: some View {
        Form {
            Section(header: Text("League Details")) {
                TextField("League Name", text: $name)
                Stepper(value: $seasonYear, in: 2020...2100) {
                    Text("Season Year: \(seasonYear)")
                }
                Picker("Format", selection: $format) {
                    ForEach(formats, id: \.self) { f in
                        Text(f.capitalized).tag(f)
                    }
                }
                Picker("Privacy", selection: $privacy) {
                    ForEach(privacyOptions, id: \.self) { p in
                        Text(p.capitalized).tag(p)
                    }
                }
            }

            Section(header: Text("Settings")) {
                Stepper(value: $maxTeams, in: 2...20) {
                    Text("Max Teams: \(maxTeams)")
                }
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
                Button(action: create) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Creating...")
                        }
                    } else {
                        Text("Create League")
                    }
                }
                .disabled(isLoading || name.isEmpty)
            }
        }
        .navigationTitle("Create League")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func create() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await appState.api.createLeague(
                    name: name,
                    seasonYear: seasonYear,
                    format: format,
                    privacy: privacy,
                    maxTeams: maxTeams,
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
        CreateLeagueView()
            .environmentObject(AppState())
    }
}
