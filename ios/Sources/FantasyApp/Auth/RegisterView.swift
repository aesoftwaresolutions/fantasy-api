import SwiftUI

public struct RegisterView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var birthDate: Date?
    @State private var includeBirthDate = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    public var body: some View {
        Form {
            Section(header: Text("Account Information")) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)

                TextField("Display Name", text: $displayName)
                    .textContentType(.name)
            }

            Section(header: Text("Optional")) {
                Toggle("Add Birth Date", isOn: $includeBirthDate)

                if includeBirthDate {
                    DatePicker(
                        "Birth Date",
                        selection: Binding(
                            get: { birthDate ?? Date() },
                            set: { birthDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            Section {
                Button(action: register) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Creating Account...")
                        }
                    } else {
                        Text("Create Account")
                    }
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty || displayName.isEmpty)
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func register() {
        isLoading = true
        errorMessage = nil

        let birthDateString: String?
        if includeBirthDate, let date = birthDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            birthDateString = formatter.string(from: date)
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
                await MainActor.run {
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
        RegisterView()
            .environmentObject(AppState())
    }
}
