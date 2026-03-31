import AppKit
import Foundation
import SwiftTerm

enum EmbeddedSSHSessionState: Equatable {
    case connecting
    case connected
    case disconnected(Int32)

    var label: String {
        switch self {
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .disconnected(let code):
            return code == 0 ? "Disconnected" : "Exited (\(code))"
        }
    }
}

@MainActor
final class EmbeddedSSHSession: NSObject, ObservableObject, Identifiable, LocalProcessTerminalViewDelegate {
    let id = UUID()
    let sourceSessionID: UUID
    let host: String
    let username: String
    let port: Int
    let terminalView: PasswordAwareTerminalView

    @Published var title: String
    @Published var state: EmbeddedSSHSessionState = .connecting
    @Published var currentDirectory: String?

    var isDisconnected: Bool {
        if case .disconnected = state {
            return true
        }
        return false
    }

    var shouldFocusTerminal = true

    private let sessionName: String
    private let password: String
    private var hasStarted = false

    init(session: RemoteSession) {
        sourceSessionID = session.id
        sessionName = session.name
        title = session.name
        host = session.host
        username = session.username
        port = session.port
        password = session.password
        terminalView = PasswordAwareTerminalView(frame: .zero)
        super.init()
        configureTerminal()
    }

    func start() {
        guard !hasStarted else {
            shouldFocusTerminal = true
            return
        }

        hasStarted = true
        state = .connecting
        shouldFocusTerminal = true
        terminalView.prepareForNewConnection()

        var environment = ProcessInfo.processInfo.environment
        environment["TERM"] = "xterm-256color"

        terminalView.startProcess(
            executable: "/usr/bin/ssh",
            args: [
                "-o", "ServerAliveInterval=30",
                "-o", "ServerAliveCountMax=3",
                "-p", String(port),
                "\(username)@\(host)"
            ],
            environment: environment.map { "\($0.key)=\($0.value)" }
        )
    }

    func disconnect() {
        terminalView.terminate()
        state = .disconnected(0)
    }

    private func configureTerminal() {
        terminalView.processDelegate = self
        terminalView.passwordProvider = { [weak self] in
            guard let self else { return nil }
            return self.password.isEmpty ? nil : self.password
        }
        terminalView.metalBufferingMode = .perFrameAggregated
        try? terminalView.setUseMetal(false)

        let foreground = NSColor(
            calibratedRed: CGFloat(0xcc) / 255.0,
            green: CGFloat(0xcc) / 255.0,
            blue: CGFloat(0xcc) / 255.0,
            alpha: 1.0
        )
        let background = NSColor(
            calibratedRed: CGFloat(0x16) / 255.0,
            green: CGFloat(0x18) / 255.0,
            blue: CGFloat(0x1b) / 255.0,
            alpha: 1.0
        )

        terminalView.nativeForegroundColor = foreground
        terminalView.nativeBackgroundColor = background
        terminalView.layer?.backgroundColor = background.cgColor
        terminalView.caretColor = .systemGreen
        terminalView.getTerminal().setCursorStyle(.steadyBlock)
    }

    nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
    }

    nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        Task { @MainActor in
            self.title = self.sessionName
            if self.state == .connecting {
                self.state = .connected
            }
        }
    }

    nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        Task { @MainActor in
            self.currentDirectory = directory
            if self.state == .connecting {
                self.state = .connected
            }
        }
    }

    nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
        Task { @MainActor in
            self.state = .disconnected(exitCode ?? -1)
        }
    }
}

final class PasswordAwareTerminalView: LocalProcessTerminalView {
    var passwordProvider: (() -> String?)?

    private var trailingOutput = ""
    private var hasSentPassword = false

    override func dataReceived(slice: ArraySlice<UInt8>) {
        super.dataReceived(slice: slice)

        let chunk = String(decoding: slice, as: UTF8.self)
        trailingOutput.append(chunk)
        if trailingOutput.count > 512 {
            trailingOutput = String(trailingOutput.suffix(512))
        }

        guard !hasSentPassword else { return }
        guard let password = passwordProvider?(), !password.isEmpty else { return }
        guard trailingOutput.localizedCaseInsensitiveContains("password:") else { return }

        hasSentPassword = true
        let bytes = Array((password + "\n").utf8)
        send(source: self, data: bytes[...])
    }

    func prepareForNewConnection() {
        trailingOutput.removeAll(keepingCapacity: true)
        hasSentPassword = false
    }
}
