import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var library: SessionLibrary
    @Published var settings: AppSettings
    @Published var selection: SidebarSelection?
    @Published var searchText = ""
    @Published var presentedError: DisplayError?
    @Published var sshTabs: [EmbeddedSSHSession] = []
    @Published var activeDetailPane: DetailPane = .details

    private let storage: AppStorage
    private let launcher: SessionLaunching

    init(storage: AppStorage = AppStorage(), launcher: SessionLaunching = SessionLauncher()) {
        self.storage = storage
        self.launcher = launcher

        do {
            library = try storage.loadLibrary()
        } catch {
            library = SampleData.makeLibrary()
        }

        do {
            settings = try storage.loadSettings()
        } catch {
            settings = .default
        }
    }

    var sidebarNodes: [SidebarNode] {
        filteredNodes(for: library.rootFolder, searchText: searchText)
    }

    var selectedSession: RemoteSession? {
        guard case .session(let id) = selection else { return nil }
        return Self.findSession(in: library.rootFolder, sessionID: id)
    }

    var selectedFolder: SessionFolder? {
        guard case .folder(let id) = selection else { return nil }
        return Self.findFolder(in: library.rootFolder, folderID: id)
    }

    var selectedSSHTab: EmbeddedSSHSession? {
        guard case .ssh(let tabID) = activeDetailPane else { return nil }
        return sshTabs.first { $0.id == tabID }
    }

    func bindingForSelectedSession<Value>(
        _ keyPath: WritableKeyPath<RemoteSession, Value>,
        default defaultValue: Value
    ) -> Binding<Value> {
        Binding(
            get: { [weak self] in
                guard let self, let session = self.selectedSession else { return defaultValue }
                return session[keyPath: keyPath]
            },
            set: { [weak self] newValue in
                self?.updateSelectedSession(keyPath, value: newValue)
            }
        )
    }

    func bindingForSelectedFolderName() -> Binding<String> {
        Binding(
            get: { [weak self] in
                self?.selectedFolder?.name ?? ""
            },
            set: { [weak self] newValue in
                self?.renameSelectedFolder(to: newValue)
            }
        )
    }

    func newSession() {
        let parentFolderID = preferredFolderIDForInsertion()
        let session = RemoteSession(
            name: "New Session",
            protocolType: .ssh,
            host: "",
            username: NSUserName()
        )
        mutateFolder(folderID: parentFolderID) { folder in
            folder.sessions.append(session)
            folder.sessions.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        selection = .session(session.id)
    }

    func newFolder() {
        let parentFolderID = preferredFolderIDForInsertion()
        let folder = SessionFolder(name: "New Folder")
        mutateFolder(folderID: parentFolderID) { parent in
            parent.folders.append(folder)
            parent.folders.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        selection = .folder(folder.id)
    }

    func deleteSelectedItem() {
        guard let selection else { return }

        switch selection {
        case .session(let sessionID):
            mutateRoot { root in
                Self.deleteSession(in: &root, sessionID: sessionID)
            }
        case .folder(let folderID):
            guard folderID != library.rootFolder.id else { return }
            mutateRoot { root in
                Self.deleteFolder(in: &root, folderID: folderID)
            }
        }

        self.selection = nil
    }

    func connectSelectedSession() {
        guard let session = selectedSession else { return }
        connect(session: session)
    }

    func connectSession(withID sessionID: UUID) {
        guard let session = Self.findSession(in: library.rootFolder, sessionID: sessionID) else { return }
        selection = .session(sessionID)
        activeDetailPane = .details
        connect(session: session)
    }

    private func connect(session: RemoteSession) {
        switch session.protocolType {
        case .ssh where settings.defaultSSHLauncher == .inApp:
            openEmbeddedSSHSession(for: session)
        default:
            do {
                try launcher.launch(session: session, settings: settings)
            } catch {
                presentedError = DisplayError(message: error.localizedDescription)
            }
        }
    }

    func closeSSHTab(_ tabID: UUID) {
        guard let index = sshTabs.firstIndex(where: { $0.id == tabID }) else { return }
        let tab = sshTabs.remove(at: index)
        tab.disconnect()

        if case .ssh(let activeID) = activeDetailPane, activeID == tabID {
            activeDetailPane = .details
        }
    }

    func selectSSHTab(_ tabID: UUID) {
        activeDetailPane = .ssh(tabID)
        if let tab = sshTabs.first(where: { $0.id == tabID }) {
            selection = .session(tab.sourceSessionID)
            tab.shouldFocusTerminal = true
        }
    }

    func showDetailsPane() {
        activeDetailPane = .details
    }

    func handleSelectionChange(_ selection: SidebarSelection?) {
        self.selection = selection
    }

    func saveSettings() {
        do {
            try storage.saveSettings(settings)
        } catch {
            presentedError = DisplayError(message: "Failed to save settings: \(error.localizedDescription)")
        }
    }

    func updateProtocol(_ protocolType: SessionProtocol) {
        guard let session = selectedSession else { return }
        updateSelectedSession(\.protocolType, value: protocolType)
        if session.port == session.protocolType.defaultPort {
            updateSelectedSession(\.port, value: protocolType.defaultPort)
        }
    }

    private func updateSelectedSession<Value>(_ keyPath: WritableKeyPath<RemoteSession, Value>, value: Value) {
        guard case .session(let sessionID) = selection else { return }
        mutateRoot { root in
            Self.updateSession(in: &root, sessionID: sessionID) { session in
                session[keyPath: keyPath] = value
                session.updatedAt = .now
            }
        }
    }

    private func openEmbeddedSSHSession(for session: RemoteSession) {
        if let existing = sshTabs.first(where: { $0.sourceSessionID == session.id }) {
            activeDetailPane = .ssh(existing.id)
            return
        }

        let tab = EmbeddedSSHSession(session: session)
        sshTabs.append(tab)
        selection = .session(session.id)
        activeDetailPane = .ssh(tab.id)
        tab.start()
    }

    private func renameSelectedFolder(to newName: String) {
        guard case .folder(let folderID) = selection, folderID != library.rootFolder.id else { return }
        mutateRoot { root in
            Self.updateFolder(in: &root, folderID: folderID) { folder in
                folder.name = newName
            }
        }
    }

    private func preferredFolderIDForInsertion() -> UUID {
        switch selection {
        case .folder(let folderID):
            return folderID
        case .session(let sessionID):
            return Self.findParentFolderID(in: library.rootFolder, sessionID: sessionID) ?? library.rootFolder.id
        case nil:
            return library.rootFolder.id
        }
    }

    private func mutateFolder(folderID: UUID, mutation: (inout SessionFolder) -> Void) {
        mutateRoot { root in
            Self.updateFolder(in: &root, folderID: folderID, mutation: mutation)
        }
    }

    private func mutateRoot(_ mutation: (inout SessionFolder) -> Void) {
        mutation(&library.rootFolder)
        persistLibrary()
        objectWillChange.send()
    }

    private func persistLibrary() {
        do {
            try storage.saveLibrary(library)
        } catch {
            presentedError = DisplayError(message: "Failed to save sessions: \(error.localizedDescription)")
        }
    }

    private func filteredNodes(for folder: SessionFolder, searchText: String) -> [SidebarNode] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let includeAll = query.isEmpty

        return folder.folders.compactMap { childFolder in
            let childNodes = filteredNodes(for: childFolder, searchText: query)
            let folderMatches = includeAll || childFolder.name.localizedCaseInsensitiveContains(query)
            guard folderMatches || !childNodes.isEmpty else { return nil }

            return SidebarNode(
                id: .folder(childFolder.id),
                title: childFolder.name,
                subtitle: nil,
                kind: .folder,
                children: childNodes
            )
        } + folder.sessions.compactMap { session in
            guard includeAll || matches(session: session, query: query) else { return nil }
            return SidebarNode(
                id: .session(session.id),
                title: session.name,
                subtitle: "\(session.protocolType.rawValue) • \(session.host)",
                kind: .session,
                children: nil
            )
        }
    }

    private func matches(session: RemoteSession, query: String) -> Bool {
        let fields = [session.name, session.host, session.username, session.notes, session.protocolType.rawValue]
        return fields.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    static func findSession(in folder: SessionFolder, sessionID: UUID) -> RemoteSession? {
        if let session = folder.sessions.first(where: { $0.id == sessionID }) {
            return session
        }
        for child in folder.folders {
            if let session = findSession(in: child, sessionID: sessionID) {
                return session
            }
        }
        return nil
    }

    static func findFolder(in folder: SessionFolder, folderID: UUID) -> SessionFolder? {
        if folder.id == folderID {
            return folder
        }
        for child in folder.folders {
            if let match = findFolder(in: child, folderID: folderID) {
                return match
            }
        }
        return nil
    }

    static func updateSession(
        in folder: inout SessionFolder,
        sessionID: UUID,
        mutation: (inout RemoteSession) -> Void
    ) {
        if let index = folder.sessions.firstIndex(where: { $0.id == sessionID }) {
            mutation(&folder.sessions[index])
            return
        }
        for index in folder.folders.indices {
            updateSession(in: &folder.folders[index], sessionID: sessionID, mutation: mutation)
        }
    }

    static func updateFolder(
        in folder: inout SessionFolder,
        folderID: UUID,
        mutation: (inout SessionFolder) -> Void
    ) {
        if folder.id == folderID {
            mutation(&folder)
            return
        }
        for index in folder.folders.indices {
            updateFolder(in: &folder.folders[index], folderID: folderID, mutation: mutation)
        }
    }

    static func deleteSession(in folder: inout SessionFolder, sessionID: UUID) {
        folder.sessions.removeAll { $0.id == sessionID }
        for index in folder.folders.indices {
            deleteSession(in: &folder.folders[index], sessionID: sessionID)
        }
    }

    static func deleteFolder(in folder: inout SessionFolder, folderID: UUID) {
        folder.folders.removeAll { $0.id == folderID }
        for index in folder.folders.indices {
            deleteFolder(in: &folder.folders[index], folderID: folderID)
        }
    }

    static func findParentFolderID(in folder: SessionFolder, sessionID: UUID) -> UUID? {
        if folder.sessions.contains(where: { $0.id == sessionID }) {
            return folder.id
        }
        for child in folder.folders {
            if let match = findParentFolderID(in: child, sessionID: sessionID) {
                return match
            }
        }
        return nil
    }
}

struct DisplayError: Identifiable {
    let id = UUID()
    let message: String
}
