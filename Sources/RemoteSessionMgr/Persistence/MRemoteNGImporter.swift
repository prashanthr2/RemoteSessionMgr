import Foundation

/// Parses an mRemoteNG confCons.xml file and converts it into
/// the app's SessionFolder / RemoteSession model hierarchy.
enum MRemoteNGImporter {

    enum ImportError: LocalizedError {
        case unreadableFile
        case invalidXML
        case noConnectionsRoot

        var errorDescription: String? {
            switch self {
            case .unreadableFile:  return "Could not read the selected file."
            case .invalidXML:     return "The file does not contain valid XML."
            case .noConnectionsRoot: return "No <Connections> root element found. Make sure this is a valid mRemoteNG confCons.xml file."
            }
        }
    }

    // MARK: – Public entry point

    /// Parse the given file URL and return a SessionFolder tree.
    /// The returned folder's name is taken from the XML root's `Name` attribute
    /// (defaulting to "Imported"). Merge this into the library as you see fit.
    static func importFolder(from url: URL) throws -> SessionFolder {
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.unreadableFile
        }

        let parser = MRemoteNGXMLParser()
        guard let root = try parser.parse(data: data) else {
            throw ImportError.noConnectionsRoot
        }
        return root
    }
}

// MARK: – XML Parser

private final class MRemoteNGXMLParser: NSObject, XMLParserDelegate {

    // Each level of the stack represents a folder being built.
    // We push when we enter a Container node and pop when we leave it.
    private var folderStack: [SessionFolder] = []
    private var parseError: Error?

    func parse(data: Data) throws -> SessionFolder? {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()

        if let err = parseError { throw err }

        // After parsing the whole document the stack should contain exactly
        // the root folder we built for the <Connections> element.
        return folderStack.first
    }

    // MARK: – XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes: [String: String] = [:]
    ) {
        let localName = stripNamespace(elementName)

        // The root element is <mrng:Connections> or <Connections>.
        // We treat it exactly like a Container.
        if localName == "Connections" {
            let name = attributes["Name"] ?? "Imported Connections"
            folderStack.append(SessionFolder(name: name))
            return
        }

        guard localName == "Node" else { return }

        let type = attributes["Type"] ?? ""

        switch type {
        case "Container":
            let name = attributes["Name"] ?? "Folder"
            folderStack.append(SessionFolder(name: name))

        case "Connection":
            guard !folderStack.isEmpty else { return }
            if let session = buildSession(from: attributes) {
                folderStack[folderStack.count - 1].sessions.append(session)
            }

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let localName = stripNamespace(elementName)

        // When a Container (or the root Connections) closes, pop it and
        // attach it as a child of the folder below it in the stack.
        guard localName == "Connections" || (localName == "Node" && folderStack.count > 1) else { return }

        // Only pop if there's something above the root to attach to.
        if folderStack.count > 1 {
            let finished = folderStack.removeLast()
            folderStack[folderStack.count - 1].folders.append(finished)
        }
        // When Connections closes and there's only the root left, leave it.
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    // MARK: – Helpers

    private func stripNamespace(_ name: String) -> String {
        // mRemoteNG uses "mrng:Connections" – strip the prefix.
        if let colon = name.firstIndex(of: ":") {
            return String(name[name.index(after: colon)...])
        }
        return name
    }

    /// Map mRemoteNG connection attributes → RemoteSession.
    private func buildSession(from attrs: [String: String]) -> RemoteSession? {
        let name     = attrs["Name"] ?? "Unnamed"
        let hostname = attrs["Hostname"] ?? ""
        guard !hostname.isEmpty else { return nil }

        let username = attrs["Username"] ?? ""
        let password = attrs["Password"] ?? ""
        let portStr  = attrs["Port"] ?? ""
        let protocol_ = attrs["Protocol"] ?? "SSH2"
        let notes    = attrs["Description"] ?? ""

        let proto: SessionProtocol
        switch protocol_.uppercased() {
        case "RDP":
            proto = .rdp
        case "SSH1", "SSH2":
            proto = .ssh
        default:
            // Skip unsupported protocol types (VNC, Telnet, etc.)
            // but still try to import as SSH if we can't tell.
            proto = .ssh
        }

        let port = Int(portStr) ?? proto.defaultPort

        return RemoteSession(
            name: name,
            protocolType: proto,
            host: hostname,
            port: port,
            username: username,
            password: password,
            notes: notes
        )
    }
}
