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

        // Verify the client binary exists. Check the actual first token of the
        // template (e.g. sdl-freerdp, xfreerdp3) rather than assuming a name,
        // and resolve it through the same login shell used to launch it so the
        // PATH matches (Homebrew's /opt/homebrew/bin isn't on the app's default
        // PATH, only on the login shell's).
        let commandName = String(trimmedTemplate.split(separator: " ").first ?? "")
        if !commandName.isEmpty, !commandName.contains("/"), !Self.commandExists(commandName) {
            throw LaunchError.missingCommand("`\(commandName)` was not found. Install it (e.g. `brew install freerdp`) or change the RDP command template in Settings.")
        }

        let command = trimmedTemplate
            .replacingOccurrences(of: "{host}", with: Self.shellQuoted(session.host))
            .replacingOccurrences(of: "{port}", with: Self.shellQuoted(String(session.port)))
            .replacingOccurrences(of: "{username}", with: Self.shellQuoted(session.username))
            .replacingOccurrences(of: "{password}", with: Self.shellQuoted(session.password))
            .replacingOccurrences(of: "{name}", with: Self.shellQuoted(session.name))

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]

        do {
            try process.run()
        } catch {
            throw LaunchError.executionFailed("Failed to launch RDP client: \(error.localizedDescription)")
        }
    }

    /// Wrap a value in single quotes so it survives being spliced into the
    /// shell command string, escaping any embedded single quotes. Prevents
    /// passwords/usernames with spaces or shell metacharacters from breaking
    /// the command or being interpreted by the shell.
    private static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func commandExists(_ command: String) -> Bool {
        // Resolve via a login shell so the PATH matches the one used to launch
        // the client (which includes Homebrew's bin directory).
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "command -v \(shellQuoted(command)) >/dev/null 2>&1"]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
