import Foundation

public final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: () -> String?

    public init(
        baseURL: URL = APIConfig.baseURL,
        session: URLSession = .shared,
        tokenProvider: @escaping () -> String?
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
    }

    // Request with an encodable body.
    private func request<B: Encodable, T: Decodable>(
        path: String,
        method: String,
        body: B,
        authorized: Bool
    ) async throws -> T {
        try await send(path: path, method: method, bodyData: try JSONEncoder().encode(body), authorized: authorized)
    }

    // Request without a body.
    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        authorized: Bool = false
    ) async throws -> T {
        try await send(path: path, method: method, bodyData: nil, authorized: authorized)
    }

    private func send<T: Decodable>(
        path: String,
        method: String,
        bodyData: Data?,
        authorized: Bool
    ) async throws -> T {
        let data = try await perform(path: path, method: method, bodyData: bodyData, authorized: authorized)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    // Perform a request that returns no body (e.g. 204 No Content).
    private func sendNoContent(
        path: String,
        method: String,
        bodyData: Data?,
        authorized: Bool
    ) async throws {
        _ = try await perform(path: path, method: method, bodyData: bodyData, authorized: authorized)
    }

    // Build, send, and validate a request; returns the raw (possibly empty) body.
    private func perform(
        path: String,
        method: String,
        bodyData: Data?,
        authorized: Bool
    ) async throws -> Data {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let bodyData = bodyData {
            request.httpBody = bodyData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if authorized {
            guard let token = tokenProvider() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.server(status: httpResponse.statusCode, code: errorResponse.error, message: errorResponse.message)
            } else {
                throw APIError.server(status: httpResponse.statusCode, code: "http_error", message: "Request failed (\(httpResponse.statusCode))")
            }
        }

        return data
    }

    public func login(email: String, password: String) async throws -> AuthResponse {
        struct LoginBody: Encodable {
            let email: String
            let password: String
        }
        let body = LoginBody(email: email, password: password)
        return try await request(path: "api/auth/login", method: "POST", body: body, authorized: false)
    }

    public func register(
        email: String,
        password: String,
        displayName: String,
        birthDate: String?
    ) async throws -> User {
        struct RegisterBody: Encodable {
            let email: String
            let password: String
            let display_name: String
            let birth_date: String?
        }
        let body = RegisterBody(email: email, password: password, display_name: displayName, birth_date: birthDate)
        let response: UserResponse = try await request(path: "api/auth/register", method: "POST", body: body, authorized: false)
        return response.user
    }

    public func listLeagues() async throws -> [League] {
        let response: LeaguesResponse = try await request(path: "api/leagues", method: "GET", authorized: true)
        return response.leagues
    }

    public func createLeague(
        name: String,
        seasonYear: Int,
        format: String? = nil,
        privacy: String? = nil,
        maxTeams: Int? = nil,
        teamName: String? = nil
    ) async throws -> League {
        struct CreateLeagueBody: Encodable {
            let name: String
            let season_year: Int
            let format: String?
            let privacy: String?
            let max_teams: Int?
            let team_name: String?
        }
        let body = CreateLeagueBody(
            name: name,
            season_year: seasonYear,
            format: format,
            privacy: privacy,
            max_teams: maxTeams,
            team_name: teamName
        )
        let response: LeagueResponse = try await request(path: "api/leagues", method: "POST", body: body, authorized: true)
        return response.league
    }

    public func joinLeague(
        inviteCode: String,
        teamName: String? = nil
    ) async throws -> League {
        struct JoinBody: Encodable {
            let invite_code: String
            let team_name: String?
        }
        let body = JoinBody(invite_code: inviteCode, team_name: teamName)
        let response: LeagueResponse = try await request(path: "api/leagues/join", method: "POST", body: body, authorized: true)
        return response.league
    }

    public func leagueTeams(leagueId: String) async throws -> [Team] {
        let response: TeamsResponse = try await request(path: "api/leagues/\(leagueId)/teams", method: "GET", authorized: true)
        return response.teams
    }

    public func getTeam(teamId: String) async throws -> Team {
        let response: TeamResponse = try await request(path: "api/teams/\(teamId)", method: "GET", authorized: true)
        return response.team
    }

    public func roster(teamId: String) async throws -> [RosterSlot] {
        let response: RosterResponse = try await request(path: "api/teams/\(teamId)/roster", method: "GET", authorized: true)
        return response.roster
    }

    public func addPlayer(
        teamId: String,
        playerId: String,
        slotType: String? = nil,
        rosterPosition: String? = nil
    ) async throws -> RosterSlot {
        struct AddPlayerBody: Encodable {
            let player_id: String
            let slot_type: String?
            let roster_position: String?
        }
        let body = AddPlayerBody(player_id: playerId, slot_type: slotType, roster_position: rosterPosition)
        let response: SlotResponse = try await request(
            path: "api/teams/\(teamId)/roster",
            method: "POST",
            body: body,
            authorized: true
        )
        return response.slot
    }

    public func dropPlayer(teamId: String, playerId: String) async throws {
        try await sendNoContent(
            path: "api/teams/\(teamId)/roster/\(playerId)",
            method: "DELETE",
            bodyData: nil,
            authorized: true
        )
    }
}
