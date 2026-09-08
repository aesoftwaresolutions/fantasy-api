import Foundation

public struct League: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let commissionerId: String
    public let format: String
    public let privacy: String
    public let inviteCode: String?
    public let maxTeams: Int
    public let scoringRulesJson: String?
    public let capAmount: Int?
    public let seasonYear: Int
    public let createdAt: String

    public init(
        id: String,
        name: String,
        commissionerId: String,
        format: String,
        privacy: String,
        inviteCode: String? = nil,
        maxTeams: Int,
        scoringRulesJson: String? = nil,
        capAmount: Int? = nil,
        seasonYear: Int,
        createdAt: String
    ) {
        self.id = id
        self.name = name
        self.commissionerId = commissionerId
        self.format = format
        self.privacy = privacy
        self.inviteCode = inviteCode
        self.maxTeams = maxTeams
        self.scoringRulesJson = scoringRulesJson
        self.capAmount = capAmount
        self.seasonYear = seasonYear
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case commissionerId = "commissioner_id"
        case format
        case privacy
        case inviteCode = "invite_code"
        case maxTeams = "max_teams"
        case scoringRulesJson = "scoring_rules_json"
        case capAmount = "cap_amount"
        case seasonYear = "season_year"
        case createdAt = "created_at"
    }
}
