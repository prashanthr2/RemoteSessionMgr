import AppKit
import Foundation

struct SSHLauncher {
    func launch(session: RemoteSession, launcher: SSHLauncherOption) throws {
        guard !session.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LaunchError.missingHost
        }
        guard !session.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LaunchError.missingUsername
        }

        let sshCommand = "ssh \(ShellCommand.shellQuote("\(session.username)@\(session.host)")) -p \(session.port)"

        switch launcher {
        case .inApp:
            throw LaunchError.executionFailed("Use the in-app session tabs to connect to SSH when In-App Tabs is selected.")
        case .terminal:
            try runAppleScript(lines: [
                "tell application \"Terminal\" to activate",
                "tell application \"Terminal\" to do script \"\(ShellCommand.appleScriptQuote(sshCommand))\""
            ])
        case .iTerm2:
            guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.iterm2") != nil else {
                throw LaunchError.missingCommand("iTerm2 is not installed or could not be found.")
            }

            try runAppleScript(lines: [
                "tell application \"iTerm2\" to activate",
                "tell application \"iTerm2\"",
                "if (count of windows) = 0 then",
                "create window with default profile command \"\(ShellCommand.appleScriptQuote(sshCommand))\"",
                "else",
                "tell current window to create tab with default profile command \"\(ShellCommand.appleScriptQuote(sshCommand))\"",
                "end if",
                "end tell"
            ])
        }
    }

    private func runAppleScript(lines: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = lines.flatMap { ["-e", $0] }

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw LaunchError.executionFailed(message?.isEmpty == false ? message! : "Failed to launch SSH session.")
        }
    }
}
