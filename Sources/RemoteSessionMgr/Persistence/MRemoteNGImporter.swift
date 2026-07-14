import CommonCrypto
import CryptoKit
import Foundation

/// Parses an mRemoteNG confCons.xml file and converts it into
/// the app's SessionFolder / RemoteSession model hierarchy.
///
/// mRemoteNG encrypts passwords with AES-256-GCM using a PBKDF2-derived key.
/// When the user has not set a custom master password, mRemoteNG derives the
/// key from the hardcoded string "mR3m" (its documented default), not an
/// empty string. We attempt decryption using that default. If decryption
/// fails (e.g. a custom master password was actually set) the password is
/// left blank so the user can fill it in manually.
enum MRemoteNGImporter {

    /// The key mRemoteNG derives from when no custom master password has been set.
    static let defaultMasterPassword = "mR3m"

    enum ImportError: LocalizedError {
        case unreadableFile
        case noConnectionsRoot

        var errorDescription: String? {
            switch self {
            case .unreadableFile:       return "Could not read the selected file."
            case .noConnectionsRoot:    return "No <Connections> root found. Make sure this is a valid mRemoteNG confCons.xml."
            }
        }
    }

    // MARK: – Public entry point

    /// Import sessions from a confCons.xml file.
    /// - Parameters:
    ///   - url: Path to confCons.xml
    ///   - masterPassword: The mRemoteNG master password. Defaults to
    ///     mRemoteNG's own default key, used when the user did not set a
    ///     custom master password (the most common case).
    static func importFolder(from url: URL, masterPassword: String = defaultMasterPassword) throws -> SessionFolder {
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.unreadableFile
        }
        let parser = MRemoteNGXMLParser(masterPassword: masterPassword)
        guard let root = try parser.parse(data: data) else {
            throw ImportError.noConnectionsRoot
        }
        return root
    }
}

// MARK: – XML Parser

private final class MRemoteNGXMLParser: NSObject, XMLParserDelegate {

    private let masterPassword: String
    private var kdfIterations: Int = 1000
    private var folderStack: [SessionFolder] = []
    private var parseError: Error?

    init(masterPassword: String) {
        self.masterPassword = masterPassword
    }

    func parse(data: Data) throws -> SessionFolder? {
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
        if let err = parseError { throw err }
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

        if localName == "Connections" {
            // Read the KDF iteration count from the root element (default 1000)
            if let iters = attributes["KdfIterations"].flatMap(Int.init) {
                kdfIterations = iters
            }
            let name = attributes["Name"] ?? "Imported Connections"
            folderStack.append(SessionFolder(name: name))
            return
        }

        guard localName == "Node" else { return }
        let type = attributes["Type"] ?? ""

        switch type {
        case "Container":
            folderStack.append(SessionFolder(name: attributes["Name"] ?? "Folder"))

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
        guard localName == "Connections" || (localName == "Node" && folderStack.count > 1) else { return }
        if folderStack.count > 1 {
            let finished = folderStack.removeLast()
            folderStack[folderStack.count - 1].folders.append(finished)
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred error: Error) {
        parseError = error
    }

    // MARK: – Helpers

    private func stripNamespace(_ name: String) -> String {
        if let colon = name.firstIndex(of: ":") {
            return String(name[name.index(after: colon)...])
        }
        return name
    }

    private func buildSession(from attrs: [String: String]) -> RemoteSession? {
        let name      = attrs["Name"] ?? "Unnamed"
        let hostname  = attrs["Hostname"] ?? ""
        guard !hostname.isEmpty else { return nil }

        let username  = attrs["Username"] ?? ""
        let rawPw     = attrs["Password"] ?? ""
        let portStr   = attrs["Port"] ?? ""
        let proto_    = attrs["Protocol"] ?? "SSH2"
        let notes     = attrs["Description"] ?? ""

        let proto: SessionProtocol
        switch proto_.uppercased() {
        case "RDP":             proto = .rdp
        case "SSH1", "SSH2":   proto = .ssh
        default:                proto = .ssh
        }

        let port     = Int(portStr) ?? proto.defaultPort
        let password = decryptPassword(rawPw) ?? ""

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

    // MARK: – AES-GCM decryption

    /// mRemoteNG password format (Base64):
    ///   salt[16] | IV[16] | ciphertext[N] | GCM-tag[16]
    /// Key = PBKDF2-HMAC-SHA1(masterPassword, salt, kdfIterations, keyLen=32)
    /// The GCM tag is authenticated with the salt as additional authenticated data.
    private func decryptPassword(_ base64: String) -> String? {
        guard !base64.isEmpty else { return "" }

        // If the value isn't valid base64 or is too short it's likely
        // already plaintext (very old confCons.xml format).
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              data.count >= 48 else {
            return base64
        }

        let salt       = data[0..<16]
        let iv         = data[16..<32]
        let ciphertext = data[32..<(data.count - 16)]
        let tag        = data[(data.count - 16)...]

        // Derive 256-bit key via PBKDF2-HMAC-SHA1
        guard let derivedKey = pbkdf2(password: masterPassword, salt: salt, iterations: kdfIterations) else {
            return nil
        }

        // AES-256-GCM decrypt
        do {
            let symKey    = SymmetricKey(data: derivedKey)
            let nonce     = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            // mRemoteNG authenticates the GCM tag using the salt as additional
            // authenticated data — omitting it makes every decrypt fail.
            let plain     = try AES.GCM.open(sealedBox, using: symKey, authenticating: salt)
            return String(data: plain, encoding: .utf8)
        } catch {
            // Key was wrong (wrong master password) or data is corrupt — return nil
            return nil
        }
    }

    /// PBKDF2-HMAC-SHA1, output 32 bytes.
    private func pbkdf2(password: String, salt: Data, iterations: Int) -> Data? {
        guard let passwordData = password.data(using: .utf8) else { return nil }
        var derivedKey = [UInt8](repeating: 0, count: 32)

        let status: Int32 = passwordData.withUnsafeBytes { pwBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pwBytes.baseAddress, pwBytes.count,
                    saltBytes.baseAddress, saltBytes.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1),
                    UInt32(iterations),
                    &derivedKey, derivedKey.count
                )
            }
        }
        return status == kCCSuccess ? Data(derivedKey) : nil
    }
}
