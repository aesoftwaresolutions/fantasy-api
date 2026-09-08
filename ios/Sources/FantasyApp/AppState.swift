import Foundation
import Observation
import FantasyKit

@Observable
@MainActor
public final class AppState {
    public var currentUser: User?
    public var isAuthenticated: Bool = false

    // Not observed by views — infrastructure, not UI state.
    @ObservationIgnored public let tokenStore: TokenStore
    @ObservationIgnored public let api: APIClient

    public init() {
        let store = TokenStore()
        self.tokenStore = store
        self.api = APIClient { store.read() }

        // No /me endpoint yet, so on relaunch we trust a stored token for
        // session state; currentUser stays nil until the next login.
        if store.read() != nil {
            isAuthenticated = true
        }
    }

    public func login(email: String, password: String) async throws {
        let response = try await api.login(email: email, password: password)
        tokenStore.save(response.token)
        currentUser = response.user
        isAuthenticated = true
    }

    public func register(
        email: String,
        password: String,
        displayName: String,
        birthDate: String?
    ) async throws {
        _ = try await api.register(
            email: email,
            password: password,
            displayName: displayName,
            birthDate: birthDate
        )
        try await login(email: email, password: password)
    }

    public func logout() {
        tokenStore.clear()
        currentUser = nil
        isAuthenticated = false
    }
}
