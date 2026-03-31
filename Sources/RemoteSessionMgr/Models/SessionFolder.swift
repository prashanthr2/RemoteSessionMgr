import Foundation

struct SessionFolder: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var folders: [SessionFolder]
    var sessions: [RemoteSession]

    init(
        id: UUID = UUID(),
        name: String,
        folders: [SessionFolder] = [],
        sessions: [RemoteSession] = []
    ) {
        self.id = id
        self.name = name
        self.folders = folders
        self.sessions = sessions
    }
}

struct SessionLibrary: Codable {
    var rootFolder: SessionFolder
}
