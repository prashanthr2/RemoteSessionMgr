import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct RemoteSessionMgrApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .focusedObject(viewModel)
        }
        .defaultSize(width: 1200, height: 760)
        .commands {
            AppCommands()
        }

        Settings {
            SettingsView()
                .environmentObject(viewModel)
                .frame(width: 520, height: 280)
                .padding(20)
        }
    }
}

struct AppCommands: Commands {
    @FocusedObject var viewModel: AppViewModel?

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Folder") {
                viewModel?.newFolder()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(viewModel == nil)

            Divider()

            Button("Import mRemoteNG Connections…") {
                openImportPanel()
            }
            .disabled(viewModel == nil)
        }

        // Replace SwiftUI's default pasteboard commands. The built-in ones
        // route through SwiftUI's own focus state and never reach the embedded
        // AppKit terminal view, so ⌘C/⌘V do nothing in an SSH session. These
        // dispatch the standard selectors down the responder chain instead,
        // which reaches both the terminal and the sidebar's text field.
        CommandGroup(replacing: .pasteboard) {
            Button("Cut") {
                NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("x", modifiers: .command)

            Button("Copy") {
                NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Paste") {
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("v", modifiers: .command)

            Button("Select All") {
                NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("a", modifiers: .command)
        }

        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Delete") {
                viewModel?.deleteSelectedItem()
            }
            .keyboardShortcut(.delete, modifiers: [])
        }
    }

    private func openImportPanel() {
        let panel = NSOpenPanel()
        panel.title = "Import mRemoteNG Connections"
        panel.message = "Select your mRemoteNG confCons.xml file"
        panel.allowedContentTypes = [.xml]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            viewModel?.importMRemoteNG(from: url)
        }
    }
}
