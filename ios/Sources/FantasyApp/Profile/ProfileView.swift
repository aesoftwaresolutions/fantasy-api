import SwiftUI

public struct ProfileView: View {
    @Environment(AppState.self) private var appState

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                FieldBackground()

                VStack(spacing: 24) {
                    header
                    Spacer()
                    Button {
                        appState.logout()
                    } label: {
                        Text("Sign out")
                            .font(.system(size: 16, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(Theme.Palette.jerseyRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Theme.Palette.jerseyRed.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(24)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Eyebrow("Profile")
                        DisplayText("Manager", size: 20)
                    }
                }
            }
            .toolbarBackground(Theme.Palette.fieldNight, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.Palette.turf.opacity(0.22))
                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Theme.Palette.turf)
            }
            .frame(width: 96, height: 96)
            .overlay(Circle().strokeBorder(Theme.Palette.endZoneGold.opacity(0.6), lineWidth: 2))

            if let user = appState.currentUser {
                Text(user.displayName)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.Palette.chalk)
                Text(user.email)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Palette.slate)
            } else {
                Text("Signed in")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.Palette.chalk)
                Text("Your profile loads after your next sign-in.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Palette.slate)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}
