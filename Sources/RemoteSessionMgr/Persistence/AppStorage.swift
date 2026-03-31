import Foundation

struct AppStorage {
    let libraryStore: JSONFileStore<SessionLibrary>
    let settingsStore: JSONFileStore<AppSettings>

    init(fileManager: FileManager = .default) {
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let baseURL = applicationSupportURL.appendingPathComponent("RemoteSessionMgr", isDirectory: true)
        let legacyBaseURL = applicationSupportURL.appendingPathComponent("RemoteDeskMac", isDirectory: true)

        Self.migrateLegacyFilesIfNeeded(
            from: legacyBaseURL,
            to: baseURL,
            fileManager: fileManager
        )

        libraryStore = JSONFileStore(fileURL: baseURL.appendingPathComponent("sessions.json"))
        settingsStore = JSONFileStore(fileURL: baseURL.appendingPathComponent("settings.json"))
    }

    func loadLibrary() throws -> SessionLibrary {
        if libraryStore.exists() {
            return try libraryStore.load()
        }
        let sample = SampleData.makeLibrary()
        try libraryStore.save(sample)
        return sample
    }

    func saveLibrary(_ library: SessionLibrary) throws {
        try libraryStore.save(library)
    }

    func loadSettings() throws -> AppSettings {
        if settingsStore.exists() {
            return try settingsStore.load()
        }
        let settings = AppSettings.default
        try settingsStore.save(settings)
        return settings
    }

    func saveSettings(_ settings: AppSettings) throws {
        try settingsStore.save(settings)
    }

    private static func migrateLegacyFilesIfNeeded(from legacyBaseURL: URL, to currentBaseURL: URL, fileManager: FileManager) {
        let migrations = [
            (legacyBaseURL.appendingPathComponent("sessions.json"), currentBaseURL.appendingPathComponent("sessions.json")),
            (legacyBaseURL.appendingPathComponent("settings.json"), currentBaseURL.appendingPathComponent("settings.json"))
        ]

        guard migrations.contains(where: { fileManager.fileExists(atPath: $0.0.path) }) else {
            return
        }

        try? fileManager.createDirectory(at: currentBaseURL, withIntermediateDirectories: true)

        for (legacyURL, currentURL) in migrations {
            guard fileManager.fileExists(atPath: legacyURL.path) else { continue }
            guard !fileManager.fileExists(atPath: currentURL.path) else { continue }
            try? fileManager.copyItem(at: legacyURL, to: currentURL)
        }
    }
}

enum SampleData {
    static func makeLibrary() -> SessionLibrary {
        let now = Date()
        let infra = SessionFolder(
            name: "Infrastructure",
            sessions: [
                RemoteSession(
                    name: "Prod Bastion",
                    protocolType: .ssh,
                    host: "bastion.example.internal",
                    port: 22,
                    username: "ops",
                    password: "",
                    notes: "Jump host for production access.",
                    createdAt: now,
                    updatedAt: now
                ),
                RemoteSession(
                    name: "Windows Admin Box",
                    protocolType: .rdp,
                    host: "10.0.20.15",
                    port: 3389,
                    username: "administrator",
                    password: "",
                    notes: "Uses xfreerdp by default.",
                    createdAt: now,
                    updatedAt: now
                )
            ]
        )

        let personal = SessionFolder(
            name: "Personal Lab",
            folders: [
                SessionFolder(
                    name: "Raspberry Pis",
                    sessions: [
                        RemoteSession(
                            name: "Pi Cluster Node 1",
                            protocolType: .ssh,
                            host: "pi-node-1.local",
                            port: 22,
                            username: "pi",
                            password: "",
                            notes: "ARM build worker.",
                            createdAt: now,
                            updatedAt: now
                        )
                    ]
                )
            ]
        )

        return SessionLibrary(rootFolder: SessionFolder(name: "Library", folders: [infra, personal]))
    }
}
