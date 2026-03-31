import Foundation

struct RDPLauncher {
    func launch(session: RemoteSession, commandTemplate: String) throws {
        guard !session.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LaunchError.missingHost
        }

        let trimmedTemplate = commandTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTemplate.isEmpty else {
            throw LaunchError.missingCommand("Set an RDP command template in Settings before connecting.")
        }

        if trimmedTemplate.hasPrefix("xfreerdp"), !Self.commandExists("xfreerdp") {
            throw LaunchError.missingCommand("`xfreerdp` was not found. Install it or change the RDP command template in Settings.")
        }

        let command = trimmedTemplate
            .replacingOccurrences(of: "{host}", with: session.host)
            .replacingOccurrences(of: "{port}", with: String(session.port))
            .replacingOccurrences(of: "{username}", with: session.username)
            .replacingOccurrences(of: "{name}", with: session.name)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]

        do {
            try process.run()
        } catch {
            throw LaunchError.executionFailed("Failed to launch RDP client: \(error.localizedDescription)")
        }
    }

    private static func commandExists(_ command: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
