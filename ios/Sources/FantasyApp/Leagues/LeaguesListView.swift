import SwiftUI
import FantasyKit

public struct LeaguesListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var leagues: [League] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    public var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                } else if leagues.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Leagues Yet")
                            .font(.headline)
                        Text("Create a league or join an existing one to get started.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(leagues) { league in
                            NavigationLink(destination: LeagueDetailView(league: league)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(league.name)
                                        .font(.headline)
                                    HStack(spacing: 8) {
                                        Text("\(league.seasonYear)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(league.format)
                                            .font(.caption2)
                                            .padding(4)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(4)
                                        Text(league.privacy)
                                            .font(.caption2)
                                            .padding(4)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding()

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .navigationTitle("My Leagues")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showCreateSheet = true }) {
                            Label("Create League", systemImage: "plus.circle")
                        }
                        Button(action: { showJoinSheet = true }) {
                            Label("Join League", systemImage: "person.crop.circle.badge.plus")
                        }
                        Divider()
                        Button(action: appState.logout) {
                            Label("Logout", systemImage: "power")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                NavigationStack {
                    CreateLeagueView(onSuccess: loadLeagues)
                }
            }
            .sheet(isPresented: $showJoinSheet) {
                NavigationStack {
                    JoinLeagueView(onSuccess: loadLeagues)
                }
            }
            .refreshable {
                await loadLeaguesAsync()
            }
            .task {
                await loadLeaguesAsync()
            }
        }
    }

    private func loadLeaguesAsync() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let fetchedLeagues = try await appState.api.listLeagues()
            await MainActor.run {
                self.leagues = fetchedLeagues
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isLoading = false
            }
        }
    }

    private func loadLeagues() {
        Task {
            await loadLeaguesAsync()
        }
    }
}

#Preview {
    NavigationStack {
        LeaguesListView()
            .environmentObject(AppState())
    }
}
