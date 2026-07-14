import SwiftUI
import UniformTypeIdentifiers

@main
struct RemoteSessionMgrApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .focusedSceneObject(viewModel)
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
    @FocusedSceneObject var viewModel: AppViewModel?

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

        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Delete") {
                viewModel?.deleteSelectedItem()
            }
            .keyboardShortcut(.delete, modifiers: [])
            .disabled(viewModel?.selection == nil)
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
