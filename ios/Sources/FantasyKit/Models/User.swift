import Foundation

public struct User: Codable, Identifiable, Hashable {
    public let id: String
    public let email: String
    public let displayName: String
    public let birthDate: String?

    public init(
        id: String,
        email: String,
        displayName: String,
        birthDate: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.birthDate = birthDate
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case birthDate = "birth_date"
    }
}
