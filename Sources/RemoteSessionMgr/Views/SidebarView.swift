import AppKit
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VSplitView {
            List(selection: selectionBinding) {
                ForEach(viewModel.sidebarNodes) { node in
                    OutlineGroup([node], children: \.children) { item in
                        sidebarRow(for: item)
                            .tag(item.id)
                    }
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $viewModel.searchText, placement: .sidebar, prompt: "Search sessions")

            SidebarInspectorView()
                .frame(minHeight: 260, idealHeight: 320)
        }
        .frame(minWidth: 300, idealWidth: 340)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { installDeleteKeyMonitor() }
    }

    // Catch Delete key app-wide so it works regardless of which
    // view currently holds keyboard focus.
    private func installDeleteKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // keyCode 51 = Delete (backspace), 117 = Forward Delete
            guard (event.keyCode == 51 || event.keyCode == 117),
                  event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty,
                  viewModel.selection != nil else {
                return event
            }
            viewModel.deleteSelectedItem()
            return nil  // consume the event
        }
    }

    private var selectionBinding: Binding<SidebarSelection?> {
        Binding(
            get: { viewModel.selection },
            set: { viewModel.handleSelectionChange($0) }
        )
    }

    @ViewBuilder
    private func sidebarRow(for node: SidebarNode) -> some View {
        switch node.kind {
        case .folder:
            Label(node.title, systemImage: "folder")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .contextMenu {
                    Button("New Session in Folder") {
                        viewModel.handleSelectionChange(node.id)
                        viewModel.newSession()
                    }
                    Button("New Subfolder") {
                        viewModel.handleSelectionChange(node.id)
                        viewModel.newFolder()
                    }
                    Divider()
                    Button("Delete Folder", role: .destructive) {
                        viewModel.handleSelectionChange(node.id)
                        viewModel.deleteSelectedItem()
                    }
                }

        case .session:
            VStack(alignment: .leading, spacing: 2) {
                Label(node.title, systemImage: "desktopcomputer")
                if let subtitle = node.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            // Double-click to connect — simultaneousGesture so it doesn't
            // block the context menu or List selection
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    if case .session(let sessionID) = node.id {
                        viewModel.connectSession(withID: sessionID)
                    }
                }
            )
            .contextMenu {
                Button("Connect") {
                    if case .session(let sessionID) = node.id {
                        viewModel.connectSession(withID: sessionID)
                    }
                }
                Divider()
                Button("Delete Session", role: .destructive) {
                    viewModel.handleSelectionChange(node.id)
                    viewModel.deleteSelectedItem()
                }
            }
        }
    }
}
