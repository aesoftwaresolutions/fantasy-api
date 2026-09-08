import SwiftUI

public struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRegister = false

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Credentials")) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button(action: login) {
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Logging in...")
                            }
                        } else {
                            Text("Log In")
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }

                Section {
                    NavigationLink("Create Account") {
                        RegisterView()
                    }
                }
            }
            .navigationTitle("Fantasy League")
        }
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
        .environmentObject(AppState())
}
