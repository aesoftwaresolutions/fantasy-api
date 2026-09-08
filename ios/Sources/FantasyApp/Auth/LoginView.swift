import SwiftUI

public struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                FieldBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        hero

                        VStack(spacing: 16) {
                            FieldTextField(
                                title: "Email",
                                text: $email,
                                keyboard: .emailAddress
                            )
                            FieldTextField(
                                title: "Password",
                                text: $password,
                                isSecure: true
                            )
                        }

                        if let errorMessage {
                            ErrorBanner(message: errorMessage)
                        }

                        Button(action: login) {
                            if isLoading {
                                ProgressView().tint(Theme.Palette.chalk)
                            } else {
                                Text("Take the field")
                            }
                        }
                        .buttonStyle(KickoffButtonStyle())
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

                        HStack(spacing: 6) {
                            Text("New here?")
                                .foregroundColor(Theme.Palette.slate)
                            NavigationLink("Create your franchise") {
                                RegisterView()
                            }
                            .foregroundColor(Theme.Palette.endZoneGold)
                            .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                    }
                    .padding(24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Fantasy Football")
            DisplayText("Run your\nleague.", size: 40)
                .fixedSize(horizontal: false, vertical: true)
            YardLine()
                .padding(.top, 4)
            Text("Draft, trade, and settle it on the field.")
                .font(.system(size: 15))
                .foregroundColor(Theme.Palette.chalkDim)
        }
        .padding(.top, 40)
        .padding(.bottom, 8)
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await appState.login(email: email, password: password)
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
    LoginView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
