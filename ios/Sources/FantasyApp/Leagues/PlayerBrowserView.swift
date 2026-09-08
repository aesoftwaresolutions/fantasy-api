import SwiftUI
import FantasyKit

// A searchable, position-filterable player picker. Calls `onSelect` with
// the chosen player and dismisses.
public struct PlayerBrowserView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let onSelect: (Player) -> Void

    @State private var searchText = ""
    @State private var position: String? = nil
    @State private var players: [Player] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    private let positions = ["QB", "RB", "WR", "TE", "K", "DEF"]

    public init(onSelect: @escaping (Player) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        ZStack {
            FieldBackground()

            VStack(spacing: 0) {
                filterBar
                content
            }
        }
        .navigationTitle("Find a Player")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Palette.fieldNight, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(Theme.Palette.slate)
            }
        }
        .searchable(text: $searchText, prompt: "Search players")
        .onChange(of: searchText) { _, _ in scheduleSearch() }
        .task { await runSearch() }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", active: position == nil) {
                    position = nil
                    scheduleSearch()
                }
                ForEach(positions, id: \.self) { pos in
                    filterChip(title: pos, active: position == pos, tint: positionTint(pos)) {
                        position = (position == pos) ? nil : pos
                        scheduleSearch()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.Palette.fieldNight.opacity(0.6))
        .glassSurface(cornerRadius: 0)
    }

    private func filterChip(title: String, active: Bool, tint: Color = Theme.Palette.turf, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(active ? Theme.Palette.fieldNight : tint)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(active ? tint : tint.opacity(0.14))
                .overlay(
                    Capsule().strokeBorder(tint.opacity(active ? 0 : 0.4), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && players.isEmpty {
            ScrollView {
                SkeletonRows(count: 8)
                    .padding(16)
            }
        } else if let errorMessage, players.isEmpty {
            Spacer()
            ErrorBanner(message: errorMessage).padding(16)
            Spacer()
        } else if players.isEmpty {
            Spacer()
            Text("No players match your search.")
                .font(.system(size: 15))
                .foregroundColor(Theme.Palette.slate)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(players) { player in
                        Button {
                            Haptics.tap()
                            onSelect(player)
                            dismiss()
                        } label: {
                            playerRow(player)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
    }

    private func playerRow(_ player: Player) -> some View {
        HStack(spacing: 12) {
            PlayerHeadshot(url: player.photoUrl, position: player.position, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Palette.chalk)
                HStack(spacing: 6) {
                    if let nfl = player.nflTeam {
                        Text(nfl)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Palette.slate)
                    }
                    if player.status != "active" {
                        Text(player.status.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.Palette.jerseyRed)
                    }
                }
            }
            Spacer()
            Image(systemName: "plus.circle.fill")
                .foregroundColor(Theme.Palette.turf)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.Palette.fieldNight2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // Debounce keystrokes so we don't fire a request per character.
    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            await runSearch()
        }
    }

    private func runSearch() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await appState.api.players(
                search: searchText,
                position: position,
                limit: 50,
                offset: 0
            )
            withAnimation(Theme.Motion.spring) {
                players = response.players
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PlayerBrowserView(onSelect: { _ in })
            .environment(AppState())
    }
    .preferredColorScheme(.dark)
}
