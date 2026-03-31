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

    static let `default` = AppSettings(
        defaultSSHLauncher: .inApp,
        rdpCommandTemplate: "xfreerdp /v:{host} /u:{username} /port:{port}"
    )
}
