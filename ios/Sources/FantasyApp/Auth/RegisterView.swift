import SwiftUI

public struct RegisterView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var birthDate = Date()
    @State private var includeBirthDate = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        ZStack {
            FieldBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Sign up")
                        DisplayText("Create your\nfranchise", size: 32)
                            .fixedSize(horizontal: false, vertical: true)
                        YardLine().padding(.top, 4)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 16) {
                        FieldTextField(title: "Manager name", text: $displayName, autocap: .words)
                        FieldTextField(title: "Email", text: $email, keyboard: .emailAddress)
                        FieldTextField(title: "Password", text: $password, isSecure: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $includeBirthDate) {
                            Text("Add birth date")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Palette.chalkDim)
                        }
                        .tint(Theme.Palette.turf)

                        if includeBirthDate {
                            DatePicker(
                                "",
                                selection: $birthDate,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(Theme.Palette.endZoneGold)
                        }
                    }
                    .padding(14)
                    .background(Theme.Palette.fieldNight2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    Button(action: register) {
                        if isLoading {
                            ProgressView().tint(Theme.Palette.chalk)
                        } else {
                            Text("Join the league")
                        }
                    }
                    .buttonStyle(KickoffButtonStyle())
                    .disabled(isLoading || email.isEmpty || password.isEmpty || displayName.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty || displayName.isEmpty ? 0.5 : 1)
                }
                .padding(24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Palette.fieldNight, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func register() {
        isLoading = true
        errorMessage = nil

        let birthDateString: String?
        if includeBirthDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthDateString = formatter.string(from: birthDate)
        } else {
            birthDateString = nil
        }

        Task {
            do {
                try await appState.register(
                    email: email,
                    password: password,
                    displayName: displayName,
                    birthDate: birthDateString
                )
                await MainActor.run { dismiss() }
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
        RegisterView()
            .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
