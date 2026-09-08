import Foundation
import SwiftUI
import FantasyKit

@MainActor
public final class AppState: ObservableObject {
    @Published public var currentUser: User?
    @Published public var isAuthenticated: Bool = false

    public let tokenStore: TokenStore
    public let api: APIClient

    public init() {
        self.tokenStore = TokenStore()
        self.api = APIClient { [weak self] in
            self?.tokenStore.read()
        }

        if let _ = tokenStore.read() {
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
