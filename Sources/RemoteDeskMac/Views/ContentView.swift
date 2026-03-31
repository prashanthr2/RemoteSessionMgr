import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 300, ideal: 340, max: 420)
        } detail: {
            VStack(spacing: 0) {
                if !viewModel.sshTabs.isEmpty {
                    SSHTabBarView()
                    Divider()
                }

                detailPane
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("RemoteDeskMac")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.newSession()
                } label: {
                    Label("New Session", systemImage: "plus.rectangle.on.rectangle")
                }

                Button {
                    viewModel.newFolder()
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }

                Button {
                    viewModel.connectSelectedSession()
                } label: {
                    Label("Connect", systemImage: "bolt.horizontal.circle")
                }
                .disabled(viewModel.selectedSession == nil)

                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Label("Settings", systemImage: "gearshape")
                    }
                } else {
                    Button {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        }
        .alert(item: $viewModel.presentedError) { error in
            Alert(
                title: Text("Connection Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let tab = viewModel.selectedSSHTab {
            SSHConsoleView(tab: tab)
        } else if let session = viewModel.selectedSession {
            SessionEditorView(sessionID: session.id)
        } else if let folder = viewModel.selectedFolder {
            FolderInspectorView(folderID: folder.id)
        } else {
            EmptyStateView()
        }
    }
}
