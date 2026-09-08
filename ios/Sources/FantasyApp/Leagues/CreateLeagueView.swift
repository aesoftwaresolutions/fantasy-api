import SwiftUI
import FantasyKit

public struct CreateLeagueView: View {
    @Environment(AppState.self) private var appState
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

    public init(onSuccess: @escaping () -> Void = {}) {
        self.onSuccess = onSuccess
    }

    public var body: some View {
        ZStack {
            FieldBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    FieldTextField(title: "League name", text: $name, autocap: .words)

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Format")
                        HStack(spacing: 8) {
                            ForEach(formats, id: \.self) { f in
                                formatButton(f)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Privacy")
                        Picker("", selection: $privacy) {
                            Text("Private").tag("private")
                            Text("Public").tag("public")
                        }
                        .pickerStyle(.segmented)
                    }

                    stepperRow(label: "Season", value: $seasonYear, range: 2020...2100, display: String(seasonYear))
                    stepperRow(label: "Max teams", value: $maxTeams, range: 2...20, display: String(maxTeams))

                    FieldTextField(title: "Your team name (optional)", text: $teamName, autocap: .words)

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    Button(action: create) {
                        if isLoading {
                            ProgressView().tint(Theme.Palette.chalk)
                        } else {
                            Text("Kick off league")
                        }
                    }
                    .buttonStyle(KickoffButtonStyle())
                    .disabled(isLoading || name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1)
                }
                .padding(24)
            }
        }
        .navigationTitle("New League")
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

    private func formatButton(_ f: String) -> some View {
        let selected = format == f
        let tint = formatTint(f)
        return Button {
            format = f
        } label: {
            Text(formatLabel(f))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(selected ? Theme.Palette.fieldNight : tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected ? tint : tint.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(tint.opacity(selected ? 0 : 0.4), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
    }

    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, display: String) -> some View {
        HStack {
            Eyebrow(label)
            Spacer()
            Text(display)
                .font(Theme.Fonts.score(17))
                .foregroundColor(Theme.Palette.endZoneGold)
                .padding(.trailing, 8)
            Stepper("", value: value, in: range)
                .labelsHidden()
                .tint(Theme.Palette.turf)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.Palette.fieldNight2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
    NavigationStack { CreateLeagueView() }
        .environment(AppState())
        .preferredColorScheme(.dark)
}
