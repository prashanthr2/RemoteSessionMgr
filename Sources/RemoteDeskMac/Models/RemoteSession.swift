import Foundation

enum SessionProtocol: String, CaseIterable, Codable, Identifiable {
    case ssh = "SSH"
    case rdp = "RDP"

    var id: String { rawValue }

    var defaultPort: Int {
        switch self {
        case .ssh:
            return 22
        case .rdp:
            return 3389
        }
    }
}

struct RemoteSession: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var protocolType: SessionProtocol
    var host: String
    var port: Int
    var username: String
    var password: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case protocolType
        case host
        case port
        case username
        case password
        case notes
        case createdAt
        case updatedAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        protocolType: SessionProtocol,
        host: String,
        port: Int? = nil,
        username: String,
        password: String = "",
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.protocolType = protocolType
        self.host = host
        self.port = port ?? protocolType.defaultPort
        self.username = username
        self.password = password
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        protocolType = try container.decode(SessionProtocol.self, forKey: .protocolType)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(Int.self, forKey: .port)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        notes = try container.decode(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
