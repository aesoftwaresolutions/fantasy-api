import Foundation

public struct Matchup: Codable, Identifiable, Hashable {
    public let id: String
    public let leagueId: String
    public let weekNumber: Int
    public let teamAId: String
    public let teamBId: String
    public let teamAScore: Double
    public let teamBScore: Double
    public let status: String   // "scheduled" | "in_progress" | "final"

    public init(
        id: String,
        leagueId: String,
        weekNumber: Int,
        teamAId: String,
        teamBId: String,
        teamAScore: Double,
        teamBScore: Double,
        status: String
    ) {
        self.id = id
        self.leagueId = leagueId
        self.weekNumber = weekNumber
        self.teamAId = teamAId
        self.teamBId = teamBId
        self.teamAScore = teamAScore
        self.teamBScore = teamBScore
        self.status = status
    }

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case weekNumber = "week_number"
        case teamAId = "team_a_id"
        case teamBId = "team_b_id"
        case teamAScore = "team_a_score"
        case teamBScore = "team_b_score"
        case status
    }
}
