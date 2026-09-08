import Foundation

// A player's slot on a team's roster. The list endpoint joins in the
// player's details (name, position, team, status); the create endpoint
// returns only the slot fields, so the player fields are optional.
public struct RosterSlot: Codable, Identifiable, Hashable {
    public let id: String
    public let teamId: String
    public let playerId: String
    public let slotType: String          // "starter" | "bench" | "ir"
    public let rosterPosition: String?
    public let acquiredAt: String?

    // Joined player details (present on the roster list, absent on create).
    public let fullName: String?
    public let position: String?
    public let nflTeam: String?
    public let status: String?           // "active" | "injured" | "inactive" | "retired"

    public init(
        id: String,
        teamId: String,
        playerId: String,
        slotType: String,
        rosterPosition: String? = nil,
        acquiredAt: String? = nil,
        fullName: String? = nil,
        position: String? = nil,
        nflTeam: String? = nil,
        status: String? = nil
    ) {
        self.id = id
        self.teamId = teamId
        self.playerId = playerId
        self.slotType = slotType
        self.rosterPosition = rosterPosition
        self.acquiredAt = acquiredAt
        self.fullName = fullName
        self.position = position
        self.nflTeam = nflTeam
        self.status = status
    }

    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case playerId = "player_id"
        case slotType = "slot_type"
        case rosterPosition = "roster_position"
        case acquiredAt = "acquired_at"
        case fullName = "full_name"
        case position
        case nflTeam = "nfl_team"
        case status
    }
}
