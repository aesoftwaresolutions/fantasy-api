import Foundation

public struct Standing: Codable, Identifiable, Hashable {
    public var id: String { teamId }
    public let teamId: String
    public let teamName: String
    public let wins: Int
    public let losses: Int
    public let ties: Int
    public let pointsFor: Double
    public let pointsAgainst: Double

    public init(
        teamId: String,
        teamName: String,
        wins: Int,
        losses: Int,
        ties: Int,
        pointsFor: Double,
        pointsAgainst: Double
    ) {
        self.teamId = teamId
        self.teamName = teamName
        self.wins = wins
        self.losses = losses
        self.ties = ties
        self.pointsFor = pointsFor
        self.pointsAgainst = pointsAgainst
    }

    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
        case teamName = "team_name"
        case wins
        case losses
        case ties
        case pointsFor = "points_for"
        case pointsAgainst = "points_against"
    }
}
