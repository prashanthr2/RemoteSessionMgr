import Foundation

enum SSHLauncherOption: String, CaseIterable, Codable, Identifiable {
    case inApp
    case terminal
    case iTerm2

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inApp:
            return "In-App Tabs"
        case .terminal:
            return "Terminal.app"
        case .iTerm2:
            return "iTerm2"
        }
    }
}

struct AppSettings: Codable {
    var defaultSSHLauncher: SSHLauncherOption
    var rdpCommandTemplate: String

    /// Default RDP command. Uses `sdl-freerdp` (from `brew install freerdp`)
    /// rather than `xfreerdp` because the SDL client renders in a native
    /// window and does not require XQuartz/X11. `/cert:ignore` skips the
    /// certificate-trust prompt so the connection isn't blocked on first use.
    static let defaultRDPCommandTemplate =
        "sdl-freerdp /v:{host} /port:{port} /u:{username} /p:{password} /cert:ignore"

    /// Previous default(s) that predate `sdl-freerdp`. Persisted settings
    /// still holding one of these are migrated to the current default on load.
    static let legacyRDPCommandTemplates = [
        "xfreerdp /v:{host} /u:{username} /port:{port}"
    ]

    static let `default` = AppSettings(
        defaultSSHLauncher: .inApp,
        rdpCommandTemplate: defaultRDPCommandTemplate
    )
}
