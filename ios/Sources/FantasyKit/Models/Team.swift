import Foundation

public struct Team: Codable, Identifiable, Hashable {
    public let id: String
    public let leagueId: String
    public let ownerUserId: String
    public let teamName: String
    public let logoUrl: String?
    public let capSpaceRemaining: Int?
    public let createdAt: String

    public init(
        id: String,
        leagueId: String,
        ownerUserId: String,
        teamName: String,
        logoUrl: String? = nil,
        capSpaceRemaining: Int? = nil,
        createdAt: String
    ) {
        self.id = id
        self.leagueId = leagueId
        self.ownerUserId = ownerUserId
        self.teamName = teamName
        self.logoUrl = logoUrl
        self.capSpaceRemaining = capSpaceRemaining
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case ownerUserId = "owner_user_id"
        case teamName = "team_name"
        case logoUrl = "logo_url"
        case capSpaceRemaining = "cap_space_remaining"
        case createdAt = "created_at"
    }
}
