import Foundation

public struct AuthResponse: Codable {
    public let token: String
    public let user: User

    public init(token: String, user: User) {
        self.token = token
        self.user = user
    }
}

public struct UserResponse: Codable {
    public let user: User

    public init(user: User) {
        self.user = user
    }
}

public struct LeaguesResponse: Codable {
    public let leagues: [League]

    public init(leagues: [League]) {
        self.leagues = leagues
    }
}

public struct LeagueResponse: Codable {
    public let league: League

    public init(league: League) {
        self.league = league
    }
}

public struct TeamsResponse: Codable {
    public let teams: [Team]

    public init(teams: [Team]) {
        self.teams = teams
    }
}

public struct APIErrorResponse: Codable {
    public let error: String
    public let message: String

    public init(error: String, message: String) {
        self.error = error
        self.message = message
    }
}

public enum APIError: Error, LocalizedError {
    case server(status: Int, code: String, message: String)
    case decoding(Error)
    case transport(Error)
    case unauthorized
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .server(_, _, let message):
            return message
        case .decoding(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .transport(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "You are not authorized. Please log in."
        case .invalidResponse:
            return "Received an invalid response from the server."
        }
    }
}
