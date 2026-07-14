import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
                }

                detailPane
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("RemoteSessionMgr")
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
