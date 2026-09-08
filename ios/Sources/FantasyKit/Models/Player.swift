import Foundation

public struct Player: Codable, Identifiable, Hashable {
    public let id: String
    public let externalProviderId: String
    public let fullName: String
    public let position: String
    public let nflTeam: String?
    public let status: String        // "active" | "injured" | "inactive" | "retired"
    public let photoUrl: String?

    public init(
        id: String,
        externalProviderId: String,
        fullName: String,
        position: String,
        nflTeam: String? = nil,
        status: String = "active",
        photoUrl: String? = nil
    ) {
        self.id = id
        self.externalProviderId = externalProviderId
        self.fullName = fullName
        self.position = position
        self.nflTeam = nflTeam
        self.status = status
        self.photoUrl = photoUrl
    }

    enum CodingKeys: String, CodingKey {
        case id
        case externalProviderId = "external_provider_id"
        case fullName = "full_name"
        case position
        case nflTeam = "nfl_team"
        case status
        case photoUrl = "photo_url"
    }
}
