import Foundation

enum LaunchError: LocalizedError {
    case missingHost
    case missingUsername
    case missingCommand(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingHost:
            return "Host is required before connecting."
        case .missingUsername:
            return "Username is required before connecting."
        case .missingCommand(let message):
            return message
        case .executionFailed(let message):
            return message
        }
    }
}

protocol SessionLaunching {
    func launch(session: RemoteSession, settings: AppSettings) throws
}

struct SessionLauncher: SessionLaunching {
    private let sshLauncher = SSHLauncher()
    private let rdpLauncher = RDPLauncher()

    func launch(session: RemoteSession, settings: AppSettings) throws {
        switch session.protocolType {
        case .ssh:
            try sshLauncher.launch(session: session, launcher: settings.defaultSSHLauncher)
        case .rdp:
            try rdpLauncher.launch(session: session, commandTemplate: settings.rdpCommandTemplate)
        }
    }
}
